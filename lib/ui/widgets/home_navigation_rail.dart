import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/playlist_profile.dart';
import '../../services/parental_service.dart';
import '../screens/profile_list_screen.dart';
import '../theme/app_theme.dart';
import 'pin_code_dialog.dart';
import 'tv_focusable.dart';

/// Barra lateral colapsable de navegación principal para la pantalla Shell
class HomeNavigationRail extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final int selectedIndex;
  final ValueChanged<int> onSelectIndex;
  final bool isFullScreen;
  final VoidCallback onToggleFullScreen;
  final PlaylistProfile? activeProfile;
  final int channelCount;
  final int vodCount;
  final int seriesCount;
  final int downloadCount;

  const HomeNavigationRail({
    super.key,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.selectedIndex,
    required this.onSelectIndex,
    required this.isFullScreen,
    required this.onToggleFullScreen,
    required this.activeProfile,
    required this.channelCount,
    required this.vodCount,
    required this.seriesCount,
    required this.downloadCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: isExpanded ? 220 : 68,
      color: AppTheme.surface,
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header con Logo y botón de colapso
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isExpanded ? 14 : 10,
                vertical: 14,
              ),
              child: isExpanded
                  ? Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                          ),
                          child: const Icon(Icons.live_tv, color: AppTheme.primary, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.appTitle,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                l10n.smartPlayer,
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TvFocusable(
                          borderRadius: BorderRadius.circular(6),
                          onPressed: onToggleExpand,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.menu_open_rounded,
                              size: 18,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: TvFocusable(
                        borderRadius: BorderRadius.circular(8),
                        onPressed: onToggleExpand,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: const Icon(
                            Icons.menu_rounded,
                            size: 20,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
            ),

            // Tarjeta de Perfil Activo
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isExpanded ? 14 : 10,
                vertical: 4,
              ),
              child: TvFocusable(
                borderRadius: BorderRadius.circular(10),
                onPressed: () async {
                  final parental = context.read<ParentalService>();
                  if (parental.isSettingsRestricted()) {
                    final ok = await PinCodeDialog.show(context, title: 'Ajustes Protegidos');
                    if (!ok) return;
                  }
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileListScreen()),
                  );
                },
                builder: (context, isFocused, isHovered) {
                  if (!isExpanded) {
                    return Tooltip(
                      message: activeProfile?.name ?? l10n.noActiveProfile,
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: isFocused
                              ? AppTheme.primary.withValues(alpha: 0.15)
                              : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isFocused ? AppTheme.primary : AppTheme.border,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.account_circle, color: AppTheme.primary, size: 22),
                        ),
                      ),
                    );
                  }
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isFocused
                          ? AppTheme.primary.withValues(alpha: 0.15)
                          : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isFocused ? AppTheme.primary : AppTheme.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_circle, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeProfile?.name ?? l10n.noActiveProfile,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                activeProfile != null ? l10n.switchProfile : l10n.tapToAdd,
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.unfold_more, size: 16, color: AppTheme.textMuted),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
            const Divider(color: AppTheme.border, height: 1),
            const SizedBox(height: 10),

            // Elementos de navegación principales
            _buildNavItem(
              context: context,
              icon: Icons.home_rounded,
              title: l10n.isEnglish ? 'Home' : 'Inicio',
              badge: '',
              index: 0,
            ),
            _buildNavItem(
              context: context,
              icon: Icons.tv,
              title: l10n.liveTv,
              badge: '$channelCount',
              index: 1,
            ),
            _buildNavItem(
              context: context,
              icon: Icons.movie_outlined,
              title: l10n.moviesVod,
              badge: '$vodCount',
              index: 2,
            ),
            _buildNavItem(
              context: context,
              icon: Icons.video_library_outlined,
              title: l10n.series,
              badge: '$seriesCount',
              index: 3,
            ),
            _buildNavItem(
              context: context,
              icon: Icons.download_done,
              title: l10n.downloadsPvr,
              badge: '$downloadCount',
              index: 4,
            ),

            const Spacer(),
            const Divider(color: AppTheme.border, height: 1),
            const SizedBox(height: 6),

            // Ajustes y Pantalla completa
            _buildNavItem(
              context: context,
              icon: Icons.settings_rounded,
              title: l10n.settings,
              badge: '',
              index: 5,
            ),
            _buildFullscreenItem(context, l10n),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String badge,
    required int index,
  }) {
    final isSelected = selectedIndex == index;

    return TvFocusable(
      margin: EdgeInsets.symmetric(
        horizontal: isExpanded ? 10 : 8,
        vertical: 2,
      ),
      borderRadius: BorderRadius.circular(10),
      onPressed: () => onSelectIndex(index),
      builder: (context, isFocused, isHovered) {
        final activeColor = isFocused || isSelected ? AppTheme.primary : AppTheme.textSecondary;
        final decoration = BoxDecoration(
          color: isSelected
              ? AppTheme.surfaceLight
              : (isFocused ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
          border: isSelected && !isFocused
              ? Border.all(color: AppTheme.primary.withValues(alpha: 0.5))
              : null,
        );

        if (!isExpanded) {
          return Tooltip(
            message: title,
            child: Container(
              height: 44,
              decoration: decoration,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, color: activeColor, size: 22),
                  if (badge.isNotEmpty && badge != '0')
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: decoration,
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              dense: true,
              leading: Icon(icon, color: activeColor, size: 20),
              title: Text(
                title,
                style: TextStyle(
                  color: isFocused || isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontWeight: isFocused || isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
              trailing: badge.isNotEmpty && badge != '0'
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 11,
                          color: isFocused || isSelected ? AppTheme.primary : AppTheme.textMuted,
                          fontWeight: isFocused || isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    )
                  : null,
              onTap: () => onSelectIndex(index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullscreenItem(BuildContext context, AppLocalizations l10n) {
    if (!isExpanded) {
      return TvFocusable(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        borderRadius: BorderRadius.circular(10),
        onPressed: onToggleFullScreen,
        builder: (context, isFocused, isHovered) {
          return Tooltip(
            message: isFullScreen ? l10n.exitFullscreen : l10n.fullscreen,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isFocused ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
              ),
            ),
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: TvFocusable(
        borderRadius: BorderRadius.circular(8),
        onPressed: onToggleFullScreen,
        builder: (context, isFocused, isHovered) {
          return Container(
            decoration: BoxDecoration(
              color: isFocused ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              dense: true,
              leading: Icon(
                isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                color: AppTheme.textSecondary,
                size: 20,
              ),
              title: Text(
                isFullScreen ? l10n.exitFullscreen : l10n.fullscreen,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              onTap: onToggleFullScreen,
            ),
          );
        },
      ),
    );
  }
}
