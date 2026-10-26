import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../../services/subtitle_service.dart';
import '../theme/app_theme.dart';
import 'tv_focusable.dart';

class SubtitlesDialog extends StatefulWidget {
  final Player player;
  final String contentTitle;

  const SubtitlesDialog({
    super.key,
    required this.player,
    required this.contentTitle,
  });

  @override
  State<SubtitlesDialog> createState() => _SubtitlesDialogState();
}

class _SubtitlesDialogState extends State<SubtitlesDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final SubtitleService _subtitleService = SubtitleService();

  // Search state
  late final TextEditingController _searchController;
  String _selectedLangCode = 'es';
  bool _isSearching = false;
  bool _isDownloading = false;
  List<RemoteSubtitleItem> _remoteResults = [];
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController = TextEditingController(text: _cleanTitle(widget.contentTitle));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _cleanTitle(String raw) {
    return raw
        .replaceAll(RegExp(r'\(\d{4}\)'), '')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .trim();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _statusMessage = null;
    });

    final results = await _subtitleService.searchSubtitles(
      query: query,
      languageCode: _selectedLangCode,
    );

    if (mounted) {
      setState(() {
        _isSearching = false;
        _remoteResults = results;
        if (results.isEmpty) {
          _statusMessage = 'No se encontraron subtítulos en línea para "$query"';
        }
      });
    }
  }

  Future<void> _downloadAndApply(RemoteSubtitleItem item) async {
    setState(() => _isDownloading = true);

    final path = await _subtitleService.downloadSubtitle(
      downloadUrl: item.downloadUrl,
      filename: '${item.releaseName}_${item.languageCode}.srt',
    );

    if (mounted) {
      setState(() => _isDownloading = false);
      if (path != null) {
        await widget.player.setSubtitleTrack(
          SubtitleTrack.uri(path, title: item.releaseName, language: item.languageCode),
        );
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.surface,
              content: Text(
                'Subtítulo cargado: ${item.releaseName}',
                style: const TextStyle(color: AppTheme.primary),
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.surface,
            content: Text(
              'No se pudo descargar el archivo de subtítulo',
              style: TextStyle(color: AppTheme.accentRed),
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickLocalFile() async {
    final path = await _subtitleService.pickLocalSubtitleFile();
    if (path != null && mounted) {
      final filename = path.split(RegExp(r'[\\/]')).last;
      await widget.player.setSubtitleTrack(
        SubtitleTrack.uri(path, title: filename, language: 'local'),
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.surface,
            content: Text(
              'Subtítulo local activado: $filename',
              style: const TextStyle(color: AppTheme.primary),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final embeddedTracks = widget.player.state.tracks.subtitle;
    final currentTrack = widget.player.state.track.subtitle;

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.subtitles, color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SUBTÍTULOS Y DESCARGA ONLINE',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Pistas incrustadas, búsqueda en OpenSubtitles o archivo local',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
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
              const SizedBox(height: 12),

              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primary,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.video_settings, size: 18),
                    text: 'Pistas del Vídeo (${embeddedTracks.length})',
                  ),
                  const Tab(
                    icon: Icon(Icons.cloud_download_outlined, size: 18),
                    text: 'Descargar Online',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tab contents
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Embedded Subtitle Tracks
                    _buildEmbeddedTracksTab(embeddedTracks, currentTrack),

                    // Tab 2: Online Subtitles Search
                    _buildOnlineSearchTab(),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              const Divider(color: AppTheme.border, height: 1),
              const SizedBox(height: 12),

              // Action Bar (Pick local subtitle file)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      widget.player.setSubtitleTrack(SubtitleTrack.no());
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.subtitles_off, size: 18, color: AppTheme.accentRed),
                    label: const Text(
                      'Desactivar subtítulos',
                      style: TextStyle(color: AppTheme.accentRed, fontSize: 12),
                    ),
                  ),
                  TvFocusable(
                    borderRadius: BorderRadius.circular(8),
                    onPressed: _pickLocalFile,
                    builder: (context, isFocused, isHovered) {
                      return ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFocused
                              ? AppTheme.primary
                              : AppTheme.surfaceLight,
                          foregroundColor: isFocused ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: AppTheme.border),
                          ),
                        ),
                        onPressed: _pickLocalFile,
                        icon: const Icon(Icons.folder_open, size: 18),
                        label: const Text('Cargar archivo (.srt/.vtt)'),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmbeddedTracksTab(List<SubtitleTrack> tracks, SubtitleTrack current) {
    if (tracks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.subtitles_off, size: 40, color: AppTheme.textMuted),
            SizedBox(height: 12),
            Text(
              'No hay pistas de subtítulos incrustadas en este stream',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            SizedBox(height: 4),
            Text(
              'Usa la pestaña "Descargar Online" para buscar subtítulos automáticamente',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: tracks.length,
      separatorBuilder: (_, _) => const Divider(color: AppTheme.border, height: 1),
      itemBuilder: (context, i) {
        final track = tracks[i];
        final isSelected = current == track;
        final label = track.title?.isNotEmpty == true
            ? '${track.title!} (${track.language ?? track.id})'
            : 'Subtítulo ${track.id} (${track.language ?? "desconocido"})';

        return TvFocusable(
          borderRadius: BorderRadius.circular(8),
          onPressed: () {
            widget.player.setSubtitleTrack(track);
            Navigator.of(context).pop();
          },
          builder: (context, isFocused, isHovered) {
            return Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.15)
                    : (isFocused ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent),
                borderRadius: BorderRadius.circular(8),
                border: isSelected ? Border.all(color: AppTheme.primary) : null,
              ),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.subtitles, color: AppTheme.primary, size: 20),
                title: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppTheme.primary : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primary) : null,
                onTap: () {
                  widget.player.setSubtitleTrack(track);
                  Navigator.of(context).pop();
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOnlineSearchTab() {
    return Column(
      children: [
        // Search Input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _performSearch(),
                decoration: const InputDecoration(
                  hintText: 'Título de la película o serie...',
                  prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Language selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: DropdownButton<String>(
                value: _selectedLangCode,
                underline: const SizedBox.shrink(),
                dropdownColor: AppTheme.surface,
                items: const [
                  DropdownMenuItem(value: 'es', child: Text('🇪🇸 ES')),
                  DropdownMenuItem(value: 'en', child: Text('🇬🇧 EN')),
                  DropdownMenuItem(value: 'fr', child: Text('🇫🇷 FR')),
                  DropdownMenuItem(value: 'pt', child: Text('🇵🇹 PT')),
                  DropdownMenuItem(value: 'de', child: Text('🇩🇪 DE')),
                  DropdownMenuItem(value: 'it', child: Text('🇮🇹 IT')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedLangCode = val);
                    _performSearch();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isSearching ? null : _performSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
              ),
              child: _isSearching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('Buscar'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Results List
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : _remoteResults.isEmpty
                  ? Center(
                      child: Text(
                        _statusMessage ?? 'Pulsa "Buscar" para consultar subtítulos en OpenSubtitles',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      itemCount: _remoteResults.length,
                      separatorBuilder: (_, _) => const Divider(color: AppTheme.border, height: 1),
                      itemBuilder: (context, i) {
                        final item = _remoteResults[i];
                        return TvFocusable(
                          borderRadius: BorderRadius.circular(8),
                          onPressed: _isDownloading ? null : () => _downloadAndApply(item),
                          builder: (context, isFocused, isHovered) {
                            return Container(
                              decoration: BoxDecoration(
                                color: isFocused
                                    ? AppTheme.primary.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                dense: true,
                                leading: const Icon(Icons.closed_caption,
                                    color: AppTheme.primary, size: 22),
                                title: Text(
                                  item.releaseName,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  'Idioma: ${item.language.toUpperCase()} • ${item.downloads} descargas',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                                ),
                                trailing: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.surfaceLight,
                                    foregroundColor: AppTheme.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  onPressed: _isDownloading ? null : () => _downloadAndApply(item),
                                  icon: const Icon(Icons.download, size: 14),
                                  label: const Text('Activar', style: TextStyle(fontSize: 11)),
                                ),
                                onTap: _isDownloading ? null : () => _downloadAndApply(item),
                              ),
                            );
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
