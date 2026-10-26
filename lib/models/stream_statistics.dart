class StreamStatistics {
  final int width;
  final int height;
  final double fps;
  final String videoCodec;
  final String audioCodec;
  final int droppedFrames;
  final double cacheDurationSeconds;
  final double cacheSizeMegabytes;
  final double bitrateKbps;

  const StreamStatistics({
    this.width = 0,
    this.height = 0,
    this.fps = 0.0,
    this.videoCodec = 'Desconocido',
    this.audioCodec = 'Desconocido',
    this.droppedFrames = 0,
    this.cacheDurationSeconds = 0.0,
    this.cacheSizeMegabytes = 0.0,
    this.bitrateKbps = 0.0,
  });

  String get resolutionFormatted {
    if (width > 0 && height > 0) {
      return '${width}x$height';
    }
    return 'Cargando...';
  }

  String get qualityLabel {
    if (height >= 2160) return '4K UHD';
    if (height >= 1440) return '2K QHD';
    if (height >= 1080) return 'Full HD 1080p';
    if (height >= 720) return 'HD 720p';
    if (height > 0) return 'SD';
    return '--';
  }

  String get fpsFormatted => fps > 0 ? '${fps.toStringAsFixed(1)} FPS' : '--';

  String get bitrateFormatted =>
      bitrateKbps > 0 ? '${(bitrateKbps / 1000).toStringAsFixed(2)} Mbps' : '--';

  String get bufferFormatted =>
      '${cacheDurationSeconds.toStringAsFixed(1)}s (${cacheSizeMegabytes.toStringAsFixed(1)} MB)';

  StreamStatistics copyWith({
    int? width,
    int? height,
    double? fps,
    String? videoCodec,
    String? audioCodec,
    int? droppedFrames,
    double? cacheDurationSeconds,
    double? cacheSizeMegabytes,
    double? bitrateKbps,
  }) {
    return StreamStatistics(
      width: width ?? this.width,
      height: height ?? this.height,
      fps: fps ?? this.fps,
      videoCodec: videoCodec ?? this.videoCodec,
      audioCodec: audioCodec ?? this.audioCodec,
      droppedFrames: droppedFrames ?? this.droppedFrames,
      cacheDurationSeconds: cacheDurationSeconds ?? this.cacheDurationSeconds,
      cacheSizeMegabytes: cacheSizeMegabytes ?? this.cacheSizeMegabytes,
      bitrateKbps: bitrateKbps ?? this.bitrateKbps,
    );
  }
}
