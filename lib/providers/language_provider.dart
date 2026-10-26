import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/log_service.dart';
import '../models/app_log.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _prefLanguageKey = 'pref_app_language';

  Locale _locale = const Locale('es');
  bool _isInitialized = false;

  Locale get locale => _locale;
  bool get isInitialized => _isInitialized;
  bool get isEnglish => _locale.languageCode == 'en';
  bool get isSpanish => _locale.languageCode == 'es';

  String get currentLanguageName => isEnglish ? 'English' : 'Español';
  String get currentFlag => isEnglish ? '🇬🇧' : '🇪🇸';

  LanguageProvider() {
    _initLocale();
  }

  Future<void> _initLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefLanguageKey);

      if (savedCode != null && (savedCode == 'en' || savedCode == 'es')) {
        _locale = Locale(savedCode);
      } else {
        // Auto-detect system locale
        final systemLocale = ui.PlatformDispatcher.instance.locale;
        if (systemLocale.languageCode.toLowerCase() == 'en') {
          _locale = const Locale('en');
        } else {
          _locale = const Locale('es');
        }
      }
    } catch (e) {
      _locale = const Locale('es');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (_locale.languageCode == newLocale.languageCode) return;
    if (newLocale.languageCode != 'es' && newLocale.languageCode != 'en') return;

    _locale = newLocale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLanguageKey, newLocale.languageCode);
      LogService.instance.info(
        LogCategory.system,
        'App language changed to ${_locale.languageCode.toUpperCase()}',
      );
    } catch (e) {
      LogService.instance.error(
        LogCategory.system,
        'Failed to save language preference',
        details: e.toString(),
      );
    }
  }

  Future<void> toggleLanguage() async {
    final target = isEnglish ? const Locale('es') : const Locale('en');
    await setLocale(target);
  }
}
