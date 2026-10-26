import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/buffer_profile.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/playback_provider.dart';
import '../../theme/app_theme.dart';
import '../tv_focusable.dart';

/// Tarjeta de configuración para idioma de la app y perfil de búfer libmpv
class PlaybackSettingsCard extends StatelessWidget {
  const PlaybackSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageProvider = context.watch<LanguageProvider>();
    final playbackProvider = context.watch<PlaybackProvider>();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          // Selector de Idioma
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Idioma de la Aplicación',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Cambia entre Español e Inglés',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              TvFocusable(
                borderRadius: BorderRadius.circular(8),
                onPressed: () => languageProvider.toggleLanguage(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${languageProvider.currentFlag} ${languageProvider.currentLanguageName}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.sync_alt_rounded, size: 16, color: AppTheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 16),

          // Selector de Búfer
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Perfil de Búfer de Reproducción (libmpv)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Ajusta la memoria intermedia según la estabilidad de tu conexión a internet.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: BufferProfile.values.map((profile) {
                  final isSelected = playbackProvider.bufferProfile == profile;
                  return TvFocusable(
                    borderRadius: BorderRadius.circular(8),
                    onPressed: () => playbackProvider.setBufferProfile(profile),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withValues(alpha: 0.15)
                            : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : AppTheme.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                            size: 16,
                            color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.isEnglish ? profile.labelEn : profile.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
