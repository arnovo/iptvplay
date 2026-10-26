import 'dart:convert';

class PlaybackProgress {
  final String id;
  final String title;
  final String url;
  final String? posterUrl;
  final int positionSeconds;
  final int durationSeconds;
  final DateTime lastWatched;
  final String type; // 'vod' or 'series'
  final String? seriesTitle;

  PlaybackProgress({
    required this.id,
    required this.title,
    required this.url,
    this.posterUrl,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.lastWatched,
    required this.type,
    this.seriesTitle,
  });

  double get progressFraction {
    if (durationSeconds <= 0) return 0.0;
    return (positionSeconds / durationSeconds).clamp(0.0, 1.0);
  }

  int get remainingSeconds => (durationSeconds - positionSeconds).clamp(0, durationSeconds);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'posterUrl': posterUrl,
      'positionSeconds': positionSeconds,
      'durationSeconds': durationSeconds,
      'lastWatched': lastWatched.toIso8601String(),
      'type': type,
      'seriesTitle': seriesTitle,
    };
  }

  factory PlaybackProgress.fromMap(Map<String, dynamic> map) {
    return PlaybackProgress(
      id: map['id'] as String,
      title: map['title'] as String,
      url: map['url'] as String,
      posterUrl: map['posterUrl'] as String?,
      positionSeconds: map['positionSeconds'] as int? ?? 0,
      durationSeconds: map['durationSeconds'] as int? ?? 0,
      lastWatched: DateTime.tryParse(map['lastWatched'] as String? ?? '') ?? DateTime.now(),
      type: map['type'] as String? ?? 'vod',
      seriesTitle: map['seriesTitle'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory PlaybackProgress.fromJson(String source) =>
      PlaybackProgress.fromMap(json.decode(source) as Map<String, dynamic>);
}
