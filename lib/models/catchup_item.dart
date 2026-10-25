class CatchupItem {
  final String id;
  final String streamId;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;
  final int durationMinutes;
  final String streamUrl;

  CatchupItem({
    required this.id,
    required this.streamId,
    required this.title,
    this.description,
    required this.start,
    required this.end,
    required this.durationMinutes,
    required this.streamUrl,
  });

  String get formattedDate {
    return '${start.day}/${start.month}/${start.year}';
  }

  String get formattedTimeRange {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final s = '${twoDigits(start.hour)}:${twoDigits(start.minute)}';
    final e = '${twoDigits(end.hour)}:${twoDigits(end.minute)}';
    return '$s - $e';
  }
}
