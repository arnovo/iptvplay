import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/playlist_profile.dart';
import '../../providers/catalog_provider.dart';
import '../screens/add_profile_dialog.dart';
import '../theme/app_theme.dart';

/// Vista para estados vacíos, de carga y de error del catálogo
class CatalogStateView extends StatelessWidget {
  final PlaylistProfile? activeProfile;
  final CatalogProvider catalogProvider;

  const CatalogStateView({
    super.key,
    required this.activeProfile,
    required this.catalogProvider,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Sin perfil activo
    if (activeProfile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.playlist_play, size: 64, color: AppTheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.welcomeTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.welcomeSubtitle,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const AddProfileDialog(),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.addPlaylistButton),
            ),
          ],
        ),
      );
    }

    // Cargando catálogo
    if (catalogProvider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.primary),
            const SizedBox(height: 20),
            Text(
              l10n.loadingCatalogTitle,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.loadingCatalogSubtitle,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Error de carga
    if (catalogProvider.errorMessage != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.accentRed.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.accentRed, size: 48),
              const SizedBox(height: 16),
              Text(l10n.catalogErrorTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                catalogProvider.errorMessage!,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => catalogProvider.loadCatalog(activeProfile!),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
