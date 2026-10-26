import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_play/services/backup_service.dart';

void main() {
  group('BackupService Encryption Tests', () {
    test('Encrypt and decrypt JSON with AES-256', () {
      final originalData = {
        'profiles': [
          {'id': 'p1', 'name': 'Mi Lista IPTV'}
        ],
        'favorites': {'live': ['ch1', 'ch2']}
      };
      final jsonString = jsonEncode(originalData);
      const password = 'SecretPassword123!';

      // Cifrado
      final encryptedJson = BackupService.encryptJson(jsonString, password);
      expect(BackupService.isEncryptedBackup(encryptedJson), isTrue);

      final decodedEnc = jsonDecode(encryptedJson) as Map<String, dynamic>;
      expect(decodedEnc['encrypted'], isTrue);
      expect(decodedEnc['cipher'], 'AES-256-CBC');
      expect(decodedEnc['payload'], isNotEmpty);
      expect(decodedEnc['payload'], isNot(contains('Mi Lista IPTV')));

      // Descifrado con contraseña correcta
      final decryptedJson = BackupService.decryptJson(encryptedJson, password);
      final decryptedData = jsonDecode(decryptedJson) as Map<String, dynamic>;

      expect(decryptedData['profiles'][0]['name'], 'Mi Lista IPTV');
      expect(decryptedData['favorites']['live'], ['ch1', 'ch2']);
    });

    test('Decryption with wrong password throws error', () {
      final jsonString = jsonEncode({'secret': '42'});
      final encrypted = BackupService.encryptJson(jsonString, 'correct_pass');

      expect(
        () => BackupService.decryptJson(encrypted, 'wrong_pass'),
        throwsA(anything),
      );
    });
  });
}
