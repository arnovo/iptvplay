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
    // Validate that downloaded files still exist on disk
    final List<DownloadItem> valid = [];
    for (final item in _items) {
      if (await File(item.localFilePath).exists()) {
        valid.add(item);
      }
    }
    _items = valid;
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

    final initial = DownloadItem(
      id: id,
      title: title,
      originalUrl: streamUrl,
      localFilePath: '',
      posterUrl: posterUrl,
      type: type,
      status: DownloadStatus.downloading,
      createdAt: DateTime.now(),
    );
    _items.insert(0, initial);
    notifyListeners();

    await _service.downloadVod(
      id: id,
      title: title,
      streamUrl: streamUrl,
      type: type,
      posterUrl: posterUrl,
      onProgress: (received, total) {
        final idx = _items.indexWhere((i) => i.id == id);
        if (idx != -1) {
          _items[idx] = _items[idx].copyWith(
            downloadedBytes: received,
            totalBytes: total,
          );
          notifyListeners();
        }
      },
      onComplete: (completed) async {
        final idx = _items.indexWhere((i) => i.id == id);
        if (idx != -1) {
          _items[idx] = completed;
          await _service.saveDownloadsMetadata(_items);
          notifyListeners();
        }
      },
      onError: (err) async {
        final idx = _items.indexWhere((i) => i.id == id);
        if (idx != -1) {
          _items[idx] = _items[idx].copyWith(status: DownloadStatus.failed);
          await _service.saveDownloadsMetadata(_items);
          notifyListeners();
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
