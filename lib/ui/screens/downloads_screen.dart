import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/download_item.dart';
import '../../providers/download_provider.dart';
import '../screens/player_screen.dart';
import '../theme/app_theme.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final downloadProvider = context.watch<DownloadProvider>();
    final items = downloadProvider.items;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.download_done, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Descargas y Grabaciones Offline',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${items.length} archivos disponibles para ver sin conexión a internet',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (downloadProvider.activeRecordings.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentRed.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.accentRed.withValues(alpha: 0.5)),
                    ),
                    child: Row(
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
                          '${downloadProvider.activeRecordings.length} Grabando...',
                          style: const TextStyle(color: AppTheme.accentRed, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // List of Downloads
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_download_outlined, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          'No tienes descargas ni grabaciones',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Graba canales en vivo o descarga películas para verlas sin conexión',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isRecording = item.status == DownloadStatus.recording;
                      final isDownloading = item.status == DownloadStatus.downloading;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isRecording ? AppTheme.accentRed.withValues(alpha: 0.5) : AppTheme.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Poster or Icon
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: item.posterUrl != null && item.posterUrl!.isNotEmpty
                                  ? Image.network(
                                      item.posterUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Icon(
                                        item.type == 'live_recording' ? Icons.fiber_manual_record : Icons.movie,
                                        color: item.type == 'live_recording' ? AppTheme.accentRed : AppTheme.primary,
                                      ),
                                    )
                                  : Icon(
                                      item.type == 'live_recording' ? Icons.fiber_manual_record : Icons.movie,
                                      color: item.type == 'live_recording' ? AppTheme.accentRed : AppTheme.primary,
                                      size: 28,
                                    ),
                            ),
                            const SizedBox(width: 16),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (isRecording) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accentRed,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('REC', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isRecording
                                        ? 'Grabando en directo (${item.formattedSize})'
                                        : isDownloading
                                            ? 'Descargando... ${(item.progressFraction * 100).toStringAsFixed(0)}% (${item.formattedSize})'
                                            : item.status == DownloadStatus.paused
                                                ? 'Descarga pausada • ${item.formattedSize} guardados'
                                                : item.status == DownloadStatus.failed
                                                    ? 'Descarga interrumpida • ${item.formattedSize}'
                                                    : '${item.formattedSize} • Guardado localmente',
                                    style: TextStyle(
                                      color: isRecording
                                          ? AppTheme.accentRed
                                          : item.status == DownloadStatus.paused
                                              ? AppTheme.accentYellow
                                              : item.status == DownloadStatus.failed
                                                  ? AppTheme.accentRed
                                                  : AppTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (isDownloading || item.status == DownloadStatus.paused) ...[
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: item.progressFraction > 0 ? item.progressFraction : null,
                                      backgroundColor: AppTheme.surfaceLight,
                                      color: item.status == DownloadStatus.paused ? AppTheme.accentYellow : AppTheme.primary,
                                      minHeight: 3,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Actions
                            if (isRecording)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentRed,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.stop, size: 18),
                                label: const Text('Detener'),
                                onPressed: () {
                                  downloadProvider.toggleLiveRecording(
                                    channelId: item.id,
                                    title: item.title,
                                    streamUrl: item.originalUrl,
                                  );
                                },
                              )
                            else if (isDownloading)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accentYellow.withValues(alpha: 0.2),
                                      foregroundColor: AppTheme.accentYellow,
                                    ),
                                    icon: const Icon(Icons.pause, size: 18),
                                    label: const Text('Pausar'),
                                    onPressed: () {
                                      downloadProvider.pauseDownload(item.id);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppTheme.textMuted, size: 20),
                                    tooltip: 'Cancelar descarga',
                                    onPressed: () {
                                      downloadProvider.deleteDownload(item.id);
                                    },
                                  ),
                                ],
                              )
                            else if (item.status == DownloadStatus.paused || item.status == DownloadStatus.failed)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.black,
                                    ),
                                    icon: const Icon(Icons.play_arrow, size: 18),
                                    label: const Text('Reanudar'),
                                    onPressed: () {
                                      downloadProvider.resumeDownload(item.id);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppTheme.textMuted, size: 20),
                                    tooltip: 'Eliminar descarga',
                                    onPressed: () {
                                      downloadProvider.deleteDownload(item.id);
                                    },
                                  ),
                                ],
                              )
                            else if (item.status == DownloadStatus.completed)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.black,
                                    ),
                                    icon: const Icon(Icons.play_arrow, size: 18),
                                    label: const Text('Reproducir'),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PlayerScreen(
                                            streamUrl: item.localFilePath,
                                            title: item.title,
                                            isLive: false,
                                            type: item.type,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppTheme.textMuted, size: 20),
                                    tooltip: 'Eliminar descarga',
                                    onPressed: () {
                                      downloadProvider.deleteDownload(item.id);
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
