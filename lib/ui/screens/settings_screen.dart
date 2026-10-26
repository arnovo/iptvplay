import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/buffer_profile.dart';
import '../../models/playlist_profile.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/epg_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/log_provider.dart';
import '../../providers/playback_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/parental_service.dart';
import '../theme/app_theme.dart';
import 'add_profile_dialog.dart';
import '../widgets/backup_dialog.dart';
import '../widgets/parental_dialog.dart';
import '../widgets/pin_code_dialog.dart';
import '../widgets/tv_focusable.dart';
import 'logs_screen.dart';
import 'profile_list_screen.dart';

/// Pantalla centralizada de Configuración para IPTV Play
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profileProvider = context.watch<ProfileProvider>();
    final catalogProvider = context.watch<CatalogProvider>();
    final parental = context.watch<ParentalService>();
    final logProvider = context.watch<LogProvider>();
    final playbackProvider = context.watch<PlaybackProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final activeProfile = profileProvider.activeProfile;

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

          // Contenido con Scroll
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // 1. SECCIÓN: GESTIÓN DE LISTAS Y PERFILES
                _buildSectionHeader(
                  icon: Icons.playlist_play_rounded,
                  title: l10n.isEnglish ? 'Playlists & Profiles' : 'Listas de Reproducción y Perfiles',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: activeProfile != null
                                  ? AppTheme.primary.withValues(alpha: 0.15)
                                  : AppTheme.surfaceLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              activeProfile != null ? Icons.check_circle_rounded : Icons.info_outline,
                              color: activeProfile != null ? AppTheme.primary : AppTheme.textMuted,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeProfile?.name ?? l10n.noActiveProfile,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  activeProfile != null
                                      ? '${activeProfile.type == PlaylistType.xtream ? 'Xtream Codes API' : 'Lista M3U'} • ${catalogProvider.content.channels.length} canales • ${catalogProvider.content.vods.length} películas • ${catalogProvider.content.series.length} series'
                                      : l10n.welcomeSubtitle,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppTheme.border, height: 1),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          // Botón Administrar Perfiles
                          TvFocusable(
                            borderRadius: BorderRadius.circular(10),
                            onPressed: () async {
                              if (parental.isSettingsRestricted()) {
                                final ok = await PinCodeDialog.show(context, title: 'Ajustes Protegidos');
                                if (!ok) return;
                              }
                              if (!context.mounted) return;
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ProfileListScreen()),
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
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.manage_accounts_rounded, size: 18, color: AppTheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.switchProfile,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Botón Añadir Lista
                          TvFocusable(
                            borderRadius: BorderRadius.circular(10),
                            onPressed: () async {
                              if (parental.isSettingsRestricted()) {
                                final ok = await PinCodeDialog.show(context, title: 'Ajustes Protegidos');
                                if (!ok) return;
                              }
                              if (!context.mounted) return;
                              showDialog(
                                context: context,
                                builder: (_) => const AddProfileDialog(),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.playlist_add_rounded, size: 18, color: Colors.black),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.addList,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Botón Recargar Contenido
                          if (activeProfile != null)
                            TvFocusable(
                              borderRadius: BorderRadius.circular(10),
                              onPressed: catalogProvider.isLoading
                                  ? null
                                  : () {
                                      catalogProvider.loadCatalog(activeProfile);
                                      context.read<EpgProvider>().loadEpg(activeProfile, forceRefresh: true);
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceLight,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.refresh_rounded,
                                      size: 18,
                                      color: catalogProvider.isLoading ? AppTheme.textMuted : AppTheme.textPrimary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      catalogProvider.isLoading ? 'Cargando...' : l10n.reloadList,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: catalogProvider.isLoading ? AppTheme.textMuted : AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. SECCIÓN: CONTROL PARENTAL Y MODO INFANTIL
                _buildSectionHeader(
                  icon: Icons.family_restroom_rounded,
                  title: l10n.isEnglish ? 'Parental Control & Kids Mode' : 'Control Parental y Modo Infantil',
                ),
                const SizedBox(height: 12),
                Container(
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
                ),

                const SizedBox(height: 24),

                // 3. SECCIÓN: REGISTROS Y LOGS DEL SISTEMA
                _buildSectionHeader(
                  icon: Icons.receipt_long_rounded,
                  title: l10n.isEnglish ? 'System Logs & Diagnostics' : 'Registros y Diagnóstico del Sistema',
                ),
                const SizedBox(height: 12),
                Container(
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
                ),

                const SizedBox(height: 24),

                // 4. SECCIÓN: COPIAS DE SEGURIDAD (BACKUP)
                _buildSectionHeader(
                  icon: Icons.cloud_sync_rounded,
                  title: l10n.isEnglish ? 'Encrypted Backups' : 'Copias de Seguridad Cifradas',
                ),
                const SizedBox(height: 12),
                Container(
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
                ),

                const SizedBox(height: 24),

                // 5. SECCIÓN: REPRODUCCIÓN, BÚFER E IDIOMA
                _buildSectionHeader(
                  icon: Icons.tune_rounded,
                  title: l10n.isEnglish ? 'Playback & Language' : 'Reproducción e Idioma',
                ),
                const SizedBox(height: 12),
                Container(
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
                ),

                const SizedBox(height: 24),

                // 6. SECCIÓN: ACERCA DE
                _buildSectionHeader(
                  icon: Icons.info_outline_rounded,
                  title: l10n.isEnglish ? 'About IPTV Play' : 'Acerca de IPTV Play',
                ),
                const SizedBox(height: 12),
                Container(
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
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.live_tv_rounded, color: AppTheme.primary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'IPTV Play • Versión 1.0.0',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Motor multimedia MediaKit (libmpv) • Cifrado seguro por hardware (Keychain/Keystore) • Cero telemetría.',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
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
