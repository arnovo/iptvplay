import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../backup_dialog.dart';
import '../tv_focusable.dart';

/// Tarjeta de configuración para copias de seguridad cifradas AES-256
class BackupSettingsCard extends StatelessWidget {
  const BackupSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.security_rounded, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Copia y Restauración Cifrada (AES-256)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Exporta e importa tus listas, favoritos, historial y recordatorios con contraseña de protección.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          TvFocusable(
            borderRadius: BorderRadius.circular(10),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const BackupDialog(),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.backup_rounded, size: 18, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text(
                    'Gestionar Backups',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
