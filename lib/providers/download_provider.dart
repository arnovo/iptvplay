import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/download_item.dart';
import '../services/download_service.dart';

class DownloadProvider extends ChangeNotifier {
  final DownloadService _service = DownloadService();
  List<DownloadItem> _items = [];
  bool _isInitialized = false;
  final Completer<void> _initCompleter = Completer<void>();

  bool get isInitialized => _isInitialized;
  Future<void> get initialized => _initCompleter.future;

  List<DownloadItem> get items => _items;
  List<DownloadItem> get completedItems =>
      _items.where((i) => i.status == DownloadStatus.completed).toList();
  List<DownloadItem> get activeRecordings =>
      _items.where((i) => i.status == DownloadStatus.recording).toList();
  List<DownloadItem> get pausedDownloads =>
      _items.where((i) => i.status == DownloadStatus.paused).toList();

  String? _currentStoragePath;
  String? _customStoragePath;
  String? get currentStoragePath => _currentStoragePath;
  bool get hasCustomStoragePath => _customStoragePath != null;

  int get totalStorageBytes {
    int total = 0;
    for (final item in _items) {
      if (item.status == DownloadStatus.completed) {
        total += item.totalBytes > 0 ? item.totalBytes : item.downloadedBytes;
      } else if (item.status == DownloadStatus.downloading ||
          item.status == DownloadStatus.paused ||
          item.status == DownloadStatus.recording) {
        total += item.downloadedBytes;
      }
    }
    return total;
  }

  String get formattedTotalStorage {
    final bytes = totalStorageBytes;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  DownloadProvider() {
    _init();
  }

  Future<void> _init() async {
    if (_isInitialized) return;
    if (kIsWeb) {
      _isInitialized = true;
      if (!_initCompleter.isCompleted) _initCompleter.complete();
      notifyListeners();
      return;
    }
    _items = await _service.loadDownloadsMetadata();
    final List<DownloadItem> valid = [];
    bool metadataChanged = false;

    for (final item in _items) {
      // Automatic migration: if file was saved with underscore (vod_id_mkv), rename to proper dot extension (vod_id.mkv)
      var currentItem = item;
      if (item.localFilePath.endsWith('_mkv') || item.localFilePath.endsWith('_mp4')) {
        final ext = item.localFilePath.endsWith('_mkv') ? 'mkv' : 'mp4';
        final newPath = item.localFilePath.replaceAll(RegExp(r'_(mkv|mp4)$'), '.$ext');
        final oldFile = File(item.localFilePath);
        if (await oldFile.exists()) {
          try {
            await oldFile.rename(newPath);
            currentItem = item.copyWith(localFilePath: newPath);
            metadataChanged = true;
          } catch (_) {}
        }
      }

      final file = File(currentItem.localFilePath);
      final exists = await file.exists();
      if (!exists) {
        metadataChanged = true;
        continue;
      }

      final fileSize = await file.length();

      // If app was killed while recording live TV: keep what was captured
      if (currentItem.status == DownloadStatus.recording) {
        valid.add(currentItem.copyWith(
          status: DownloadStatus.completed,
          totalBytes: fileSize,
          downloadedBytes: fileSize,
        ));
        metadataChanged = true;
      }
      // If app was closed during a VOD download: keep partial file and mark paused
      else if (currentItem.status == DownloadStatus.downloading) {
        valid.add(currentItem.copyWith(
          status: DownloadStatus.paused,
          downloadedBytes: fileSize,
        ));
        metadataChanged = true;
      } else {
        valid.add(currentItem);
      }
    }

    _items = valid;
    if (metadataChanged) {
      await _service.saveDownloadsMetadata(_items);
    }
    _customStoragePath = await _service.getCustomStorageDirectory();
    _currentStoragePath = await _service.getStorageDirectoryPath();
    _isInitialized = true;
    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
    notifyListeners();
  }

  Future<void> changeStorageDirectory(String newPath) async {
    await _service.setCustomStorageDirectory(newPath);
    _customStoragePath = newPath;
    _currentStoragePath = newPath;
    notifyListeners();
  }

  Future<void> resetStorageDirectory() async {
    await _service.resetStorageDirectory();
    _customStoragePath = null;
    _currentStoragePath = await _service.getStorageDirectoryPath();
    notifyListeners();
  }

  Future<void> openStorageDirectory() async {
    final path = _currentStoragePath ?? await _service.getStorageDirectoryPath();
    await DownloadService.openInFileManager(path);
  }

  Future<void> openItemInFileManager(DownloadItem item) async {
    await DownloadService.openInFileManager(item.localFilePath);
  }

  Future<void> openPathInFileManager(String path) async {
    await DownloadService.openInFileManager(path);
  }

  Future<void> resumeAllPaused() async {
    final paused = List<DownloadItem>.from(pausedDownloads);
    for (final item in paused) {
      await resumeDownload(item.id);
    }
  }

  bool isChannelRecording(String channelId) {
    return _service.isRecording(channelId);
  }

  Future<void> toggleLiveRecording({
    required String channelId,
    required String title,
    required String streamUrl,
    String? posterUrl,
  }) async {
    if (isChannelRecording(channelId)) {
      await _service.stopLiveRecording(channelId);
      final idx = _items.indexWhere((i) => i.id == channelId && i.status == DownloadStatus.recording);
      if (idx != -1) {
        final existing = _items[idx];
        final file = File(existing.localFilePath);
        final size = await file.exists() ? await file.length() : 0;
        _items[idx] = existing.copyWith(
          status: DownloadStatus.completed,
          totalBytes: size,
          downloadedBytes: size,
        );
        await _service.saveDownloadsMetadata(_items);
      }
    } else {
      final item = await _service.startLiveRecording(
        channelId: channelId,
        title: title,
        streamUrl: streamUrl,
        posterUrl: posterUrl,
        onByteUpdate: (bytes, speed) {
          final idx = _items.indexWhere((i) => i.id == channelId && i.status == DownloadStatus.recording);
          if (idx != -1) {
            _items[idx] = _items[idx].copyWith(
              downloadedBytes: bytes,
              speedBytesPerSecond: speed,
            );
            notifyListeners();
          }
        },
      );
      _items.insert(0, item);
      await _service.saveDownloadsMetadata(_items);
    }
    notifyListeners();
  }

  Future<void> startVodDownload({
    required String id,
    required String title,
    required String streamUrl,
    required String type,
    String? posterUrl,
  }) async {
    // Check if already downloading or completed
    if (_items.any((i) => i.id == id && i.status == DownloadStatus.completed)) {
      return;
    }

    final localPath = await _service.getVodFilePath(id, streamUrl);

    final initial = DownloadItem(
      id: id,
      title: title,
      originalUrl: streamUrl,
      localFilePath: localPath,
      posterUrl: posterUrl,
      type: type,
      status: DownloadStatus.downloading,
      createdAt: DateTime.now(),
    );
    _items.insert(0, initial);
    await _service.saveDownloadsMetadata(_items);
    notifyListeners();

    _executeVodDownload(initial);
  }

  Future<void> pauseDownload(String id) async {
    _service.cancelDownload(id);
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final item = _items[idx];
      final file = File(item.localFilePath);
      final size = await file.exists() ? await file.length() : item.downloadedBytes;
      _items[idx] = item.copyWith(
        status: DownloadStatus.paused,
        downloadedBytes: size,
        speedBytesPerSecond: 0.0,
      );
      await _service.saveDownloadsMetadata(_items);
      notifyListeners();
    }
  }

  Future<void> resumeDownload(String id) async {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx == -1) return;

    final item = _items[idx];
    _items[idx] = item.copyWith(
      status: DownloadStatus.downloading,
      speedBytesPerSecond: 0.0,
    );
    notifyListeners();

    _executeVodDownload(item);
  }

  Future<void> _executeVodDownload(DownloadItem item) async {
    await _service.downloadVod(
      id: item.id,
      title: item.title,
      streamUrl: item.originalUrl,
      type: item.type,
      posterUrl: item.posterUrl,
      existingFilePath: item.localFilePath,
      onProgress: (received, total, speed) {
        final idx = _items.indexWhere((i) => i.id == item.id);
        if (idx != -1) {
          _items[idx] = _items[idx].copyWith(
            downloadedBytes: received,
            totalBytes: total > 0 ? total : _items[idx].totalBytes,
            speedBytesPerSecond: speed,
          );
          notifyListeners();
        }
      },
      onComplete: (completed) async {
        final idx = _items.indexWhere((i) => i.id == item.id);
        if (idx != -1) {
          _items[idx] = completed.copyWith(speedBytesPerSecond: 0.0);
          await _service.saveDownloadsMetadata(_items);
          notifyListeners();
        }
      },
      onError: (err) async {
        final idx = _items.indexWhere((i) => i.id == item.id);
        if (idx != -1) {
          if (_items[idx].status != DownloadStatus.paused) {
            _items[idx] = _items[idx].copyWith(
              status: DownloadStatus.failed,
              speedBytesPerSecond: 0.0,
            );
            await _service.saveDownloadsMetadata(_items);
            notifyListeners();
          }
        }
      },
    );
  }

  Future<void> deleteDownload(String id) async {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final item = _items[idx];
      final file = File(item.localFilePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      _items.removeAt(idx);
      await _service.saveDownloadsMetadata(_items);
      notifyListeners();
    }
  }
}
