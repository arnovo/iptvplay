import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vod_item.dart';
import '../../providers/download_provider.dart';
import '../../providers/user_activity_provider.dart';
import '../../services/tmdb_service.dart';
import '../screens/player_screen.dart';
import '../theme/app_theme.dart';

class MediaDetailSheet extends StatefulWidget {
  final VodItem vod;
  final int? resumeSeconds;

  const MediaDetailSheet({
    super.key,
    required this.vod,
    this.resumeSeconds,
  });

  @override
  State<MediaDetailSheet> createState() => _MediaDetailSheetState();
}

class _MediaDetailSheetState extends State<MediaDetailSheet> {
  final TmdbService _tmdbService = TmdbService();
  TmdbMetadata? _metadata;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTmdb();
  }

  Future<void> _loadTmdb() async {
    final meta = await _tmdbService.searchMetadata(title: widget.vod.name, isSeries: false);
    if (mounted) {
      setState(() {
        _metadata = meta;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userActivity = context.watch<UserActivityProvider>();
    final downloadProvider = context.watch<DownloadProvider>();
    final isFav = userActivity.isFavorite(widget.vod.id, 'vod');
    final downloadedItem = downloadProvider.completedItems
        .where((i) => i.id == widget.vod.id)
        .firstOrNull;
    final isDownloaded = downloadedItem != null;

    final poster = _metadata?.fullPosterUrl ?? widget.vod.posterUrl;
    final backdrop = _metadata?.fullBackdropUrl ?? widget.vod.posterUrl;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: 720,
        height: 520,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Backdrop Image with Gradient
            if (backdrop != null && backdrop.isNotEmpty)
              Positioned.fill(
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        AppTheme.surface.withValues(alpha: 0.85),
                        AppTheme.surface,
                      ],
                      stops: const [0.0, 0.5, 0.9],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstOut,
                  child: Image.network(
                    backdrop,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(),
                  ),
                ),
              ),

            // Close Button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),

            // Content
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Floating Poster
                    Container(
                      width: 170,
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.7),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: poster != null && poster.isNotEmpty
                          ? Image.network(
                              poster,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Center(
                                child: Icon(Icons.movie, size: 50, color: AppTheme.textMuted),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.movie, size: 50, color: AppTheme.textMuted),
                            ),
                    ),
                    const SizedBox(width: 24),
                    // Details & Actions
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title
                          Text(
                            _metadata?.title ?? widget.vod.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          // Badges (Rating, Year, TMDB)
                          Row(
                            children: [
                              if (_metadata != null && _metadata!.rating > 0) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        _metadata!.rating.toStringAsFixed(1),
                                        style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              if (_metadata != null && _metadata!.releaseDate.isNotEmpty) ...[
                                Text(
                                  _metadata!.releaseDate.split('-').first,
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'TMDB INFO',
                                  style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Synopsis
                          Text(
                            _isLoading
                                ? 'Cargando información ampliada...'
                                : (_metadata?.overview.isNotEmpty == true
                                    ? _metadata!.overview
                                    : 'Sin sinopsis disponible para esta película.'),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: 20),

                          // Actions
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.play_arrow, size: 22),
                                label: Text(
                                  widget.resumeSeconds != null && widget.resumeSeconds! > 10 ? 'Reanudar' : 'Ver Ahora',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PlayerScreen(
                                        streamUrl: downloadedItem != null
                                            ? downloadedItem.localFilePath
                                            : widget.vod.url,
                                        title: widget.vod.name,
                                        isLive: false,
                                        contentId: widget.vod.id,
                                        type: 'vod',
                                        posterUrl: poster,
                                        initialPositionSeconds: widget.resumeSeconds,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Favorite Button
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isFav ? Colors.amber : Colors.white,
                                  side: BorderSide(color: isFav ? Colors.amber : AppTheme.border),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: Icon(isFav ? Icons.star : Icons.star_border, size: 18),
                                label: Text(isFav ? 'Favorito' : 'Guardar'),
                                onPressed: () {
                                  userActivity.toggleFavorite(widget.vod.id, 'vod');
                                },
                              ),
                              // Download Button
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDownloaded ? AppTheme.accentGreen : Colors.white,
                                  side: BorderSide(color: isDownloaded ? AppTheme.accentGreen : AppTheme.border),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: Icon(isDownloaded ? Icons.check_circle : Icons.download, size: 18),
                                label: Text(isDownloaded ? 'Descargada' : 'Descargar'),
                                onPressed: isDownloaded
                                    ? null
                                    : () {
                                        downloadProvider.startVodDownload(
                                          id: widget.vod.id,
                                          title: widget.vod.name,
                                          streamUrl: widget.vod.url,
                                          type: 'vod',
                                          posterUrl: poster,
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Descarga iniciada en segundo plano')),
                                        );
                                      },
                              ),
                              // Open in folder button if downloaded
                              if (downloadedItem != null)
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primary,
                                    side: const BorderSide(color: AppTheme.primary),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.folder_open, size: 18),
                                  label: const Text('Abrir carpeta'),
                                  onPressed: () {
                                    downloadProvider.openItemInFileManager(downloadedItem);
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
