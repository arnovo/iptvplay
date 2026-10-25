import 'package:flutter/foundation.dart';
import '../models/playlist_profile.dart';
import '../services/storage_service.dart';
import '../services/iptv_repository.dart';

class ProfileProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final IptvRepository _iptvRepository = IptvRepository();

  List<PlaylistProfile> _profiles = [];
  PlaylistProfile? _activeProfile;
  bool _isLoading = false;

  List<PlaylistProfile> get profiles => _profiles;
  PlaylistProfile? get activeProfile => _activeProfile;
  bool get isLoading => _isLoading;

  Future<void> loadProfiles() async {
    _isLoading = true;
    notifyListeners();

    try {
      _profiles = await _storageService.getProfiles();
      final activeId = await _storageService.getActiveProfileId();
      if (activeId != null) {
        _activeProfile = _profiles.firstWhere(
          (p) => p.id == activeId,
          orElse: () => _profiles.isNotEmpty ? _profiles.first : throw Exception(),
        );
      } else if (_profiles.isNotEmpty) {
        _activeProfile = _profiles.first;
        await _storageService.setActiveProfileId(_activeProfile!.id);
      } else {
        _activeProfile = null;
      }
    } catch (_) {
      _activeProfile = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectProfile(PlaylistProfile profile) async {
    _activeProfile = profile;
    await _storageService.setActiveProfileId(profile.id);
    notifyListeners();
  }

  Future<void> addProfile(PlaylistProfile profile) async {
    await _storageService.saveProfile(profile);
    await loadProfiles();
    await selectProfile(profile);
  }

  Future<void> deleteProfile(String id) async {
    await _iptvRepository.deleteCache(id);
    await _storageService.deleteProfile(id);
    await loadProfiles();
  }
}
