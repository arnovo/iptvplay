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
