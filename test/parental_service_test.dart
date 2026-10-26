import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iptv_play/models/parental_settings.dart';
import 'package:iptv_play/services/parental_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ParentalSettings Model Tests', () {
    test('Hasing and verification of PIN', () {
      const pin = '1234';
      const salt = 'test_salt_123';
      final hash = ParentalSettings.hashPin(pin, salt);

      final settings = ParentalSettings(
        enabled: true,
        pinHash: hash,
        salt: salt,
      );

      expect(settings.verifyPin('1234'), isTrue);
      expect(settings.verifyPin('0000'), isFalse);
      expect(settings.verifyPin('4321'), isFalse);
    });

    test('Adult category keyword detection', () {
      expect(ParentalSettings.isAdultCategoryName('Canales Adultos'), isTrue);
      expect(ParentalSettings.isAdultCategoryName('XXX Movies HD'), isTrue);
      expect(ParentalSettings.isAdultCategoryName('Zona +18'), isTrue);
      expect(ParentalSettings.isAdultCategoryName('Cine Erotica'), isTrue);
      expect(ParentalSettings.isAdultCategoryName('Deportes LaLiga'), isFalse);
      expect(ParentalSettings.isAdultCategoryName('Infantil y Dibujos'), isFalse);
    });

    test('Category restriction checking', () {
      const settings = ParentalSettings(
        enabled: true,
        lockAdultCategories: true,
        customLockedCategoryIds: ['cat_custom_locked'],
      );

      // Bloqueado por keyword
      expect(
        settings.isCategoryRestricted(categoryId: 'c1', categoryName: 'Adultos +18'),
        isTrue,
      );

      // Bloqueado por ID manual
      expect(
        settings.isCategoryRestricted(categoryId: 'cat_custom_locked', categoryName: 'General'),
        isTrue,
      );

      // Permitido
      expect(
        settings.isCategoryRestricted(categoryId: 'c2', categoryName: 'Cine Comedia'),
        isFalse,
      );
    });
  });

  group('ParentalService State Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Enable, verify, unlock and disable lifecycle', () async {
      final service = ParentalService.instance;
      await service.init();

      expect(service.isEnabled, isFalse);
      expect(service.isSessionUnlocked, isFalse);

      // Activar con PIN 2580
      final enabledOk = await service.setPinAndEnable(newPin: '2580', lockAdult: true);
      expect(enabledOk, isTrue);
      expect(service.isEnabled, isTrue);
      expect(service.isSessionUnlocked, isFalse);

      // Intento con PIN erróneo
      expect(service.unlockWithPin('0000'), isFalse);
      expect(service.isSessionUnlocked, isFalse);

      // Desbloqueo exitoso
      expect(service.unlockWithPin('2580'), isTrue);
      expect(service.isSessionUnlocked, isTrue);

      // Bloquear sesión de nuevo
      service.lockSession();
      expect(service.isSessionUnlocked, isFalse);

      // Desactivar completamente
      await service.disable();
      expect(service.isEnabled, isFalse);
      expect(service.isSessionUnlocked, isFalse);
    });
  });
}
