import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../tv_focusable.dart';

/// Encabezado estandarizado para las secciones del Home Hub
class HubSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String subtitle;
  final VoidCallback? onSeeAll;

  const HubSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.subtitle,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        if (onSeeAll != null)
          TvFocusable(
            onPressed: onSeeAll!,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: const Row(
                children: [
                  Text(
                    'Ver todo',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: AppTheme.primary, size: 16),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
