import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/download_item.dart';
import '../services/download_service.dart';

class DownloadProvider extends ChangeNotifier {
  final DownloadService _service = DownloadService();
  List<DownloadItem> _items = [];
  bool _isInitialized = false;

  List<DownloadItem> get items => _items;
  List<DownloadItem> get completedItems =>
      _items.where((i) => i.status == DownloadStatus.completed).toList();
  List<DownloadItem> get activeRecordings =>
      _items.where((i) => i.status == DownloadStatus.recording).toList();

  DownloadProvider() {
    _init();
  }

  Future<void> _init() async {
    if (_isInitialized) return;
    _items = await _service.loadDownloadsMetadata();
    final List<DownloadItem> valid = [];
    bool metadataChanged = false;

    for (final item in _items) {
      final file = File(item.localFilePath);
      final exists = await file.exists();
      if (!exists) {
        metadataChanged = true;
        continue;
      }

      final fileSize = await file.length();

      // If app was killed while recording live TV: keep what was captured
      if (item.status == DownloadStatus.recording) {
        valid.add(item.copyWith(
          status: DownloadStatus.completed,
          totalBytes: fileSize,
          downloadedBytes: fileSize,
        ));
        metadataChanged = true;
      }
      // If app was closed during a VOD download: keep partial file and mark paused
      else if (item.status == DownloadStatus.downloading) {
        valid.add(item.copyWith(
          status: DownloadStatus.paused,
          downloadedBytes: fileSize,
        ));
        metadataChanged = true;
      } else {
        valid.add(item);
      }
    }

    _items = valid;
    if (metadataChanged) {
      await _service.saveDownloadsMetadata(_items);
    }
    _isInitialized = true;
    notifyListeners();
  }

  bool isChannelRecording(String channelId) {
    return _service.isRecording(channelId);
  }

  Future<void> toggleLiveRecording({
    required String channelId,
    required String title,
    required String streamUrl,
    String? posterUrl,
  }) async {
    if (isChannelRecording(channelId)) {
      await _service.stopLiveRecording(channelId);
      final idx = _items.indexWhere((i) => i.id == channelId && i.status == DownloadStatus.recording);
      if (idx != -1) {
        final existing = _items[idx];
        final file = File(existing.localFilePath);
        final size = await file.exists() ? await file.length() : 0;
        _items[idx] = existing.copyWith(
          status: DownloadStatus.completed,
          totalBytes: size,
          downloadedBytes: size,
        );
        await _service.saveDownloadsMetadata(_items);
      }
    } else {
      final item = await _service.startLiveRecording(
        channelId: channelId,
        title: title,
        streamUrl: streamUrl,
        posterUrl: posterUrl,
        onByteUpdate: (bytes) {
          final idx = _items.indexWhere((i) => i.id == channelId && i.status == DownloadStatus.recording);
          if (idx != -1) {
            _items[idx] = _items[idx].copyWith(downloadedBytes: bytes);
            notifyListeners();
          }
        },
      );
      _items.insert(0, item);
      await _service.saveDownloadsMetadata(_items);
    }
    notifyListeners();
  }

  Future<void> startVodDownload({
    required String id,
    required String title,
    required String streamUrl,
    required String type,
    String? posterUrl,
  }) async {
    // Check if already downloading or completed
    if (_items.any((i) => i.id == id && i.status == DownloadStatus.completed)) {
      return;
    }

    final localPath = await _service.getVodFilePath(id, streamUrl);

    final initial = DownloadItem(
      id: id,
      title: title,
      originalUrl: streamUrl,
      localFilePath: localPath,
      posterUrl: posterUrl,
      type: type,
      status: DownloadStatus.downloading,
      createdAt: DateTime.now(),
    );
    _items.insert(0, initial);
    await _service.saveDownloadsMetadata(_items);
    notifyListeners();

    _executeVodDownload(initial);
  }

  Future<void> pauseDownload(String id) async {
    _service.cancelDownload(id);
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final item = _items[idx];
      final file = File(item.localFilePath);
      final size = await file.exists() ? await file.length() : item.downloadedBytes;
      _items[idx] = item.copyWith(
        status: DownloadStatus.paused,
        downloadedBytes: size,
      );
      await _service.saveDownloadsMetadata(_items);
      notifyListeners();
    }
  }

  Future<void> resumeDownload(String id) async {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx == -1) return;

    final item = _items[idx];
    _items[idx] = item.copyWith(status: DownloadStatus.downloading);
    notifyListeners();

    _executeVodDownload(item);
  }

  Future<void> _executeVodDownload(DownloadItem item) async {
    await _service.downloadVod(
      id: item.id,
      title: item.title,
      streamUrl: item.originalUrl,
      type: item.type,
      posterUrl: item.posterUrl,
      existingFilePath: item.localFilePath,
      onProgress: (received, total) {
        final idx = _items.indexWhere((i) => i.id == item.id);
        if (idx != -1) {
          _items[idx] = _items[idx].copyWith(
            downloadedBytes: received,
            totalBytes: total > 0 ? total : _items[idx].totalBytes,
          );
          notifyListeners();
        }
      },
      onComplete: (completed) async {
        final idx = _items.indexWhere((i) => i.id == item.id);
        if (idx != -1) {
          _items[idx] = completed;
          await _service.saveDownloadsMetadata(_items);
          notifyListeners();
        }
      },
      onError: (err) async {
        final idx = _items.indexWhere((i) => i.id == item.id);
        if (idx != -1) {
          // If cancelled by pause, it's already marked paused
          if (_items[idx].status != DownloadStatus.paused) {
            _items[idx] = _items[idx].copyWith(status: DownloadStatus.failed);
            await _service.saveDownloadsMetadata(_items);
            notifyListeners();
          }
        }
      },
    );
  }

  Future<void> deleteDownload(String id) async {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final item = _items[idx];
      final file = File(item.localFilePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      _items.removeAt(idx);
      await _service.saveDownloadsMetadata(_items);
      notifyListeners();
    }
  }
}
