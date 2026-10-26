import 'package:flutter/material.dart';
import '../../../models/playback_progress.dart';
import '../../../providers/catalog_provider.dart';
import '../../screens/player_screen.dart';
import '../../theme/app_theme.dart';
import '../tv_focusable.dart';

/// Fila horizontal de contenidos en curso para reanudar reproducción
class HubContinueWatchingRow extends StatelessWidget {
  final List<PlaybackProgress> items;
  final CatalogProvider catalog;

  const HubContinueWatchingRow({
    super.key,
    required this.items,
    required this.catalog,
  });

  @override
  Widget build(BuildContext context) {
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
}
