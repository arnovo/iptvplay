import 'package:flutter/material.dart';
import '../ui/theme/app_theme.dart';

enum LogLevel {
  info('INFO'),
  warning('WARN'),
  error('ERROR'),
  success('OK');

  final String label;
  const LogLevel(this.label);

  Color get color {
    switch (this) {
      case LogLevel.info:
        return AppTheme.primary;
      case LogLevel.warning:
        return AppTheme.accentYellow;
      case LogLevel.error:
        return AppTheme.accentRed;
      case LogLevel.success:
        return AppTheme.accentGreen;
    }
  }

  IconData get icon {
    switch (this) {
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.warning:
        return Icons.warning_amber_rounded;
      case LogLevel.error:
        return Icons.error_outline;
      case LogLevel.success:
        return Icons.check_circle_outline;
    }
  }
}

enum LogCategory {
  network('Red / IPTV', Icons.cloud_outlined),
  player('Reproductor', Icons.play_circle_outline),
  epg('Guía EPG', Icons.calendar_today_outlined),
  downloads('Descargas / PVR', Icons.download_outlined),
  server('Servidor LAN', Icons.router_outlined),
  system('Sistema', Icons.settings_outlined);

  final String label;
  final IconData icon;
  const LogCategory(this.label, this.icon);
}

class AppLog {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final LogCategory category;
  final String message;
  final String? details;

  AppLog({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.details,
  });

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  String get formattedDateTime {
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    return '$day/$month $formattedTime';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'level': level.name,
        'category': category.name,
        'message': message,
        'details': details,
      };

  factory AppLog.fromJson(Map<String, dynamic> json) => AppLog(
        id: json['id'] ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
        level: LogLevel.values.firstWhere(
          (e) => e.name == json['level'],
          orElse: () => LogLevel.info,
        ),
        category: LogCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => LogCategory.system,
        ),
        message: json['message'] ?? '',
        details: json['details'],
      );
}
