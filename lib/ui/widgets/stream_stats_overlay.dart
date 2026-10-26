import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/buffer_profile.dart';
import '../../providers/playback_provider.dart';
import '../theme/app_theme.dart';
import 'tv_focusable.dart';

/// Floating technical stats overlay (OSD / Stats for Nerds) for diagnosis.
class StreamStatsOverlay extends StatelessWidget {
  const StreamStatsOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final playback = context.watch<PlaybackProvider>();
    if (!playback.showStats) return const SizedBox.shrink();

    final stats = playback.statistics;
    final currentProfile = playback.bufferProfile;

    return Positioned(
      top: 70,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGlow.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.analytics_outlined, color: AppTheme.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'ESTADÍSTICAS DEL STREAM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => playback.toggleStats(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppTheme.border, height: 1),
              const SizedBox(height: 12),

              // Metrics table
              _buildStatRow('Resolución', stats.resolutionFormatted, extraBadge: stats.qualityLabel),
              _buildStatRow('Tasa de refresco', stats.fpsFormatted),
              _buildStatRow('Códec de vídeo', stats.videoCodec),
              _buildStatRow('Códec de audio', stats.audioCodec),
              _buildStatRow('Búfer activo', stats.bufferFormatted),
              _buildStatRow(
                'Cuadros perdidos (Drops)',
                '${stats.droppedFrames}',
                isWarning: stats.droppedFrames > 15,
              ),

              const SizedBox(height: 10),
              const Divider(color: AppTheme.border, height: 1),
              const SizedBox(height: 10),

              // Buffer profile quick switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Modo de Búfer:',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      currentProfile.name.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Profile buttons (TV focusable)
              Row(
                children: BufferProfile.values.map((profile) {
                  final isSelected = profile == currentProfile;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: TvFocusable(
                        borderRadius: BorderRadius.circular(6),
                        onPressed: () => playback.setBufferProfile(profile),
                        builder: (context, isFocused, isHovered) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary
                                  : (isFocused ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.surfaceLight),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected || isFocused ? AppTheme.primary : AppTheme.border,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _profileShortName(profile),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.black : Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _profileShortName(BufferProfile profile) {
    switch (profile) {
      case BufferProfile.fastZapping:
        return 'Zapping';
      case BufferProfile.balanced:
        return 'Estándar';
      case BufferProfile.highResilience:
        return 'Alta Res.';
    }
  }

  Widget _buildStatRow(String title, String value, {String? extraBadge, bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isWarning ? AppTheme.accentRed : Colors.white,
                ),
              ),
              if (extraBadge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    extraBadge,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
