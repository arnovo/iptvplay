import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_log.dart';
import 'log_service.dart';
import 'url_sanitizer_service.dart';

class RemoteSubtitleItem {
  final String id;
  final String language;
  final String languageCode;
  final String releaseName;
  final String downloadUrl;
  final int downloads;
  final double rating;

  const RemoteSubtitleItem({
    required this.id,
    required this.language,
    required this.languageCode,
    required this.releaseName,
    required this.downloadUrl,
    this.downloads = 0,
    this.rating = 0.0,
  });
}

class SubtitleService {
  final Dio _dio;

  SubtitleService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 25),
                headers: {
                  'User-Agent': 'IPTVPlay/1.0.0 (Darwin; Apple Silicon)',
                },
              ),
            ) {
    _dio.interceptors.add(UrlSanitizerService.createSsrfInterceptor(allowInternalRelay: false));
  }

  /// Search online subtitles by title and optional language code ('es', 'en', 'fr', 'pt', etc.)
  Future<List<RemoteSubtitleItem>> searchSubtitles({
    required String query,
    String languageCode = 'es',
    String? imdbId,
  }) async {
    final cleanQuery = query.replaceAll(RegExp(r'\(\d{4}\)'), '').trim();
    if (cleanQuery.isEmpty) return [];

    try {
      // Use OpenSubtitles REST API public search
      final url = 'https://api.opensubtitles.com/api/v1/subtitles';
      final response = await _dio.get(
        url,
        queryParameters: {
          'query': cleanQuery,
          'languages': languageCode,
          if (imdbId != null && imdbId.isNotEmpty) 'imdb_id': imdbId.replaceAll(RegExp(r'[^0-9]'), ''),
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
            // Default public application key for opensubtitles api v1
            'Api-Key': 'W1f6r2vR84Y5Y2ZzO38kM7wD5F6Q7A8B',
          },
        ),
      );

      if (response.data != null && response.data is Map && response.data['data'] != null) {
        final List list = response.data['data'];
        final List<RemoteSubtitleItem> results = [];

        for (final item in list) {
          final attributes = item['attributes'] as Map<String, dynamic>? ?? {};
          final files = attributes['files'] as List? ?? [];
          final fileId = files.isNotEmpty ? files.first['file_id'] : null;

          if (fileId != null) {
            results.add(
              RemoteSubtitleItem(
                id: item['id']?.toString() ?? '$fileId',
                language: attributes['language']?.toString() ?? languageCode.toUpperCase(),
                languageCode: languageCode,
                releaseName: attributes['release']?.toString() ??
                    files.first['file_name']?.toString() ??
                    cleanQuery,
                downloadUrl: 'https://api.opensubtitles.com/api/v1/download?file_id=$fileId',
                downloads: (attributes['download_count'] as num?)?.toInt() ?? 0,
                rating: (attributes['ratings'] as num?)?.toDouble() ?? 0.0,
              ),
            );
          }
        }

        return results;
      }
    } catch (e) {
      LogService.instance.warning(
        LogCategory.network,
        'No se pudieron consultar subtítulos en línea para "$cleanQuery"',
        details: e.toString(),
      );
    }

    return [];
  }

  /// Downloads subtitle file to local device cache and returns the absolute file path
  Future<String?> downloadSubtitle({
    required String downloadUrl,
    required String filename,
  }) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${docsDir.path}/iptv_cache/subtitles');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final safeName = filename.replaceAll(RegExp(r'[^a-zA-Z0-9_\.-]'), '_');
      final targetFile = File('${cacheDir.path}/$safeName');

      // Request download link or binary directly
      final response = await _dio.get(
        downloadUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept': '*/*',
          },
        ),
      );

      if (response.data != null) {
        await targetFile.writeAsBytes(response.data as List<int>);
        LogService.instance.success(
          LogCategory.player,
          'Subtítulo descargado con éxito',
          details: targetFile.path,
        );
        return targetFile.path;
      }
    } catch (e) {
      LogService.instance.error(
        LogCategory.player,
        'Error al descargar archivo de subtítulo',
        details: e.toString(),
      );
    }
    return null;
  }

  /// Lets user pick a subtitle file from local storage (.srt, .vtt, .ass, .sub)
  Future<String?> pickLocalSubtitleFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['srt', 'vtt', 'sub', 'ass'],
        dialogTitle: 'Seleccionar archivo de subtítulo',
      );

      if (result.isNotEmpty && result.first.path != null) {
        final path = result.first.path!;
        LogService.instance.info(
          LogCategory.player,
          'Archivo de subtítulo local seleccionado',
          details: path,
        );
        return path;
      }
    } catch (e) {
      LogService.instance.warning(
        LogCategory.player,
        'Selección de archivo de subtítulo cancelada o no permitida',
        details: e.toString(),
      );
    }
    return null;
  }
}
