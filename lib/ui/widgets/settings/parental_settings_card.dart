import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/parental_service.dart';
import '../../theme/app_theme.dart';
import '../parental_dialog.dart';
import '../tv_focusable.dart';

/// Tarjeta de configuración para el Control Parental y protección por PIN
class ParentalSettingsCard extends StatelessWidget {
  const ParentalSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final parental = context.watch<ParentalService>();

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
              color: parental.isEnabled
                  ? (parental.isSessionUnlocked
                      ? AppTheme.accentGreen.withValues(alpha: 0.15)
                      : AppTheme.accentYellow.withValues(alpha: 0.15))
                  : AppTheme.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              parental.isEnabled
                  ? (parental.isSessionUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded)
                  : Icons.shield_outlined,
              color: parental.isEnabled
                  ? (parental.isSessionUnlocked ? AppTheme.accentGreen : AppTheme.accentYellow)
                  : AppTheme.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parental.isEnabled
                      ? (parental.isSessionUnlocked
                          ? 'Control Parental Activo (Desbloqueado temporalmente)'
                          : 'Control Parental Activo (Bloqueado con PIN)')
                      : 'Control Parental Desactivado',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Oculta automáticamente categorías para adultos (+18 / XXX) y protege los ajustes mediante un código PIN de 4 dígitos.',
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
                builder: (_) => const ParentalDialog(),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Icon(
                    parental.isEnabled ? Icons.settings_rounded : Icons.lock_outline_rounded,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    parental.isEnabled ? 'Gestionar PIN' : 'Activar PIN',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
