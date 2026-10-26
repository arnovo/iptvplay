import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../../models/epg_reminder.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/download_provider.dart';
import '../../providers/epg_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/reminder_service.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/catalog_state_view.dart';
import '../widgets/home_navigation_rail.dart';
import '../widgets/miniplayer_bar.dart';
import 'downloads_screen.dart';
import 'home_hub_screen.dart';
import 'live_tv_screen.dart';
import 'player_screen.dart';
import 'series_screen.dart';
import 'settings_screen.dart';
import 'vod_screen.dart';

/// Contenedor raíz de navegación ("Shell") con menú lateral colapsable,
/// miniplayer persistente y gestión del ciclo de vida de perfiles.
class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _selectedIndex = 0;
  bool _isFullScreen = false;
  bool _isSidebarExpanded = true;
  StreamSubscription<EpgReminder>? _reminderSub;

  @override
  void initState() {
    super.initState();
    _checkFullScreen();
    _subscribeToReminders();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  @override
  void dispose() {
    _reminderSub?.cancel();
    super.dispose();
  }

  void _subscribeToReminders() {
    _reminderSub = ReminderService.instance.onReminderAlert.listen((reminder) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.accentYellow, width: 1.5),
          ),
          content: Row(
            children: [
              const Icon(Icons.notifications_active, color: AppTheme.accentYellow),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '¡Comienza tu programa!',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentYellow, fontSize: 13),
                    ),
                    Text(
                      '${reminder.programTitle} en ${reminder.channelName}',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'VER AHORA',
            textColor: AppTheme.primary,
            onPressed: () {
              final catalog = context.read<CatalogProvider>();
              final channel = catalog.content.channels.where((c) => c.id == reminder.channelId).firstOrNull;
              if (channel != null) {
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
              }
            },
          ),
          duration: const Duration(seconds: 10),
        ),
      );
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
      if (!kIsWeb) {
        context.read<EpgProvider>().loadEpg(profileProvider.activeProfile!);
      }
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
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
        content: Text(message, style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(l10n.cancel, style: const TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: Text(
              l10n.resume,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (shouldResume == true && mounted) {
      for (final item in paused) {
        downloadProvider.resumeDownload(item.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final catalogProvider = context.watch<CatalogProvider>();
    final downloadProvider = context.watch<DownloadProvider>();
    final activeProfile = profileProvider.activeProfile;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                HomeNavigationRail(
                  isExpanded: _isSidebarExpanded,
                  onToggleExpand: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded),
                  selectedIndex: _selectedIndex,
                  onSelectIndex: (idx) => setState(() => _selectedIndex = idx),
                  isFullScreen: _isFullScreen,
                  onToggleFullScreen: _toggleFullScreen,
                  activeProfile: activeProfile,
                  channelCount: catalogProvider.content.channels.length,
                  vodCount: catalogProvider.content.vods.length,
                  seriesCount: catalogProvider.content.series.length,
                  downloadCount: downloadProvider.items.length,
                ),
                const VerticalDivider(width: 1, color: AppTheme.border),
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

  Widget _buildBody(dynamic activeProfile, CatalogProvider catalogProvider) {
    // Si la pestaña es descargas o ajustes, no requerimos catálogo activo
    if (_selectedIndex == 4) {
      return const DownloadsScreen();
    }
    if (_selectedIndex == 5) {
      return const SettingsScreen();
    }

    // Estados especiales del catálogo (sin perfil, cargando o error)
    if (activeProfile == null || catalogProvider.isLoading || catalogProvider.errorMessage != null) {
      return CatalogStateView(
        activeProfile: activeProfile,
        catalogProvider: catalogProvider,
      );
    }

    switch (_selectedIndex) {
      case 0:
        return HomeHubScreen(
          onNavigateToLive: () => setState(() => _selectedIndex = 1),
          onNavigateToVod: () => setState(() => _selectedIndex = 2),
          onNavigateToSeries: () => setState(() => _selectedIndex = 3),
        );
      case 1:
        return const LiveTvScreen();
      case 2:
        return const VodScreen();
      case 3:
        return const SeriesScreen();
      case 4:
        return const DownloadsScreen();
      case 5:
        return const SettingsScreen();
      default:
        return HomeHubScreen(
          onNavigateToLive: () => setState(() => _selectedIndex = 1),
          onNavigateToVod: () => setState(() => _selectedIndex = 2),
          onNavigateToSeries: () => setState(() => _selectedIndex = 3),
        );
    }
  }
}
