import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_log.dart';
import '../models/playlist_profile.dart';
import 'log_service.dart';

class StorageService {
  static const String _keyProfiles = 'iptv_profiles';
  static const String _keyActiveProfileId = 'iptv_active_profile_id';
  static const String _secKeyPrefix = 'sec_profile_pwd_';

  final FlutterSecureStorage _secureStorage;

  StorageService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<List<PlaylistProfile>> getProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_keyProfiles) ?? [];
    final List<PlaylistProfile> loadedProfiles = [];
    bool needsMigrationSave = false;

    for (final item in rawList) {
      final baseProfile = PlaylistProfile.fromJson(item);
      String? securePassword;

      try {
        securePassword = await _secureStorage.read(key: '$_secKeyPrefix${baseProfile.id}');
      } catch (e) {
        LogService.instance.warning(
          LogCategory.system,
          'No se pudo acceder a SecureStorage para el perfil ${baseProfile.id}',
          details: e.toString(),
        );
      }

      // If secure password exists, attach it
      if (securePassword != null && securePassword.isNotEmpty) {
        loadedProfiles.add(baseProfile.copyWith(password: securePassword));
      } else if (baseProfile.password != null && baseProfile.password!.isNotEmpty) {
        // Legacy plaintext password detected: migrate to hardware secure storage
        try {
          await _secureStorage.write(
            key: '$_secKeyPrefix${baseProfile.id}',
            value: baseProfile.password!,
          );
          needsMigrationSave = true;
          LogService.instance.info(
            LogCategory.system,
            'Migrada contraseña de perfil a almacenamiento cifrado seguro',
            details: 'Perfil ID: ${baseProfile.id}',
          );
        } catch (_) {}
        loadedProfiles.add(baseProfile);
      } else {
        loadedProfiles.add(baseProfile);
      }
    }

    // If legacy passwords were migrated, sanitize plaintext passwords from SharedPreferences
    if (needsMigrationSave) {
      await _saveProfilesInternal(prefs, loadedProfiles);
    }

    return loadedProfiles;
  }

  Future<void> saveProfile(PlaylistProfile profile) async {
    // 1. Store password in secure hardware storage if present
    if (profile.password != null && profile.password!.isNotEmpty) {
      try {
        await _secureStorage.write(
          key: '$_secKeyPrefix${profile.id}',
          value: profile.password!,
        );
      } catch (e) {
        LogService.instance.warning(
          LogCategory.system,
          'Fallo al escribir en SecureStorage (usando fallback local)',
          details: e.toString(),
        );
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final profiles = await getProfiles();
    final index = profiles.indexWhere((p) => p.id == profile.id);

    if (index >= 0) {
      profiles[index] = profile;
    } else {
      profiles.add(profile);
    }

    await _saveProfilesInternal(prefs, profiles);
  }

  Future<void> saveProfiles(List<PlaylistProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    for (final p in profiles) {
      if (p.password != null && p.password!.isNotEmpty) {
        try {
          await _secureStorage.write(
            key: '$_secKeyPrefix${p.id}',
            value: p.password!,
          );
        } catch (_) {}
      }
    }
    await _saveProfilesInternal(prefs, profiles);
  }

  /// Internal helper to persist profiles in SharedPreferences with plaintext passwords scrubbed
  Future<void> _saveProfilesInternal(SharedPreferences prefs, List<PlaylistProfile> profiles) async {
    final sanitizedList = profiles.map((p) {
      // Scrub plaintext password before writing to shared preferences JSON
      return p.copyWith(password: '').toJson();
    }).toList();
    await prefs.setStringList(_keyProfiles, sanitizedList);
  }

  Future<void> deleteProfile(String id) async {
    try {
      await _secureStorage.delete(key: '$_secKeyPrefix$id');
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final profiles = await getProfiles();
    profiles.removeWhere((p) => p.id == id);
    await _saveProfilesInternal(prefs, profiles);

    final activeId = await getActiveProfileId();
    if (activeId == id) {
      await setActiveProfileId(null);
    }
  }

  Future<String?> getActiveProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActiveProfileId);
  }

  Future<void> setActiveProfileId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_keyActiveProfileId);
    } else {
      await prefs.setString(_keyActiveProfileId, id);
    }
  }
}
