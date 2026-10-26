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

    final title = paused.length == 1
        ? 'Reanudar descarga pausada'
        : 'Reanudar descargas pausadas';

    final message = paused.length == 1
        ? 'Se ha detectado una descarga incompleta:\n"${paused.first.title}"\n\n¿Deseas reanudarla ahora desde donde se quedó?'
        : 'Se han detectado ${paused.length} descargas incompletas:\n${paused.take(3).map((e) => '• ${e.title}').join('\n')}${paused.length > 3 ? '\n• ...' : ''}\n\n¿Deseas reanudarlas ahora?';

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
            child: const Text('Más tarde', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: Text(paused.length == 1 ? 'Reanudar' : 'Reanudar todas'),
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
                  ? 'Reanudando descarga de "${paused.first.title}"...'
                  : 'Reanudando ${paused.length} descargas...',
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
    final activeProfile = profileProvider.activeProfile;

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
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'IPTV Play',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          Text(
                            'Smart Player',
                            style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Active Profile Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileListScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
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
                                  activeProfile?.name ?? 'Sin lista activa',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  activeProfile != null ? 'Cambiar lista' : 'Toca para añadir',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.unfold_more, size: 16, color: AppTheme.textMuted),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(color: AppTheme.border, height: 1),
                const SizedBox(height: 12),

                // Navigation Tabs
                _buildNavItem(
                  icon: Icons.tv,
                  title: 'TV en Vivo',
                  badge: '${catalogProvider.content.channels.length}',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.movie_outlined,
                  title: 'Películas (VOD)',
                  badge: '${catalogProvider.content.vods.length}',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.video_library_outlined,
                  title: 'Series',
                  badge: '${catalogProvider.content.series.length}',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.download_done,
                  title: 'Descargas & PVR',
                  badge: '${context.watch<DownloadProvider>().items.length}',
                  index: 3,
                ),
                _buildNavItem(
                  icon: Icons.receipt_long,
                  title: 'Registros',
                  badge: '${context.watch<LogProvider>().totalCount}',
                  index: 4,
                ),

                const Spacer(),

                // Bottom actions
                const Divider(color: AppTheme.border, height: 1),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.cloud_sync, color: AppTheme.textSecondary, size: 20),
                  title: const Text('Copia de seguridad', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const BackupDialog(),
                    );
                  },
                ),
                if (activeProfile != null)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.refresh, color: AppTheme.textSecondary, size: 20),
                    title: const Text('Recargar lista', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    onTap: catalogProvider.isLoading
                        ? null
                        : () {
                            catalogProvider.loadCatalog(activeProfile);
                            context.read<EpgProvider>().loadEpg(activeProfile, forceRefresh: true);
                          },
                  ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.playlist_add, color: AppTheme.primary, size: 20),
                  title: const Text('Añadir lista', style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const AddProfileDialog(),
                    );
                  },
                ),
                ListTile(
                  dense: true,
                  leading: Icon(
                    _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  title: Text(
                    _isFullScreen ? 'Salir de pantalla completa' : 'Pantalla completa',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  onTap: _toggleFullScreen,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.surfaceLight : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected ? Border.all(color: AppTheme.primary.withValues(alpha: 0.5)) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          dense: true,
          leading: Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.textSecondary, size: 20),
          title: Text(
            title,
            style: TextStyle(
              color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          onTap: () => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }

  Widget _buildBody(dynamic activeProfile, CatalogProvider catalogProvider) {
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
            const Text(
              '¡Bienvenido a IPTV Play!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Para empezar a ver TV en vivo, películas y series, añade tu primera lista.',
              style: TextStyle(color: AppTheme.textSecondary),
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
              label: const Text('Añadir Lista o Cuenta Xtream'),
            ),
          ],
        ),
      );
    }

    if (catalogProvider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 20),
            Text(
              'Cargando canales y catálogo...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
            SizedBox(height: 6),
            Text(
              'Procesando lista M3U / Servidor Xtream...',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
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
              const Text('Error al cargar la lista', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                label: const Text('Reintentar'),
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
