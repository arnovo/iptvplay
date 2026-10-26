import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/channel.dart';
import '../../models/epg_program.dart';
import '../../models/epg_reminder.dart';
import '../../providers/profile_provider.dart';
import '../../services/reminder_service.dart';
import '../screens/player_screen.dart';
import '../theme/app_theme.dart';
import 'catchup_dialog.dart';
import 'tv_focusable.dart';

/// Modal con opciones detalladas del programa EPG (Directo, Recordatorio o Catchup)
class EpgProgramDetailsModal extends StatefulWidget {
  final Channel channel;
  final EpgProgram program;
  final VoidCallback? onReminderChanged;

  const EpgProgramDetailsModal({
    super.key,
    required this.channel,
    required this.program,
    this.onReminderChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required Channel channel,
    required EpgProgram program,
    VoidCallback? onReminderChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppTheme.border, width: 1.5),
      ),
      builder: (_) => EpgProgramDetailsModal(
        channel: channel,
        program: program,
        onReminderChanged: onReminderChanged,
      ),
    );
  }

  @override
  State<EpgProgramDetailsModal> createState() => _EpgProgramDetailsModalState();
}

class _EpgProgramDetailsModalState extends State<EpgProgramDetailsModal> {
  final ReminderService _reminderService = ReminderService.instance;

  @override
  Widget build(BuildContext context) {
    final hasReminder = _reminderService.isReminderSet(
      widget.channel.id,
      widget.program.start,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.channel.logoUrl != null && widget.channel.logoUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.channel.logoUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(Icons.tv, size: 24),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.program.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.channel.name} • ${widget.program.formattedTimeRange} (${widget.program.durationText})',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.program.description != null && widget.program.description!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              widget.program.description!,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              // Acción 1: Si es en directo -> Ver Canal
              if (widget.program.isCurrent)
                Expanded(
                  child: TvFocusable(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlayerScreen(
                            streamUrl: widget.channel.url,
                            title: widget.channel.name,
                            isLive: true,
                            contentId: widget.channel.id,
                            type: 'live',
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, color: AppTheme.background),
                          SizedBox(width: 6),
                          Text(
                            'Ver Canal en Directo',
                            style: TextStyle(
                              color: AppTheme.background,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              // Acción 2: Si es futuro -> Recordatorio
              else if (widget.program.isFuture)
                Expanded(
                  child: TvFocusable(
                    onPressed: () async {
                      if (hasReminder) {
                        final r = _reminderService.reminders.firstWhere(
                          (rem) =>
                              rem.channelId == widget.channel.id &&
                              rem.startTime.millisecondsSinceEpoch == widget.program.start.millisecondsSinceEpoch,
                        );
                        await _reminderService.removeReminder(r.id);
                      } else {
                        final reminder = EpgReminder(
                          id: '${widget.channel.id}_${widget.program.start.millisecondsSinceEpoch}',
                          channelId: widget.channel.id,
                          channelName: widget.channel.name,
                          channelLogo: widget.channel.logoUrl,
                          programTitle: widget.program.title,
                          programDescription: widget.program.description,
                          startTime: widget.program.start,
                          endTime: widget.program.end,
                        );
                        await _reminderService.addReminder(reminder);
                      }
                      if (mounted) setState(() {});
                      widget.onReminderChanged?.call();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: hasReminder ? AppTheme.accentYellow : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: hasReminder ? AppTheme.accentYellow : AppTheme.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            hasReminder ? Icons.notifications_active : Icons.notification_add_outlined,
                            color: hasReminder ? AppTheme.background : AppTheme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hasReminder ? 'Recordatorio Activado' : 'Avisarme al Comenzar',
                            style: TextStyle(
                              color: hasReminder ? AppTheme.background : AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              // Acción 3: Si es pasado -> Catchup si hay perfil activo
              else if (context.read<ProfileProvider>().activeProfile != null)
                Expanded(
                  child: TvFocusable(
                    onPressed: () {
                      final profile = context.read<ProfileProvider>().activeProfile;
                      if (profile == null) return;
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (_) => CatchupDialog(
                          channel: widget.channel,
                          profile: profile,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, color: AppTheme.primary, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Ver Grabación (Catchup)',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
