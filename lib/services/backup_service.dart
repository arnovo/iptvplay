import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/playlist_profile.dart';
import '../models/playback_progress.dart';
import 'storage_service.dart';
import 'user_activity_service.dart';

class BackupData {
  final int version;
  final DateTime exportedAt;
  final List<PlaylistProfile> profiles;
  final String? activeProfileId;
  final List<String> favLive;
  final List<String> favVod;
  final List<String> favSeries;
  final List<PlaybackProgress> progressList;

  BackupData({
    required this.version,
    required this.exportedAt,
    required this.profiles,
    this.activeProfileId,
    required this.favLive,
    required this.favVod,
    required this.favSeries,
    required this.progressList,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'app': 'IPTV Play',
        'exportedAt': exportedAt.toIso8601String(),
        'profiles': profiles.map((p) => p.toJson()).toList(),
        'activeProfileId': activeProfileId,
        'favorites': {
          'live': favLive,
          'vod': favVod,
          'series': favSeries,
        },
        'progress': progressList.map((p) => p.toJson()).toList(),
      };

  factory BackupData.fromJson(Map<String, dynamic> json) {
    final favMap = json['favorites'] as Map<String, dynamic>? ?? {};
    final profilesRaw = (json['profiles'] as List?) ?? [];
    final progressRaw = (json['progress'] as List?) ?? [];

    return BackupData(
      version: json['version'] ?? 1,
      exportedAt: DateTime.tryParse(json['exportedAt'] ?? '') ?? DateTime.now(),
      profiles: profilesRaw.map((p) => PlaylistProfile.fromJson(p)).toList(),
      activeProfileId: json['activeProfileId'],
      favLive: (favMap['live'] as List?)?.map((e) => e.toString()).toList() ?? [],
      favVod: (favMap['vod'] as List?)?.map((e) => e.toString()).toList() ?? [],
      favSeries: (favMap['series'] as List?)?.map((e) => e.toString()).toList() ?? [],
      progressList: progressRaw.map((p) => PlaybackProgress.fromJson(p)).toList(),
    );
  }
}

class BackupService {
  final StorageService _storageService = StorageService();
  final UserActivityService _activityService = UserActivityService();

  /// Create backup data structure from current local storage
  Future<BackupData> createBackupData() async {
    final profiles = await _storageService.getProfiles();
    final activeId = await _storageService.getActiveProfileId();

    final favLive = (await _activityService.getFavorites('live')).toList();
    final favVod = (await _activityService.getFavorites('vod')).toList();
    final favSeries = (await _activityService.getFavorites('series')).toList();
    final progress = await _activityService.getAllPlaybackProgress();

    return BackupData(
      version: 1,
      exportedAt: DateTime.now(),
      profiles: profiles,
      activeProfileId: activeId,
      favLive: favLive,
      favVod: favVod,
      favSeries: favSeries,
      progressList: progress,
    );
  }

  /// Export backup to a file chosen by the user
  Future<String?> exportBackupToFile() async {
    final backup = await createBackupData();
    final jsonString = const JsonEncoder.withIndent('  ').convert(backup.toJson());

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final now = DateTime.now();
    final filename = 'iptv_backup_${now.year}${twoDigits(now.month)}${twoDigits(now.day)}_${twoDigits(now.hour)}${twoDigits(now.minute)}.json';

    try {
      final uri = await FilePicker.saveFile(
        dialogTitle: 'Guardar copia de seguridad',
        fileName: filename,
        bytes: utf8.encode(jsonString),
      );
      if (uri != null) {
        return uri.toFilePath();
      }
    } catch (_) {}

    // Fallback to user Downloads if dialog cancelled or returns null on some platforms
    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir != null) {
      final selectedPath = '${downloadsDir.path}/$filename';
      final file = File(selectedPath);
      await file.writeAsString(jsonString);
      return selectedPath;
    }
    return null;
  }

  /// Import backup file selected by the user
  Future<bool> importBackupFromFile() async {
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Seleccionar copia de seguridad',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result.isEmpty || result.first.path == null) {
        return false;
      }

      final file = File(result.first.path!);
      final content = await file.readAsString();
      return await restoreBackupFromJson(content);
    } catch (_) {
      return false;
    }
  }

  /// Restore backup data into local storage
  Future<bool> restoreBackupFromJson(String jsonString) async {
    try {
      final Map<String, dynamic> parsed = jsonDecode(jsonString);
      final backup = BackupData.fromJson(parsed);

      // Save profiles
      await _storageService.saveProfiles(backup.profiles);
      if (backup.activeProfileId != null) {
        await _storageService.setActiveProfileId(backup.activeProfileId!);
      }

      // Save favorites
      for (final id in backup.favLive) {
        await _activityService.toggleFavorite(id, 'live');
      }
      for (final id in backup.favVod) {
        await _activityService.toggleFavorite(id, 'vod');
      }
      for (final id in backup.favSeries) {
        await _activityService.toggleFavorite(id, 'series');
      }

      // Save playback progress
      for (final p in backup.progressList) {
        await _activityService.savePlaybackProgress(p);
      }

      return true;
    } catch (_) {
      return false;
    }
  }
}
