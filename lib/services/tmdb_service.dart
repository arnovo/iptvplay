import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class TmdbMetadata {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double rating;
  final String releaseDate;
  final List<String> genres;

  TmdbMetadata({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.rating,
    required this.releaseDate,
    required this.genres,
  });

  String? get fullPosterUrl => posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : null;
  String? get fullBackdropUrl => backdropPath != null ? 'https://image.tmdb.org/t/p/w1280$backdropPath' : null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'overview': overview,
        'posterPath': posterPath,
        'backdropPath': backdropPath,
        'rating': rating,
        'releaseDate': releaseDate,
        'genres': genres,
      };

  factory TmdbMetadata.fromJson(Map<String, dynamic> json) => TmdbMetadata(
        id: json['id'] ?? 0,
        title: json['title'] ?? '',
        overview: json['overview'] ?? '',
        posterPath: json['posterPath'],
        backdropPath: json['backdropPath'],
        rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 0.0,
        releaseDate: json['releaseDate'] ?? '',
        genres: (json['genres'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );
}

class TmdbService {
  // Public standard IPTV app discovery client key
  static const String _defaultApiKey = '453b34691c36098028734e5659da0ba7';
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.themoviedb.org/3',
      connectTimeout: const Duration(seconds: 10),
    ),
  );

  /// Search TMDB for movie or series metadata
  Future<TmdbMetadata?> searchMetadata({
    required String title,
    bool isSeries = false,
  }) async {
    final cleanTitle = _cleanTitleForSearch(title);
    if (cleanTitle.isEmpty) return null;

    // Check disk cache first
    final cached = await _loadFromCache(cleanTitle);
    if (cached != null) return cached;

    try {
      final endpoint = isSeries ? '/search/tv' : '/search/movie';
      final response = await _dio.get(
        endpoint,
        queryParameters: {
          'api_key': _defaultApiKey,
          'query': cleanTitle,
          'language': 'es-ES',
          'include_adult': false,
        },
      );

      if (response.data != null && response.data['results'] != null) {
        final List results = response.data['results'];
        if (results.isNotEmpty) {
          final first = results.first;
          final meta = TmdbMetadata(
            id: first['id'] ?? 0,
            title: first[isSeries ? 'name' : 'title']?.toString() ?? title,
            overview: first['overview']?.toString() ?? 'Sin descripción disponible.',
            posterPath: first['poster_path'],
            backdropPath: first['backdrop_path'],
            rating: (first['vote_average'] is num) ? (first['vote_average'] as num).toDouble() : 0.0,
            releaseDate: first[isSeries ? 'first_air_date' : 'release_date']?.toString() ?? '',
            genres: [],
          );

          await _saveToCache(cleanTitle, meta);
          return meta;
        }
      }
    } catch (_) {}

    return null;
  }

  String _cleanTitleForSearch(String raw) {
    // Strip common IPTV tags like "[ES]", "(2024)", "4K", "FHD", "1080p", "Castellano"
    return raw
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .replaceAll(RegExp(r'\b(4K|UHD|FHD|HD|1080p|720p|Castellano|Latino|Dual|VOSE|ES|SPA)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static final Map<String, TmdbMetadata> _webTmdbMemoryCache = {};

  Future<void> _saveToCache(String cleanTitle, TmdbMetadata meta) async {
    if (kIsWeb) {
      _webTmdbMemoryCache[cleanTitle] = meta;
      return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${dir.path}/iptv_cache/tmdb');
      if (!await cacheDir.exists()) await cacheDir.create(recursive: true);

      final safeKey = cleanTitle.replaceAll(RegExp(r'[^\w]'), '_');
      final file = File('${cacheDir.path}/$safeKey.json');
      await file.writeAsString(jsonEncode(meta.toJson()));
    } catch (_) {}
  }

  Future<TmdbMetadata?> _loadFromCache(String cleanTitle) async {
    if (kIsWeb) {
      return _webTmdbMemoryCache[cleanTitle];
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final safeKey = cleanTitle.replaceAll(RegExp(r'[^\w]'), '_');
      final file = File('${dir.path}/iptv_cache/tmdb/$safeKey.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        return TmdbMetadata.fromJson(jsonDecode(content));
      }
    } catch (_) {}
    return null;
  }
}
