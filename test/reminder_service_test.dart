import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iptv_play/models/epg_reminder.dart';
import 'package:iptv_play/services/reminder_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EpgReminder Model Tests', () {
    test('Calculates timeUntilStart and isUpcoming correctly', () {
      final now = DateTime.now();
      final future = now.add(const Duration(minutes: 45));
      final futureEnd = future.add(const Duration(hours: 1));

      final reminder = EpgReminder(
        id: 'rem_1',
        channelId: 'ch_1',
        channelName: 'Canal Deportes',
        programTitle: 'Final Champions League',
        startTime: future,
        endTime: futureEnd,
      );

      expect(reminder.isUpcoming, isTrue);
      expect(reminder.timeUntilStart.inMinutes, inInclusiveRange(44, 46));

      final map = reminder.toMap();
      final fromMap = EpgReminder.fromMap(map);
      expect(fromMap.id, 'rem_1');
      expect(fromMap.programTitle, 'Final Champions League');
    });
  });

  group('ReminderService State Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Add, check and remove reminders', () async {
      final service = ReminderService.instance;
      await service.init();

      final now = DateTime.now();
      final startTime = now.add(const Duration(hours: 2));

      final reminder = EpgReminder(
        id: 'test_rem_100',
        channelId: 'channel_100',
        channelName: 'Eurosport',
        programTitle: 'Grand Slam Tenis',
        startTime: startTime,
        endTime: startTime.add(const Duration(hours: 2)),
      );

      // Añadir
      final ok = await service.addReminder(reminder);
      expect(ok, isTrue);

      // Comprobar si existe
      expect(service.isReminderSet('channel_100', startTime), isTrue);
      expect(service.upcomingReminders.length, 1);

      // Intentar añadir duplicado
      final duplicateOk = await service.addReminder(reminder);
      expect(duplicateOk, isFalse);

      // Eliminar
      await service.removeReminder('test_rem_100');
      expect(service.isReminderSet('channel_100', startTime), isFalse);
      expect(service.upcomingReminders.isEmpty, isTrue);
    });
  });
}
