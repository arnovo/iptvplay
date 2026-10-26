import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iptv_play/models/playlist_profile.dart';
import 'package:iptv_play/services/url_sanitizer_service.dart';
import 'package:iptv_play/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UrlSanitizerService Security Tests', () {
    test('Validates legitimate http and https URLs', () {
      expect(UrlSanitizerService.isValidWebUrl('http://myiptv.provider.com:8080/get.php'), isTrue);
      expect(UrlSanitizerService.isValidWebUrl('https://myiptv.provider.com/live.m3u8'), isTrue);
      expect(UrlSanitizerService.isValidWebUrl('http://192.168.1.100:8080/playlist.m3u'), isTrue);
    });

    test('Rejects dangerous or non-http schemes', () {
      expect(UrlSanitizerService.isValidWebUrl('file:///etc/passwd'), isFalse);
      expect(UrlSanitizerService.isValidWebUrl('javascript:alert(1)'), isFalse);
      expect(UrlSanitizerService.isValidWebUrl('data:text/html;base64,PHNjcmlwdD4='), isFalse);
      expect(UrlSanitizerService.isValidWebUrl('ftp://ftp.example.com/file.m3u'), isFalse);
      expect(UrlSanitizerService.isValidWebUrl('content://media/external/video/media/1'), isFalse);
      expect(UrlSanitizerService.isValidWebUrl(''), isFalse);
      expect(UrlSanitizerService.isValidWebUrl(null), isFalse);
    });

    test('Detects loopback, localhost and cloud metadata SSRF targets', () {
      expect(UrlSanitizerService.isLoopbackOrBlocked(Uri.parse('http://localhost/admin')), isTrue);
      expect(UrlSanitizerService.isLoopbackOrBlocked(Uri.parse('http://127.0.0.1/secrets')), isTrue);
      expect(UrlSanitizerService.isLoopbackOrBlocked(Uri.parse('http://127.0.0.5:9090')), isTrue);
      expect(UrlSanitizerService.isLoopbackOrBlocked(Uri.parse('http://169.254.169.254/latest/meta-data')), isTrue);
      expect(UrlSanitizerService.isLoopbackOrBlocked(Uri.parse('http://0.0.0.0/')), isTrue);
    });

    test('Permits legitimate external URLs and internal relay port 8088 exception', () {
      expect(UrlSanitizerService.isLoopbackOrBlocked(Uri.parse('http://myiptv.com/stream.ts')), isFalse);
      // Port 8088 on localhost permitted only for internal stream relay
      expect(
        UrlSanitizerService.isLoopbackOrBlocked(Uri.parse('http://127.0.0.1:8088/stream'), allowInternalRelay: true),
        isFalse,
      );
      // Disallow port 8088 if allowInternalRelay is explicitly false
      expect(
        UrlSanitizerService.isLoopbackOrBlocked(Uri.parse('http://127.0.0.1:8088/stream'), allowInternalRelay: false),
        isTrue,
      );
    });
  });

  group('StorageService Credential Security Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('Saves and loads profile with password encrypted in secure storage', () async {
      final storage = StorageService();

      final profile = PlaylistProfile(
        id: 'prof_secure_1',
        name: 'Xtream Premium',
        type: PlaylistType.xtream,
        serverUrl: 'http://xtream.server.com:8080',
        username: 'user123',
        password: 'SuperSecretPassword!#99',
        createdAt: DateTime.now(),
      );

      await storage.saveProfile(profile);

      // Verify loaded profile has decrypted password
      final loaded = await storage.getProfiles();
      expect(loaded.length, 1);
      expect(loaded.first.id, 'prof_secure_1');
      expect(loaded.first.username, 'user123');
      expect(loaded.first.password, 'SuperSecretPassword!#99');

      // Verify raw SharedPreferences does not contain plaintext password
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList('iptv_profiles') ?? [];
      expect(rawList.first.contains('SuperSecretPassword!#99'), isFalse);
    });

    test('Migrates legacy plaintext password to secure storage automatically', () async {
      // Simulate existing legacy profile in SharedPreferences with plaintext password
      final legacyProfile = PlaylistProfile(
        id: 'legacy_prof_1',
        name: 'Legacy Xtream',
        type: PlaylistType.xtream,
        serverUrl: 'http://legacy.server.com:8080',
        username: 'olduser',
        password: 'PlainLegacyPassword123',
        createdAt: DateTime.now(),
      );

      SharedPreferences.setMockInitialValues({
        'iptv_profiles': [legacyProfile.toJson()],
      });
      FlutterSecureStorage.setMockInitialValues({});

      final storage = StorageService();
      final loaded = await storage.getProfiles();

      expect(loaded.first.password, 'PlainLegacyPassword123');

      // Verify SharedPreferences plaintext has now been scrubbed
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList('iptv_profiles') ?? [];
      expect(rawList.first.contains('PlainLegacyPassword123'), isFalse);
    });
  });
}
