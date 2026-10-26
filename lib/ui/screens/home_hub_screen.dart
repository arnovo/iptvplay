import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/user_activity_provider.dart';
import '../../services/parental_service.dart';
import '../../services/reminder_service.dart';
import '../theme/app_theme.dart';
import '../widgets/home_hub/home_hero_banner.dart';
import '../widgets/home_hub/hub_continue_watching_row.dart';
import '../widgets/home_hub/hub_favorite_channels_row.dart';
import '../widgets/home_hub/hub_reminders_row.dart';
import '../widgets/home_hub/hub_section_header.dart';
import '../widgets/home_hub/hub_series_row.dart';
import '../widgets/home_hub/hub_vods_row.dart';

/// Pantalla de Inicio "Home Hub" estilo Netflix / Plex para IPTV Play
///
/// Coordina las diferentes filas y secciones modulares del catálogo.
class HomeHubScreen extends StatelessWidget {
  final VoidCallback onNavigateToLive;
  final VoidCallback onNavigateToVod;
  final VoidCallback onNavigateToSeries;

  const HomeHubScreen({
    super.key,
    required this.onNavigateToLive,
    required this.onNavigateToVod,
    required this.onNavigateToSeries,
  });

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().activeProfile;
    final catalog = context.watch<CatalogProvider>();
    final userActivity = context.watch<UserActivityProvider>();
    final reminders = context.watch<ReminderService>().upcomingReminders;
    final parental = context.watch<ParentalService>();

    // Filtrado de seguridad parental
    final continueWatching = userActivity.continueWatching.where((p) {
      return !parental.isCategoryRestricted(categoryId: '', categoryName: p.title);
    }).toList();

    final favChannels = catalog.content.channels.where((c) {
      final isFavOrRecent = userActivity.isFavorite(c.id, 'live') ||
          userActivity.recentChannels.any((rc) => rc.id == c.id);
      final isRestricted = parental.isCategoryRestricted(
        categoryId: c.categoryId,
        categoryName: c.name,
      );
      return isFavOrRecent && !isRestricted;
    }).take(15).toList();

    final vods = catalog.content.vods.where((v) {
      return !parental.isCategoryRestricted(categoryId: v.categoryId, categoryName: v.name);
    }).take(12).toList();

    final series = catalog.content.series.where((s) {
      return !parental.isCategoryRestricted(categoryId: s.categoryId, categoryName: s.name);
    }).take(12).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera Hero de Bienvenida y resumen
            HomeHeroBanner(
              profile: profile,
              catalog: catalog,
              onNavigateToLive: onNavigateToLive,
            ),
            const SizedBox(height: 28),

            // Fila 1: Continuar Viendo
            if (continueWatching.isNotEmpty) ...[
              const HubSectionHeader(
                title: 'Continuar Viendo',
                icon: Icons.play_circle_fill_rounded,
                subtitle: 'Retoma tus películas y series donde las dejaste',
              ),
              const SizedBox(height: 12),
              HubContinueWatchingRow(items: continueWatching, catalog: catalog),
              const SizedBox(height: 28),
            ],

            // Fila 2: Próximos Recordatorios de Emisión
            if (reminders.isNotEmpty) ...[
              const HubSectionHeader(
                title: 'Recordatorios Programados',
                icon: Icons.notifications_active_rounded,
                subtitle: 'Eventos próximos que no te quieres perder',
              ),
              const SizedBox(height: 12),
              HubRemindersRow(reminders: reminders),
              const SizedBox(height: 28),
            ],

            // Fila 3: Canales Favoritos y Frecuentes
            if (favChannels.isNotEmpty) ...[
              HubSectionHeader(
                title: 'Tus Canales Favoritos y Frecuentes',
                icon: Icons.live_tv_rounded,
                subtitle: 'Sintonización directa con emisión actual en vivo',
                onSeeAll: onNavigateToLive,
              ),
              const SizedBox(height: 12),
              HubFavoriteChannelsRow(channels: favChannels),
              const SizedBox(height: 28),
            ],

            // Fila 4: Películas Destacadas
            if (vods.isNotEmpty) ...[
              HubSectionHeader(
                title: 'Películas en el Catálogo',
                icon: Icons.movie_filter_rounded,
                subtitle: 'Títulos disponibles para reproducir en cualquier momento',
                onSeeAll: onNavigateToVod,
              ),
              const SizedBox(height: 12),
              HubVodsRow(vods: vods),
              const SizedBox(height: 28),
            ],

            // Fila 5: Series
            if (series.isNotEmpty) ...[
              HubSectionHeader(
                title: 'Series Disponibles',
                icon: Icons.video_library_rounded,
                subtitle: 'Temporadas y episodios completos',
                onSeeAll: onNavigateToSeries,
              ),
              const SizedBox(height: 12),
              HubSeriesRow(seriesList: series, onNavigateToSeries: onNavigateToSeries),
              const SizedBox(height: 28),
            ],
          ],
        ),
      ),
    );
  }
}
