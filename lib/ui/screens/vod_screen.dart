import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/user_activity_provider.dart';
import '../../models/vod_item.dart';
import '../../models/sort_option.dart';
import '../theme/app_theme.dart';
import '../widgets/category_sidebar.dart';
import '../widgets/media_detail_sheet.dart';
import '../widgets/sort_filter_button.dart';
import 'player_screen.dart';

class VodScreen extends StatelessWidget {
  const VodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final userActivity = context.watch<UserActivityProvider>();
    final selectedCategory = catalog.selectedVodCategoryId;

    List<VodItem> vods;
    if (selectedCategory == '__fav__') {
      vods = catalog.sortVods(catalog.content.vods
          .where((v) => userActivity.isFavorite(v.id, 'vod'))
          .where((v) => catalog.vodSearchQuery.isEmpty || v.name.toLowerCase().contains(catalog.vodSearchQuery.toLowerCase()))
          .toList());
    } else {
      vods = catalog.filteredVods;
    }

    final categories = catalog.content.vodCategories;
    final continueWatching = userActivity.continueWatching.where((p) => p.type == 'vod').toList();

    return Row(
      children: [
        CategorySidebar(
          categories: categories,
          selectedCategoryId: selectedCategory,
          totalCount: catalog.content.vods.length,
          onSelectCategory: (id) => catalog.setVodCategory(id),
          customTopItems: [
            CategoryCustomItem(
              id: '__fav__',
              name: 'Favoritos',
              icon: Icons.star,
              count: userActivity.favVod.length,
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
                        onChanged: (val) => catalog.setVodSearch(val),
                        decoration: const InputDecoration(
                          hintText: 'Buscar películas...',
                          prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SortFilterButton(
                      currentOption: catalog.vodSort,
                      availableOptions: const [
                        SortOption.defaultOrder,
                        SortOption.dateDesc,
                        SortOption.dateAsc,
                        SortOption.ratingDesc,
                        SortOption.nameAsc,
                        SortOption.nameDesc,
                      ],
                      onSelected: (opt) => catalog.setVodSort(opt),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${vods.length} películas',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              // Continue Watching Row (if any)
              if (continueWatching.isNotEmpty && selectedCategory == 'all' && catalog.vodSearchQuery.isEmpty)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceLight,
                    border: Border(bottom: BorderSide(color: AppTheme.border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.history, size: 16, color: AppTheme.primary),
                          SizedBox(width: 6),
                          Text(
                            'CONTINUAR VIENDO',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: continueWatching.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, idx) {
                            final item = continueWatching[idx];
                            return InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PlayerScreen(
                                      streamUrl: item.url,
                                      title: item.title,
                                      isLive: false,
                                      contentId: item.id,
                                      type: 'vod',
                                      posterUrl: item.posterUrl,
                                      initialPositionSeconds: item.positionSeconds,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 220,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: item.posterUrl != null
                                          ? Image.network(
                                              item.posterUrl!,
                                              width: 45,
                                              height: 70,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) => Container(
                                                width: 45,
                                                height: 70,
                                                color: AppTheme.surfaceLight,
                                                child: const Icon(Icons.movie, size: 20),
                                              ),
                                            )
                                          : Container(
                                              width: 45,
                                              height: 70,
                                              color: AppTheme.surfaceLight,
                                              child: const Icon(Icons.movie, size: 20),
                                            ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          LinearProgressIndicator(
                                            value: item.progressFraction,
                                            color: AppTheme.primary,
                                            backgroundColor: Colors.white12,
                                            minHeight: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.play_circle_filled, color: AppTheme.primary, size: 24),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

              // Movies Grid
              Expanded(
                child: vods.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              selectedCategory == '__fav__' ? Icons.star_border : Icons.movie_outlined,
                              size: 64,
                              color: AppTheme.textMuted.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              selectedCategory == '__fav__'
                                  ? 'No tienes películas favoritas todavía'
                                  : 'No se encontraron películas',
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
                        itemCount: vods.length,
                        itemBuilder: (context, index) {
                          final movie = vods[index];
                          return _buildMovieCard(context, movie, userActivity);
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMovieCard(BuildContext context, VodItem movie, UserActivityProvider userActivity) {
    final isFav = userActivity.isFavorite(movie.id, 'vod');
    final progress = userActivity.getProgress(movie.id);

    return InkWell(
      onTap: () => _showMovieDetails(context, movie, progress?.positionSeconds),
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
                  movie.posterUrl != null && movie.posterUrl!.isNotEmpty
                      ? Image.network(
                          movie.posterUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildPosterPlaceholder(),
                        )
                      : _buildPosterPlaceholder(),

                  // Rating Badge
                  if (movie.rating != null && movie.rating!.isNotEmpty)
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
                              movie.rating!,
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
                        userActivity.toggleFavorite(movie.id, 'vod');
                      },
                    ),
                  ),

                  // Playback Progress Bar on poster
                  if (progress != null && progress.progressFraction > 0)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: progress.progressFraction,
                        color: AppTheme.primary,
                        backgroundColor: Colors.black54,
                        minHeight: 4,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                movie.name,
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
        child: Icon(Icons.movie, color: AppTheme.textMuted, size: 40),
      ),
    );
  }

  void _showMovieDetails(BuildContext context, VodItem movie, int? savedPosition) {
    showDialog(
      context: context,
      builder: (ctx) => MediaDetailSheet(
        vod: movie,
        resumeSeconds: savedPosition,
      ),
    );
  }
}
