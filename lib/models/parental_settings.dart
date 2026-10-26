import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Configuración de control parental y modo infantil.
class ParentalSettings {
  final bool enabled;
  final String pinHash;
  final String salt;
  final bool lockAdultCategories;
  final bool lockSettings;
  final List<String> customLockedCategoryIds;

  const ParentalSettings({
    this.enabled = false,
    this.pinHash = '',
    this.salt = 'iptv_play_salt',
    this.lockAdultCategories = true,
    this.lockSettings = false,
    this.customLockedCategoryIds = const [],
  });

  /// Hash a 4-digit PIN with salt
  static String hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  /// Verifica si el PIN provisto coincide con el hash guardado
  bool verifyPin(String pin) {
    if (pinHash.isEmpty) return true;
    final testHash = hashPin(pin, salt);
    return testHash == pinHash;
  }

  /// Lista de palabras clave que identifican categorías de contenido para adultos
  static const List<String> adultKeywords = [
    'xxx',
    'adult',
    'adultos',
    '+18',
    '18+',
    'erotic',
    'erotica',
    'porn',
    'playboy',
    'venus',
    'redlight',
    'for adults',
    'para adultos',
  ];

  /// Comprueba si el nombre de una categoría coincide con contenido adulto
  static bool isAdultCategoryName(String name) {
    final lower = name.toLowerCase().trim();
    for (final kw in adultKeywords) {
      if (lower.contains(kw)) {
        return true;
      }
    }
    return false;
  }

  /// Determina si una categoría específica está bloqueada según las reglas activas
  bool isCategoryRestricted({
    required String categoryId,
    required String categoryName,
  }) {
    if (!enabled) return false;

    // Si bloquea categorías adultas automáticamente
    if (lockAdultCategories && isAdultCategoryName(categoryName)) {
      return true;
    }

    // Si está en la lista manual de categorías bloqueadas
    if (customLockedCategoryIds.contains(categoryId)) {
      return true;
    }

    return false;
  }

  ParentalSettings copyWith({
    bool? enabled,
    String? pinHash,
    String? salt,
    bool? lockAdultCategories,
    bool? lockSettings,
    List<String>? customLockedCategoryIds,
  }) {
    return ParentalSettings(
      enabled: enabled ?? this.enabled,
      pinHash: pinHash ?? this.pinHash,
      salt: salt ?? this.salt,
      lockAdultCategories: lockAdultCategories ?? this.lockAdultCategories,
      lockSettings: lockSettings ?? this.lockSettings,
      customLockedCategoryIds:
          customLockedCategoryIds ?? this.customLockedCategoryIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'pinHash': pinHash,
      'salt': salt,
      'lockAdultCategories': lockAdultCategories,
      'lockSettings': lockSettings,
      'customLockedCategoryIds': customLockedCategoryIds,
    };
  }

  factory ParentalSettings.fromMap(Map<String, dynamic> map) {
    return ParentalSettings(
      enabled: map['enabled'] as bool? ?? false,
      pinHash: map['pinHash'] as String? ?? '',
      salt: map['salt'] as String? ?? 'iptv_play_salt',
      lockAdultCategories: map['lockAdultCategories'] as bool? ?? true,
      lockSettings: map['lockSettings'] as bool? ?? false,
      customLockedCategoryIds: (map['customLockedCategoryIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
