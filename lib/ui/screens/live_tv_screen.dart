import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/user_activity_provider.dart';
import '../../providers/epg_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/download_provider.dart';
import '../../models/channel.dart';
import '../../models/sort_option.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/category_sidebar.dart';
import '../widgets/channel_epg_dialog.dart';
import '../widgets/catchup_dialog.dart';
import '../widgets/sort_filter_button.dart';
import '../widgets/tv_focusable.dart';
import '../../services/parental_service.dart';
import 'player_screen.dart';
import 'multiview_screen.dart';
import 'epg_grid_screen.dart';
import '../widgets/voice_search_dialog.dart';

class LiveTvScreen extends StatelessWidget {
  const LiveTvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final userActivity = context.watch<UserActivityProvider>();
    final epg = context.watch<EpgProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final downloadProvider = context.watch<DownloadProvider>();
    final parental = context.watch<ParentalService>();
    final activeProfile = profileProvider.activeProfile;
    final selectedCategory = catalog.selectedLiveCategoryId;
    final l10n = context.l10n;

    final restrictedCategoryIds = <String>{};
    final categories = catalog.content.liveCategories.where((c) {
      if (parental.isCategoryRestricted(categoryId: c.id, categoryName: c.name)) {
        restrictedCategoryIds.add(c.id);
        return false;
      }
      return true;
    }).toList();

    List<Channel> channels;
    if (selectedCategory == '__fav__') {
      channels = catalog.sortChannels(catalog.content.channels
          .where((c) => userActivity.isFavorite(c.id, 'live'))
          .where((c) => catalog.liveSearchQuery.isEmpty || c.name.toLowerCase().contains(catalog.liveSearchQuery.toLowerCase()))
          .toList());
    } else if (selectedCategory == '__recents__') {
      channels = userActivity.recentChannels
          .where((c) => catalog.liveSearchQuery.isEmpty || c.name.toLowerCase().contains(catalog.liveSearchQuery.toLowerCase()))
          .toList();
    } else {
      channels = catalog.filteredChannels;
    }

    if (restrictedCategoryIds.isNotEmpty) {
      channels = channels.where((c) => !restrictedCategoryIds.contains(c.categoryId)).toList();
    }

    return Row(
      children: [
        if (catalog.isSubmenuVisible)
          CategorySidebar(
            categories: categories,
            selectedCategoryId: selectedCategory,
            totalCount: catalog.content.channels.length,
            onSelectCategory: (id) => catalog.setLiveCategory(id),
            onToggleCollapse: () => catalog.toggleSubmenu(),
            customTopItems: [
              CategoryCustomItem(
                id: '__fav__',
                name: l10n.favorites,
                icon: Icons.star,
                count: userActivity.favLive.length,
              ),
              CategoryCustomItem(
                id: '__recents__',
                name: l10n.recents,
                icon: Icons.history,
                count: userActivity.recentChannels.length,
              ),
            ],
          ),
        Expanded(
          child: Column(
            children: [
              // Search Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  border: Border(bottom: BorderSide(color: AppTheme.border)),
                ),
                child: Row(
                  children: [
                    // Botón Ocultar/Mostrar Submenú de Categorías
                    TvFocusable(
                      borderRadius: BorderRadius.circular(8),
                      onPressed: () => catalog.toggleSubmenu(),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: catalog.isSubmenuVisible
                              ? AppTheme.surfaceLight
                              : AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: catalog.isSubmenuVisible ? AppTheme.border : AppTheme.primary,
                          ),
                        ),
                        child: Icon(
                          catalog.isSubmenuVisible
                              ? Icons.view_sidebar_rounded
                              : Icons.view_sidebar_outlined,
                          size: 18,
                          color: catalog.isSubmenuVisible ? AppTheme.textSecondary : AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        onChanged: (val) => catalog.setLiveSearch(val),
                        decoration: InputDecoration(
                          hintText: l10n.searchChannels,
                          prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.mic, color: AppTheme.primary, size: 20),
                            tooltip: 'Búsqueda por Voz en Smart TV',
                            onPressed: () async {
                              final query = await VoiceSearchDialog.show(
                                context,
                                currentQuery: catalog.liveSearchQuery,
                                title: 'Buscar Canales por Voz',
                              );
                              if (query != null) {
                                catalog.setLiveSearch(query);
                              }
                            },
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SortFilterButton(
                      currentOption: catalog.liveSort,
                      availableOptions: const [
                        SortOption.defaultOrder,
                        SortOption.nameAsc,
                        SortOption.nameDesc,
                      ],
                      onSelected: (opt) => catalog.setLiveSort(opt),
                    ),
                    const SizedBox(width: 8),
                    // Botón Guía EPG en Cuadrícula
                    TvFocusable(
                      borderRadius: BorderRadius.circular(8),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const EpgGridScreen()),
                        );
                      },
                      builder: (context, isFocused, isHovered) {
                        return Container(
                          decoration: BoxDecoration(
                            color: isFocused ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isFocused ? AppTheme.primary : AppTheme.border),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.grid_on_rounded, color: AppTheme.primary, size: 20),
                            tooltip: 'Guía de Programación en Cuadrícula (EPG)',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const EpgGridScreen()),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    TvFocusable(
                      borderRadius: BorderRadius.circular(8),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MultiviewScreen()),
                        );
                      },
                      builder: (context, isFocused, isHovered) {
                        return Container(
                          decoration: BoxDecoration(
                            color: isFocused ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isFocused ? AppTheme.primary : AppTheme.border),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.dashboard_customize, color: AppTheme.primary, size: 20),
                            tooltip: 'Pantalla Dividida (Multiview 4 Canales)',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const MultiviewScreen()),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    if (selectedCategory == '__recents__' && channels.isNotEmpty) ...[
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.accentRed,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        icon: const Icon(Icons.delete_sweep, size: 16),
                        label: Text(l10n.clearRecents, style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          userActivity.clearRecentChannels();
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${channels.length} ${l10n.isEnglish ? "channels" : "canales"}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              // Channel List
              Expanded(
                child: channels.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              selectedCategory == '__fav__'
                                  ? Icons.star_border
                                  : Icons.tv_off,
                              size: 64,
                              color: AppTheme.textMuted.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              selectedCategory == '__fav__'
                                  ? (l10n.isEnglish
                                      ? 'No favorite channels yet'
                                      : 'No tienes canales favoritos todavía')
                                  : l10n.noChannelsFound,
                              style: const TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: channels.length,
                        itemBuilder: (context, index) {
                          final channel = channels[index];
                          final isFav = userActivity.isFavorite(channel.id, 'live');

                          return TvFocusable(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                            borderRadius: BorderRadius.circular(10),
                            onPressed: () {
                              userActivity.addRecentChannel(channel);
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
                            builder: (context, isFocused, isHovered) {
                              return Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceLight,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isFocused
                                            ? AppTheme.primary
                                            : AppTheme.border.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: channel.logoUrl != null && channel.logoUrl!.isNotEmpty
                                        ? Image.network(
                                            channel.logoUrl!,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, _, _) => const Icon(
                                              Icons.live_tv,
                                              color: AppTheme.textMuted,
                                              size: 24,
                                            ),
                                          )
                                        : const Icon(Icons.live_tv, color: AppTheme.textMuted, size: 24),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          channel.name,
                                          style: TextStyle(
                                            fontWeight: isFocused ? FontWeight.bold : FontWeight.w600,
                                            fontSize: 15,
                                            color: isFocused ? AppTheme.primary : AppTheme.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (downloadProvider.isChannelRecording(channel.id))
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accentRed,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('REC', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                  subtitle: Builder(
                                    builder: (context) {
                                      final currentProg = epg.getCurrentProgram(
                                        channel.id,
                                        channelTvgId: channel.epgChannelId,
                                        channelName: channel.name,
                                      );

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (currentProg != null) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              '${currentProg.title} • ${currentProg.formattedTimeRange}',
                                              style: const TextStyle(
                                                color: AppTheme.primary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(2),
                                              child: LinearProgressIndicator(
                                                value: currentProg.progressFraction,
                                                backgroundColor: AppTheme.surfaceLight,
                                                color: AppTheme.primary,
                                                minHeight: 2.5,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                          ],
                                          Text(
                                            channel.groupTitle ?? '${l10n.isEnglish ? "Channel" : "Canal"} ${channel.channelNumber ?? index + 1}',
                                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // EPG Guide Button
                                      IconButton(
                                        icon: const Icon(Icons.event_note, color: AppTheme.textSecondary, size: 20),
                                        tooltip: l10n.channelSchedule,
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => ChannelEpgDialog(channel: channel),
                                          );
                                        },
                                      ),
                                      // Catch-up / Replay Button
                                      if (activeProfile != null)
                                        IconButton(
                                          icon: const Icon(Icons.history, color: AppTheme.textSecondary, size: 20),
                                          tooltip: l10n.catchupTitle,
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => CatchupDialog(
                                                channel: channel,
                                                profile: activeProfile,
                                              ),
                                            );
                                          },
                                        ),
                                      // PVR Record Button
                                      IconButton(
                                        icon: Icon(
                                          downloadProvider.isChannelRecording(channel.id) ? Icons.stop_circle : Icons.fiber_manual_record,
                                          color: downloadProvider.isChannelRecording(channel.id) ? AppTheme.accentRed : AppTheme.textMuted,
                                          size: 20,
                                        ),
                                        tooltip: downloadProvider.isChannelRecording(channel.id) ? l10n.stopRecording : l10n.recordChannel,
                                        onPressed: () {
                                          downloadProvider.toggleLiveRecording(
                                            channelId: channel.id,
                                            title: channel.name,
                                            streamUrl: channel.url,
                                            posterUrl: channel.logoUrl,
                                          );
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                downloadProvider.isChannelRecording(channel.id)
                                                    ? (l10n.isEnglish
                                                        ? 'Recording of "${channel.name}" stopped and saved'
                                                        : 'Grabación de "${channel.name}" detenida y guardada')
                                                    : (l10n.isEnglish
                                                        ? 'Recording "${channel.name}" in background...'
                                                        : 'Grabando "${channel.name}" en segundo plano...'),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      // Favorite Star Button
                                      IconButton(
                                        icon: Icon(
                                          isFav ? Icons.star : Icons.star_border,
                                          color: isFav ? Colors.amber : AppTheme.textMuted,
                                          size: 22,
                                        ),
                                        onPressed: () {
                                          userActivity.toggleFavorite(channel.id, 'live');
                                        },
                                      ),
                                      if (selectedCategory == '__recents__')
                                        IconButton(
                                          icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                                          tooltip: l10n.isEnglish ? 'Remove from recent' : 'Quitar de recientes',
                                          onPressed: () {
                                            userActivity.removeRecentChannel(channel.id);
                                          },
                                        ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isFocused ? AppTheme.primary : AppTheme.surfaceLight,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.play_arrow,
                                          color: isFocused ? Colors.black : AppTheme.primary,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    userActivity.addRecentChannel(channel);
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
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
