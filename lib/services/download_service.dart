import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/download_item.dart';

class DownloadService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': 'IPTVExpert/1.0.0 (Darwin; Apple Silicon)',
      },
    ),
  );

  final Map<String, CancelToken> _activeTokens = {};
  final Map<String, IOSink> _activeSinks = {};

  Future<String> getStorageDirectoryPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${dir.path}/iptv_offline');
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir.path;
  }

  /// Start recording a live TV stream to .ts file
  Future<DownloadItem> startLiveRecording({
    required String channelId,
    required String title,
    required String streamUrl,
    String? posterUrl,
    required Function(int bytes) onByteUpdate,
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

    // Run recording stream asynchronously
    _dio.get<ResponseBody>(
      streamUrl,
      options: Options(responseType: ResponseType.stream),
      cancelToken: cancelToken,
    ).then((response) async {
      int totalBytesWritten = 0;
      final stream = response.data?.stream;
      if (stream != null) {
        await for (final chunk in stream) {
          sink.add(chunk);
          totalBytesWritten += chunk.length;
          onByteUpdate(totalBytesWritten);
        }
      }
      await sink.flush();
      await sink.close();
    }).catchError((_) async {
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
  }

  bool isRecording(String channelId) => _activeTokens.containsKey(channelId);

  Future<String> getVodFilePath(String id, String streamUrl) async {
    final storagePath = await getStorageDirectoryPath();
    final ext = streamUrl.contains('.mkv') ? 'mkv' : 'mp4';
    return '$storagePath/vod_${id}_$ext';
  }

  /// Download or resume VOD movie or Series episode
  Future<void> downloadVod({
    required String id,
    required String title,
    required String streamUrl,
    required String type,
    String? posterUrl,
    String? existingFilePath,
    required Function(int received, int total) onProgress,
    required Function(DownloadItem completed) onComplete,
    required Function(String error) onError,
  }) async {
    final storagePath = await getStorageDirectoryPath();
    final ext = streamUrl.contains('.mkv') ? 'mkv' : 'mp4';
    final targetPath = existingFilePath ?? '$storagePath/vod_${id}_$ext';

    final file = File(targetPath);
    int existingBytes = 0;
    if (await file.exists()) {
      existingBytes = await file.length();
    }

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

      final stream = response.data?.stream;
      if (stream != null) {
        await for (final chunk in stream) {
          sink.add(chunk);
          currentReceived += chunk.length;
          onProgress(currentReceived, totalSize);
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

      onComplete(completed);
    } catch (e) {
      _activeTokens.remove(id);
      onError(e.toString());
    }
  }

  void cancelDownload(String id) {
    _activeTokens[id]?.cancel();
    _activeTokens.remove(id);
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
