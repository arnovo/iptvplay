import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'web_storage_service.dart';
import '../models/playlist_profile.dart';
import '../models/channel.dart';
import '../models/vod_item.dart';
import '../models/series_item.dart';
import '../models/category.dart';
import 'm3u_parser_service.dart';
import 'xtream_service.dart';

class LoadedContent {
  final List<Channel> channels;
  final List<VodItem> vods;
  final List<SeriesItem> series;
  final List<ContentCategory> liveCategories;
  final List<ContentCategory> vodCategories;
  final List<ContentCategory> seriesCategories;

  LoadedContent({
    required this.channels,
    required this.vods,
    required this.series,
    required this.liveCategories,
    required this.vodCategories,
    required this.seriesCategories,
  });

  factory LoadedContent.empty() {
    return LoadedContent(
      channels: [],
      vods: [],
      series: [],
      liveCategories: [],
      vodCategories: [],
      seriesCategories: [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'channels': channels.map((c) => {
        'id': c.id,
        'name': c.name,
        'url': c.url,
        'logoUrl': c.logoUrl,
        'categoryId': c.categoryId,
        'groupTitle': c.groupTitle,
        'epgChannelId': c.epgChannelId,
        'channelNumber': c.channelNumber,
      }).toList(),
      'vods': vods.map((v) => {
        'id': v.id,
        'name': v.name,
        'url': v.url,
        'posterUrl': v.posterUrl,
        'categoryId': v.categoryId,
        'rating': v.rating,
        'releaseDate': v.releaseDate,
        'containerExtension': v.containerExtension,
      }).toList(),
      'series': series.map((s) => {
        'id': s.id,
        'name': s.name,
        'posterUrl': s.posterUrl,
        'categoryId': s.categoryId,
        'rating': s.rating,
        'releaseDate': s.releaseDate,
        'plot': s.plot,
        'episodes': s.episodes.map((e) => {
          'id': e.id,
          'title': e.title,
          'episodeNum': e.episodeNum,
          'seasonNum': e.seasonNum,
          'url': e.url,
          'containerExtension': e.containerExtension,
          'info': e.info,
        }).toList(),
      }).toList(),
      'liveCategories': liveCategories.map((c) => {'id': c.id, 'name': c.name}).toList(),
      'vodCategories': vodCategories.map((c) => {'id': c.id, 'name': c.name}).toList(),
      'seriesCategories': seriesCategories.map((c) => {'id': c.id, 'name': c.name}).toList(),
    };
  }

  factory LoadedContent.fromMap(Map<String, dynamic> map) {
    final rawChannels = (map['channels'] as List?) ?? [];
    final rawVods = (map['vods'] as List?) ?? [];
    final rawSeries = (map['series'] as List?) ?? [];
    final rawLiveCats = (map['liveCategories'] as List?) ?? [];
    final rawVodCats = (map['vodCategories'] as List?) ?? [];
    final rawSeriesCats = (map['seriesCategories'] as List?) ?? [];

    return LoadedContent(
      channels: rawChannels.map((c) => Channel(
        id: c['id']?.toString() ?? '',
        name: c['name']?.toString() ?? '',
        url: c['url']?.toString() ?? '',
        logoUrl: c['logoUrl']?.toString(),
        categoryId: c['categoryId']?.toString() ?? 'all',
        groupTitle: c['groupTitle']?.toString(),
        epgChannelId: c['epgChannelId']?.toString(),
        channelNumber: c['channelNumber'] as int?,
      )).toList(),
      vods: rawVods.map((v) => VodItem(
        id: v['id']?.toString() ?? '',
        name: v['name']?.toString() ?? '',
        url: v['url']?.toString() ?? '',
        posterUrl: v['posterUrl']?.toString(),
        categoryId: v['categoryId']?.toString() ?? 'all',
        rating: v['rating']?.toString(),
        releaseDate: v['releaseDate']?.toString(),
        containerExtension: v['containerExtension']?.toString(),
      )).toList(),
      series: rawSeries.map((s) {
        final rawEps = (s['episodes'] as List?) ?? [];
        return SeriesItem(
          id: s['id']?.toString() ?? '',
          name: s['name']?.toString() ?? '',
          posterUrl: s['posterUrl']?.toString(),
          categoryId: s['categoryId']?.toString() ?? 'all',
          rating: s['rating']?.toString(),
          releaseDate: s['releaseDate']?.toString(),
          plot: s['plot']?.toString(),
          episodes: rawEps.map((e) => SeriesEpisode(
            id: e['id']?.toString() ?? '',
            title: e['title']?.toString() ?? '',
            episodeNum: (e['episodeNum'] as int?) ?? 1,
            seasonNum: (e['seasonNum'] as int?) ?? 1,
            url: e['url']?.toString() ?? '',
            containerExtension: e['containerExtension']?.toString(),
            info: e['info']?.toString(),
          )).toList(),
        );
      }).toList(),
      liveCategories: rawLiveCats.map((c) => ContentCategory(
        id: c['id']?.toString() ?? '',
        name: c['name']?.toString() ?? '',
      )).toList(),
      vodCategories: rawVodCats.map((c) => ContentCategory(
        id: c['id']?.toString() ?? '',
        name: c['name']?.toString() ?? '',
      )).toList(),
      seriesCategories: rawSeriesCats.map((c) => ContentCategory(
        id: c['id']?.toString() ?? '',
        name: c['name']?.toString() ?? '',
      )).toList(),
    );
  }
}

class IptvRepository {
  final M3uParserService _m3uParser = M3uParserService();
  final XtreamService _xtreamService = XtreamService();

  // In-memory cache for fast access
  static final Map<String, LoadedContent> _webMemoryCache = {};
  static const String _webCacheKeyPrefix = 'iptv_web_cache_';

  Future<File> _getCacheFile(String profileId) async {
    final dir = await getApplicationSupportDirectory();
    final cacheDir = Directory('${dir.path}/iptv_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return File('${cacheDir.path}/catalog_$profileId.json');
  }

  Future<LoadedContent?> getCachedContent(String profileId) async {
    if (kIsWeb) {
      if (_webMemoryCache.containsKey(profileId)) {
        return _webMemoryCache[profileId];
      }
      try {
        final jsonStr = await WebStorageService.getItem('$_webCacheKeyPrefix$profileId');
        if (jsonStr != null && jsonStr.isNotEmpty) {
          final map = json.decode(jsonStr) as Map<String, dynamic>;
          final content = LoadedContent.fromMap(map);
          _webMemoryCache[profileId] = content;
          return content;
        }
      } catch (e) {
        debugPrint('Error leyendo caché web IndexedDB: $e');
      }
      return null;
    }
    try {
      final file = await _getCacheFile(profileId);
      if (await file.exists()) {
        final jsonStr = await file.readAsString();
        if (jsonStr.isNotEmpty) {
          final map = json.decode(jsonStr) as Map<String, dynamic>;
          return LoadedContent.fromMap(map);
        }
      }
    } catch (e) {
      debugPrint('Error leyendo caché local: $e');
    }
    return null;
  }

  Future<void> saveCachedContent(String profileId, LoadedContent content) async {
    if (kIsWeb) {
      _webMemoryCache[profileId] = content;
      try {
        final jsonStr = json.encode(content.toMap());
        await WebStorageService.setItem('$_webCacheKeyPrefix$profileId', jsonStr);
      } catch (e) {
        debugPrint('Error guardando caché web IndexedDB: $e');
      }
      return;
    }
    try {
      final file = await _getCacheFile(profileId);
      final jsonStr = json.encode(content.toMap());
      await file.writeAsString(jsonStr, flush: true);
    } catch (e) {
      debugPrint('Error guardando caché local: $e');
    }
  }

  Future<void> deleteCache(String profileId) async {
    if (kIsWeb) {
      _webMemoryCache.remove(profileId);
      try {
        await WebStorageService.removeItem('$_webCacheKeyPrefix$profileId');
      } catch (_) {}
      return;
    }
    try {
      final file = await _getCacheFile(profileId);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<LoadedContent> loadProfileContent(PlaylistProfile profile) async {
    if (profile.type == PlaylistType.m3u) {
      if (profile.m3uUrl == null || profile.m3uUrl!.isEmpty) {
        throw Exception('URL de la lista M3U no proporcionada');
      }
      final result = await _m3uParser.downloadAndParse(profile.m3uUrl!);
      return LoadedContent(
        channels: result.channels,
        vods: result.vods,
        series: result.series,
        liveCategories: result.liveCategories,
        vodCategories: result.vodCategories,
        seriesCategories: result.seriesCategories,
      );
    } else {
      final server = profile.serverUrl ?? '';
      final user = profile.username ?? '';
      final pass = profile.password ?? '';

      if (server.isEmpty || user.isEmpty || pass.isEmpty) {
        throw Exception('Credenciales de Xtream Codes incompletas');
      }

      final liveCatsFuture = _xtreamService.getLiveCategories(server, user, pass);
      final liveStreamsFuture = _xtreamService.getLiveStreams(server, user, pass);
      final vodCatsFuture = _xtreamService.getVodCategories(server, user, pass);
      final vodStreamsFuture = _xtreamService.getVodStreams(server, user, pass);
      final seriesCatsFuture = _xtreamService.getSeriesCategories(server, user, pass);
      final seriesFuture = _xtreamService.getSeries(server, user, pass);

      final results = await Future.wait([
        liveCatsFuture,
        liveStreamsFuture,
        vodCatsFuture,
        vodStreamsFuture,
        seriesCatsFuture,
        seriesFuture,
      ]);

      return LoadedContent(
        liveCategories: results[0] as List<ContentCategory>,
        channels: results[1] as List<Channel>,
        vodCategories: results[2] as List<ContentCategory>,
        vods: results[3] as List<VodItem>,
        seriesCategories: results[4] as List<ContentCategory>,
        series: results[5] as List<SeriesItem>,
      );
    }
  }

  Future<List<SeriesEpisode>> loadSeriesEpisodes(PlaylistProfile profile, String seriesId) async {
    if (profile.type == PlaylistType.xtream) {
      return _xtreamService.getSeriesEpisodes(
        profile.serverUrl ?? '',
        profile.username ?? '',
        profile.password ?? '',
        seriesId,
      );
    }
    return [];
  }
}
