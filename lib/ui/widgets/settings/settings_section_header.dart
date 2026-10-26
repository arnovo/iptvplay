import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Encabezado estandarizado para las secciones de configuración
class SettingsSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const SettingsSectionHeader({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
