import 'package:flutter/material.dart';
import '../../models/catchup_item.dart';
import '../../models/channel.dart';
import '../../models/playlist_profile.dart';
import '../../services/catchup_service.dart';
import '../../l10n/app_localizations.dart';
import '../screens/player_screen.dart';
import '../theme/app_theme.dart';

class CatchupDialog extends StatefulWidget {
  final Channel channel;
  final PlaylistProfile profile;

  const CatchupDialog({
    super.key,
    required this.channel,
    required this.profile,
  });

  @override
  State<CatchupDialog> createState() => _CatchupDialogState();
}

class _CatchupDialogState extends State<CatchupDialog> {
  final CatchupService _catchupService = CatchupService();
  bool _isLoading = true;
  List<CatchupItem> _programs = [];

  @override
  void initState() {
    super.initState();
    _loadCatchup();
  }

  Future<void> _loadCatchup() async {
    final list = await _catchupService.getXtreamCatchupPrograms(
      profile: widget.profile,
      streamId: widget.channel.id,
    );
    if (mounted) {
      setState(() {
        _programs = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Container(
        width: 550,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.catchup7DaysTitle,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.channel.name,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.border, height: 1),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : _programs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.tv_off, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text(
                                l10n.noRecordedBroadcasts,
                                style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.noCatchupProviderSupport,
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _programs.length,
                          separatorBuilder: (_, _) => const Divider(color: AppTheme.border, height: 1),
                          itemBuilder: (context, index) {
                            final prog = _programs[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              leading: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceLight,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Text(
                                  prog.formattedDate,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                ),
                              ),
                              title: Text(
                                prog.title,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${prog.formattedTimeRange} (${prog.durationMinutes} min)',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                  ),
                                  if (prog.description != null && prog.description!.isNotEmpty)
                                    Text(
                                      prog.description!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                    ),
                                ],
                              ),
                              trailing: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                icon: const Icon(Icons.play_arrow, size: 16),
                                label: Text(l10n.watch, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PlayerScreen(
                                        streamUrl: prog.streamUrl,
                                        title: '${widget.channel.name} - ${prog.title}',
                                        isLive: false,
                                        type: 'catchup',
                                      ),
                                    ),
                                  );
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
