/// Representa un recordatorio programado para la emisión de un evento EPG futuro
class EpgReminder {
  final String id;
  final String channelId;
  final String channelName;
  final String? channelLogo;
  final String programTitle;
  final String? programDescription;
  final DateTime startTime;
  final DateTime endTime;
  final bool notified;

  const EpgReminder({
    required this.id,
    required this.channelId,
    required this.channelName,
    this.channelLogo,
    required this.programTitle,
    this.programDescription,
    required this.startTime,
    required this.endTime,
    this.notified = false,
  });

  bool get isUpcoming => startTime.isAfter(DateTime.now());

  Duration get timeUntilStart => startTime.difference(DateTime.now());

  EpgReminder copyWith({
    String? id,
    String? channelId,
    String? channelName,
    String? channelLogo,
    String? programTitle,
    String? programDescription,
    DateTime? startTime,
    DateTime? endTime,
    bool? notified,
  }) {
    return EpgReminder(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      channelLogo: channelLogo ?? this.channelLogo,
      programTitle: programTitle ?? this.programTitle,
      programDescription: programDescription ?? this.programDescription,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notified: notified ?? this.notified,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'channelId': channelId,
      'channelName': channelName,
      'channelLogo': channelLogo,
      'programTitle': programTitle,
      'programDescription': programDescription,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'notified': notified,
    };
  }

  factory EpgReminder.fromMap(Map<String, dynamic> map) {
    return EpgReminder(
      id: map['id'] as String,
      channelId: map['channelId'] as String,
      channelName: map['channelName'] as String,
      channelLogo: map['channelLogo'] as String?,
      programTitle: map['programTitle'] as String,
      programDescription: map['programDescription'] as String?,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: DateTime.parse(map['endTime'] as String),
      notified: map['notified'] as bool? ?? false,
    );
  }
}
