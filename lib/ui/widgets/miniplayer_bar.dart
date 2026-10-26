import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/playback_provider.dart';
import '../theme/app_theme.dart';

class MiniplayerBar extends StatelessWidget {
  const MiniplayerBar({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final playback = context.watch<PlaybackProvider>();

    if (!playback.hasMedia) {
      return const SizedBox.shrink();
    }

    final isLive = playback.isLive;
    final position = playback.position;
    final duration = playback.duration;
    final progressFraction = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: const Border(
            top: BorderSide(color: AppTheme.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Mini Progress Bar (for VOD)
            if (!isLive && duration > Duration.zero)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (details) {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box != null && box.size.width > 0) {
                    final fraction = (details.localPosition.dx / box.size.width).clamp(0.0, 1.0);
                    playback.seek(Duration(milliseconds: (duration.inMilliseconds * fraction).round()));
                  }
                },
                onTapDown: (details) {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box != null && box.size.width > 0) {
                    final fraction = (details.localPosition.dx / box.size.width).clamp(0.0, 1.0);
                    playback.seek(Duration(milliseconds: (duration.inMilliseconds * fraction).round()));
                  }
                },
                child: SizedBox(
                  height: 3,
                  width: double.infinity,
                  child: LinearProgressIndicator(
                    value: progressFraction,
                    backgroundColor: AppTheme.surfaceLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    minHeight: 3,
                  ),
                ),
              )
            else
              const SizedBox(height: 3),

            // Content & Controls Row
            Expanded(
              child: InkWell(
                onTap: () => playback.maximizeCurrentPlayer(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Thumbnail
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: playback.currentPosterUrl != null && playback.currentPosterUrl!.isNotEmpty
                            ? Image.network(
                                playback.currentPosterUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Icon(
                                  isLive ? Icons.live_tv : Icons.movie,
                                  color: AppTheme.primary,
                                  size: 22,
                                ),
                              )
                            : Icon(
                                isLive ? Icons.live_tv : Icons.movie,
                                color: AppTheme.primary,
                                size: 22,
                              ),
                      ),
                      const SizedBox(width: 14),

                      // Title & Subtitle Info
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playback.currentTitle ?? 'Reproduciendo',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            if (isLive)
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.accentRed,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'EN DIRECTO',
                                    style: TextStyle(
                                      color: AppTheme.accentRed,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                '${_formatDuration(position)} / ${_formatDuration(duration)}',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Center Controls: -10s, Play/Pause, +10s
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isLive) ...[
                            IconButton(
                              icon: const Icon(Icons.replay_10, color: AppTheme.textSecondary, size: 22),
                              tooltip: 'Retroceder 10 segundos',
                              onPressed: () => playback.seekRelative(const Duration(seconds: -10)),
                            ),
                          ],
                          IconButton(
                            icon: Icon(
                              playback.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                              color: AppTheme.primary,
                              size: 36,
                            ),
                            tooltip: playback.isPlaying ? 'Pausar' : 'Reproducir',
                            onPressed: () => playback.playOrPause(),
                          ),
                          if (!isLive) ...[
                            IconButton(
                              icon: const Icon(Icons.forward_10, color: AppTheme.textSecondary, size: 22),
                              tooltip: 'Avanzar 10 segundos',
                              onPressed: () => playback.seekRelative(const Duration(seconds: 10)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Maximize / Expand button
                      IconButton(
                        icon: const Icon(Icons.open_in_full, color: AppTheme.textPrimary, size: 20),
                        tooltip: 'Hacerlo más grande (Abrir reproductor)',
                        onPressed: () => playback.maximizeCurrentPlayer(context),
                      ),

                      // Stop / Close button
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                        tooltip: 'Detener y cerrar',
                        onPressed: () => playback.stop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
