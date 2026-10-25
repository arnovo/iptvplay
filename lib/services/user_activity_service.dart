import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playback_progress.dart';
import '../models/channel.dart';

class UserActivityService {
  static const String _keyFavLive = 'fav_channels';
  static const String _keyFavVod = 'fav_vods';
  static const String _keyFavSeries = 'fav_series';
  static const String _keyRecentChannels = 'recent_channels';
  static const String _keyPlaybackProgress = 'playback_progress';

  Future<Set<String>> getFavorites(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKeyForType(type);
    final list = prefs.getStringList(key) ?? [];
    return list.toSet();
  }

  Future<void> toggleFavorite(String id, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKeyForType(type);
    final set = (prefs.getStringList(key) ?? []).toSet();

    if (set.contains(id)) {
      set.remove(id);
    } else {
      set.add(id);
    }

    await prefs.setStringList(key, set.toList());
  }

  String _getKeyForType(String type) {
    switch (type) {
      case 'live':
        return _keyFavLive;
      case 'vod':
        return _keyFavVod;
      case 'series':
        return _keyFavSeries;
      default:
        return _keyFavLive;
    }
  }

  Future<List<PlaybackProgress>> getAllPlaybackProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_keyPlaybackProgress) ?? [];
    final items = <PlaybackProgress>[];

    for (final raw in rawList) {
      try {
        items.add(PlaybackProgress.fromJson(raw));
      } catch (_) {}
    }

    items.sort((a, b) => b.lastWatched.compareTo(a.lastWatched));
    return items;
  }

  Future<void> savePlaybackProgress(PlaybackProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getAllPlaybackProgress();
    
    // Remove if already exists
    items.removeWhere((p) => p.id == progress.id);

    // Only keep if watched less than 95% (if completed, don't keep in continue watching)
    if (progress.progressFraction < 0.95 && progress.positionSeconds > 10) {
      items.insert(0, progress);
    }

    // Keep maximum 30 items
    if (items.length > 30) {
      items.removeRange(30, items.length);
    }

    final rawList = items.map((p) => p.toJson()).toList();
    await prefs.setStringList(_keyPlaybackProgress, rawList);
  }

  Future<List<Map<String, dynamic>>> getRecentChannelsRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_keyRecentChannels) ?? [];
    return rawList.map((e) {
      try {
        return json.decode(e) as Map<String, dynamic>;
      } catch (_) {
        return <String, dynamic>{};
      }
    }).where((m) => m.isNotEmpty).toList();
  }

  Future<void> addRecentChannel(Channel channel) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getRecentChannelsRaw();
    current.removeWhere((item) => item['id'] == channel.id);

    current.insert(0, {
      'id': channel.id,
      'name': channel.name,
      'url': channel.url,
      'logoUrl': channel.logoUrl,
      'categoryId': channel.categoryId,
      'groupTitle': channel.groupTitle,
      'channelNumber': channel.channelNumber,
      'epgChannelId': channel.epgChannelId,
    });

    if (current.length > 25) {
      current.removeRange(25, current.length);
    }

    final rawList = current.map((e) => json.encode(e)).toList();
    await prefs.setStringList(_keyRecentChannels, rawList);
  }
}
