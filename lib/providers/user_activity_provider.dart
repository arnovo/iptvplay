import 'package:flutter/foundation.dart';
import '../models/playback_progress.dart';
import '../models/channel.dart';
import '../services/user_activity_service.dart';

class UserActivityProvider extends ChangeNotifier {
  final UserActivityService _service = UserActivityService();

  Set<String> _favLive = {};
  Set<String> _favVod = {};
  Set<String> _favSeries = {};

  List<PlaybackProgress> _continueWatching = [];
  List<Channel> _recentChannels = [];

  Set<String> get favLive => _favLive;
  Set<String> get favVod => _favVod;
  Set<String> get favSeries => _favSeries;
  List<PlaybackProgress> get continueWatching => _continueWatching;
  List<Channel> get recentChannels => _recentChannels;

  UserActivityProvider() {
    loadActivity();
  }

  Future<void> loadActivity() async {
    _favLive = await _service.getFavorites('live');
    _favVod = await _service.getFavorites('vod');
    _favSeries = await _service.getFavorites('series');
    _continueWatching = await _service.getAllPlaybackProgress();

    final rawRecents = await _service.getRecentChannelsRaw();
    _recentChannels = rawRecents.map((m) {
      return Channel(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        url: m['url'] ?? '',
        logoUrl: m['logoUrl'],
        categoryId: m['categoryId'] ?? 'all',
        groupTitle: m['groupTitle'],
        channelNumber: m['channelNumber'],
        epgChannelId: m['epgChannelId'],
      );
    }).toList();

    notifyListeners();
  }

  bool isFavorite(String id, String type) {
    switch (type) {
      case 'live':
        return _favLive.contains(id);
      case 'vod':
        return _favVod.contains(id);
      case 'series':
        return _favSeries.contains(id);
      default:
        return false;
    }
  }

  Future<void> toggleFavorite(String id, String type) async {
    await _service.toggleFavorite(id, type);
    switch (type) {
      case 'live':
        _favLive = await _service.getFavorites('live');
        break;
      case 'vod':
        _favVod = await _service.getFavorites('vod');
        break;
      case 'series':
        _favSeries = await _service.getFavorites('series');
        break;
    }
    notifyListeners();
  }

  PlaybackProgress? getProgress(String id) {
    try {
      return _continueWatching.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProgress({
    required String id,
    required String title,
    required String url,
    String? posterUrl,
    required int positionSeconds,
    required int durationSeconds,
    required String type,
    String? seriesTitle,
  }) async {
    final progress = PlaybackProgress(
      id: id,
      title: title,
      url: url,
      posterUrl: posterUrl,
      positionSeconds: positionSeconds,
      durationSeconds: durationSeconds,
      lastWatched: DateTime.now(),
      type: type,
      seriesTitle: seriesTitle,
    );

    await _service.savePlaybackProgress(progress);
    _continueWatching = await _service.getAllPlaybackProgress();
    notifyListeners();
  }

  Future<void> addRecentChannel(Channel channel) async {
    await _service.addRecentChannel(channel);
    final rawRecents = await _service.getRecentChannelsRaw();
    _recentChannels = rawRecents.map((m) {
      return Channel(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        url: m['url'] ?? '',
        logoUrl: m['logoUrl'],
        categoryId: m['categoryId'] ?? 'all',
        groupTitle: m['groupTitle'],
        channelNumber: m['channelNumber'],
        epgChannelId: m['epgChannelId'],
      );
    }).toList();
    notifyListeners();
  }

  Future<void> removeRecentChannel(String channelId) async {
    await _service.removeRecentChannel(channelId);
    _recentChannels.removeWhere((c) => c.id == channelId);
    notifyListeners();
  }

  Future<void> clearRecentChannels() async {
    await _service.clearRecentChannels();
    _recentChannels.clear();
    notifyListeners();
  }
}
