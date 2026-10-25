import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/user_activity_provider.dart';
import '../../providers/epg_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/download_provider.dart';
import '../../models/channel.dart';
import '../../models/sort_option.dart';
import '../theme/app_theme.dart';
import '../widgets/category_sidebar.dart';
import '../widgets/channel_epg_dialog.dart';
import '../widgets/catchup_dialog.dart';
import '../widgets/sort_filter_button.dart';
import 'player_screen.dart';

class LiveTvScreen extends StatelessWidget {
  const LiveTvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final userActivity = context.watch<UserActivityProvider>();
    final epg = context.watch<EpgProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final downloadProvider = context.watch<DownloadProvider>();
    final activeProfile = profileProvider.activeProfile;
    final selectedCategory = catalog.selectedLiveCategoryId;

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

    final categories = catalog.content.liveCategories;

    return Row(
      children: [
        CategorySidebar(
          categories: categories,
          selectedCategoryId: selectedCategory,
          totalCount: catalog.content.channels.length,
          onSelectCategory: (id) => catalog.setLiveCategory(id),
          customTopItems: [
            CategoryCustomItem(
              id: '__fav__',
              name: 'Favoritos',
              icon: Icons.star,
              count: userActivity.favLive.length,
            ),
            CategoryCustomItem(
              id: '__recents__',
              name: 'Recientes',
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
                    Expanded(
                      child: TextField(
                        onChanged: (val) => catalog.setLiveSearch(val),
                        decoration: const InputDecoration(
                          hintText: 'Buscar canales en vivo...',
                          prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
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
                    const SizedBox(width: 12),
                    if (selectedCategory == '__recents__' && channels.isNotEmpty) ...[
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.accentRed,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        icon: const Icon(Icons.delete_sweep, size: 16),
                        label: const Text('Limpiar recientes', style: TextStyle(fontSize: 12)),
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
                        '${channels.length} canales',
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
                                  ? 'No tienes canales favoritos todavía'
                                  : 'No se encontraron canales',
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

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
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
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
                                      channel.groupTitle ?? 'Canal ${channel.channelNumber ?? index + 1}',
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
                                  tooltip: 'Guía EPG del canal',
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
                                    tooltip: 'Replay TV (Programas anteriores)',
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
                                  tooltip: downloadProvider.isChannelRecording(channel.id) ? 'Detener grabación' : 'Grabar en directo',
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
                                              ? 'Grabación de "${channel.name}" detenida y guardada'
                                              : 'Grabando "${channel.name}" en segundo plano...',
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
                                    tooltip: 'Quitar de recientes',
                                    onPressed: () {
                                      userActivity.removeRecentChannel(channel.id);
                                    },
                                  ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.surfaceLight,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.play_arrow, color: AppTheme.primary, size: 20),
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
