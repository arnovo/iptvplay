import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist_profile.dart';

class StorageService {
  static const String _keyProfiles = 'iptv_profiles';
  static const String _keyActiveProfileId = 'iptv_active_profile_id';

  Future<List<PlaylistProfile>> getProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_keyProfiles) ?? [];
    return rawList
        .map((item) => PlaylistProfile.fromJson(item))
        .toList();
  }

  Future<void> saveProfile(PlaylistProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = await getProfiles();
    final index = profiles.indexWhere((p) => p.id == profile.id);

    if (index >= 0) {
      profiles[index] = profile;
    } else {
      profiles.add(profile);
    }

    final rawList = profiles.map((p) => p.toJson()).toList();
    await prefs.setStringList(_keyProfiles, rawList);
  }

  Future<void> deleteProfile(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = await getProfiles();
    profiles.removeWhere((p) => p.id == id);
    final rawList = profiles.map((p) => p.toJson()).toList();
    await prefs.setStringList(_keyProfiles, rawList);

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
