import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Modal bottom sheet dialog for choosing screen aspect ratio and fullscreen mode.
class ScreenFormatDialog extends StatelessWidget {
  final BoxFit currentFit;
  final bool isFullScreen;
  final ValueChanged<BoxFit> onFitChanged;
  final VoidCallback onToggleFullScreen;

  const ScreenFormatDialog({
    super.key,
    required this.currentFit,
    required this.isFullScreen,
    required this.onFitChanged,
    required this.onToggleFullScreen,
  });

  static String getAspectRatioName(BoxFit fit, AppLocalizations l10n) {
    if (fit == BoxFit.cover) return l10n.aspectNameCover;
    if (fit == BoxFit.fill) return l10n.aspectNameFill;
    return l10n.aspectNameContain;
  }

  static Future<void> show({
    required BuildContext context,
    required BoxFit currentFit,
    required bool isFullScreen,
    required ValueChanged<BoxFit> onFitChanged,
    required VoidCallback onToggleFullScreen,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => ScreenFormatDialog(
        currentFit: currentFit,
        isFullScreen: isFullScreen,
        onFitChanged: onFitChanged,
        onToggleFullScreen: onToggleFullScreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.aspect_ratio, color: AppTheme.primary),
                const SizedBox(width: 10),
                Text(
                  l10n.screenFormatTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              dense: true,
              leading: const Icon(Icons.fullscreen, color: AppTheme.primary),
              title: Text(l10n.aspectCoverTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(l10n.aspectCoverSubtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              trailing: currentFit == BoxFit.cover ? const Icon(Icons.check, color: AppTheme.primary) : null,
              onTap: () {
                onFitChanged(BoxFit.cover);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.fit_screen, color: AppTheme.primary),
              title: Text(l10n.aspectContainTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(l10n.aspectContainSubtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              trailing: currentFit == BoxFit.contain ? const Icon(Icons.check, color: AppTheme.primary) : null,
              onTap: () {
                onFitChanged(BoxFit.contain);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.aspect_ratio, color: AppTheme.primary),
              title: Text(l10n.aspectFillTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(l10n.aspectFillSubtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              trailing: currentFit == BoxFit.fill ? const Icon(Icons.check, color: AppTheme.primary) : null,
              onTap: () {
                onFitChanged(BoxFit.fill);
                Navigator.of(context).pop();
              },
            ),
            const Divider(color: AppTheme.border),
            ListTile(
              dense: true,
              leading: Icon(isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen, color: AppTheme.accentGreen),
              title: Text(
                isFullScreen ? l10n.windowFullscreenExit : l10n.windowFullscreenEnter,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentGreen),
              ),
              subtitle: Text(l10n.windowFullscreenSubtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              onTap: () {
                Navigator.of(context).pop();
                onToggleFullScreen();
              },
            ),
          ],
        ),
      ),
    );
  }
}
