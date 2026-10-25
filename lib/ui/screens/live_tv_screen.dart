import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/user_activity_provider.dart';
import '../../models/channel.dart';
import '../theme/app_theme.dart';
import '../widgets/category_sidebar.dart';
import 'player_screen.dart';

class LiveTvScreen extends StatelessWidget {
  const LiveTvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final userActivity = context.watch<UserActivityProvider>();
    final selectedCategory = catalog.selectedLiveCategoryId;

    List<Channel> channels;
    if (selectedCategory == '__fav__') {
      channels = catalog.content.channels
          .where((c) => userActivity.isFavorite(c.id, 'live'))
          .where((c) => catalog.liveSearchQuery.isEmpty || c.name.toLowerCase().contains(catalog.liveSearchQuery.toLowerCase()))
          .toList();
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
                            title: Text(
                              channel.name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              channel.groupTitle ?? 'Canal ${channel.channelNumber ?? index + 1}',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
