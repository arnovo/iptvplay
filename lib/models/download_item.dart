enum DownloadStatus {
  downloading,
  recording,
  completed,
  paused,
  failed,
}

class DownloadItem {
  final String id;
  final String title;
  final String originalUrl;
  final String localFilePath;
  final String? posterUrl;
  final String type; // 'live_recording', 'vod', 'series'
  final int totalBytes;
  final int downloadedBytes;
  final DownloadStatus status;
  final DateTime createdAt;
  final int durationSeconds;
  final double speedBytesPerSecond;

  DownloadItem({
    required this.id,
    required this.title,
    required this.originalUrl,
    required this.localFilePath,
    this.posterUrl,
    required this.type,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    required this.status,
    required this.createdAt,
    this.durationSeconds = 0,
    this.speedBytesPerSecond = 0.0,
  });

  double get progressFraction {
    if (status == DownloadStatus.completed) return 1.0;
    if (status == DownloadStatus.recording) return 0.5; // active recording pulse
    if (totalBytes <= 0) return 0.0;
    return (downloadedBytes / totalBytes).clamp(0.0, 1.0);
  }

  String get formattedSize {
    final bytes = downloadedBytes > 0 ? downloadedBytes : totalBytes;
    if (bytes <= 0) return '0 MB';
    final mb = bytes / (1024 * 1024);
    if (mb > 1024) {
      final gb = mb / 1024;
      return '${gb.toStringAsFixed(1)} GB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  String get formattedSpeed {
    if (speedBytesPerSecond <= 0) return '';
    final kb = speedBytesPerSecond / 1024;
    if (kb >= 1024) {
      final mb = kb / 1024;
      return '${mb.toStringAsFixed(1)} MB/s';
    }
    return '${kb.toStringAsFixed(0)} KB/s';
  }

  String get formattedEta {
    if (speedBytesPerSecond <= 0 || totalBytes <= 0 || downloadedBytes >= totalBytes) return '';
    final remainingBytes = totalBytes - downloadedBytes;
    final secondsRemaining = (remainingBytes / speedBytesPerSecond).round();
    if (secondsRemaining <= 0) return '';
    if (secondsRemaining < 60) return '$secondsRemaining s restantes';
    final mins = secondsRemaining ~/ 60;
    final secs = secondsRemaining % 60;
    return '$mins min ${secs}s restantes';
  }

  DownloadItem copyWith({
    String? id,
    String? title,
    String? originalUrl,
    String? localFilePath,
    String? posterUrl,
    String? type,
    int? totalBytes,
    int? downloadedBytes,
    DownloadStatus? status,
    DateTime? createdAt,
    int? durationSeconds,
    double? speedBytesPerSecond,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      title: title ?? this.title,
      originalUrl: originalUrl ?? this.originalUrl,
      localFilePath: localFilePath ?? this.localFilePath,
      posterUrl: posterUrl ?? this.posterUrl,
      type: type ?? this.type,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      speedBytesPerSecond: speedBytesPerSecond ?? this.speedBytesPerSecond,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'originalUrl': originalUrl,
        'localFilePath': localFilePath,
        'posterUrl': posterUrl,
        'type': type,
        'totalBytes': totalBytes,
        'downloadedBytes': downloadedBytes,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'durationSeconds': durationSeconds,
      };

  factory DownloadItem.fromJson(Map<String, dynamic> json) => DownloadItem(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        originalUrl: json['originalUrl'] ?? '',
        localFilePath: json['localFilePath'] ?? '',
        posterUrl: json['posterUrl'],
        type: json['type'] ?? 'vod',
        totalBytes: json['totalBytes'] ?? 0,
        downloadedBytes: json['downloadedBytes'] ?? 0,
        status: DownloadStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => DownloadStatus.completed,
        ),
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        durationSeconds: json['durationSeconds'] ?? 0,
      );
}
