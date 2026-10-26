import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Center visual feedback overlays: Buffering indicator, Quick flash action icon,
/// Continuous seek feedback banner, and Playback error message card.
class PlayerCenterIndicators extends StatelessWidget {
  final bool isBuffering;
  final String? errorMessage;
  final IconData? centerFlashIcon;
  final String? seekFeedbackText;
  final int accumulatedSeekSeconds;
  final VoidCallback onRetry;

  const PlayerCenterIndicators({
    super.key,
    required this.isBuffering,
    required this.errorMessage,
    required this.centerFlashIcon,
    required this.seekFeedbackText,
    required this.accumulatedSeekSeconds,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Stack(
      children: [
        // Buffering indicator
        if (isBuffering && errorMessage == null)
          const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),

        // Quick Center Flash Feedback Icon (Fades within 300-600ms)
        if (centerFlashIcon != null)
          Center(
            child: AnimatedOpacity(
              opacity: centerFlashIcon != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                ),
                child: Icon(centerFlashIcon, color: AppTheme.primary, size: 54),
              ),
            ),
          ),

        // Continuous Seek Feedback Indicator
        if (seekFeedbackText != null)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    accumulatedSeekSeconds > 0 ? Icons.fast_forward : Icons.fast_rewind,
                    color: AppTheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    seekFeedbackText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Error display
        if (errorMessage != null)
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accentRed.withValues(alpha: 0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.accentRed, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    l10n.playbackError,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
