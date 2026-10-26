import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/playlist_profile.dart';
import '../../../providers/catalog_provider.dart';
import '../../../providers/epg_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../services/parental_service.dart';
import '../../screens/add_profile_dialog.dart';
import '../../screens/profile_list_screen.dart';
import '../../theme/app_theme.dart';
import '../pin_code_dialog.dart';
import '../tv_focusable.dart';

/// Tarjeta de configuración y gestión de perfiles y listas IPTV
class ProfileSettingsCard extends StatelessWidget {
  const ProfileSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profileProvider = context.watch<ProfileProvider>();
    final catalogProvider = context.watch<CatalogProvider>();
    final parental = context.watch<ParentalService>();
    final activeProfile = profileProvider.activeProfile;

    return Container(
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
                          if (!kIsWeb) {
                            context.read<EpgProvider>().loadEpg(activeProfile, forceRefresh: true);
                          }
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
    );
  }
}
