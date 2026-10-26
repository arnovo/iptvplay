import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/parental_settings.dart';
import '../models/app_log.dart';
import 'log_service.dart';

/// Servicio para la gestión del control parental y modo niños
class ParentalService extends ChangeNotifier {
  ParentalService._();
  static final ParentalService instance = ParentalService._();

  static const String _prefKey = 'pref_parental_settings';

  ParentalSettings _settings = const ParentalSettings();
  bool _isSessionUnlocked = false;

  ParentalSettings get settings => _settings;
  bool get isEnabled => _settings.enabled;
  bool get isSessionUnlocked => _isSessionUnlocked;

  /// Inicializa cargando las preferencias de almacenamiento
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        _settings = ParentalSettings.fromMap(map);
      }
    } catch (e) {
      LogService.instance.error(
        LogCategory.system,
        'Error cargando configuración de control parental',
        details: e.toString(),
      );
    }
    notifyListeners();
  }

  /// Guarda la configuración actual en SharedPreferences
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(_settings.toMap()));
    } catch (e) {
      LogService.instance.error(
        LogCategory.system,
        'Error guardando configuración de control parental',
        details: e.toString(),
      );
    }
  }

  /// Desbloquea la sesión actual mediante el PIN
  bool unlockWithPin(String pin) {
    if (!_settings.enabled) {
      _isSessionUnlocked = true;
      notifyListeners();
      return true;
    }

    final isValid = _settings.verifyPin(pin);
    if (isValid) {
      _isSessionUnlocked = true;
      LogService.instance.info(
        LogCategory.system,
        'Control parental desbloqueado para la sesión actual',
      );
      notifyListeners();
      return true;
    }

    LogService.instance.warning(
      LogCategory.system,
      'Intento de desbloqueo de control parental con PIN inválido',
    );
    return false;
  }

  /// Vuelve a bloquear la sesión activa
  void lockSession() {
    _isSessionUnlocked = false;
    LogService.instance.info(
      LogCategory.system,
      'Sesión de control parental bloqueada nuevamente',
    );
    notifyListeners();
  }

  /// Configura un nuevo PIN y activa el control parental
  Future<bool> setPinAndEnable({
    required String newPin,
    bool lockAdult = true,
    bool lockSettings = false,
  }) async {
    if (newPin.length < 4) return false;
    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    final pinHash = ParentalSettings.hashPin(newPin, salt);

    _settings = _settings.copyWith(
      enabled: true,
      pinHash: pinHash,
      salt: salt,
      lockAdultCategories: lockAdult,
      lockSettings: lockSettings,
    );

    _isSessionUnlocked = false;
    await _save();
    LogService.instance.success(
      LogCategory.system,
      'Control parental activado exitosamente',
    );
    notifyListeners();
    return true;
  }

  /// Desactiva el control parental verificando el PIN actual
  Future<bool> disableWithPin(String currentPin) async {
    if (!_settings.verifyPin(currentPin)) {
      return false;
    }

    _settings = _settings.copyWith(
      enabled: false,
      pinHash: '',
    );
    _isSessionUnlocked = false;
    await _save();
    LogService.instance.info(
      LogCategory.system,
      'Control parental desactivado',
    );
    notifyListeners();
    return true;
  }

  /// Desactiva directamente el control parental (cuando ya se validó el PIN previamente)
  Future<void> disable() async {
    _settings = const ParentalSettings();
    _isSessionUnlocked = false;
    await _save();
    LogService.instance.info(
      LogCategory.system,
      'Control parental desactivado completamente',
    );
    notifyListeners();
  }

  /// Actualiza opciones como bloquear categorías adultas o bloquear ajustes
  Future<void> updateOptions({
    bool? lockAdult,
    bool? lockSettings,
  }) async {
    _settings = _settings.copyWith(
      lockAdultCategories: lockAdult ?? _settings.lockAdultCategories,
      lockSettings: lockSettings ?? _settings.lockSettings,
    );
    await _save();
    notifyListeners();
  }

  /// Comprueba si una categoría debe ocultarse o restringirse
  bool isCategoryRestricted({
    required String categoryId,
    required String categoryName,
  }) {
    if (!_settings.enabled || _isSessionUnlocked) {
      return false;
    }
    return _settings.isCategoryRestricted(
      categoryId: categoryId,
      categoryName: categoryName,
    );
  }

  /// Comprueba si los ajustes requieren PIN
  bool isSettingsRestricted() {
    if (!_settings.enabled || _isSessionUnlocked) {
      return false;
    }
    return _settings.lockSettings;
  }
}
