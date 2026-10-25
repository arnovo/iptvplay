import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/channel.dart';
import '../../models/epg_program.dart';
import '../../providers/epg_provider.dart';
import '../../providers/profile_provider.dart';
import '../theme/app_theme.dart';

class ChannelEpgDialog extends StatefulWidget {
  final Channel channel;

  const ChannelEpgDialog({
    super.key,
    required this.channel,
  });

  @override
  State<ChannelEpgDialog> createState() => _ChannelEpgDialogState();
}

class _ChannelEpgDialogState extends State<ChannelEpgDialog> {
  bool _isLoading = false;
  List<EpgProgram> _schedule = [];

  @override
  void initState() {
    super.initState();
    _loadChannelSchedule();
  }

  Future<void> _loadChannelSchedule() async {
    final epg = context.read<EpgProvider>();
    final activeProfile = context.read<ProfileProvider>().activeProfile;

    // Check existing
    var list = epg.getChannelSchedule(
      widget.channel.id,
      channelTvgId: widget.channel.epgChannelId,
      channelName: widget.channel.name,
    );

    if (list.isEmpty && activeProfile != null) {
      setState(() => _isLoading = true);
      list = await epg.fetchChannelEpgOnDemand(
        profile: activeProfile,
        streamId: widget.channel.id,
      );
    }

    if (mounted) {
      setState(() {
        _schedule = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  child: const Icon(Icons.calendar_today, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Guía de Programación (EPG)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  : _schedule.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              const Text(
                                'No hay datos de EPG para este canal',
                                style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Asegúrate de que la lista contenga un tvg-id o archivo XMLTV válido',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _schedule.length,
                          separatorBuilder: (_, _) => const Divider(color: AppTheme.border, height: 1),
                          itemBuilder: (context, index) {
                            final prog = _schedule[index];
                            final isNow = prog.isCurrent;

                            return Container(
                              color: isNow ? AppTheme.primary.withValues(alpha: 0.08) : Colors.transparent,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                leading: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      prog.formattedTimeRange,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isNow ? FontWeight.bold : FontWeight.w500,
                                        color: isNow ? AppTheme.primary : AppTheme.textSecondary,
                                      ),
                                    ),
                                    if (isNow) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'AHORA',
                                          style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                title: Text(
                                  prog.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isNow ? FontWeight.bold : FontWeight.w500,
                                    color: isNow ? AppTheme.textPrimary : AppTheme.textSecondary,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (prog.description != null && prog.description!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          prog.description!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                        ),
                                      ),
                                    if (isNow) ...[
                                      const SizedBox(height: 6),
                                      LinearProgressIndicator(
                                        value: prog.progressFraction,
                                        backgroundColor: AppTheme.surfaceLight,
                                        color: AppTheme.primary,
                                        minHeight: 3,
                                      ),
                                    ],
                                  ],
                                ),
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
