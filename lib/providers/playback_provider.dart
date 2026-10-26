import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/app_log.dart';
import '../services/log_service.dart';
import '../ui/screens/player_screen.dart';

class PlaybackProvider extends ChangeNotifier {
  late final Player _player;
  late final VideoController _videoController;

  String? _currentStreamUrl;
  String? _currentTitle;
  String? _currentPosterUrl;
  String? _currentContentId;
  String? _currentType;
  bool _isLive = false;

  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 100.0;
  bool _isMuted = false;
  bool _isPlayerScreenOpen = false;

  final List<StreamSubscription> _subscriptions = [];

  Player get player => _player;
  VideoController get videoController => _videoController;

  String? get currentStreamUrl => _currentStreamUrl;
  String? get currentTitle => _currentTitle;
  String? get currentPosterUrl => _currentPosterUrl;
  String? get currentContentId => _currentContentId;
  String? get currentType => _currentType;
  bool get isLive => _isLive;

  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  bool get isMuted => _isMuted;
  bool get isPlayerScreenOpen => _isPlayerScreenOpen;
  bool get hasMedia => _currentStreamUrl != null;

  PlaybackProvider() {
    _player = Player();
    _videoController = VideoController(_player);

    _subscriptions.add(
      _player.stream.playing.listen((playing) {
        _isPlaying = playing;
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _player.stream.buffering.listen((buffering) {
        _isBuffering = buffering;
        _safeNotifyListeners();
      }),
    );

    _subscriptions.add(
      _player.stream.position.listen((pos) {
        _position = pos;
        _safeNotifyListeners();
      }),
    );

    _subscriptions.add(
      _player.stream.duration.listen((dur) {
        _duration = dur;
        _safeNotifyListeners();
      }),
    );

    _subscriptions.add(
      _player.stream.error.listen((error) {
        LogService.instance.error(
          LogCategory.player,
          'Error en el reproductor de vídeo',
          details: error,
        );
      }),
    );
  }

  void _safeNotifyListeners() {
    try {
      if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      } else {
        notifyListeners();
      }
    } catch (_) {
      notifyListeners();
    }
  }

  void setPlayerScreenOpen(bool isOpen) {
    if (_isPlayerScreenOpen == isOpen) return;
    _isPlayerScreenOpen = isOpen;
    _safeNotifyListeners();
  }

  /// Start playing a stream. Ensures only ONE single stream is ever active at any time.
  Future<void> play({
    required String streamUrl,
    required String title,
    bool isLive = false,
    String? posterUrl,
    String? contentId,
    String? type,
    int? initialPositionSeconds,
  }) async {
    // If the exact same stream is already playing, do not restart
    if (_currentStreamUrl == streamUrl && _isPlaying) {
      return;
    }

    LogService.instance.info(
      LogCategory.player,
      'Iniciando reproducción: $title',
      details: 'URL: $streamUrl • Tipo: ${isLive ? "En vivo" : (type ?? "VOD")}',
    );

    _currentStreamUrl = streamUrl;
    _currentTitle = title;
    _currentPosterUrl = posterUrl;
    _currentContentId = contentId;
    _currentType = type;
    _isLive = isLive;
    _position = Duration.zero;
    _duration = Duration.zero;
    _isBuffering = true;
    notifyListeners();

    await _player.open(Media(streamUrl));

    if (initialPositionSeconds != null && initialPositionSeconds > 0 && !isLive) {
      await _player.seek(Duration(seconds: initialPositionSeconds));
    }
  }

  /// Plays the media and brings up the PlayerScreen if not already visible
  Future<void> openPlayer(
    BuildContext context, {
    required String streamUrl,
    required String title,
    bool isLive = false,
    String? posterUrl,
    String? contentId,
    String? type,
    int? initialPositionSeconds,
  }) async {
    await play(
      streamUrl: streamUrl,
      title: title,
      isLive: isLive,
      posterUrl: posterUrl,
      contentId: contentId,
      type: type,
      initialPositionSeconds: initialPositionSeconds,
    );

    if (!_isPlayerScreenOpen && context.mounted) {
      _isPlayerScreenOpen = true;
      notifyListeners();

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const PlayerScreen(),
        ),
      );

      _isPlayerScreenOpen = false;
      notifyListeners();
    }
  }

  /// Reopen player screen with currently playing media
  Future<void> maximizeCurrentPlayer(BuildContext context) async {
    if (!hasMedia) return;
    if (!_isPlayerScreenOpen && context.mounted) {
      _isPlayerScreenOpen = true;
      notifyListeners();

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const PlayerScreen(),
        ),
      );

      _isPlayerScreenOpen = false;
      notifyListeners();
    }
  }

  Future<void> playOrPause() async {
    await _player.playOrPause();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentStreamUrl = null;
    _currentTitle = null;
    _currentPosterUrl = null;
    _currentContentId = null;
    _currentType = null;
    _isLive = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> seek(Duration target) async {
    await _player.seek(target);
  }

  Future<void> seekRelative(Duration delta) async {
    final cur = _position;
    final dur = _duration;
    Duration target = cur + delta;
    if (target < Duration.zero) target = Duration.zero;
    if (dur > Duration.zero && target > dur) target = dur;
    await _player.seek(target);
  }

  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 100.0);
    _isMuted = _volume == 0.0;
    await _player.setVolume(_volume);
    notifyListeners();
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await _player.setVolume(_isMuted ? 0.0 : _volume);
    notifyListeners();
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _player.dispose();
    super.dispose();
  }
}
