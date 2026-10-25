import 'dart:async';
import 'dart:io';
import 'log_service.dart';
import '../models/app_log.dart';

class LocalStreamServer {
  static final LocalStreamServer _instance = LocalStreamServer._internal();
  factory LocalStreamServer() => _instance;
  LocalStreamServer._internal();

  HttpServer? _server;
  String? _targetStreamUrl;
  String? _targetTitle;
  int _port = 8088;
  String? _localIp;

  // Upstream single-connection multiplexer
  HttpClient? _upstreamClient;
  StreamSubscription<List<int>>? _upstreamSub;
  final Set<HttpResponse> _clients = {};
  final List<List<int>> _recentChunks = [];
  int _recentBytes = 0;
  static const int _maxRecentBytes = 384 * 1024; // ~384 KB buffer

  final StreamController<int> _clientsController = StreamController<int>.broadcast();
  Stream<int> get activeClientsStream => _clientsController.stream;

  bool get isRunning => _server != null;
  String? get targetStreamUrl => _targetStreamUrl;
  String? get targetTitle => _targetTitle;
  int get port => _port;
  String? get localIp => _localIp;
  int get activeClients => _clients.length;

  /// Web Player URL (HTML5 player with embedded mpegts.js and hls.js)
  String? get webPlayerUrl {
    if (_server == null || _localIp == null) return null;
    return 'http://$_localIp:$_port/';
  }

  /// Raw media stream URL for VLC, Smart TV, Kodi, Infuse
  String? get rawStreamUrl {
    if (_server == null || _localIp == null) return null;
    final isM3u8 = _targetStreamUrl?.contains('.m3u8') ?? false;
    final ext = isM3u8 ? 'm3u8' : 'ts';
    return 'http://$_localIp:$_port/stream.$ext';
  }

  /// Default stream URL (points to web player for browser compatibility)
  String? get streamUrl => webPlayerUrl;

  /// Get the local LAN IP address of this device (e.g. 192.168.1.X)
  Future<String> findLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          // Look for typical private local IP ranges (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
          if (!addr.isLoopback &&
              (addr.address.startsWith('192.168.') ||
                  addr.address.startsWith('10.') ||
                  addr.address.startsWith('172.'))) {
            return addr.address;
          }
        }
      }

      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        return interfaces.first.addresses.first.address;
      }
    } catch (_) {}

    return '127.0.0.1';
  }

  /// Start local streaming server proxying targetStreamUrl
  Future<String?> startServer({
    required String targetStreamUrl,
    required String title,
    int preferredPort = 8088,
  }) async {
    await stopServer();

    _targetStreamUrl = targetStreamUrl;
    _targetTitle = title;
    _localIp = await findLocalIpAddress();

    // Find available port starting from preferredPort
    for (int p = preferredPort; p < preferredPort + 10; p++) {
      try {
        _server = await HttpServer.bind(
          InternetAddress.anyIPv4,
          p,
          shared: true,
        );
        _port = p;
        break;
      } catch (_) {}
    }

    if (_server == null) {
      LogService.instance.error(
        LogCategory.server,
        'No se pudo iniciar el servidor HTTP local en el puerto $preferredPort',
      );
      return null;
    }

    _server!.listen(_handleHttpRequest);

    LogService.instance.success(
      LogCategory.server,
      'Servidor de reenvío LAN iniciado en http://$_localIp:$_port/',
      details: 'Canal: "$title" | Destino: $targetStreamUrl',
    );

    return webPlayerUrl;
  }

  void _handleHttpRequest(HttpRequest request) async {
    // Add CORS headers for web browsers and Smart TVs
    request.response.headers.set('Access-Control-Allow-Origin', '*');
    request.response.headers.set('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');
    request.response.headers.set('Access-Control-Allow-Headers', '*');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    final path = request.uri.path;

    // Favicon handler
    if (path == '/favicon.ico') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return;
    }

    final userAgent = request.headers.value('user-agent')?.toLowerCase() ?? '';
    final acceptHeader = request.headers.value('accept')?.toLowerCase() ?? '';

    // Detect dedicated media player apps (VLC, Kodi, ExoPlayer, TiviMate, Smart TV apps)
    final isMediaPlayer = userAgent.contains('vlc') ||
        userAgent.contains('kodi') ||
        userAgent.contains('exoplayer') ||
        userAgent.contains('lavf') ||
        userAgent.contains('smart') ||
        userAgent.contains('tivimate') ||
        userAgent.contains('infuse') ||
        userAgent.contains('applecoremedia');

    // Route explicit media stream endpoints directly to media streaming
    if (path == '/stream.ts' ||
        path == '/stream.m3u8' ||
        path == '/live' ||
        path == '/raw' ||
        path == '/video.ts' ||
        (isMediaPlayer && (path == '/' || path == '/stream' || path.isEmpty))) {
      await _handleMediaRequest(request);
      return;
    }

    // Default: Web Player for all browsers and direct navigations
    if (!isMediaPlayer &&
        (path == '/' ||
            path == '/player' ||
            path == '/watch' ||
            path.isEmpty ||
            (path == '/stream' && acceptHeader.contains('text/html')))) {
      await _serveWebPlayer(request);
      return;
    }

    // For non-browser /stream requests without .ts extension
    if (path == '/stream') {
      await _handleMediaRequest(request);
      return;
    }

    // Default: 404
    request.response.statusCode = HttpStatus.notFound;
    request.response.write('Ruta no encontrada');
    await request.response.close();
  }

  /// Handles media requests (both HEAD and GET) with multiplexed broadcasting
  Future<void> _handleMediaRequest(HttpRequest request) async {
    if (_targetStreamUrl == null || _targetStreamUrl!.isEmpty) {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('No hay flujo activo para reenviar.');
      await request.response.close();
      return;
    }

    final isM3u8 = _targetStreamUrl!.contains('.m3u8');
    final contentType = isM3u8 ? 'application/x-mpegURL' : 'video/mp2t';
    final filename = isM3u8 ? 'stream.m3u8' : 'stream.ts';

    // Handle HEAD request (required by VLC on iOS)
    if (request.method == 'HEAD') {
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.set('Content-Type', contentType);
      request.response.headers.set('Content-Disposition', 'inline; filename="$filename"');
      request.response.headers.set('Accept-Ranges', 'none');
      request.response.headers.set('Connection', 'keep-alive');
      request.response.headers.set('Access-Control-Allow-Origin', '*');
      await request.response.close();
      return;
    }

    // Handle GET streaming request
    final clientIp = request.connectionInfo?.remoteAddress.address ?? 'cliente';
    request.response.statusCode = HttpStatus.ok;
    request.response.headers.set('Content-Type', contentType);
    request.response.headers.set('Content-Disposition', 'inline; filename="$filename"');
    request.response.headers.set('Connection', 'keep-alive');
    request.response.headers.set('Cache-Control', 'no-cache, no-store, must-revalidate');
    request.response.headers.set('Pragma', 'no-cache');
    request.response.headers.set('Accept-Ranges', 'none');
    request.response.headers.set('Access-Control-Allow-Origin', '*');
    request.response.bufferOutput = false;

    // Start single upstream connection if not already running
    if (_upstreamSub == null) {
      await _startUpstream();
    }

    // Register client
    _clients.add(request.response);
    _clientsController.add(_clients.length);

    LogService.instance.info(
      LogCategory.server,
      'Cliente conectado al stream LAN ($clientIp). Clientes activos: ${_clients.length}',
    );

    // Send recent PAT/PMT/I-frame burst buffer for instant tune-in
    try {
      for (final chunk in _recentChunks) {
        request.response.add(chunk);
      }
      await request.response.flush();
    } catch (_) {
      _removeClient(request.response, clientIp);
      return;
    }

    // Handle client disconnect
    request.response.done.then((_) {
      _removeClient(request.response, clientIp);
    }).catchError((_) {
      _removeClient(request.response, clientIp);
    });
  }

  void _removeClient(HttpResponse response, String clientIp) {
    if (_clients.remove(response)) {
      _clientsController.add(_clients.length);
      LogService.instance.info(
        LogCategory.server,
        'Cliente desconectado del stream LAN ($clientIp). Clientes activos: ${_clients.length}',
      );
      if (_clients.isEmpty) {
        _stopUpstream();
      }
    }
  }

  /// Starts single upstream connection to IPTV provider
  Future<void> _startUpstream() async {
    if (_targetStreamUrl == null || _targetStreamUrl!.isEmpty) return;

    _stopUpstream();

    try {
      _upstreamClient = HttpClient();
      _upstreamClient!.findProxy = null;
      _upstreamClient!.badCertificateCallback = (cert, host, port) => true;

      final req = await _upstreamClient!.getUrl(Uri.parse(_targetStreamUrl!));
      req.headers.set('User-Agent', 'IPTVSmartersPro/3.1.5.1 (Linux; Android 12) AppleWebKit/537.36');
      req.headers.set('Accept', '*/*');
      req.followRedirects = true;
      req.maxRedirects = 5;

      final resp = await req.close();
      if (resp.statusCode != HttpStatus.ok) {
        LogService.instance.error(
          LogCategory.server,
          'Error del servidor IPTV upstream: HTTP ${resp.statusCode}',
        );
        _stopUpstream();
        return;
      }

      _upstreamSub = resp.listen(
        (chunk) {
          // Store in burst buffer
          _recentChunks.add(chunk);
          _recentBytes += chunk.length;
          while (_recentBytes > _maxRecentBytes && _recentChunks.isNotEmpty) {
            _recentBytes -= _recentChunks.removeAt(0).length;
          }

          // Broadcast to all active clients
          final toRemove = <HttpResponse>[];
          for (final client in _clients) {
            try {
              client.add(chunk);
            } catch (_) {
              toRemove.add(client);
            }
          }

          for (final c in toRemove) {
            _clients.remove(c);
            try { c.close(); } catch (_) {}
          }
          if (toRemove.isNotEmpty) {
            _clientsController.add(_clients.length);
            if (_clients.isEmpty) {
              _stopUpstream();
            }
          }
        },
        onError: (err) {
          LogService.instance.warning(
            LogCategory.server,
            'Flujo upstream interrumpido: $err',
          );
          _stopUpstream();
        },
        onDone: () {
          _stopUpstream();
        },
        cancelOnError: true,
      );
    } catch (e) {
      LogService.instance.error(
        LogCategory.server,
        'Fallo al iniciar conexión upstream con servidor IPTV',
        details: e.toString(),
      );
      _stopUpstream();
    }
  }

  void _stopUpstream() {
    _upstreamSub?.cancel();
    _upstreamSub = null;
    _upstreamClient?.close(force: true);
    _upstreamClient = null;
    _recentChunks.clear();
    _recentBytes = 0;
  }

  /// Serves the HTML5 Web Player with mpegts.js & hls.js
  Future<void> _serveWebPlayer(HttpRequest request) async {
    final title = _targetTitle ?? 'Canal en Directo';
    final isM3u8 = _targetStreamUrl?.contains('.m3u8') ?? false;
    final mediaUrl = rawStreamUrl ?? 'http://$_localIp:$_port/stream.ts';

    request.response.headers.contentType = ContentType.html;
    request.response.headers.set('Cache-Control', 'no-cache, no-store');

    request.response.write('''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$title - IPTV Play Directo</title>
  <script src="https://cdn.jsdelivr.net/npm/mpegts.js@1.7.3/dist/mpegts.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/hls.js@1.5.8/dist/hls.min.js"></script>
  <style>
    :root {
      --bg: #0B0F19;
      --card-bg: #151D2F;
      --card-border: rgba(255, 255, 255, 0.08);
      --primary: #00E5FF;
      --primary-glow: rgba(0, 229, 255, 0.35);
      --accent-green: #10B981;
      --accent-red: #EF4444;
      --accent-yellow: #F59E0B;
      --text: #F8FAFC;
      --text-muted: #94A3B8;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background-color: var(--bg);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 24px 16px;
    }
    .header {
      width: 100%;
      max-width: 960px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;
      flex-wrap: wrap;
      gap: 12px;
    }
    .brand {
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .logo-badge {
      background: linear-gradient(135deg, #00E5FF 0%, #3B82F6 100%);
      color: #000;
      font-weight: 800;
      font-size: 13px;
      padding: 5px 10px;
      border-radius: 8px;
      letter-spacing: 0.5px;
    }
    .live-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background: rgba(239, 68, 68, 0.15);
      border: 1px solid rgba(239, 68, 68, 0.4);
      color: #F87171;
      padding: 4px 10px;
      border-radius: 999px;
      font-size: 12px;
      font-weight: 700;
      letter-spacing: 0.5px;
    }
    .live-dot {
      width: 8px;
      height: 8px;
      background-color: #EF4444;
      border-radius: 50%;
      animation: pulse 1.5s infinite;
    }
    @keyframes pulse {
      0% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.7); }
      70% { transform: scale(1.1); box-shadow: 0 0 0 6px rgba(239, 68, 68, 0); }
      100% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(239, 68, 68, 0); }
    }
    .main-container {
      width: 100%;
      max-width: 960px;
      display: flex;
      flex-direction: column;
      gap: 20px;
    }
    .player-card {
      background: var(--card-bg);
      border: 1px solid var(--card-border);
      border-radius: 18px;
      overflow: hidden;
      box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4);
      position: relative;
    }
    .player-wrapper {
      position: relative;
      width: 100%;
      aspect-ratio: 16 / 9;
      background: #000;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    video {
      width: 100%;
      height: 100%;
      display: block;
      outline: none;
    }
    .overlay-status {
      position: absolute;
      top: 14px;
      left: 14px;
      background: rgba(0, 0, 0, 0.75);
      backdrop-filter: blur(8px);
      padding: 6px 12px;
      border-radius: 8px;
      font-size: 13px;
      color: var(--primary);
      border: 1px solid rgba(0, 229, 255, 0.3);
      pointer-events: none;
      z-index: 10;
    }
    .notice-banner {
      display: none;
      background: rgba(245, 158, 11, 0.15);
      border: 1px solid rgba(245, 158, 11, 0.4);
      color: #FCD34D;
      padding: 10px 16px;
      border-radius: 10px;
      font-size: 12px;
      line-height: 1.4;
      margin-bottom: 12px;
    }
    .unmute-btn {
      position: absolute;
      bottom: 24px;
      left: 50%;
      transform: translateX(-50%);
      background: rgba(0, 229, 255, 0.95);
      color: #000;
      padding: 10px 22px;
      border-radius: 30px;
      font-weight: 700;
      font-size: 14px;
      cursor: pointer;
      border: none;
      box-shadow: 0 4px 18px var(--primary-glow);
      display: none;
      z-index: 20;
      transition: transform 0.2s;
    }
    .unmute-btn:hover {
      transform: translateX(-50%) scale(1.05);
    }
    .player-info {
      padding: 18px 24px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-top: 1px solid var(--card-border);
      flex-wrap: wrap;
      gap: 16px;
    }
    .channel-title {
      font-size: 18px;
      font-weight: 700;
      color: #FFF;
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .actions-row {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
    }
    .btn {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 9px 16px;
      border-radius: 10px;
      font-size: 13px;
      font-weight: 600;
      text-decoration: none;
      cursor: pointer;
      border: none;
      transition: all 0.2s;
    }
    .btn-primary {
      background: var(--primary);
      color: #000;
    }
    .btn-primary:hover {
      background: #33EBFF;
      box-shadow: 0 0 12px var(--primary-glow);
    }
    .btn-secondary {
      background: rgba(255, 255, 255, 0.08);
      color: var(--text);
      border: 1px solid var(--card-border);
    }
    .btn-secondary:hover {
      background: rgba(255, 255, 255, 0.15);
    }
    .card {
      background: var(--card-bg);
      border: 1px solid var(--card-border);
      border-radius: 16px;
      padding: 22px;
    }
    .card-title {
      font-size: 15px;
      font-weight: 700;
      margin-bottom: 14px;
      display: flex;
      align-items: center;
      gap: 8px;
      color: var(--primary);
    }
    .urls-grid {
      display: grid;
      grid-template-columns: 1fr;
      gap: 14px;
    }
    @media (min-width: 640px) {
      .urls-grid { grid-template-columns: 1fr 1fr; }
    }
    .url-box {
      background: #0B0F19;
      border: 1px solid var(--card-border);
      border-radius: 12px;
      padding: 14px;
      display: flex;
      flex-direction: column;
      gap: 8px;
    }
    .url-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .url-label {
      font-size: 12px;
      color: var(--text-muted);
      font-weight: 600;
    }
    .url-code {
      font-family: monospace;
      font-size: 13px;
      color: var(--primary);
      word-break: break-all;
      background: rgba(0, 0, 0, 0.4);
      padding: 8px 10px;
      border-radius: 8px;
    }
    .steps-list {
      list-style: none;
      display: flex;
      flex-direction: column;
      gap: 8px;
      font-size: 13px;
      color: var(--text-muted);
      margin-top: 10px;
    }
    .steps-list li {
      display: flex;
      align-items: flex-start;
      gap: 8px;
    }
    .step-num {
      background: rgba(0, 229, 255, 0.15);
      color: var(--primary);
      font-weight: bold;
      width: 20px;
      height: 20px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 11px;
      flex-shrink: 0;
    }
  </style>
</head>
<body>
  <div class="header">
    <div class="brand">
      <span class="logo-badge">IPTV PLAY</span>
      <span class="live-badge"><span class="live-dot"></span> EN DIRECTO</span>
    </div>
    <span style="color: var(--text-muted); font-size: 13px;">Reenvío Local Activo</span>
  </div>

  <div class="main-container">
    <div id="audioNotice" class="notice-banner">
      ⚠️ <strong>Audio no compatible en navegador web:</strong> Este canal emite con audio MPEG Layer 2 / AC3 (estándar de emisión satélite). El vídeo se reproduce en directo en el navegador; para escuchar el audio con máxima calidad, pulsa en <strong>"▶ Abrir en VLC"</strong> o copia el enlace directo.
    </div>

    <div class="player-card">
      <div class="player-wrapper">
        <video id="player" controls autoplay playsinline></video>
        <div id="statusBadge" class="overlay-status">Iniciando reproductor...</div>
        <button id="unmuteBtn" class="unmute-btn">🔊 Activar Audio</button>
      </div>

      <div class="player-info">
        <div class="channel-title">
          <span>📺</span>
          <span>$title</span>
        </div>

        <div class="actions-row">
          <a href="vlc://$mediaUrl" class="btn btn-primary" id="vlcBtn">
            ▶ Abrir en VLC
          </a>
          <button class="btn btn-secondary" onclick="reloadPlayer()">
            🔄 Recargar Flujo
          </button>
        </div>
      </div>
    </div>

    <div class="card">
      <div class="card-title">📡 URLs de Conexión en Red Local</div>
      <div class="urls-grid">
        <div class="url-box">
          <div class="url-header">
            <span class="url-label">🌐 NAVEGADOR (PC, Móvil, Tablet)</span>
            <button class="btn btn-secondary" style="padding: 4px 10px; font-size: 11px;" id="btnCopyWeb" onclick="copyText(window.location.origin + '/', 'btnCopyWeb')">Copiar</button>
          </div>
          <div class="url-code" id="webUrlText">http://$_localIp:$_port/</div>
          <p style="font-size: 11px; color: var(--text-muted);">Abre este enlace directamente en Chrome, Safari, Firefox o Edge sin necesidad de instalar nada.</p>
        </div>

        <div class="url-box">
          <div class="url-header">
            <span class="url-label">📺 SMART TV / VLC / KODI / INFUSE</span>
            <button class="btn btn-secondary" style="padding: 4px 10px; font-size: 11px;" id="btnCopyStream" onclick="copyText('$mediaUrl', 'btnCopyStream')">Copiar</button>
          </div>
          <div class="url-code">$mediaUrl</div>
          <p style="font-size: 11px; color: var(--text-muted);">Pega esta URL en reproductores externos para reproducir el flujo continuo con todos los canales de audio y subtítulos.</p>
        </div>
      </div>

      <ul class="steps-list" style="margin-top: 18px;">
        <li><span class="step-num">1</span> Asegúrate de que el otro dispositivo esté conectado a la misma red Wi-Fi o cableada.</li>
        <li><span class="step-num">2</span> Para Smart TVs y VLC: abre VLC ("Flujo de red" o "Abrir red") y pega el enlace directo.</li>
      </ul>
    </div>
  </div>

  <script>
    const streamUrl = window.location.origin + '/stream.ts';
    const video = document.getElementById('player');
    const statusBadge = document.getElementById('statusBadge');
    const unmuteBtn = document.getElementById('unmuteBtn');
    const audioNotice = document.getElementById('audioNotice');
    const isM3u8 = ${isM3u8 ? 'true' : 'false'};
    let mpegPlayer = null;
    let hlsPlayer = null;
    let fallbackToVideoOnlyTried = false;

    function setStatus(text, isError = false) {
      if (!statusBadge) return;
      statusBadge.textContent = text;
      statusBadge.style.color = isError ? '#EF4444' : '#00E5FF';
      statusBadge.style.borderColor = isError ? 'rgba(239, 68, 68, 0.5)' : 'rgba(0, 229, 255, 0.3)';
    }

    function initPlayer() {
      setStatus('Conectando al flujo...');

      if (isM3u8) {
        if (typeof Hls !== 'undefined' && Hls.isSupported()) {
          hlsPlayer = new Hls({ enableWorker: true, lowLatencyMode: true });
          hlsPlayer.loadSource(streamUrl);
          hlsPlayer.attachMedia(video);
          hlsPlayer.on(Hls.Events.MANIFEST_PARSED, () => {
            setStatus('En directo (HLS)');
            attemptPlay();
          });
          hlsPlayer.on(Hls.Events.ERROR, (event, data) => {
            if (data.fatal) {
              setStatus('Reconectando flujo HLS...', true);
              hlsPlayer.startLoad();
            }
          });
          return;
        } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
          video.src = streamUrl;
          attemptPlay();
          return;
        }
      }

      // Start MPEG-TS player (with auto-fallback to video-only if audio codec is unsupported by MSE)
      startMpegts(true);
    }

    function startMpegts(enableAudio) {
      if (typeof mpegts === 'undefined' || !mpegts.getFeatureList().mseLivePlayback) {
        // Native fallback (Safari / iOS)
        video.src = streamUrl;
        attemptPlay();
        return;
      }

      if (mpegPlayer) {
        try { mpegPlayer.destroy(); } catch (_) {}
        mpegPlayer = null;
      }

      try {
        mpegPlayer = mpegts.createPlayer({
          type: 'm2ts',
          isLive: true,
          url: streamUrl,
          hasAudio: enableAudio,
          hasVideo: true,
        }, {
          enableWorker: true,
          lazyLoad: false,
          stashInitialSize: 256,
          liveBufferLatencyChasing: true,
          autoCleanupSourceBuffer: true,
          fixAudioTimestampGap: false,
        });

        mpegPlayer.attachMediaElement(video);
        mpegPlayer.load();
        attemptPlay();

        mpegPlayer.on(mpegts.Events.ERROR, (type, detail) => {
          console.warn('mpegts error:', type, detail);
          // If browser MSE rejects the audio format (common with European TV MP2 audio)
          if (enableAudio && !fallbackToVideoOnlyTried && 
              (detail === 'MediaMSEError' || type === 'MediaError')) {
            fallbackToVideoOnlyTried = true;
            console.log('Falling back to video-only in browser MSE');
            if (audioNotice) audioNotice.style.display = 'block';
            setStatus('Audio MPEG-2 no soportado en web • Vídeo en directo', false);
            startMpegts(false);
            return;
          }
          setStatus('Reconectando...', true);
        });

        mpegPlayer.on(mpegts.Events.MEDIA_INFO, (info) => {
          console.log('Media info:', info);
          setStatus('En directo (MPEG-TS)');
        });
      } catch (e) {
        console.error('Failed to create mpegts player:', e);
        if (enableAudio && !fallbackToVideoOnlyTried) {
          fallbackToVideoOnlyTried = true;
          startMpegts(false);
        }
      }
    }

    function attemptPlay() {
      const promise = video.play();
      if (promise !== undefined) {
        promise.then(() => {
          setStatus('En directo');
        }).catch((err) => {
          // Browser autoplay restriction: mute and play
          video.muted = true;
          video.play().then(() => {
            unmuteBtn.style.display = 'block';
            setStatus('En directo (Audio silenciado)');
          }).catch(() => {
            setStatus('Pulsa el botón de reproducción');
          });
        });
      }
    }

    unmuteBtn.onclick = () => {
      video.muted = false;
      unmuteBtn.style.display = 'none';
      setStatus('En directo');
    };

    function reloadPlayer() {
      fallbackToVideoOnlyTried = false;
      if (audioNotice) audioNotice.style.display = 'none';
      if (mpegPlayer) {
        try { mpegPlayer.destroy(); } catch (_) {}
        mpegPlayer = null;
      }
      if (hlsPlayer) {
        try { hlsPlayer.destroy(); } catch (_) {}
        hlsPlayer = null;
      }
      initPlayer();
    }

    function copyText(text, btnId) {
      navigator.clipboard.writeText(text).then(() => {
        const btn = document.getElementById(btnId);
        if (btn) {
          const old = btn.textContent;
          btn.textContent = '¡Copiado!';
          setTimeout(() => { btn.textContent = old; }, 2000);
        }
      });
    }

    window.addEventListener('DOMContentLoaded', () => {
      document.getElementById('webUrlText').textContent = window.location.origin + '/';
      initPlayer();
    });
  </script>
</body>
</html>
''');
    await request.response.close();
  }

  /// Stop local streaming server
  Future<void> stopServer() async {
    _stopUpstream();
    for (final client in _clients) {
      try { client.close(); } catch (_) {}
    }
    _clients.clear();

    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      LogService.instance.info(
        LogCategory.server,
        'Servidor de reenvío LAN detenido',
      );
    }
    _clientsController.add(0);
  }
}
