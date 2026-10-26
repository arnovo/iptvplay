import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/channel.dart';
import '../../../providers/download_provider.dart';
import '../../../providers/playback_provider.dart';
import '../../../providers/stream_server_provider.dart';
import '../../../providers/user_activity_provider.dart';
import '../../screens/multiview_screen.dart';
import '../../theme/app_theme.dart';
import '../lan_stream_dialog.dart';

/// Top bar overlay inside the player screen containing title, channel info,
/// format button, audio/subtitles dialog triggers, and quick action icons.
class PlayerTopBar extends StatelessWidget {
  final String title;
  final String streamUrl;
  final bool isLive;
  final String? contentId;
  final String? type;
  final String? posterUrl;
  final String aspectRatioName;
  final bool isFullScreen;
  final VoidCallback onShowScreenFormat;
  final VoidCallback onToggleAspectRatio;
  final VoidCallback onShowAudioTracks;
  final VoidCallback onShowSubtitles;
  final VoidCallback onToggleFullScreen;
  final VoidCallback onUserInteraction;

  const PlayerTopBar({
    super.key,
    required this.title,
    required this.streamUrl,
    required this.isLive,
    this.contentId,
    this.type,
    this.posterUrl,
    required this.aspectRatioName,
    required this.isFullScreen,
    required this.onShowScreenFormat,
    required this.onToggleAspectRatio,
    required this.onShowAudioTracks,
    required this.onShowSubtitles,
    required this.onToggleFullScreen,
    required this.onUserInteraction,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            tooltip: l10n.minimizeTooltip,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isLive)
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.accentRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.liveOnAir,
                        style: const TextStyle(
                          color: AppTheme.accentRed,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Screen Mode / Aspect Ratio Button
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white10,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            icon: const Icon(Icons.aspect_ratio, size: 16, color: AppTheme.primary),
            label: Text(
              l10n.screenRatioLabel(aspectRatioName),
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: onShowScreenFormat,
            onLongPress: onToggleAspectRatio,
          ),
          const SizedBox(width: 6),
          // Audio Track Button
          IconButton(
            icon: const Icon(Icons.audiotrack, color: Colors.white, size: 20),
            tooltip: l10n.audioTracksTooltip,
            onPressed: onShowAudioTracks,
          ),
          // Subtitles Button
          IconButton(
            icon: const Icon(Icons.subtitles, color: Colors.white, size: 20),
            tooltip: l10n.subtitlesTooltip,
            onPressed: onShowSubtitles,
          ),
          // Favorite Star Button
          if (contentId != null && type != null)
            Consumer<UserActivityProvider>(
              builder: (context, activity, _) {
                final isFav = activity.isFavorite(contentId!, type!);
                return IconButton(
                  icon: Icon(
                    isFav ? Icons.star : Icons.star_border,
                    color: isFav ? Colors.amber : Colors.white,
                    size: 22,
                  ),
                  tooltip: isFav ? l10n.removeFavoriteTooltip : l10n.addFavoriteTooltip,
                  onPressed: () {
                    activity.toggleFavorite(contentId!, type!);
                    onUserInteraction();
                  },
                );
              },
            ),
          // Live PVR Record Button
          if (isLive && contentId != null)
            Consumer<DownloadProvider>(
              builder: (context, downloads, _) {
                final isRec = downloads.isChannelRecording(contentId!);
                return IconButton(
                  icon: Icon(
                    isRec ? Icons.stop_circle : Icons.fiber_manual_record,
                    color: isRec ? AppTheme.accentRed : Colors.white,
                    size: 22,
                  ),
                  tooltip: isRec ? l10n.stopPvrTooltip : l10n.recordPvrTooltip,
                  onPressed: () {
                    downloads.toggleLiveRecording(
                      channelId: contentId!,
                      title: title,
                      streamUrl: streamUrl,
                      posterUrl: posterUrl,
                    );
                    onUserInteraction();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isRec
                              ? l10n.recordingStoppedToast(title)
                              : l10n.recordingStartedToast(title),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          // Multiview Button for Live Streams
          if (isLive)
            IconButton(
              icon: const Icon(Icons.dashboard_customize, color: Colors.white, size: 20),
              tooltip: 'Abrir en Multiview',
              onPressed: () {
                final currentChannel = Channel(
                  id: contentId ?? 'curr',
                  name: title,
                  url: streamUrl,
                  logoUrl: posterUrl,
                  categoryId: 'live',
                );
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MultiviewScreen(initialChannel: currentChannel),
                  ),
                );
              },
            ),
          // VOD Offline Download Button
          if (!isLive && contentId != null)
            Consumer<DownloadProvider>(
              builder: (context, downloads, _) {
                final isDownloaded = downloads.completedItems.any((i) => i.id == contentId);
                return IconButton(
                  icon: Icon(
                    isDownloaded ? Icons.download_done : Icons.download,
                    color: isDownloaded ? AppTheme.accentGreen : Colors.white,
                    size: 22,
                  ),
                  tooltip: isDownloaded
                      ? l10n.downloadedOpenFolderTooltip
                      : l10n.downloadOfflineTooltip,
                  onPressed: isDownloaded
                      ? () {
                          final item =
                              downloads.completedItems.where((i) => i.id == contentId).firstOrNull;
                          if (item != null) {
                            downloads.openItemInFileManager(item);
                          }
                        }
                      : () {
                          downloads.startVodDownload(
                            id: contentId!,
                            title: title,
                            streamUrl: streamUrl,
                            type: type ?? 'vod',
                            posterUrl: posterUrl,
                          );
                          onUserInteraction();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.downloadStartedToast)),
                          );
                        },
                );
              },
            ),
          // Cast / LAN Stream Reforward Button (Solo en plataformas nativas)
          if (!kIsWeb)
            Consumer<StreamServerProvider>(
            builder: (context, streamServer, _) {
              final isSharing = streamServer.isRunning;
              return IconButton(
                icon: Icon(
                  Icons.cell_tower,
                  color: isSharing ? AppTheme.primary : Colors.white,
                  size: 22,
                ),
                tooltip: isSharing
                    ? l10n.lanSharingActiveTooltip
                    : l10n.lanSharingInactiveTooltip,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => LanStreamDialog(
                      title: title,
                      streamUrl: streamUrl,
                    ),
                  );
                  onUserInteraction();
                },
              );
            },
          ),
          // Stream Stats HUD Button
          IconButton(
            icon: Icon(
              Icons.analytics_outlined,
              color: context.watch<PlaybackProvider>().showStats
                  ? AppTheme.primary
                  : Colors.white,
              size: 22,
            ),
            tooltip: 'Estadísticas del stream (I)',
            onPressed: () {
              context.read<PlaybackProvider>().toggleStats();
              onUserInteraction();
            },
          ),
          // Fullscreen Button
          IconButton(
            icon: Icon(
              isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
              size: 24,
            ),
            tooltip: isFullScreen ? l10n.exitFullscreenTooltip : l10n.enterFullscreenTooltip,
            onPressed: onToggleFullScreen,
          ),
          // Stop & Close Button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 24),
            tooltip: l10n.stopAndClosePlayerTooltip,
            onPressed: () {
              context.read<PlaybackProvider>().stop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
