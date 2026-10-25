import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../../providers/user_activity_provider.dart';
import '../../providers/download_provider.dart';
import '../theme/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  final String streamUrl;
  final String title;
  final bool isLive;
  final String? contentId;
  final String? type; // 'live', 'vod', 'series'
  final String? posterUrl;
  final int? initialPositionSeconds;

  const PlayerScreen({
    super.key,
    required this.streamUrl,
    required this.title,
    this.isLive = false,
    this.contentId,
    this.type,
    this.posterUrl,
    this.initialPositionSeconds,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player;
  late final VideoController _controller;

  bool _showControls = true;
  Timer? _controlsTimer;
  Timer? _progressSaveTimer;
  bool _isBuffering = true;
  String? _errorMessage;

  // Center flash icon animation for play/pause
  IconData? _centerFlashIcon;
  Timer? _flashTimer;

  // Aspect ratio
  BoxFit _aspectRatioFit = BoxFit.contain;
  String _aspectRatioName = 'Ajustar';

  // Volume
  double _volume = 100.0;
  bool _isMuted = false;

  // Speed
  double _playbackRate = 1.0;

  // Fullscreen state
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);

    _checkInitialFullScreen();
    _initPlayer();
  }

  Future<void> _checkInitialFullScreen() async {
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
    } else {
      setState(() => _isFullScreen = !_isFullScreen);
      if (_isFullScreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    }
    _startControlsTimer();
  }

  Future<void> _initPlayer() async {
    try {
      _player.stream.buffering.listen((buffering) {
        if (mounted) setState(() => _isBuffering = buffering);
      });

      _player.stream.error.listen((error) {
        if (mounted && error.isNotEmpty) {
          setState(() => _errorMessage = error);
        }
      });

      await _player.open(Media(widget.streamUrl));

      // Auto-resume if position was passed
      if (!widget.isLive && widget.initialPositionSeconds != null && widget.initialPositionSeconds! > 10) {
        await _player.seek(Duration(seconds: widget.initialPositionSeconds!));
      }

      // Periodically save progress every 5 seconds for VOD & Series
      if (!widget.isLive && widget.contentId != null) {
        _progressSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
          _saveCurrentProgress();
        });
      }

      _startControlsTimer();
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    }
  }

  void _saveCurrentProgress() {
    if (widget.contentId == null || widget.isLive) return;
    final pos = _player.state.position.inSeconds;
    final dur = _player.state.duration.inSeconds;
    if (dur > 0 && pos > 0) {
      context.read<UserActivityProvider>().saveProgress(
        id: widget.contentId!,
        title: widget.title,
        url: widget.streamUrl,
        posterUrl: widget.posterUrl,
        positionSeconds: pos,
        durationSeconds: dur,
        type: widget.type ?? 'vod',
      );
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    // Quick auto-hide after 1.5 seconds so controls don't linger
    _controlsTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted && _player.state.playing) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) _startControlsTimer();
    });
  }

  void _onPlayPauseTap() {
    _player.playOrPause();
    final willPlay = !_player.state.playing;

    setState(() {
      _centerFlashIcon = willPlay ? Icons.play_arrow : Icons.pause;
    });

    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _centerFlashIcon = null);
      }
    });

    _startControlsTimer();
  }

  void _showScreenFormatDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.aspect_ratio, color: AppTheme.primary),
                  SizedBox(width: 10),
                  Text(
                    'Formato y Modo de Pantalla',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                dense: true,
                leading: const Icon(Icons.fullscreen, color: AppTheme.primary),
                title: const Text('Pantalla completa (Llenar / Zoom)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Llena toda la pantalla sin bordes negros', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                trailing: _aspectRatioFit == BoxFit.cover ? const Icon(Icons.check, color: AppTheme.primary) : null,
                onTap: () {
                  setState(() {
                    _aspectRatioFit = BoxFit.cover;
                    _aspectRatioName = 'Completa';
                  });
                  Navigator.of(ctx).pop();
                  _startControlsTimer();
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.fit_screen, color: AppTheme.primary),
                title: const Text('Ajustar a pantalla (Original)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Mantiene la proporción nativa del vídeo', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                trailing: _aspectRatioFit == BoxFit.contain ? const Icon(Icons.check, color: AppTheme.primary) : null,
                onTap: () {
                  setState(() {
                    _aspectRatioFit = BoxFit.contain;
                    _aspectRatioName = 'Ajustar';
                  });
                  Navigator.of(ctx).pop();
                  _startControlsTimer();
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.aspect_ratio, color: AppTheme.primary),
                title: const Text('Estirar (16:9)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Escala la imagen a formato panorámico', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                trailing: _aspectRatioFit == BoxFit.fill ? const Icon(Icons.check, color: AppTheme.primary) : null,
                onTap: () {
                  setState(() {
                    _aspectRatioFit = BoxFit.fill;
                    _aspectRatioName = 'Estirar';
                  });
                  Navigator.of(ctx).pop();
                  _startControlsTimer();
                },
              ),
              const Divider(color: AppTheme.border),
              ListTile(
                dense: true,
                leading: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen, color: AppTheme.accentGreen),
                title: Text(
                  _isFullScreen ? 'Salir de pantalla completa (Ventana)' : 'Activar pantalla completa (Ventana)',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentGreen),
                ),
                subtitle: const Text('Maximiza la ventana ocupando todo tu monitor (o pulsa tecla F)', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _toggleFullScreen();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleAspectRatio() {
    setState(() {
      if (_aspectRatioFit == BoxFit.contain) {
        _aspectRatioFit = BoxFit.cover;
        _aspectRatioName = 'Completa';
      } else if (_aspectRatioFit == BoxFit.cover) {
        _aspectRatioFit = BoxFit.fill;
        _aspectRatioName = 'Estirar';
      } else {
        _aspectRatioFit = BoxFit.contain;
        _aspectRatioName = 'Ajustar';
      }
    });
    _startControlsTimer();
  }

  void _cyclePlaybackRate() {
    const rates = [0.75, 1.0, 1.25, 1.5, 2.0];
    final currentIndex = rates.indexOf(_playbackRate);
    final nextRate = rates[(currentIndex + 1) % rates.length];
    setState(() => _playbackRate = nextRate);
    _player.setRate(nextRate);
    _startControlsTimer();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _player.setVolume(_isMuted ? 0.0 : _volume);
    });
    _startControlsTimer();
  }

  void _showAudioTracksDialog() {
    final tracks = _player.state.tracks.audio;
    final current = _player.state.track.audio;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.audiotrack, color: AppTheme.primary),
                  SizedBox(width: 10),
                  Text(
                    'Pistas de Audio',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (tracks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No hay pistas adicionales disponibles', style: TextStyle(color: AppTheme.textMuted)),
                )
              else
                ...tracks.map((track) {
                  final isSelected = current == track;
                  return ListTile(
                    dense: true,
                    title: Text(
                      track.title?.isNotEmpty == true ? track.title! : track.language?.isNotEmpty == true ? track.language! : 'Pista ${track.id}',
                      style: TextStyle(
                        color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primary) : null,
                    onTap: () {
                      _player.setAudioTrack(track);
                      Navigator.of(ctx).pop();
                    },
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  void _showSubtitleTracksDialog() {
    final tracks = _player.state.tracks.subtitle;
    final current = _player.state.track.subtitle;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.subtitles, color: AppTheme.primary),
                  SizedBox(width: 10),
                  Text(
                    'Subtítulos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                dense: true,
                title: Text(
                  'Desactivados',
                  style: TextStyle(
                    color: current == SubtitleTrack.no() ? AppTheme.primary : AppTheme.textPrimary,
                    fontWeight: current == SubtitleTrack.no() ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: current == SubtitleTrack.no() ? const Icon(Icons.check, color: AppTheme.primary) : null,
                onTap: () {
                  _player.setSubtitleTrack(SubtitleTrack.no());
                  Navigator.of(ctx).pop();
                },
              ),
              ...tracks.map((track) {
                final isSelected = current == track;
                return ListTile(
                  dense: true,
                  title: Text(
                    track.title?.isNotEmpty == true ? track.title! : track.language?.isNotEmpty == true ? track.language! : 'Subtítulo ${track.id}',
                    style: TextStyle(
                      color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primary) : null,
                  onTap: () {
                    _player.setSubtitleTrack(track);
                    Navigator.of(ctx).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  void dispose() {
    _saveCurrentProgress();
    if (_isFullScreen) {
      if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
        windowManager.setFullScreen(false);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    }
    _controlsTimer?.cancel();
    _progressSaveTimer?.cancel();
    _flashTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.keyF) {
              _toggleFullScreen();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              if (_isFullScreen) {
                _toggleFullScreen();
                return KeyEventResult.handled;
              }
            } else if (event.logicalKey == LogicalKeyboardKey.space) {
              _onPlayPauseTap();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.keyM) {
              _toggleMute();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              final pos = _player.state.position;
              _player.seek(pos + const Duration(seconds: 10));
              _startControlsTimer();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              final pos = _player.state.position;
              _player.seek(pos - const Duration(seconds: 10));
              _startControlsTimer();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              setState(() {
                _volume = (_volume + 5.0).clamp(0.0, 100.0);
                _isMuted = false;
                _player.setVolume(_volume);
              });
              _startControlsTimer();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              setState(() {
                _volume = (_volume - 5.0).clamp(0.0, 100.0);
                _isMuted = _volume == 0;
                _player.setVolume(_volume);
              });
              _startControlsTimer();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          onHover: (_) {
            if (!_showControls) {
              setState(() => _showControls = true);
            }
            _startControlsTimer();
          },
          child: GestureDetector(
            onTap: _toggleControls,
            onDoubleTap: _toggleFullScreen,
          child: Stack(
            children: [
              // Video Surface
              Center(
                child: Video(
                  controller: _controller,
                  fit: _aspectRatioFit,
                  controls: NoVideoControls,
                ),
              ),

              // Buffering indicator
              if (_isBuffering && _errorMessage == null)
                const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),

              // Quick Center Flash Feedback Icon (Fades quickly within 600ms)
              if (_centerFlashIcon != null)
                Center(
                  child: AnimatedOpacity(
                    opacity: _centerFlashIcon != null ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_centerFlashIcon, color: AppTheme.primary, size: 54),
                    ),
                  ),
                ),

              // Error display
              if (_errorMessage != null)
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
                        const Text(
                          'Error de reproducción',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _errorMessage = null);
                            _player.open(Media(widget.streamUrl));
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ),

              // Overlay Controls
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: _buildControlsOverlay(),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildControlsOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.85),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.isLive)
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.accentRed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'EN DIRECTO',
                                style: TextStyle(
                                  color: AppTheme.accentRed,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Screen Mode / Aspect Ratio Button
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white10,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.aspect_ratio, size: 16, color: AppTheme.primary),
                    label: Text('Pantalla: $_aspectRatioName', style: const TextStyle(fontSize: 12)),
                    onPressed: _showScreenFormatDialog,
                    onLongPress: _toggleAspectRatio,
                  ),
                  const SizedBox(width: 6),
                  // Audio Track Button
                  IconButton(
                    icon: const Icon(Icons.audiotrack, color: Colors.white, size: 20),
                    tooltip: 'Pistas de audio',
                    onPressed: _showAudioTracksDialog,
                  ),
                  // Subtitles Button
                  IconButton(
                    icon: const Icon(Icons.subtitles, color: Colors.white, size: 20),
                    tooltip: 'Subtítulos',
                    onPressed: _showSubtitleTracksDialog,
                  ),
                  // Favorite Star Button
                  if (widget.contentId != null && widget.type != null)
                    Consumer<UserActivityProvider>(
                      builder: (context, activity, _) {
                        final isFav = activity.isFavorite(widget.contentId!, widget.type!);
                        return IconButton(
                          icon: Icon(
                            isFav ? Icons.star : Icons.star_border,
                            color: isFav ? Colors.amber : Colors.white,
                            size: 22,
                          ),
                          tooltip: isFav ? 'Quitar de favoritos' : 'Añadir a favoritos',
                          onPressed: () {
                            activity.toggleFavorite(widget.contentId!, widget.type!);
                            _startControlsTimer();
                          },
                        );
                      },
                    ),
                  // Live PVR Record Button
                  if (widget.isLive && widget.contentId != null)
                    Consumer<DownloadProvider>(
                      builder: (context, downloads, _) {
                        final isRec = downloads.isChannelRecording(widget.contentId!);
                        return IconButton(
                          icon: Icon(
                            isRec ? Icons.stop_circle : Icons.fiber_manual_record,
                            color: isRec ? AppTheme.accentRed : Colors.white,
                            size: 22,
                          ),
                          tooltip: isRec ? 'Detener grabación PVR' : 'Grabar transmisión',
                          onPressed: () {
                            downloads.toggleLiveRecording(
                              channelId: widget.contentId!,
                              title: widget.title,
                              streamUrl: widget.streamUrl,
                              posterUrl: widget.posterUrl,
                            );
                            _startControlsTimer();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isRec
                                      ? 'Grabación de "${widget.title}" detenida y guardada en Descargas'
                                      : 'Grabando "${widget.title}" en segundo plano...',
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  // VOD Offline Download Button
                  if (!widget.isLive && widget.contentId != null)
                    Consumer<DownloadProvider>(
                      builder: (context, downloads, _) {
                        final isDownloaded = downloads.completedItems.any((i) => i.id == widget.contentId);
                        return IconButton(
                          icon: Icon(
                            isDownloaded ? Icons.download_done : Icons.download,
                            color: isDownloaded ? AppTheme.accentGreen : Colors.white,
                            size: 22,
                          ),
                          tooltip: isDownloaded ? 'Descargado localmente' : 'Descargar para ver sin conexión',
                          onPressed: isDownloaded
                              ? null
                              : () {
                                  downloads.startVodDownload(
                                    id: widget.contentId!,
                                    title: widget.title,
                                    streamUrl: widget.streamUrl,
                                    type: widget.type ?? 'vod',
                                    posterUrl: widget.posterUrl,
                                  );
                                  _startControlsTimer();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Descarga iniciada en segundo plano')),
                                  );
                                },
                        );
                      },
                    ),
                  // Fullscreen Button
                  IconButton(
                    icon: Icon(
                      _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: Colors.white,
                      size: 24,
                    ),
                    tooltip: _isFullScreen ? 'Salir de pantalla completa' : 'Pantalla completa',
                    onPressed: _toggleFullScreen,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Center Quick Play / Pause Button
            Center(
              child: StreamBuilder<bool>(
                stream: _player.stream.playing,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data ?? true;
                  return IconButton(
                    iconSize: 64,
                    icon: Icon(
                      isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: AppTheme.primary,
                    ),
                    onPressed: _onPlayPauseTap,
                  );
                },
              ),
            ),

            const Spacer(),

            // Bottom Bar Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  if (!widget.isLive) ...[
                    StreamBuilder<Duration>(
                      stream: _player.stream.position,
                      builder: (context, posSnapshot) {
                        final position = posSnapshot.data ?? Duration.zero;
                        return StreamBuilder<Duration>(
                          stream: _player.stream.duration,
                          builder: (context, durSnapshot) {
                            final duration = durSnapshot.data ?? Duration.zero;
                            final maxSec = duration.inSeconds.toDouble();
                            final curSec = position.inSeconds.toDouble().clamp(0.0, maxSec > 0 ? maxSec : 1.0);

                            return Column(
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    thumbColor: AppTheme.primary,
                                    activeTrackColor: AppTheme.primary,
                                    inactiveTrackColor: Colors.white24,
                                    trackHeight: 4,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  ),
                                  child: Slider(
                                    value: curSec,
                                    max: maxSec > 0 ? maxSec : 1.0,
                                    onChanged: (val) {
                                      _player.seek(Duration(seconds: val.toInt()));
                                      _startControlsTimer();
                                    },
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(position),
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                    ),
                                    Text(
                                      _formatDuration(duration),
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],

                  // Advanced Action Toolbar (Speed, Volume Mute)
                  Row(
                    children: [
                      // Playback Speed Button (For VOD/Series)
                      if (!widget.isLive)
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white10,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          onPressed: _cyclePlaybackRate,
                          child: Text(
                            '${_playbackRate}x',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                          ),
                        ),
                      const Spacer(),
                      // Volume Control
                      IconButton(
                        icon: Icon(
                          _isMuted || _volume == 0 ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _toggleMute,
                      ),
                      SizedBox(
                        width: 90,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbColor: AppTheme.primary,
                            activeTrackColor: AppTheme.primary,
                            inactiveTrackColor: Colors.white24,
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                          ),
                          child: Slider(
                            value: _isMuted ? 0.0 : _volume,
                            max: 100.0,
                            onChanged: (val) {
                              setState(() {
                                _volume = val;
                                _isMuted = val == 0;
                                _player.setVolume(val);
                              });
                              _startControlsTimer();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Fullscreen Button
                      IconButton(
                        icon: Icon(
                          _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                          color: Colors.white,
                          size: 22,
                        ),
                        tooltip: _isFullScreen ? 'Salir de pantalla completa' : 'Pantalla completa',
                        onPressed: _toggleFullScreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
