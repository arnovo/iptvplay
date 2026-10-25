import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/category.dart';
import '../models/channel.dart';
import '../models/vod_item.dart';
import '../models/series_item.dart';

class M3uParseResult {
  final List<Channel> channels;
  final List<VodItem> vods;
  final List<SeriesItem> series;
  final List<ContentCategory> liveCategories;
  final List<ContentCategory> vodCategories;
  final List<ContentCategory> seriesCategories;

  M3uParseResult({
    required this.channels,
    required this.vods,
    required this.series,
    required this.liveCategories,
    required this.vodCategories,
    required this.seriesCategories,
  });
}

class M3uParserService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 40),
      headers: {
        'User-Agent': 'IPTVSmartersPro/3.1.5.1 (Linux; Android 12) AppleWebKit/537.36',
      },
    ),
  );

  Future<M3uParseResult> downloadAndParse(String m3uUrl) async {
    final response = await _dio.get<String>(
      m3uUrl,
      options: Options(responseType: ResponseType.plain),
    );

    final content = response.data ?? '';
    return parseContent(content);
  }

  M3uParseResult parseContent(String content) {
    final lines = const LineSplitter().convert(content);

    final List<Channel> channels = [];
    final List<VodItem> vods = [];
    final List<SeriesItem> seriesList = [];

    final Map<String, ContentCategory> liveCategoriesMap = {};
    final Map<String, ContentCategory> vodCategoriesMap = {};
    final Map<String, ContentCategory> seriesCategoriesMap = {};

    String? currentExtinf;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF:')) {
        currentExtinf = line;
      } else if (!line.startsWith('#') && currentExtinf != null) {
        final streamUrl = line;
        _processEntry(
          currentExtinf,
          streamUrl,
          channels,
          vods,
          seriesList,
          liveCategoriesMap,
          vodCategoriesMap,
          seriesCategoriesMap,
          index: channels.length + vods.length + seriesList.length,
        );
        currentExtinf = null;
      }
    }

    return M3uParseResult(
      channels: channels,
      vods: vods,
      series: seriesList,
      liveCategories: liveCategoriesMap.values.toList(),
      vodCategories: vodCategoriesMap.values.toList(),
      seriesCategories: seriesCategoriesMap.values.toList(),
    );
  }

  void _processEntry(
    String extinf,
    String url,
    List<Channel> channels,
    List<VodItem> vods,
    List<SeriesItem> seriesList,
    Map<String, ContentCategory> liveCatMap,
    Map<String, ContentCategory> vodCatMap,
    Map<String, ContentCategory> seriesCatMap, {
    required int index,
  }) {
    // Extract metadata from EXTINF
    final groupTitleMatch = RegExp(r'group-title="([^"]*)"', caseSensitive: false).firstMatch(extinf);
    final tvgLogoMatch = RegExp(r'tvg-logo="([^"]*)"', caseSensitive: false).firstMatch(extinf);
    final tvgIdMatch = RegExp(r'tvg-id="([^"]*)"', caseSensitive: false).firstMatch(extinf);
    
    // Name is after the last comma
    String name = 'Canal $index';
    final commaIndex = extinf.lastIndexOf(',');
    if (commaIndex != -1 && commaIndex + 1 < extinf.length) {
      name = extinf.substring(commaIndex + 1).trim();
    }

    final groupTitle = (groupTitleMatch?.group(1) ?? 'General').trim();
    final logoUrl = tvgLogoMatch?.group(1)?.trim();
    final tvgId = tvgIdMatch?.group(1)?.trim();

    final categoryId = groupTitle.toLowerCase().replaceAll(RegExp(r'\s+'), '_');

    final lowerGroup = groupTitle.toLowerCase();
    final lowerUrl = url.toLowerCase();

    // Determine type: Series, Movie (VOD) or Live
    if (lowerGroup.contains('serie') ||
        lowerGroup.contains('series') ||
        lowerGroup.contains('temporada') ||
        RegExp(r's\d+e\d+', caseSensitive: false).hasMatch(name)) {
      seriesCatMap.putIfAbsent(
        categoryId,
        () => ContentCategory(id: categoryId, name: groupTitle),
      );
      seriesList.add(
        SeriesItem(
          id: 's_$index',
          name: name,
          posterUrl: logoUrl,
          categoryId: categoryId,
          episodes: [
            SeriesEpisode(
              id: 'ep_$index',
              title: name,
              episodeNum: 1,
              seasonNum: 1,
              url: url,
            ),
          ],
        ),
      );
    } else if (lowerGroup.contains('vod') ||
        lowerGroup.contains('pelicula') ||
        lowerGroup.contains('película') ||
        lowerGroup.contains('movie') ||
        lowerGroup.contains('cinema') ||
        lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.mkv')) {
      vodCatMap.putIfAbsent(
        categoryId,
        () => ContentCategory(id: categoryId, name: groupTitle),
      );
      vods.add(
        VodItem(
          id: 'v_$index',
          name: name,
          url: url,
          posterUrl: logoUrl,
          categoryId: categoryId,
        ),
      );
    } else {
      liveCatMap.putIfAbsent(
        categoryId,
        () => ContentCategory(id: categoryId, name: groupTitle),
      );
      channels.add(
        Channel(
          id: 'ch_$index',
          name: name,
          url: url,
          logoUrl: logoUrl,
          categoryId: categoryId,
          groupTitle: groupTitle,
          epgChannelId: tvgId,
          channelNumber: index + 1,
        ),
      );
    }
  }
}
