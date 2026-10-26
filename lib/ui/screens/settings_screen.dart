import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/settings/about_app_card.dart';
import '../widgets/settings/backup_settings_card.dart';
import '../widgets/settings/parental_settings_card.dart';
import '../widgets/settings/playback_settings_card.dart';
import '../widgets/settings/profile_settings_card.dart';
import '../widgets/settings/settings_section_header.dart';
import '../widgets/settings/system_logs_card.dart';

/// Pantalla centralizada de Configuración para IPTV Play.
///
/// Coordina de forma desacoplada los componentes modulares de ajustes:
/// perfiles, control parental, registros, backups, reproducción y sistema.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de Configuración
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGlow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.settings_rounded, color: AppTheme.primary, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.settings,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.settingsSubtitle,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contenido modular con scroll
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // 1. Gestión de Listas y Perfiles
                SettingsSectionHeader(
                  icon: Icons.playlist_play_rounded,
                  title: l10n.isEnglish ? 'Playlists & Profiles' : 'Listas de Reproducción y Perfiles',
                ),
                const SizedBox(height: 12),
                const ProfileSettingsCard(),
                const SizedBox(height: 24),

                // 2. Control Parental y Modo Infantil
                SettingsSectionHeader(
                  icon: Icons.family_restroom_rounded,
                  title: l10n.isEnglish ? 'Parental Control & Kids Mode' : 'Control Parental y Modo Infantil',
                ),
                const SizedBox(height: 12),
                const ParentalSettingsCard(),
                const SizedBox(height: 24),

                // 3. Registros y Diagnóstico del Sistema
                SettingsSectionHeader(
                  icon: Icons.receipt_long_rounded,
                  title: l10n.isEnglish ? 'System Logs & Diagnostics' : 'Registros y Diagnóstico del Sistema',
                ),
                const SizedBox(height: 12),
                const SystemLogsCard(),
                const SizedBox(height: 24),

                // 4. Copias de Seguridad Cifradas (AES-256)
                SettingsSectionHeader(
                  icon: Icons.cloud_sync_rounded,
                  title: l10n.isEnglish ? 'Encrypted Backups' : 'Copias de Seguridad Cifradas',
                ),
                const SizedBox(height: 12),
                const BackupSettingsCard(),
                const SizedBox(height: 24),

                // 5. Reproducción, Búfer e Idioma
                SettingsSectionHeader(
                  icon: Icons.tune_rounded,
                  title: l10n.isEnglish ? 'Playback & Language' : 'Reproducción e Idioma',
                ),
                const SizedBox(height: 12),
                const PlaybackSettingsCard(),
                const SizedBox(height: 24),

                // 6. Acerca de IPTV Play
                SettingsSectionHeader(
                  icon: Icons.info_outline_rounded,
                  title: l10n.isEnglish ? 'About IPTV Play' : 'Acerca de IPTV Play',
                ),
                const SizedBox(height: 12),
                const AboutAppCard(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
