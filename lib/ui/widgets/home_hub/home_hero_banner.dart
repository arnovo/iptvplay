import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../models/playlist_profile.dart';
import '../../../providers/catalog_provider.dart';
import '../../screens/epg_grid_screen.dart';
import '../../screens/multiview_screen.dart';
import '../../theme/app_theme.dart';
import '../tv_focusable.dart';

/// Banner Hero con resumen del catálogo cargado y accesos directos
class HomeHeroBanner extends StatelessWidget {
  final PlaylistProfile? profile;
  final CatalogProvider catalog;
  final VoidCallback onNavigateToLive;

  const HomeHeroBanner({
    super.key,
    required this.profile,
    required this.catalog,
    required this.onNavigateToLive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            AppTheme.surface,
            AppTheme.surfaceLight.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGlow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary, width: 1.5),
                ),
                child: const Icon(Icons.hub_rounded, color: AppTheme.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bienvenido a IPTV Play',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile != null
                          ? 'Lista activa: ${profile!.name} • ${catalog.content.channels.length} canales • ${catalog.content.vods.length} películas • ${catalog.content.series.length} series'
                          : 'Selecciona o añade una lista de reproducción para comenzar',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Accesos rápidos
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              TvFocusable(
                onPressed: onNavigateToLive,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tv, color: AppTheme.background, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Ver TV en Directo',
                        style: TextStyle(
                          color: AppTheme.background,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!kIsWeb)
                TvFocusable(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EpgGridScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.grid_on_rounded, color: AppTheme.primary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Guía de TV (EPG)',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              TvFocusable(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MultiviewScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.dashboard_customize_rounded, color: AppTheme.primary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Multiview 4 Canales',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
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
