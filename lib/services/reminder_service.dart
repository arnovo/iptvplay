import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/epg_reminder.dart';
import '../models/app_log.dart';
import 'log_service.dart';

/// Servicio para la programación y alerta de recordatorios de programas EPG
class ReminderService extends ChangeNotifier {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  static const String _prefKey = 'pref_epg_reminders';
  List<EpgReminder> _reminders = [];
  Timer? _checkTimer;

  // Stream de eventos para alertas en tiempo real en la UI
  final _alertController = StreamController<EpgReminder>.broadcast();
  Stream<EpgReminder> get onReminderAlert => _alertController.stream;

  List<EpgReminder> get reminders => List.unmodifiable(_reminders);

  List<EpgReminder> get upcomingReminders {
    final now = DateTime.now();
    return _reminders
        .where((r) => r.endTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Inicializa cargando recordatorios y arrancando el comprobador periódico
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        _reminders = list
            .map((item) => EpgReminder.fromMap(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      LogService.instance.error(
        LogCategory.epg,
        'Error cargando recordatorios EPG',
        details: e.toString(),
      );
    }

    _cleanExpiredReminders();
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkDueReminders();
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _alertController.close();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _reminders.map((r) => r.toMap()).toList();
      await prefs.setString(_prefKey, jsonEncode(list));
    } catch (e) {
      LogService.instance.error(
        LogCategory.epg,
        'Error guardando recordatorios EPG',
        details: e.toString(),
      );
    }
  }

  /// Comprueba si algún recordatorio está dentro de los próximos 2 minutos o ha empezado
  void _checkDueReminders() {
    final now = DateTime.now();
    bool changed = false;

    for (int i = 0; i < _reminders.length; i++) {
      final r = _reminders[i];
      if (!r.notified) {
        final diffSeconds = r.startTime.difference(now).inSeconds;
        // Si está a 2 minutos o menos (o recién empezado en los últimos 2 minutos)
        if (diffSeconds <= 120 && diffSeconds >= -120) {
          _reminders[i] = r.copyWith(notified: true);
          changed = true;

          LogService.instance.info(
            LogCategory.epg,
            '¡Recordatorio de emisión!',
            details: '${r.programTitle} en ${r.channelName}',
          );

          _alertController.add(_reminders[i]);
        }
      }
    }

    if (changed) {
      _save();
      notifyListeners();
    }
  }

  /// Elimina recordatorios finalizados hace más de 6 horas
  void _cleanExpiredReminders() {
    final threshold = DateTime.now().subtract(const Duration(hours: 6));
    final initialCount = _reminders.length;
    _reminders.removeWhere((r) => r.endTime.isBefore(threshold));
    if (_reminders.length != initialCount) {
      _save();
    }
  }

  /// Añade un nuevo recordatorio
  Future<bool> addReminder(EpgReminder reminder) async {
    // Evita duplicados
    if (isReminderSet(reminder.channelId, reminder.startTime)) {
      return false;
    }

    _reminders.add(reminder);
    await _save();

    LogService.instance.info(
      LogCategory.epg,
      'Recordatorio programado',
      details: '${reminder.programTitle} - ${reminder.startTime.toLocal()}',
    );

    notifyListeners();
    return true;
  }

  /// Elimina un recordatorio por su ID
  Future<void> removeReminder(String reminderId) async {
    _reminders.removeWhere((r) => r.id == reminderId);
    await _save();
    notifyListeners();
  }

  /// Comprueba si ya existe un recordatorio para este canal y hora de inicio
  bool isReminderSet(String channelId, DateTime startTime) {
    return _reminders.any(
      (r) =>
          r.channelId == channelId &&
          r.startTime.millisecondsSinceEpoch == startTime.millisecondsSinceEpoch,
    );
  }
}
