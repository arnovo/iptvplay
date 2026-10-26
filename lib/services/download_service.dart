import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/download_item.dart';
import '../models/app_log.dart';
import 'log_service.dart';
import 'url_sanitizer_service.dart';

class DownloadService {
  static const String prefDownloadDirKey = 'pref_download_directory';

  final Dio _dio;

  DownloadService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                headers: {
                  'User-Agent': 'IPTVPlay/1.0.0 (Darwin; Apple Silicon)',
                },
              ),
            ) {
    _dio.interceptors.add(UrlSanitizerService.createSsrfInterceptor(allowInternalRelay: false));
  }

  final Map<String, CancelToken> _activeTokens = {};
  final Map<String, IOSink> _activeSinks = {};

  Future<String?> getCustomStorageDirectory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customPath = prefs.getString(prefDownloadDirKey);
      if (customPath != null && customPath.isNotEmpty) {
        final dir = Directory(customPath);
        if (await dir.exists()) {
          return dir.path;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> setCustomStorageDirectory(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefDownloadDirKey, path);
    LogService.instance.info(
      LogCategory.downloads,
      'Carpeta de descargas cambiada a: $path',
    );
  }

  Future<void> resetStorageDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefDownloadDirKey);
  }

  Future<String> getStorageDirectoryPath() async {
    final custom = await getCustomStorageDirectory();
    if (custom != null) {
      return custom;
    }
    final dir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${dir.path}/iptv_offline');
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir.path;
  }

  /// Open or reveal file/folder in native file manager (Finder / Explorer / xdg-open)
  static Future<void> openInFileManager(String path) async {
    try {
      final file = File(path);
      final dir = Directory(path);
      final existsFile = await file.exists();
      final existsDir = await dir.exists();

      if (!existsFile && !existsDir) return;

      if (!kIsWeb && Platform.isMacOS) {
        if (existsFile) {
          await Process.run('open', ['-R', path]);
        } else {
          await Process.run('open', [path]);
        }
      } else if (!kIsWeb && Platform.isWindows) {
        if (existsFile) {
          await Process.run('explorer.exe', ['/select,', path]);
        } else {
          await Process.run('explorer.exe', [path]);
        }
      } else if (!kIsWeb && Platform.isLinux) {
        final target = existsFile ? file.parent.path : path;
        await Process.run('xdg-open', [target]);
      }
    } catch (e) {
      LogService.instance.error(
        LogCategory.system,
        'No se pudo abrir el explorador de archivos para: $path',
        details: e.toString(),
      );
    }
  }

  /// Start recording a live TV stream to .ts file
  Future<DownloadItem> startLiveRecording({
    required String channelId,
    required String title,
    required String streamUrl,
    String? posterUrl,
    required Function(int bytes, double speed) onByteUpdate,
  }) async {
    final storagePath = await getStorageDirectoryPath();
    final sanitizedTitle = title.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
    final filename = 'rec_${channelId}_${DateTime.now().millisecondsSinceEpoch}.ts';
    final targetPath = '$storagePath/$filename';
    final file = File(targetPath);
    final sink = file.openWrite();

    final cancelToken = CancelToken();
    _activeTokens[channelId] = cancelToken;
    _activeSinks[channelId] = sink;

    final item = DownloadItem(
      id: channelId,
      title: 'Grabación: $sanitizedTitle',
      originalUrl: streamUrl,
      localFilePath: targetPath,
      posterUrl: posterUrl,
      type: 'live_recording',
      status: DownloadStatus.recording,
      createdAt: DateTime.now(),
    );

    LogService.instance.info(
      LogCategory.downloads,
      'Grabación en directo iniciada: $sanitizedTitle',
      details: 'Stream URL: $streamUrl • Destino: $targetPath',
    );

    // Run recording stream asynchronously
    _dio.get<ResponseBody>(
      streamUrl,
      options: Options(responseType: ResponseType.stream),
      cancelToken: cancelToken,
    ).then((response) async {
      int totalBytesWritten = 0;
      int lastSampleBytes = 0;
      DateTime lastSampleTime = DateTime.now();
      double currentSpeed = 0.0;

      final stream = response.data?.stream;
      if (stream != null) {
        await for (final chunk in stream) {
          sink.add(chunk);
          totalBytesWritten += chunk.length;

          final now = DateTime.now();
          final elapsedMs = now.difference(lastSampleTime).inMilliseconds;
          if (elapsedMs >= 600) {
            final delta = totalBytesWritten - lastSampleBytes;
            currentSpeed = delta / (elapsedMs / 1000.0);
            lastSampleBytes = totalBytesWritten;
            lastSampleTime = now;
            onByteUpdate(totalBytesWritten, currentSpeed);
          }
        }
      }
      await sink.flush();
      await sink.close();
      onByteUpdate(totalBytesWritten, 0.0);
    }).catchError((err) async {
      LogService.instance.error(
        LogCategory.downloads,
        'Error durante la grabación en directo: $sanitizedTitle',
        details: err.toString(),
      );
      try {
        await sink.flush();
        await sink.close();
      } catch (_) {}
    });

    return item;
  }

  /// Stop an active stream recording
  Future<void> stopLiveRecording(String channelId) async {
    final token = _activeTokens.remove(channelId);
    token?.cancel();
    final sink = _activeSinks.remove(channelId);
    if (sink != null) {
      await sink.flush();
      await sink.close();
    }
    LogService.instance.success(
      LogCategory.downloads,
      'Grabación en directo finalizada para canal $channelId',
    );
  }

  bool isRecording(String channelId) => _activeTokens.containsKey(channelId);

  Future<String> getVodFilePath(String id, String streamUrl) async {
    final storagePath = await getStorageDirectoryPath();
    final ext = streamUrl.contains('.mkv') ? 'mkv' : 'mp4';
    return '$storagePath/vod_$id.$ext';
  }

  /// Download or resume VOD movie or Series episode
  Future<void> downloadVod({
    required String id,
    required String title,
    required String streamUrl,
    required String type,
    String? posterUrl,
    String? existingFilePath,
    required Function(int received, int total, double speed) onProgress,
    required Function(DownloadItem completed) onComplete,
    required Function(String error) onError,
  }) async {
    final storagePath = await getStorageDirectoryPath();
    final ext = streamUrl.contains('.mkv') ? 'mkv' : 'mp4';
    final targetPath = existingFilePath ?? '$storagePath/vod_$id.$ext';

    final file = File(targetPath);
    int existingBytes = 0;
    if (await file.exists()) {
      existingBytes = await file.length();
    }

    LogService.instance.info(
      LogCategory.downloads,
      'Iniciando descarga: $title',
      details: 'Tipo: $type • Bytes previos: $existingBytes • Archivo: $targetPath',
    );

    final cancelToken = CancelToken();
    _activeTokens[id] = cancelToken;

    try {
      final response = await _dio.get<ResponseBody>(
        streamUrl,
        options: Options(
          responseType: ResponseType.stream,
          headers: existingBytes > 0 ? {'Range': 'bytes=$existingBytes-'} : null,
        ),
        cancelToken: cancelToken,
      );

      final isPartial = response.statusCode == 206;
      final totalHeader = response.headers.value('content-length');
      final totalFromServer = totalHeader != null ? int.tryParse(totalHeader) ?? 0 : 0;
      final totalSize = isPartial ? existingBytes + totalFromServer : (totalFromServer > 0 ? totalFromServer : 0);

      final sink = file.openWrite(mode: isPartial ? FileMode.append : FileMode.write);
      int currentReceived = isPartial ? existingBytes : 0;
      int lastSampleBytes = currentReceived;
      DateTime lastSampleTime = DateTime.now();
      double currentSpeed = 0.0;

      final stream = response.data?.stream;
      if (stream != null) {
        await for (final chunk in stream) {
          sink.add(chunk);
          currentReceived += chunk.length;

          final now = DateTime.now();
          final elapsedMs = now.difference(lastSampleTime).inMilliseconds;
          if (elapsedMs >= 600) {
            final delta = currentReceived - lastSampleBytes;
            currentSpeed = delta / (elapsedMs / 1000.0);
            lastSampleBytes = currentReceived;
            lastSampleTime = now;
            onProgress(currentReceived, totalSize, currentSpeed);
          }
        }
      }

      await sink.flush();
      await sink.close();
      _activeTokens.remove(id);

      final finalSize = await file.length();
      final completed = DownloadItem(
        id: id,
        title: title,
        originalUrl: streamUrl,
        localFilePath: targetPath,
        posterUrl: posterUrl,
        type: type,
        totalBytes: finalSize,
        downloadedBytes: finalSize,
        status: DownloadStatus.completed,
        createdAt: DateTime.now(),
      );

      LogService.instance.success(
        LogCategory.downloads,
        'Descarga completada con éxito: $title',
        details: 'Tamaño: ${completed.formattedSize} • Archivo: $targetPath',
      );

      onComplete(completed);
    } catch (e) {
      _activeTokens.remove(id);
      LogService.instance.error(
        LogCategory.downloads,
        'Error o interrupción en descarga: $title',
        details: e.toString(),
      );
      onError(e.toString());
    }
  }

  void cancelDownload(String id) {
    _activeTokens[id]?.cancel();
    _activeTokens.remove(id);
    LogService.instance.info(
      LogCategory.downloads,
      'Descarga pausada / cancelada (ID: $id)',
    );
  }

  /// Metadata persistence
  Future<List<DownloadItem>> loadDownloadsMetadata() async {
    try {
      final storagePath = await getStorageDirectoryPath();
      final metaFile = File('$storagePath/downloads_metadata.json');
      if (await metaFile.exists()) {
        final content = await metaFile.readAsString();
        final List list = jsonDecode(content);
        return list.map((json) => DownloadItem.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveDownloadsMetadata(List<DownloadItem> items) async {
    try {
      final storagePath = await getStorageDirectoryPath();
      final metaFile = File('$storagePath/downloads_metadata.json');
      final jsonList = items.map((i) => i.toJson()).toList();
      await metaFile.writeAsString(jsonEncode(jsonList));
    } catch (_) {}
  }
}
