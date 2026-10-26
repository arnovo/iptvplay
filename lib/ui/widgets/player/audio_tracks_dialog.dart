import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Modal bottom sheet dialog for selecting audio tracks with codec/format badges.
class AudioTracksDialog extends StatelessWidget {
  final Player player;

  const AudioTracksDialog({
    super.key,
    required this.player,
  });

  static Future<void> show(BuildContext context, Player player) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => AudioTracksDialog(player: player),
    );
  }

  static String formatLanguageCode(String? code, String fallback) {
    if (code == null || code.isEmpty) return fallback;
    switch (code.toLowerCase()) {
      case 'spa':
      case 'es':
      case 'esp':
        return '🇪🇸 Español';
      case 'eng':
      case 'en':
        return '🇬🇧 Inglés';
      case 'fra':
      case 'fr':
        return '🇫🇷 Francés';
      case 'deu':
      case 'de':
        return '🇩🇪 Alemán';
      case 'ita':
      case 'it':
        return '🇮🇹 Italiano';
      case 'por':
      case 'pt':
        return '🇵🇹 Portugués';
      case 'ara':
      case 'ar':
        return '🇸🇦 Árabe';
      case 'rus':
      case 'ru':
        return '🇷🇺 Ruso';
      case 'jpn':
      case 'ja':
        return '🇯🇵 Japonés';
      case 'chi':
      case 'zho':
      case 'zh':
        return '🇨🇳 Chino';
      case 'dut':
      case 'nld':
      case 'nl':
        return '🇳🇱 Holandés';
      case 'pol':
      case 'pl':
        return '🇵🇱 Polaco';
      case 'dan':
      case 'da':
        return '🇩🇰 Danés';
      case 'swe':
      case 'sv':
        return '🇸🇪 Sueco';
      case 'nor':
      case 'no':
        return '🇳🇴 Noruego';
      case 'fin':
      case 'fi':
        return '🇫🇮 Finlandés';
      default:
        return '🌐 ${code.toUpperCase()}';
    }
  }

  static String? detectAudioBadge(String rawTitle) {
    final lowerTitle = rawTitle.toLowerCase();
    if (lowerTitle.contains('atmos')) {
      return 'DOLBY ATMOS';
    } else if (lowerTitle.contains('5.1') || lowerTitle.contains('surround')) {
      return '5.1 SURROUND';
    } else if (lowerTitle.contains('7.1')) {
      return '7.1 SURROUND';
    } else if (lowerTitle.contains('ac3') ||
        lowerTitle.contains('eac3') ||
        lowerTitle.contains('dolby')) {
      return 'DOLBY DIGITAL';
    } else if (lowerTitle.contains('dts')) {
      return 'DTS';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tracks = player.state.tracks.audio;
    final current = player.state.track.audio;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.audiotrack, color: AppTheme.primary),
                const SizedBox(width: 10),
                Text(
                  l10n.audioTracks,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n.tracksAvailableCount(tracks.length),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (tracks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    l10n.noAudioTracksAvailable,
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: tracks.length,
                  separatorBuilder: (_, _) => const Divider(color: AppTheme.border, height: 1),
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    final isSelected = current == track;
                    final langName = formatLanguageCode(track.language, 'Pista ${track.id}');
                    final rawTitle = track.title ?? '';
                    final label = rawTitle.isNotEmpty ? '$rawTitle ($langName)' : langName;
                    final audioBadge = detectAudioBadge(rawTitle);

                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (audioBadge != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  audioBadge,
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primary) : null,
                        onTap: () {
                          player.setAudioTrack(track);
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
