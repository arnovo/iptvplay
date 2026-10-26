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
import '../../providers/stream_server_provider.dart';
import '../../providers/playback_provider.dart';
import '../../models/app_log.dart';
import '../../services/log_service.dart';
import '../widgets/lan_stream_dialog.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

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

  String _getAspectRatioName([BuildContext? ctx]) {
    final loc = ctx != null ? ctx.l10n : l10n;
    if (_aspectRatioFit == BoxFit.cover) return loc.aspectNameCover;
    if (_aspectRatioFit == BoxFit.fill) return loc.aspectNameFill;
    return loc.aspectNameContain;
  }

  // Volume
  double _volume = 100.0;
  bool _isMuted = false;

  // Speed
  double _playbackRate = 1.0;

  // Fullscreen state
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
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
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
                  trailing: _aspectRatioFit == BoxFit.cover ? const Icon(Icons.check, color: AppTheme.primary) : null,
                  onTap: () {
                    setState(() {
                      _aspectRatioFit = BoxFit.cover;
                    });
                    Navigator.of(ctx).pop();
                    _startControlsTimer();
                  },
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.fit_screen, color: AppTheme.primary),
                  title: Text(l10n.aspectContainTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(l10n.aspectContainSubtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  trailing: _aspectRatioFit == BoxFit.contain ? const Icon(Icons.check, color: AppTheme.primary) : null,
                  onTap: () {
                    setState(() {
                      _aspectRatioFit = BoxFit.contain;
                    });
                    Navigator.of(ctx).pop();
                    _startControlsTimer();
                  },
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.aspect_ratio, color: AppTheme.primary),
                  title: Text(l10n.aspectFillTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(l10n.aspectFillSubtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  trailing: _aspectRatioFit == BoxFit.fill ? const Icon(Icons.check, color: AppTheme.primary) : null,
                  onTap: () {
                    setState(() {
                      _aspectRatioFit = BoxFit.fill;
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
                    _isFullScreen ? l10n.windowFullscreenExit : l10n.windowFullscreenEnter,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentGreen),
                  ),
                  subtitle: Text(l10n.windowFullscreenSubtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _toggleFullScreen();
                  },
                ),
              ],
            ),
          ),
        );
      },
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

  String _formatLanguageCode(String? code, String fallback) {
    if (code == null || code.isEmpty) return fallback;
    final lower = code.toLowerCase();
    switch (lower) {
      case 'spa':
      case 'es':
        return 'Español';
      case 'eng':
      case 'en':
        return 'Inglés';
      case 'fre':
      case 'fra':
      case 'fr':
        return 'Francés';
      case 'ger':
      case 'deu':
      case 'de':
        return 'Alemán';
      case 'ita':
      case 'it':
        return 'Italiano';
      case 'por':
      case 'pt':
        return 'Portugués';
      case 'ara':
      case 'ar':
        return 'Árabe';
      case 'rus':
      case 'ru':
        return 'Ruso';
      case 'jpn':
      case 'ja':
        return 'Japonés';
      case 'chi':
      case 'zho':
      case 'zh':
        return 'Chino';
      case 'dut':
      case 'nld':
      case 'nl':
        return 'Holandés';
      case 'pol':
      case 'pl':
        return 'Polaco';
      case 'dan':
      case 'da':
        return 'Danés';
      case 'swe':
      case 'sv':
        return 'Sueco';
      case 'nor':
      case 'no':
        return 'Noruego';
      case 'fin':
      case 'fi':
        return 'Finlandés';
      default:
        return code.toUpperCase();
    }
  }

  void _showAudioTracksDialog() {
    final l10n = context.l10n;
    final tracks = _player.state.tracks.audio;
    final current = _player.state.track.audio;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.audiotrack, color: AppTheme.primary),
                    const SizedBox(width: 10),
                    Text(
                      l10n.audioTracks,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.tracksAvailableCount(tracks.length),
                        style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (tracks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(l10n.noAudioTracksAvailable, style: const TextStyle(color: AppTheme.textMuted)),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: tracks.length,
                      separatorBuilder: (_, _) => const Divider(color: AppTheme.border, height: 1),
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        final isSelected = current == track;
                        final langName = _formatLanguageCode(track.language, 'Pista ${track.id}');
                        final label = track.title?.isNotEmpty == true
                            ? '${track.title!} ($langName)'
                            : langName;

                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            title: Text(
                              label,
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
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSubtitleTracksDialog() {
    final l10n = context.l10n;
    final tracks = _player.state.tracks.subtitle;
    final current = _player.state.track.subtitle;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.subtitles, color: AppTheme.primary),
                    const SizedBox(width: 10),
                    Text(
                      l10n.subtitles,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.languagesAvailableCount(tracks.length),
                        style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(
                      l10n.subtitlesDisabled,
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
                ),
                const Divider(color: AppTheme.border, height: 1),
                if (tracks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(l10n.noSubtitlesAvailable, style: const TextStyle(color: AppTheme.textMuted)),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: tracks.length,
                      separatorBuilder: (_, _) => const Divider(color: AppTheme.border, height: 1),
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        final isSelected = current == track;
                        final langName = _formatLanguageCode(track.language, 'Subtítulo ${track.id}');
                        final label = track.title?.isNotEmpty == true
                            ? '${track.title!} ($langName)'
                            : langName;

                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            title: Text(
                              label,
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
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
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

  void _triggerSingleSeek(int seconds) {
    if (_isLive) return;
    final pos = _player.state.position;
    final dur = _player.state.duration;
    Duration target = pos + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (dur > Duration.zero && target > dur) target = dur;
    _player.seek(target);

    _accumulatedSeekSeconds += seconds;
    final sign = _accumulatedSeekSeconds > 0 ? '+' : '';
    setState(() {
      _seekFeedbackText = '$sign${_accumulatedSeekSeconds}s';
    });

    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _seekFeedbackText = null;
          _accumulatedSeekSeconds = 0;
        });
      }
    });
    _startControlsTimer();
  }

  void _handleSeekKeyDown(int seconds) {
    if (_isLive) return;
    final key = seconds > 0 ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft;
    if (_activeSeekKey == key) return;
    _activeSeekKey = key;

    _triggerSingleSeek(seconds);

    _continuousSeekTimer?.cancel();
    // Start continuous seek with delay (350ms) then repeating every 160ms as long as held
    _continuousSeekTimer = Timer(const Duration(milliseconds: 350), () {
      _continuousSeekTimer = Timer.periodic(const Duration(milliseconds: 160), (_) {
        _triggerSingleSeek(seconds);
      });
    });
  }

  void _handleSeekKeyUp(LogicalKeyboardKey key) {
    if (_activeSeekKey == key) {
      _activeSeekKey = null;
      _continuousSeekTimer?.cancel();
      _continuousSeekTimer = null;
    }
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
            if (event.logicalKey == LogicalKeyboardKey.keyF) {
              _toggleFullScreen();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.escape ||
                event.logicalKey == LogicalKeyboardKey.goBack) {
              if (_isFullScreen) {
                _toggleFullScreen();
                return KeyEventResult.handled;
              } else if (_showControls) {
                setState(() => _showControls = false);
                return KeyEventResult.handled;
              }
            } else if (event.logicalKey == LogicalKeyboardKey.space ||
                event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.gameButtonA ||
                event.logicalKey == LogicalKeyboardKey.mediaPlayPause) {
              _onPlayPauseTap();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.mediaPlay) {
              _player.play();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.mediaPause) {
              _player.pause();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.keyM) {
              _toggleMute();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.mediaFastForward) {
              _handleSeekKeyDown(10);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.mediaRewind) {
              _handleSeekKeyDown(-10);
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

              // Continuous Seek Feedback Indicator
              if (_seekFeedbackText != null)
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
                          _accumulatedSeekSeconds > 0 ? Icons.fast_forward : Icons.fast_rewind,
                          color: AppTheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _seekFeedbackText!,
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
                        Text(
                          l10n.playbackError,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            _player.open(Media(_streamUrl));
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.retry),
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
                    tooltip: l10n.minimizeTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_isLive)
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
                              Text(
                                l10n.liveOnAir,
                                style: const TextStyle(
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
                    label: Text(l10n.screenRatioLabel(_getAspectRatioName(context)), style: const TextStyle(fontSize: 12)),
                    onPressed: _showScreenFormatDialog,
                    onLongPress: _toggleAspectRatio,
                  ),
                  const SizedBox(width: 6),
                  // Audio Track Button
                  IconButton(
                    icon: const Icon(Icons.audiotrack, color: Colors.white, size: 20),
                    tooltip: l10n.audioTracksTooltip,
                    onPressed: _showAudioTracksDialog,
                  ),
                  // Subtitles Button
                  IconButton(
                    icon: const Icon(Icons.subtitles, color: Colors.white, size: 20),
                    tooltip: l10n.subtitlesTooltip,
                    onPressed: _showSubtitleTracksDialog,
                  ),
                  // Favorite Star Button
                  if (_contentId != null && _type != null)
                    Consumer<UserActivityProvider>(
                      builder: (context, activity, _) {
                        final isFav = activity.isFavorite(_contentId!, _type!);
                        return IconButton(
                          icon: Icon(
                            isFav ? Icons.star : Icons.star_border,
                            color: isFav ? Colors.amber : Colors.white,
                            size: 22,
                          ),
                          tooltip: isFav ? l10n.removeFavoriteTooltip : l10n.addFavoriteTooltip,
                          onPressed: () {
                            activity.toggleFavorite(_contentId!, _type!);
                            _startControlsTimer();
                          },
                        );
                      },
                    ),
                  // Live PVR Record Button
                  if (_isLive && _contentId != null)
                    Consumer<DownloadProvider>(
                      builder: (context, downloads, _) {
                        final isRec = downloads.isChannelRecording(_contentId!);
                        return IconButton(
                          icon: Icon(
                            isRec ? Icons.stop_circle : Icons.fiber_manual_record,
                            color: isRec ? AppTheme.accentRed : Colors.white,
                            size: 22,
                          ),
                          tooltip: isRec ? l10n.stopPvrTooltip : l10n.recordPvrTooltip,
                          onPressed: () {
                            downloads.toggleLiveRecording(
                              channelId: _contentId!,
                              title: _title,
                              streamUrl: _streamUrl,
                              posterUrl: _posterUrl,
                            );
                            _startControlsTimer();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isRec
                                      ? l10n.recordingStoppedToast(_title)
                                      : l10n.recordingStartedToast(_title),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  // VOD Offline Download Button
                  if (!_isLive && _contentId != null)
                    Consumer<DownloadProvider>(
                      builder: (context, downloads, _) {
                        final isDownloaded = downloads.completedItems.any((i) => i.id == _contentId);
                        return IconButton(
                          icon: Icon(
                            isDownloaded ? Icons.download_done : Icons.download,
                            color: isDownloaded ? AppTheme.accentGreen : Colors.white,
                            size: 22,
                          ),
                          tooltip: isDownloaded ? l10n.downloadedOpenFolderTooltip : l10n.downloadOfflineTooltip,
                          onPressed: isDownloaded
                              ? () {
                                  final item = downloads.completedItems.where((i) => i.id == _contentId).firstOrNull;
                                  if (item != null) {
                                    downloads.openItemInFileManager(item);
                                  }
                                }
                              : () {
                                  downloads.startVodDownload(
                                    id: _contentId!,
                                    title: _title,
                                    streamUrl: _streamUrl,
                                    type: _type ?? 'vod',
                                    posterUrl: _posterUrl,
                                  );
                                  _startControlsTimer();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.downloadStartedToast)),
                                  );
                                },
                        );
                      },
                    ),
                  // Cast / LAN Stream Reforward Button
                  Consumer<StreamServerProvider>(
                    builder: (context, streamServer, _) {
                      final isSharing = streamServer.isRunning;
                      return IconButton(
                        icon: Icon(
                          Icons.cell_tower,
                          color: isSharing ? AppTheme.primary : Colors.white,
                          size: 22,
                        ),
                        tooltip: isSharing ? l10n.lanSharingActiveTooltip : l10n.lanSharingInactiveTooltip,
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => LanStreamDialog(
                              title: _title,
                              streamUrl: _streamUrl,
                            ),
                          );
                          _startControlsTimer();
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
                    tooltip: _isFullScreen ? l10n.exitFullscreenTooltip : l10n.enterFullscreenTooltip,
                    onPressed: _toggleFullScreen,
                  ),
                  // Stop & Close Button
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 24),
                    tooltip: l10n.stopAndClosePlayerTooltip,
                    onPressed: () {
                      context.read<PlaybackProvider>().stop();
                      Navigator.of(context).pop();
                    },
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
                  if (!_isLive) ...[
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
                      if (!_isLive)
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
                        tooltip: _isFullScreen ? l10n.exitFullscreenTooltip : l10n.enterFullscreenTooltip,
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
