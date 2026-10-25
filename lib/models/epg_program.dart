class EpgProgram {
  final String id;
  final String channelId;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;
  final String? posterUrl;
  final String? category;

  EpgProgram({
    required this.id,
    required this.channelId,
    required this.title,
    this.description,
    required this.start,
    required this.end,
    this.posterUrl,
    this.category,
  });

  bool get isCurrent {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  bool get isPast {
    return DateTime.now().isAfter(end);
  }

  bool get isFuture {
    return DateTime.now().isBefore(start);
  }

  double get progressFraction {
    final now = DateTime.now();
    if (now.isBefore(start)) return 0.0;
    if (now.isAfter(end)) return 1.0;
    final total = end.difference(start).inSeconds;
    if (total <= 0) return 0.0;
    final elapsed = now.difference(start).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  String get durationText {
    final diff = end.difference(start);
    final hours = diff.inHours;
    final mins = diff.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours h $mins m';
    }
    return '$mins min';
  }

  String get formattedTimeRange {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final s = '${twoDigits(start.hour)}:${twoDigits(start.minute)}';
    final e = '${twoDigits(end.hour)}:${twoDigits(end.minute)}';
    return '$s - $e';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'channelId': channelId,
        'title': title,
        'description': description,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'posterUrl': posterUrl,
        'category': category,
      };

  factory EpgProgram.fromJson(Map<String, dynamic> json) => EpgProgram(
        id: json['id'] ?? '',
        channelId: json['channelId'] ?? '',
        title: json['title'] ?? '',
        description: json['description'],
        start: DateTime.tryParse(json['start'] ?? '') ?? DateTime.now(),
        end: DateTime.tryParse(json['end'] ?? '') ?? DateTime.now(),
        posterUrl: json['posterUrl'],
        category: json['category'],
      );
}
