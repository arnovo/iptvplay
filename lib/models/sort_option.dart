import 'package:flutter/material.dart';

enum SortOption {
  defaultOrder('default', 'Por defecto', Icons.swap_vert),
  nameAsc('name_asc', 'Nombre (A - Z)', Icons.sort_by_alpha),
  nameDesc('name_desc', 'Nombre (Z - A)', Icons.sort_by_alpha),
  dateDesc('date_desc', 'Más recientes primero', Icons.schedule),
  dateAsc('date_asc', 'Más antiguos primero', Icons.history),
  ratingDesc('rating_desc', 'Mejor valorados', Icons.star_rate_rounded);

  final String key;
  final String label;
  final IconData icon;

  const SortOption(this.key, this.label, this.icon);

  static SortOption fromKey(String? key) {
    return SortOption.values.firstWhere(
      (e) => e.key == key,
      orElse: () => SortOption.defaultOrder,
    );
  }
}
