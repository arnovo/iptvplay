import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/user_activity_provider.dart';
import '../../models/series_item.dart';
import '../theme/app_theme.dart';
import '../widgets/category_sidebar.dart';
import 'player_screen.dart';

class SeriesScreen extends StatelessWidget {
  const SeriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final userActivity = context.watch<UserActivityProvider>();
    final selectedCategory = catalog.selectedSeriesCategoryId;

    List<SeriesItem> seriesList;
    if (selectedCategory == '__fav__') {
      seriesList = catalog.content.series
          .where((s) => userActivity.isFavorite(s.id, 'series'))
          .where((s) => catalog.seriesSearchQuery.isEmpty || s.name.toLowerCase().contains(catalog.seriesSearchQuery.toLowerCase()))
          .toList();
    } else {
      seriesList = catalog.filteredSeries;
    }

    final categories = catalog.content.seriesCategories;

    return Row(
      children: [
        CategorySidebar(
          categories: categories,
          selectedCategoryId: selectedCategory,
          totalCount: catalog.content.series.length,
          onSelectCategory: (id) => catalog.setSeriesCategory(id),
          customTopItems: [
            CategoryCustomItem(
              id: '__fav__',
              name: 'Favoritos',
              icon: Icons.star,
              count: userActivity.favSeries.length,
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
                        onChanged: (val) => catalog.setSeriesSearch(val),
                        decoration: const InputDecoration(
                          hintText: 'Buscar series...',
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
                        '${seriesList.length} series',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              // Series Grid
              Expanded(
                child: seriesList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              selectedCategory == '__fav__' ? Icons.star_border : Icons.tv,
                              size: 64,
                              color: AppTheme.textMuted.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              selectedCategory == '__fav__'
                                  ? 'No tienes series favoritas todavía'
                                  : 'No se encontraron series',
                              style: const TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 180,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: seriesList.length,
                        itemBuilder: (context, index) {
                          final series = seriesList[index];
                          return _buildSeriesCard(context, series, userActivity);
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSeriesCard(BuildContext context, SeriesItem series, UserActivityProvider userActivity) {
    final isFav = userActivity.isFavorite(series.id, 'series');

    return InkWell(
      onTap: () => _showSeriesEpisodes(context, series),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  series.posterUrl != null && series.posterUrl!.isNotEmpty
                      ? Image.network(
                          series.posterUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildPosterPlaceholder(),
                        )
                      : _buildPosterPlaceholder(),

                  // Rating badge
                  if (series.rating != null && series.rating!.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              series.rating!,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Favorite Button
                  Positioned(
                    top: 4,
                    left: 4,
                    child: IconButton(
                      icon: Icon(
                        isFav ? Icons.star : Icons.star_border,
                        color: isFav ? Colors.amber : Colors.white70,
                        size: 22,
                      ),
                      onPressed: () {
                        userActivity.toggleFavorite(series.id, 'series');
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                series.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterPlaceholder() {
    return Container(
      color: AppTheme.surfaceLight,
      child: const Center(
        child: Icon(Icons.video_library, color: AppTheme.textMuted, size: 40),
      ),
    );
  }

  void _showSeriesEpisodes(BuildContext context, SeriesItem series) async {
    final profile = context.read<ProfileProvider>().activeProfile;
    final userActivity = context.read<UserActivityProvider>();
    if (profile == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return FutureBuilder<List<SeriesEpisode>>(
          future: context.read<CatalogProvider>().loadEpisodesForSeries(profile, series),
          builder: (context, snapshot) {
            final episodes = snapshot.data ?? series.episodes;
            final isLoading = snapshot.connectionState == ConnectionState.waiting;

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (series.posterUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                series.posterUrl!,
                                width: 60,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const SizedBox(),
                              ),
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  series.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (series.plot != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    series.plot!,
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppTheme.border),
                      const SizedBox(height: 8),
                      const Text(
                        'EPISODIOS DISPONIBLES',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: isLoading
                            ? const Center(
                                child: CircularProgressIndicator(color: AppTheme.primary),
                              )
                            : episodes.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No se encontraron episodios',
                                      style: TextStyle(color: AppTheme.textSecondary),
                                    ),
                                  )
                                : ListView.separated(
                                    controller: scrollController,
                                    itemCount: episodes.length,
                                    separatorBuilder: (_, _) => const Divider(color: AppTheme.border, height: 1),
                                    itemBuilder: (context, epIndex) {
                                      final ep = episodes[epIndex];
                                      final progress = userActivity.getProgress(ep.id);

                                      return ListTile(
                                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppTheme.surfaceLight,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'T${ep.seasonNum} E${ep.episodeNum}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          ep.title,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                        ),
                                        subtitle: progress != null && progress.progressFraction > 0
                                            ? Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: LinearProgressIndicator(
                                                  value: progress.progressFraction,
                                                  color: AppTheme.primary,
                                                  backgroundColor: Colors.white12,
                                                  minHeight: 3,
                                                ),
                                              )
                                            : null,
                                        trailing: const Icon(
                                          Icons.play_circle_fill,
                                          color: AppTheme.primary,
                                          size: 28,
                                        ),
                                        onTap: () {
                                          Navigator.of(ctx).pop();
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => PlayerScreen(
                                                streamUrl: ep.url,
                                                title: '${series.name} - ${ep.title}',
                                                isLive: false,
                                                contentId: ep.id,
                                                type: 'series',
                                                posterUrl: series.posterUrl,
                                                initialPositionSeconds: progress?.positionSeconds,
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
                );
              },
            );
          },
        );
      },
    );
  }
}
