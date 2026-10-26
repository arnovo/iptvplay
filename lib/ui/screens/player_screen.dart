import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_log.dart';
import '../../providers/playback_provider.dart';
import '../../providers/stream_server_provider.dart';
import '../../providers/user_activity_provider.dart';
import '../../services/log_service.dart';
import '../theme/app_theme.dart';
import '../widgets/player/audio_tracks_dialog.dart';
import '../widgets/player/player_bottom_bar.dart';
import '../widgets/player/player_center_indicators.dart';
import '../widgets/player/player_top_bar.dart';
import '../widgets/player/screen_format_dialog.dart';
import '../widgets/stream_stats_overlay.dart';
import '../widgets/subtitles_dialog.dart';

/// Fullscreen player screen orchestrator with TV D-Pad focusability,
/// continuous scrubbing, multi-audio/subtitle track switches, and LAN loopback detection.
class PlayerScreen extends StatefulWidget {
  final String? streamUrl;
  final String? title;
  final bool? isLive;
  final String? contentId;
  final String? type; // 'live', 'vod', 'series'
  final String? posterUrl;
  final int? initialPositionSeconds;

  const PlayerScreen({
    super.key,
    this.streamUrl,
    this.title,
    this.isLive,
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
  final List<StreamSubscription> _localSubscriptions = [];

  String get _title => widget.title ?? context.read<PlaybackProvider>().currentTitle ?? '';
  String get _streamUrl => widget.streamUrl ?? context.read<PlaybackProvider>().currentStreamUrl ?? '';
  bool get _isLive => widget.isLive ?? context.read<PlaybackProvider>().isLive;
  String? get _posterUrl => widget.posterUrl ?? context.read<PlaybackProvider>().currentPosterUrl;
  String? get _contentId => widget.contentId ?? context.read<PlaybackProvider>().currentContentId;
  String? get _type => widget.type ?? context.read<PlaybackProvider>().currentType;

  // Continuous seek with arrow keys
  Timer? _continuousSeekTimer;
  LogicalKeyboardKey? _activeSeekKey;
  int _accumulatedSeekSeconds = 0;
  String? _seekFeedbackText;
  Timer? _feedbackTimer;

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
  AppLocalizations get l10n => context.l10n;

  // Volume & Speed
  double _volume = 100.0;
  bool _isMuted = false;
  double _playbackRate = 1.0;
  bool _isFullScreen = false;

  // Stream loopback tracking
  String? _currentPlayingUrl;
  StreamServerProvider? _streamServerProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<StreamServerProvider>();
    if (_streamServerProvider != provider) {
      _streamServerProvider?.removeListener(_onServerStateChanged);
      _streamServerProvider = provider;
      _streamServerProvider?.addListener(_onServerStateChanged);
    }
  }

  void _onServerStateChanged() {
    final provider = _streamServerProvider;
    if (provider == null || !mounted) return;

    if (provider.isRunning && provider.targetStreamUrl == _streamUrl) {
      final localUrl = provider.localStreamUrl;
      if (localUrl != null && _currentPlayingUrl != localUrl) {
        _currentPlayingUrl = localUrl;
        LogService.instance.info(
          LogCategory.player,
          'Rerouting active player through LAN relay socket: $localUrl',
        );
        _player.open(Media(localUrl));
      }
    } else if (!provider.isRunning && _currentPlayingUrl != _streamUrl) {
      _currentPlayingUrl = _streamUrl;
      _player.open(Media(_streamUrl));
    }
  }

  @override
  void initState() {
    super.initState();
    final playback = context.read<PlaybackProvider>();
    _player = playback.player;
    _controller = playback.videoController;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PlaybackProvider>().setPlayerScreenOpen(true);
      }
    });

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
      final playback = context.read<PlaybackProvider>();

      _localSubscriptions.add(
        _player.stream.buffering.listen((buffering) {
          if (mounted) setState(() => _isBuffering = buffering);
        }),
      );

      _localSubscriptions.add(
        _player.stream.tracks.listen((_) {
          if (mounted) setState(() {});
        }),
      );

      _localSubscriptions.add(
        _player.stream.error.listen((error) {
          if (mounted && error.isNotEmpty) {
            LogService.instance.error(
              LogCategory.player,
              'Error de reproducción en: $_title',
              details: error,
            );
            setState(() => _errorMessage = error);
          }
        }),
      );

      _localSubscriptions.add(
        _player.stream.completed.listen((completed) {
          if (completed && mounted) {
            _saveCurrentProgress();
            Navigator.of(context).pop();
          }
        }),
      );

      if (widget.streamUrl != null && widget.title != null) {
        _currentPlayingUrl = widget.streamUrl;
        await playback.play(
          streamUrl: widget.streamUrl!,
          title: widget.title!,
          isLive: widget.isLive ?? false,
          posterUrl: widget.posterUrl,
          contentId: widget.contentId,
          type: widget.type,
          initialPositionSeconds: widget.initialPositionSeconds,
        );
      } else {
        _currentPlayingUrl = playback.currentStreamUrl;
      }

      // Periodically save progress every 5 seconds for VOD & Series
      if (!_isLive && _contentId != null) {
        _progressSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
          _saveCurrentProgress();
        });
      }

      _startControlsTimer();
    } catch (e) {
      LogService.instance.error(
        LogCategory.player,
        'Fallo al inicializar reproductor para $_title',
        details: e.toString(),
      );
      if (mounted) setState(() => _errorMessage = e.toString());
    }
  }

  void _saveCurrentProgress() {
    final cid = _contentId;
    if (cid == null || _isLive) return;
    final pos = _player.state.position.inSeconds;
    final dur = _player.state.duration.inSeconds;
    if (dur > 0 && pos > 0) {
      context.read<UserActivityProvider>().saveProgress(
        id: cid,
        title: _title,
        url: _streamUrl,
        posterUrl: _posterUrl,
        positionSeconds: pos,
        durationSeconds: dur,
        type: _type ?? 'vod',
      );
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
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

  void _showScreenFormatDialog() {
    ScreenFormatDialog.show(
      context: context,
      currentFit: _aspectRatioFit,
      isFullScreen: _isFullScreen,
      onFitChanged: (newFit) {
        setState(() => _aspectRatioFit = newFit);
        _startControlsTimer();
      },
      onToggleFullScreen: _toggleFullScreen,
    );
  }

  void _toggleAspectRatio() {
    setState(() {
      if (_aspectRatioFit == BoxFit.contain) {
        _aspectRatioFit = BoxFit.cover;
      } else if (_aspectRatioFit == BoxFit.cover) {
        _aspectRatioFit = BoxFit.fill;
      } else {
        _aspectRatioFit = BoxFit.contain;
      }
    });
    _startControlsTimer();
  }

  void _cyclePlaybackRate() {
    final rates = [0.75, 1.0, 1.25, 1.5, 2.0];
    final nextIndex = (rates.indexOf(_playbackRate) + 1) % rates.length;
    final newRate = rates[nextIndex];
    setState(() => _playbackRate = newRate);
    _player.setRate(newRate);
    _startControlsTimer();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _player.setVolume(_isMuted ? 0.0 : _volume);
    });
    _triggerFlashIcon(_isMuted ? Icons.volume_off : Icons.volume_up);
    _startControlsTimer();
  }

  void _triggerFlashIcon(IconData icon) {
    _flashTimer?.cancel();
    setState(() => _centerFlashIcon = icon);
    _flashTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _centerFlashIcon = null);
    });
  }

  void _onPlayPauseTap() {
    _player.playOrPause();
    final willPlay = !_player.state.playing;
    _triggerFlashIcon(willPlay ? Icons.play_arrow : Icons.pause);
    _startControlsTimer();
  }

  void _handleSeekKeyDown(LogicalKeyboardKey key) {
    if (_activeSeekKey != null) return;
    _activeSeekKey = key;
    final isForward = (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.mediaFastForward);
    final delta = isForward ? 10 : -10;

    _accumulatedSeekSeconds = delta;
    _updateSeekFeedback();

    _continuousSeekTimer?.cancel();
    _continuousSeekTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      final step = isForward ? 10 : -10;
      _accumulatedSeekSeconds += step;
      _updateSeekFeedback();
    });
  }

  void _handleSeekKeyUp(LogicalKeyboardKey key) {
    if (_activeSeekKey == key) {
      _activeSeekKey = null;
      _continuousSeekTimer?.cancel();
      _continuousSeekTimer = null;
    }
  }

  void _triggerSingleSeek(int seconds) {
    final currentPos = _player.state.position.inSeconds;
    final duration = _player.state.duration.inSeconds;
    final target = (currentPos + seconds).clamp(0, duration > 0 ? duration : 86400);

    _player.seek(Duration(seconds: target));
    setState(() {
      _seekFeedbackText = seconds > 0 ? '+$seconds s' : '$seconds s';
    });
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _seekFeedbackText = null);
    });
  }

  void _updateSeekFeedback() {
    final prefix = _accumulatedSeekSeconds > 0 ? '+' : '';
    setState(() {
      _seekFeedbackText = '$prefix$_accumulatedSeekSeconds s';
    });
  }

  @override
  void dispose() {
    context.read<PlaybackProvider>().setPlayerScreenOpen(false);
    _streamServerProvider?.removeListener(_onServerStateChanged);
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
    _continuousSeekTimer?.cancel();
    _feedbackTimer?.cancel();
    for (final sub in _localSubscriptions) {
      sub.cancel();
    }
    _localSubscriptions.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.space ||
                event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.gameButtonA ||
                event.logicalKey == LogicalKeyboardKey.mediaPlayPause) {
              _onPlayPauseTap();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.mediaPlay) {
              _player.play();
              _triggerFlashIcon(Icons.play_arrow);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.mediaPause) {
              _player.pause();
              _triggerFlashIcon(Icons.pause);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.keyI ||
                event.logicalKey == LogicalKeyboardKey.info) {
              context.read<PlaybackProvider>().toggleStats();
              _startControlsTimer();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
              _toggleFullScreen();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.keyM) {
              _toggleMute();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.mediaFastForward) {
              _handleSeekKeyDown(event.logicalKey);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.mediaRewind) {
              _handleSeekKeyDown(event.logicalKey);
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
          } else if (event is KeyUpEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.mediaFastForward ||
                event.logicalKey == LogicalKeyboardKey.mediaRewind) {
              _handleSeekKeyUp(event.logicalKey);
              return KeyEventResult.handled;
            }
          } else if (event is KeyRepeatEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _triggerSingleSeek(10);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _triggerSingleSeek(-10);
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

                // Center visual indicators (Buffering, Flash icon, Continuous seek, Error)
                PlayerCenterIndicators(
                  isBuffering: _isBuffering,
                  errorMessage: _errorMessage,
                  centerFlashIcon: _centerFlashIcon,
                  seekFeedbackText: _seekFeedbackText,
                  accumulatedSeekSeconds: _accumulatedSeekSeconds,
                  onRetry: () {
                    setState(() => _errorMessage = null);
                    _player.open(Media(_streamUrl));
                  },
                ),

                // Overlay Controls (Top & Bottom bars + Center play/pause)
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: _buildControlsOverlay(l10n),
                  ),
                ),

                // Technical Stream Statistics Overlay (HUD / OSD)
                const StreamStatsOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlsOverlay(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.85),
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
            PlayerTopBar(
              title: _title,
              streamUrl: _streamUrl,
              isLive: _isLive,
              contentId: _contentId,
              type: _type,
              posterUrl: _posterUrl,
              aspectRatioName: ScreenFormatDialog.getAspectRatioName(_aspectRatioFit, l10n),
              isFullScreen: _isFullScreen,
              onShowScreenFormat: _showScreenFormatDialog,
              onToggleAspectRatio: _toggleAspectRatio,
              onShowAudioTracks: () => AudioTracksDialog.show(context, _player),
              onShowSubtitles: () => showDialog(
                context: context,
                builder: (_) => SubtitlesDialog(
                  player: _player,
                  contentTitle: _title,
                ),
              ),
              onToggleFullScreen: _toggleFullScreen,
              onUserInteraction: _startControlsTimer,
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
            PlayerBottomBar(
              player: _player,
              isLive: _isLive,
              playbackRate: _playbackRate,
              volume: _volume,
              isMuted: _isMuted,
              isFullScreen: _isFullScreen,
              onCyclePlaybackRate: _cyclePlaybackRate,
              onToggleMute: _toggleMute,
              onVolumeChanged: (val) {
                setState(() {
                  _volume = val;
                  _isMuted = val == 0;
                  _player.setVolume(val);
                });
              },
              onToggleFullScreen: _toggleFullScreen,
              onUserInteraction: _startControlsTimer,
            ),
          ],
        ),
      ),
    );
  }
}
