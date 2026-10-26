import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../tv_focusable.dart';

/// Fila horizontal de recordatorios de programas de TV próximos
class HubRemindersRow extends StatelessWidget {
  final List<dynamic> reminders;

  const HubRemindersRow({
    super.key,
    required this.reminders,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: reminders.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final r = reminders[index];
          final minutesUntil = r.startTime.difference(DateTime.now()).inMinutes;

          return TvFocusable(
            onPressed: () {},
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 240,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentYellow.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accentYellow.withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.alarm, color: AppTheme.accentYellow, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          r.programTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${r.channelName} • ${timeFormat.format(r.startTime)}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                        Text(
                          minutesUntil > 0 ? 'Empieza en $minutesUntil min' : 'Comenzando ahora',
                          style: const TextStyle(
                            color: AppTheme.accentYellow,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
