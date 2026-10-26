import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/channel.dart';
import '../../../providers/epg_provider.dart';
import '../../screens/player_screen.dart';
import '../../theme/app_theme.dart';
import '../tv_focusable.dart';

/// Fila horizontal de canales favoritos con indicador de directo y programa EPG actual
class HubFavoriteChannelsRow extends StatelessWidget {
  final List<Channel> channels;

  const HubFavoriteChannelsRow({
    super.key,
    required this.channels,
  });

  @override
  Widget build(BuildContext context) {
    final epg = context.watch<EpgProvider>();

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: channels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final channel = channels[index];
          final currentProgram = epg.getCurrentProgram(
            channel.id,
            channelTvgId: channel.epgChannelId,
            channelName: channel.name,
          );

          return TvFocusable(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlayerScreen(
                    streamUrl: channel.url,
                    title: channel.name,
                    isLive: true,
                    contentId: channel.id,
                    type: 'live',
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      if (channel.logoUrl != null && channel.logoUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            channel.logoUrl!,
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(Icons.tv, size: 20),
                          ),
                        )
                      else
                        const Icon(Icons.tv, size: 20, color: AppTheme.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          channel.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentRed.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.accentRed, width: 0.8),
                        ),
                        child: const Text(
                          'VIVO',
                          style: TextStyle(
                            color: AppTheme.accentRed,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentProgram?.title ?? 'Emisión en directo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                  if (currentProgram != null) ...[
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: currentProgram.progressFraction,
                      minHeight: 3,
                      backgroundColor: AppTheme.surfaceLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
