import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../../providers/profile_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/epg_provider.dart';
import '../../providers/download_provider.dart';
import '../../providers/log_provider.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'live_tv_screen.dart';
import 'vod_screen.dart';
import 'series_screen.dart';
import 'downloads_screen.dart';
import 'logs_screen.dart';
import 'profile_list_screen.dart';
import 'add_profile_dialog.dart';
import '../widgets/backup_dialog.dart';
import '../widgets/miniplayer_bar.dart';
import '../widgets/tv_focusable.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _selectedIndex = 0;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _checkFullScreen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  Future<void> _checkFullScreen() async {
    if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      final isFull = await windowManager.isFullScreen();
      if (mounted) setState(() => _isFullScreen = isFull);
    }
  }

  Future<void> _toggleFullScreen() async {
    if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      final isFull = await windowManager.isFullScreen();
      await windowManager.setFullScreen(!isFull);
      if (mounted) setState(() => _isFullScreen = !isFull);
    }
  }

  Future<void> _initData() async {
    final profileProvider = context.read<ProfileProvider>();
    await profileProvider.loadProfiles();
    if (mounted && profileProvider.activeProfile != null) {
      context.read<CatalogProvider>().loadCatalog(profileProvider.activeProfile!);
      context.read<EpgProvider>().loadEpg(profileProvider.activeProfile!);
    }
    if (mounted) {
      _checkPausedDownloadsOnStartup();
    }
  }

  Future<void> _checkPausedDownloadsOnStartup() async {
    final downloadProvider = context.read<DownloadProvider>();
    if (!downloadProvider.isInitialized) {
      await downloadProvider.initialized;
    }
    if (!mounted) return;

    final paused = downloadProvider.pausedDownloads;
    if (paused.isEmpty) return;

    final l10n = context.l10n;
    final title = paused.length == 1
        ? l10n.resumePausedDownloadTitle
        : l10n.resumePausedDownloadsTitle;

    final message = paused.length == 1
        ? l10n.resumeSinglePausedMessage(paused.first.title)
        : l10n.resumeMultiplePausedMessage(paused.length);

    final shouldResume = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.pause_circle_outline, color: AppTheme.accentYellow, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.later, style: const TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: Text(paused.length == 1 ? l10n.resume : l10n.resumeAll),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (shouldResume == true && mounted) {
      await downloadProvider.resumeAllPaused();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.surface,
            content: Text(
              paused.length == 1
                  ? '${l10n.downloading} "${paused.first.title}"...'
                  : '${l10n.downloading} (${paused.length})...',
              style: const TextStyle(color: AppTheme.primary),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final catalogProvider = context.watch<CatalogProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final activeProfile = profileProvider.activeProfile;
    final l10n = context.l10n;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Navigation Rail / Sidebar
                Container(
                  width: 220,
                  color: AppTheme.surface,
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App Logo
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                                ),
                                child: const Icon(Icons.live_tv, color: AppTheme.primary, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.appTitle,
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                  ),
                                  Text(
                                    l10n.smartPlayer,
                                    style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Active Profile Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: TvFocusable(
                            borderRadius: BorderRadius.circular(10),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ProfileListScreen()),
                              );
                            },
                            builder: (context, isFocused, isHovered) {
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

                        const SizedBox(height: 16),
                        const Divider(color: AppTheme.border, height: 1),
                        const SizedBox(height: 12),

                        // Navigation Tabs
                        _buildNavItem(
                          icon: Icons.tv,
                          title: l10n.liveTv,
                          badge: '${catalogProvider.content.channels.length}',
                          index: 0,
                        ),
                        _buildNavItem(
                          icon: Icons.movie_outlined,
                          title: l10n.moviesVod,
                          badge: '${catalogProvider.content.vods.length}',
                          index: 1,
                        ),
                        _buildNavItem(
                          icon: Icons.video_library_outlined,
                          title: l10n.series,
                          badge: '${catalogProvider.content.series.length}',
                          index: 2,
                        ),
                        _buildNavItem(
                          icon: Icons.download_done,
                          title: l10n.downloadsPvr,
                          badge: '${context.watch<DownloadProvider>().items.length}',
                          index: 3,
                        ),
                        _buildNavItem(
                          icon: Icons.receipt_long,
                          title: l10n.logs,
                          badge: '${context.watch<LogProvider>().totalCount}',
                          index: 4,
                        ),

                        const Spacer(),

                        // Bottom actions
                        const Divider(color: AppTheme.border, height: 1),

                        // Language Switcher Tile
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          child: TvFocusable(
                            borderRadius: BorderRadius.circular(8),
                            onPressed: () => languageProvider.toggleLanguage(),
                            builder: (context, isFocused, isHovered) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: isFocused ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.language, color: AppTheme.textSecondary, size: 20),
                                  title: Text(
                                    l10n.language,
                                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceLight,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      '${languageProvider.currentFlag} ${languageProvider.currentLanguageName}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  onTap: () => languageProvider.toggleLanguage(),
                                ),
                              );
                            },
                          ),
                        ),

                        // Backup
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          child: TvFocusable(
                            borderRadius: BorderRadius.circular(8),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const BackupDialog(),
                              );
                            },
                            builder: (context, isFocused, isHovered) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: isFocused ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.cloud_sync, color: AppTheme.textSecondary, size: 20),
                                  title: Text(l10n.backup, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => const BackupDialog(),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),

                        if (activeProfile != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            child: TvFocusable(
                              borderRadius: BorderRadius.circular(8),
                              onPressed: catalogProvider.isLoading
                                  ? null
                                  : () {
                                      catalogProvider.loadCatalog(activeProfile);
                                      context.read<EpgProvider>().loadEpg(activeProfile, forceRefresh: true);
                                    },
                              builder: (context, isFocused, isHovered) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: isFocused ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.refresh, color: AppTheme.textSecondary, size: 20),
                                    title: Text(l10n.reloadList, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                    onTap: catalogProvider.isLoading
                                        ? null
                                        : () {
                                            catalogProvider.loadCatalog(activeProfile);
                                            context.read<EpgProvider>().loadEpg(activeProfile, forceRefresh: true);
                                          },
                                  ),
                                );
                              },
                            ),
                          ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          child: TvFocusable(
                            borderRadius: BorderRadius.circular(8),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const AddProfileDialog(),
                              );
                            },
                            builder: (context, isFocused, isHovered) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: isFocused ? AppTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.playlist_add, color: AppTheme.primary, size: 20),
                                  title: Text(
                                    l10n.addList,
                                    style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.bold),
                                  ),
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => const AddProfileDialog(),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          child: TvFocusable(
                            borderRadius: BorderRadius.circular(8),
                            onPressed: _toggleFullScreen,
                            builder: (context, isFocused, isHovered) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: isFocused ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(
                                    _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                    color: AppTheme.textSecondary,
                                    size: 20,
                                  ),
                                  title: Text(
                                    _isFullScreen ? l10n.exitFullscreen : l10n.fullscreen,
                                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                  ),
                                  onTap: _toggleFullScreen,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                const VerticalDivider(width: 1, color: AppTheme.border),

                // Main View Content
                Expanded(
                  child: _buildBody(activeProfile, catalogProvider),
                ),
              ],
            ),
          ),
          const MiniplayerBar(),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required String badge,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return TvFocusable(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      borderRadius: BorderRadius.circular(10),
      onPressed: () => setState(() => _selectedIndex = index),
      builder: (context, isFocused, isHovered) {
        final activeColor = isFocused || isSelected ? AppTheme.primary : AppTheme.textSecondary;
        return Container(
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.surfaceLight
                : (isFocused ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: isSelected && !isFocused
                ? Border.all(color: AppTheme.primary.withValues(alpha: 0.5))
                : null,
          ),
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
              trailing: Container(
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
              ),
              onTap: () => setState(() => _selectedIndex = index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(dynamic activeProfile, CatalogProvider catalogProvider) {
    final l10n = context.l10n;

    if (_selectedIndex == 3) {
      return const DownloadsScreen();
    }
    if (_selectedIndex == 4) {
      return const LogsScreen();
    }

    if (activeProfile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.playlist_play, size: 64, color: AppTheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.welcomeTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.welcomeSubtitle,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const AddProfileDialog(),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.addPlaylistButton),
            ),
          ],
        ),
      );
    }

    if (catalogProvider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.primary),
            const SizedBox(height: 20),
            Text(
              l10n.loadingCatalogTitle,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.loadingCatalogSubtitle,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (catalogProvider.errorMessage != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.accentRed.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.accentRed, size: 48),
              const SizedBox(height: 16),
              Text(l10n.catalogErrorTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                catalogProvider.errorMessage!,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => catalogProvider.loadCatalog(activeProfile),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    switch (_selectedIndex) {
      case 0:
        return const LiveTvScreen();
      case 1:
        return const VodScreen();
      case 2:
        return const SeriesScreen();
      case 3:
        return const DownloadsScreen();
      case 4:
        return const LogsScreen();
      default:
        return const LiveTvScreen();
    }
  }
}
