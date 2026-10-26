import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Bottom bar controls overlay: timeline scrubber, duration indicators,
/// playback speed selector, volume slider, mute toggle, and fullscreen trigger.
class PlayerBottomBar extends StatelessWidget {
  final Player player;
  final bool isLive;
  final double playbackRate;
  final double volume;
  final bool isMuted;
  final bool isFullScreen;
  final VoidCallback onCyclePlaybackRate;
  final VoidCallback onToggleMute;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onToggleFullScreen;
  final VoidCallback onUserInteraction;

  const PlayerBottomBar({
    super.key,
    required this.player,
    required this.isLive,
    required this.playbackRate,
    required this.volume,
    required this.isMuted,
    required this.isFullScreen,
    required this.onCyclePlaybackRate,
    required this.onToggleMute,
    required this.onVolumeChanged,
    required this.onToggleFullScreen,
    required this.onUserInteraction,
  });

  static String formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          if (!isLive) ...[
            StreamBuilder<Duration>(
              stream: player.stream.position,
              builder: (context, posSnapshot) {
                final position = posSnapshot.data ?? Duration.zero;
                return StreamBuilder<Duration>(
                  stream: player.stream.duration,
                  builder: (context, durSnapshot) {
                    final duration = durSnapshot.data ?? Duration.zero;
                    final maxSec = duration.inSeconds.toDouble();
                    final curSec = position.inSeconds
                        .toDouble()
                        .clamp(0.0, maxSec > 0 ? maxSec : 1.0);

                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbColor: AppTheme.primary,
                            activeTrackColor: AppTheme.primary,
                            inactiveTrackColor: Colors.white24,
                            trackHeight: 4,
                            thumbShape:
                                const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: curSec,
                            max: maxSec > 0 ? maxSec : 1.0,
                            onChanged: (val) {
                              player.seek(Duration(seconds: val.toInt()));
                              onUserInteraction();
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formatDuration(position),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              formatDuration(duration),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],

          // Advanced Action Toolbar (Speed, Volume Mute, Fullscreen)
          Row(
            children: [
              // Playback Speed Button (For VOD/Series)
              if (!isLive)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white10,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onPressed: onCyclePlaybackRate,
                  child: Text(
                    '${playbackRate}x',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              const Spacer(),
              // Volume Control
              IconButton(
                icon: Icon(
                  isMuted || volume == 0 ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: onToggleMute,
              ),
              SizedBox(
                width: 90,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbColor: AppTheme.primary,
                    activeTrackColor: AppTheme.primary,
                    inactiveTrackColor: Colors.white24,
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 5),
                  ),
                  child: Slider(
                    value: isMuted ? 0.0 : volume,
                    max: 100.0,
                    onChanged: (val) {
                      onVolumeChanged(val);
                      onUserInteraction();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Fullscreen Button
              IconButton(
                icon: Icon(
                  isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                  size: 22,
                ),
                tooltip: isFullScreen
                    ? l10n.exitFullscreenTooltip
                    : l10n.enterFullscreenTooltip,
                onPressed: onToggleFullScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
