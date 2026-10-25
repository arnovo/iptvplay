import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/epg_program.dart';
import '../models/playlist_profile.dart';
import '../services/epg_service.dart';

class EpgProvider extends ChangeNotifier {
  final EpgService _epgService = EpgService();
  Map<String, List<EpgProgram>> _epgData = {};
  bool _isLoading = false;
  Timer? _tickerTimer;

  Map<String, List<EpgProgram>> get epgData => _epgData;
  bool get isLoading => _isLoading;

  EpgProvider() {
    // Ticker every minute to update progress bars of active shows
    _tickerTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  Future<void> loadEpg(PlaylistProfile profile, {bool forceRefresh = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Try cache first
      if (!forceRefresh) {
        final cached = await _epgService.loadEpgCache(profile.id);
        if (cached.isNotEmpty) {
          _epgData = cached;
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // Check if profile is Xtream Codes or M3U with XMLTV
      if (profile.type == PlaylistType.xtream && profile.serverUrl != null && profile.username != null && profile.password != null) {
        final server = profile.serverUrl!;
        final cleanServer = server.endsWith('/') ? server.substring(0, server.length - 1) : server;
        final xmltvUrl = '$cleanServer/xmltv.php?username=${profile.username}&password=${profile.password}';
        final parsed = await _epgService.fetchAndParseXmltv(xmltvUrl, profileId: profile.id);
        if (parsed.isNotEmpty) {
          _epgData = parsed;
        }
      } else if (profile.m3uUrl != null && profile.m3uUrl!.isNotEmpty) {
        // Look for companion EPG URL if standard
        final uri = Uri.tryParse(profile.m3uUrl!);
        if (uri != null) {
          // If M3U contains an epg / xmltv query or brother file
          final epgCandidate = profile.m3uUrl!.replaceAll(RegExp(r'\.m3u8?(\?.*)?$'), '.xml.gz');
          final parsed = await _epgService.fetchAndParseXmltv(epgCandidate, profileId: profile.id);
          if (parsed.isNotEmpty) {
            _epgData = parsed;
          }
        }
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  /// Finds current active program for channel
  EpgProgram? getCurrentProgram(String channelId, {String? channelTvgId, String? channelName}) {
    List<EpgProgram>? list = _epgData[channelId];
    if (list == null && channelTvgId != null) {
      list = _epgData[channelTvgId];
    }
    if (list == null && channelName != null) {
      list = _epgData[channelName];
    }
    if (list == null || list.isEmpty) return null;

    final now = DateTime.now();
    for (final p in list) {
      if (now.isAfter(p.start) && now.isBefore(p.end)) {
        return p;
      }
    }
    // Fallback: next upcoming
    for (final p in list) {
      if (p.start.isAfter(now)) return p;
    }
    return list.firstOrNull;
  }

  /// Returns upcoming programs for a channel
  List<EpgProgram> getChannelSchedule(String channelId, {String? channelTvgId, String? channelName}) {
    List<EpgProgram>? list = _epgData[channelId];
    if (list == null && channelTvgId != null) {
      list = _epgData[channelTvgId];
    }
    if (list == null && channelName != null) {
      list = _epgData[channelName];
    }
    return list ?? [];
  }

  /// Fetches short EPG on-demand for a single channel (useful for Xtream)
  Future<List<EpgProgram>> fetchChannelEpgOnDemand({
    required PlaylistProfile profile,
    required String streamId,
  }) async {
    if (profile.type != PlaylistType.xtream || profile.serverUrl == null || profile.username == null || profile.password == null) {
      return getChannelSchedule(streamId);
    }

    final programs = await _epgService.fetchXtreamShortEpg(
      serverUrl: profile.serverUrl!,
      username: profile.username!,
      password: profile.password!,
      streamId: streamId,
    );

    if (programs.isNotEmpty) {
      _epgData[streamId] = programs;
      notifyListeners();
    }
    return programs;
  }
}
