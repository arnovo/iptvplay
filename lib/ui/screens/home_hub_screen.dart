import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/channel.dart';
import '../../models/playback_progress.dart';
import '../../models/vod_item.dart';
import '../../models/series_item.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/epg_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/user_activity_provider.dart';
import '../../services/parental_service.dart';
import '../../services/reminder_service.dart';
import '../theme/app_theme.dart';
import '../widgets/media_detail_sheet.dart';
import '../widgets/tv_focusable.dart';
import 'epg_grid_screen.dart';
import 'multiview_screen.dart';
import 'player_screen.dart';

/// Pantalla de Inicio "Home Hub" estilo Netflix / Plex para IPTV Play
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

    // Filtro de control parental
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
            // Cabecera Hero de Bienvenida
            _buildHeroBanner(context, profile, catalog),

            const SizedBox(height: 28),

            // Fila 1: Continuar Viendo (si hay contenidos en curso)
            if (continueWatching.isNotEmpty) ...[
              _buildSectionHeader(
                title: 'Continuar Viendo',
                icon: Icons.play_circle_fill_rounded,
                subtitle: 'Retoma tus películas y series donde las dejaste',
              ),
              const SizedBox(height: 12),
              _buildContinueWatchingRow(context, continueWatching, catalog),
              const SizedBox(height: 28),
            ],

            // Fila 2: Próximos Recordatorios de Emisión (si los hay)
            if (reminders.isNotEmpty) ...[
              _buildSectionHeader(
                title: 'Recordatorios Programados',
                icon: Icons.notifications_active_rounded,
                subtitle: 'Eventos próximos que no te quieres perder',
              ),
              const SizedBox(height: 12),
              _buildRemindersRow(context, reminders),
              const SizedBox(height: 28),
            ],

            // Fila 3: Canales Favoritos y Frecuentes
            if (favChannels.isNotEmpty) ...[
              _buildSectionHeader(
                title: 'Tus Canales Favoritos y Frecuentes',
                icon: Icons.live_tv_rounded,
                subtitle: 'Sintonización directa con emisión actual en vivo',
                onSeeAll: onNavigateToLive,
              ),
              const SizedBox(height: 12),
              _buildFavoriteChannelsRow(context, favChannels),
              const SizedBox(height: 28),
            ],

            // Fila 4: Películas Destacadas
            if (vods.isNotEmpty) ...[
              _buildSectionHeader(
                title: 'Películas en el Catálogo',
                icon: Icons.movie_filter_rounded,
                subtitle: 'Títulos disponibles para reproducir en cualquier momento',
                onSeeAll: onNavigateToVod,
              ),
              const SizedBox(height: 12),
              _buildVodsRow(context, vods),
              const SizedBox(height: 28),
            ],

            // Fila 5: Series
            if (series.isNotEmpty) ...[
              _buildSectionHeader(
                title: 'Series Disponibles',
                icon: Icons.video_library_rounded,
                subtitle: 'Temporadas y episodios completos',
                onSeeAll: onNavigateToSeries,
              ),
              const SizedBox(height: 12),
              _buildSeriesRow(context, series),
              const SizedBox(height: 28),
            ],
          ],
        ),
      ),
    );
  }

  /// Banner Hero con resumen de catálogo y accesos directos
  Widget _buildHeroBanner(BuildContext context, dynamic profile, CatalogProvider catalog) {
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
                    Text(
                      'Bienvenido a IPTV Play',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile != null
                          ? 'Lista activa: ${profile.name} • ${catalog.content.channels.length} canales • ${catalog.content.vods.length} películas • ${catalog.content.series.length} series'
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

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required String subtitle,
    VoidCallback? onSeeAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        if (onSeeAll != null)
          TvFocusable(
            onPressed: onSeeAll,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: const Row(
                children: [
                  Text(
                    'Ver todo',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: AppTheme.primary, size: 16),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Fila de Continuar Viendo con barra de progreso
  Widget _buildContinueWatchingRow(
    BuildContext context,
    List<PlaybackProgress> items,
    CatalogProvider catalog,
  ) {
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final progress = items[index];
          final vodItem = catalog.content.vods.where((v) => v.id == progress.id).firstOrNull;

          return TvFocusable(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlayerScreen(
                    streamUrl: progress.url,
                    title: progress.title,
                    isLive: false,
                    contentId: progress.id,
                    type: progress.type,
                    posterUrl: progress.posterUrl,
                    initialPositionSeconds: progress.positionSeconds,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 220,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagen o banner
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            image: vodItem?.posterUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(vodItem!.posterUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: vodItem?.posterUrl == null
                              ? const Icon(Icons.movie, color: AppTheme.textMuted, size: 36)
                              : null,
                        ),
                      ),
                      // Título y duración restante
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              progress.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Quedan ${(progress.remainingSeconds / 60).ceil()} min',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Barra de progreso inferior
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: LinearProgressIndicator(
                      value: progress.progressFraction,
                      minHeight: 4,
                      backgroundColor: AppTheme.surfaceLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Fila de Recordatorios EPG
  Widget _buildRemindersRow(BuildContext context, List<dynamic> reminders) {
    final timeFormat = DateFormat('HH:mm');

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: reminders.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final r = reminders[index];
          final minutesUntil = r.startTime.difference(DateTime.now()).inMinutes;

          return TvFocusable(
            onPressed: () {},
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 240,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentYellow.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accentYellow.withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.alarm, color: AppTheme.accentYellow, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          r.programTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${r.channelName} • ${timeFormat.format(r.startTime)}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                        Text(
                          minutesUntil > 0 ? 'Empieza en $minutesUntil min' : 'Comenzando ahora',
                          style: const TextStyle(
                            color: AppTheme.accentYellow,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Fila de Canales Favoritos con el programa actual en directo
  Widget _buildFavoriteChannelsRow(BuildContext context, List<Channel> channels) {
    final epg = context.watch<EpgProvider>();

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: channels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final channel = channels[index];
          final currentProgram = epg.getCurrentProgram(
            channel.id,
            channelTvgId: channel.epgChannelId,
            channelName: channel.name,
          );

          return TvFocusable(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlayerScreen(
                    streamUrl: channel.url,
                    title: channel.name,
                    isLive: true,
                    contentId: channel.id,
                    type: 'live',
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      if (channel.logoUrl != null && channel.logoUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            channel.logoUrl!,
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(Icons.tv, size: 20),
                          ),
                        )
                      else
                        const Icon(Icons.tv, size: 20, color: AppTheme.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          channel.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentRed.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.accentRed, width: 0.8),
                        ),
                        child: const Text(
                          'VIVO',
                          style: TextStyle(
                            color: AppTheme.accentRed,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentProgram?.title ?? 'Emisión en directo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                  if (currentProgram != null) ...[
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: currentProgram.progressFraction,
                      minHeight: 3,
                      backgroundColor: AppTheme.surfaceLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Fila de Películas VOD
  Widget _buildVodsRow(BuildContext context, List<VodItem> vods) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: vods.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final vod = vods[index];
          return TvFocusable(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => MediaDetailSheet(vod: vod),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                      child: Container(
                        color: AppTheme.surfaceLight,
                        child: vod.posterUrl != null
                            ? Image.network(
                                vod.posterUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Icon(Icons.movie, color: AppTheme.textMuted),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.movie, color: AppTheme.textMuted),
                              ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      vod.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Fila de Series
  Widget _buildSeriesRow(BuildContext context, List<SeriesItem> seriesList) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: seriesList.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final s = seriesList[index];
          return TvFocusable(
            onPressed: onNavigateToSeries,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                      child: Container(
                        color: AppTheme.surfaceLight,
                        child: s.posterUrl != null
                            ? Image.network(
                                s.posterUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Icon(Icons.tv, color: AppTheme.textMuted),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.tv, color: AppTheme.textMuted),
                              ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
