import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_log.dart';
import '../models/buffer_profile.dart';
import '../models/stream_statistics.dart';
import '../services/log_service.dart';
import '../ui/screens/player_screen.dart';

class PlaybackProvider extends ChangeNotifier {
  static const String prefBufferProfileKey = 'pref_buffer_profile';

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

  // Buffer profile & Statistics
  BufferProfile _bufferProfile = BufferProfile.balanced;
  StreamStatistics _statistics = const StreamStatistics();
  bool _showStats = false;
  Timer? _statsTimer;

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

  BufferProfile get bufferProfile => _bufferProfile;
  StreamStatistics get statistics => _statistics;
  bool get showStats => _showStats;

  PlaybackProvider() {
    _player = Player();
    _videoController = VideoController(_player);

    _initBufferProfile();

    _subscriptions.add(
      _player.stream.playing.listen((playing) {
        _isPlaying = playing;
        if (playing) {
          _startStatsTimer();
        } else {
          _stopStatsTimer();
        }
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
    await _applyBufferProfileToPlayer();

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

  Future<void> _initBufferProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt(prefBufferProfileKey);
      if (savedIndex != null && savedIndex >= 0 && savedIndex < BufferProfile.values.length) {
        _bufferProfile = BufferProfile.values[savedIndex];
      }
    } catch (_) {}
  }

  Future<void> setBufferProfile(BufferProfile profile) async {
    _bufferProfile = profile;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(prefBufferProfileKey, profile.index);
    } catch (_) {}

    await _applyBufferProfileToPlayer();

    LogService.instance.info(
      LogCategory.player,
      'Perfil de búfer actualizado: ${profile.label}',
      details: 'maxBytes: ${profile.maxBytes} • readahead: ${profile.readaheadSeconds}s',
    );
  }

  Future<void> _applyBufferProfileToPlayer() async {
    try {
      final platform = _player.platform as dynamic;
      await platform.setProperty('demuxer-max-bytes', _bufferProfile.maxBytes.toString());
      await platform.setProperty('demuxer-readahead-secs', _bufferProfile.readaheadSeconds.toString());
      await platform.setProperty('cache-pause', _bufferProfile.cachePause ? 'yes' : 'no');
    } catch (e) {
      LogService.instance.warning(
        LogCategory.player,
        'No se pudieron aplicar propiedades libmpv de búfer',
        details: e.toString(),
      );
    }
  }

  void toggleStats() {
    _showStats = !_showStats;
    if (_showStats && _isPlaying) {
      _startStatsTimer();
      _updateStatistics();
    }
    notifyListeners();
  }

  void _startStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _updateStatistics();
    });
  }

  void _stopStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }

  Future<void> _updateStatistics() async {
    if (!_isPlaying || !hasMedia) return;

    try {
      final platform = _player.platform as dynamic;

      final wStr = await platform.getProperty('video-params/w');
      final hStr = await platform.getProperty('video-params/h');
      final fpsStr = await platform.getProperty('estimated-vf-fps');
      final vCodec = await platform.getProperty('video-format');
      final aCodec = await platform.getProperty('audio-codec-name');
      final dropStr = await platform.getProperty('frame-drop-count');
      final cacheSecStr = await platform.getProperty('demuxer-cache-duration');
      final cacheStateStr = await platform.getProperty('demuxer-cache-state');

      int w = int.tryParse(wStr.trim()) ?? 0;
      int h = int.tryParse(hStr.trim()) ?? 0;
      double fps = double.tryParse(fpsStr.trim()) ?? 0.0;
      int drops = int.tryParse(dropStr.trim()) ?? 0;
      double cacheSec = double.tryParse(cacheSecStr.trim()) ?? 0.0;

      double cacheMb = 0.0;
      double bitrate = 0.0;
      if (cacheStateStr.isNotEmpty) {
        // demuxer-cache-state may return bytes or json
        final matchBytes = RegExp(r'bytes=(\d+)').firstMatch(cacheStateStr);
        if (matchBytes != null) {
          final bytes = int.tryParse(matchBytes.group(1) ?? '0') ?? 0;
          cacheMb = bytes / (1024 * 1024);
        }
      }

      _statistics = _statistics.copyWith(
        width: w,
        height: h,
        fps: fps,
        videoCodec: vCodec.isNotEmpty ? vCodec.toUpperCase() : 'Nativo',
        audioCodec: aCodec.isNotEmpty ? aCodec.toUpperCase() : 'Nativo',
        droppedFrames: drops,
        cacheDurationSeconds: cacheSec,
        cacheSizeMegabytes: cacheMb,
        bitrateKbps: bitrate,
      );

      _safeNotifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _stopStatsTimer();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _player.dispose();
    super.dispose();
  }
}
