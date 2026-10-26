import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/log_provider.dart';
import '../../screens/logs_screen.dart';
import '../../theme/app_theme.dart';
import '../tv_focusable.dart';

/// Tarjeta de configuración para diagnóstico y visor de logs del sistema
class SystemLogsCard extends StatelessWidget {
  const SystemLogsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final logProvider = context.watch<LogProvider>();

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
            child: const Icon(Icons.analytics_outlined, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${logProvider.totalCount} eventos registrados',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (logProvider.errorCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentRed.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${logProvider.errorCount} errores',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentRed,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Monitoreo en tiempo real de red, descargas, EPG, reproductor y servidor de retransmisión.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          TvFocusable(
            borderRadius: BorderRadius.circular(10),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LogsScreen()),
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
                  Icon(Icons.open_in_new_rounded, size: 18, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text(
                    'Abrir Visor de Logs',
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
