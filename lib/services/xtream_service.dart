import 'package:dio/dio.dart';
import '../models/category.dart';
import '../models/channel.dart';
import '../models/vod_item.dart';
import '../models/series_item.dart';
import 'url_sanitizer_service.dart';

class XtreamService {
  final Dio _dio;

  XtreamService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                headers: {
                  'User-Agent': 'IPTVSmartersPro/3.1.5.1 (Linux; Android 12) AppleWebKit/537.36',
                },
              ),
            ) {
    _dio.interceptors.add(UrlSanitizerService.createSsrfInterceptor(allowInternalRelay: false));
  }

  String _cleanServerUrl(String url) {
    var cleaned = url.trim();
    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      cleaned = 'http://$cleaned';
    }
    return UrlSanitizerService.sanitizeUrl(cleaned.replaceAll(RegExp(r'/+$'), ''));
  }

  Future<bool> testAuthentication(String serverUrl, String username, String password) async {
    final baseUrl = _cleanServerUrl(serverUrl);
    try {
      final response = await _dio.get(
        '$baseUrl/player_api.php',
        queryParameters: {
          'username': username,
          'password': password,
        },
      );
      if (response.statusCode == 200 && response.data is Map) {
        final userInfo = response.data['user_info'];
        if (userInfo != null && userInfo['auth'] == 1) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<List<ContentCategory>> getLiveCategories(String serverUrl, String username, String password) async {
    final baseUrl = _cleanServerUrl(serverUrl);
    final response = await _dio.get(
      '$baseUrl/player_api.php',
      queryParameters: {
        'username': username,
        'password': password,
        'action': 'get_live_categories',
      },
    );

    if (response.data is List) {
      return (response.data as List).map((cat) {
        return ContentCategory(
          id: cat['category_id']?.toString() ?? '',
          name: cat['category_name']?.toString() ?? 'Sin categoría',
        );
      }).toList();
    }
    return [];
  }

  Future<List<Channel>> getLiveStreams(String serverUrl, String username, String password) async {
    final baseUrl = _cleanServerUrl(serverUrl);
    final response = await _dio.get(
      '$baseUrl/player_api.php',
      queryParameters: {
        'username': username,
        'password': password,
        'action': 'get_live_streams',
      },
    );

    if (response.data is List) {
      return (response.data as List).map((stream) {
        return Channel.fromXtreamJson(stream, baseUrl, username, password);
      }).toList();
    }
    return [];
  }

  Future<List<ContentCategory>> getVodCategories(String serverUrl, String username, String password) async {
    final baseUrl = _cleanServerUrl(serverUrl);
    final response = await _dio.get(
      '$baseUrl/player_api.php',
      queryParameters: {
        'username': username,
        'password': password,
        'action': 'get_vod_categories',
      },
    );

    if (response.data is List) {
      return (response.data as List).map((cat) {
        return ContentCategory(
          id: cat['category_id']?.toString() ?? '',
          name: cat['category_name']?.toString() ?? 'Sin categoría',
        );
      }).toList();
    }
    return [];
  }

  Future<List<VodItem>> getVodStreams(String serverUrl, String username, String password) async {
    final baseUrl = _cleanServerUrl(serverUrl);
    final response = await _dio.get(
      '$baseUrl/player_api.php',
      queryParameters: {
        'username': username,
        'password': password,
        'action': 'get_vod_streams',
      },
    );

    if (response.data is List) {
      return (response.data as List).map((stream) {
        return VodItem.fromXtreamJson(stream, baseUrl, username, password);
      }).toList();
    }
    return [];
  }

  Future<List<ContentCategory>> getSeriesCategories(String serverUrl, String username, String password) async {
    final baseUrl = _cleanServerUrl(serverUrl);
    final response = await _dio.get(
      '$baseUrl/player_api.php',
      queryParameters: {
        'username': username,
        'password': password,
        'action': 'get_series_categories',
      },
    );

    if (response.data is List) {
      return (response.data as List).map((cat) {
        return ContentCategory(
          id: cat['category_id']?.toString() ?? '',
          name: cat['category_name']?.toString() ?? 'Sin categoría',
        );
      }).toList();
    }
    return [];
  }

  Future<List<SeriesItem>> getSeries(String serverUrl, String username, String password) async {
    final baseUrl = _cleanServerUrl(serverUrl);
    final response = await _dio.get(
      '$baseUrl/player_api.php',
      queryParameters: {
        'username': username,
        'password': password,
        'action': 'get_series',
      },
    );

    if (response.data is List) {
      return (response.data as List).map((s) {
        return SeriesItem.fromXtreamJson(s);
      }).toList();
    }
    return [];
  }

  Future<List<SeriesEpisode>> getSeriesEpisodes(
    String serverUrl,
    String username,
    String password,
    String seriesId,
  ) async {
    final baseUrl = _cleanServerUrl(serverUrl);
    final response = await _dio.get(
      '$baseUrl/player_api.php',
      queryParameters: {
        'username': username,
        'password': password,
        'action': 'get_series_info',
        'series_id': seriesId,
      },
    );

    final episodes = <SeriesEpisode>[];
    if (response.data is Map && response.data['episodes'] != null) {
      final epsMap = response.data['episodes'];
      if (epsMap is Map) {
        epsMap.forEach((seasonKey, seasonEpisodes) {
          if (seasonEpisodes is List) {
            for (var ep in seasonEpisodes) {
              if (ep is Map<String, dynamic>) {
                episodes.add(SeriesEpisode.fromXtreamJson(ep, baseUrl, username, password));
              }
            }
          }
        });
      }
    }
    return episodes;
  }
}
