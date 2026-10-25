import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
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
  int _activeClients = 0;

  final StreamController<int> _clientsController = StreamController<int>.broadcast();
  Stream<int> get activeClientsStream => _clientsController.stream;

  bool get isRunning => _server != null;
  String? get targetStreamUrl => _targetStreamUrl;
  String? get targetTitle => _targetTitle;
  int get port => _port;
  String? get localIp => _localIp;
  int get activeClients => _activeClients;

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
    request.response.headers.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
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

    final acceptHeader = request.headers.value('accept')?.toLowerCase() ?? '';
    final isBrowserRequest = acceptHeader.contains('text/html') ||
        acceptHeader.contains('application/xhtml+xml');

    // Route to Web Player if client is a browser or accessing player routes
    if (path == '/' ||
        path == '/player' ||
        path == '/watch' ||
        (isBrowserRequest && (path == '/stream' || path.isEmpty))) {
      await _serveWebPlayer(request);
      return;
    }

    // Media stream endpoints for VLC, Smart TV, or in-browser MSE video tags
    if (path == '/stream' ||
        path == '/stream.ts' ||
        path == '/stream.m3u8' ||
        path == '/live' ||
        path == '/raw' ||
        path == '/video.ts') {
      await _serveMediaStream(request);
      return;
    }

    // Default: 404
    request.response.statusCode = HttpStatus.notFound;
    request.response.write('Ruta no encontrada');
    await request.response.close();
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
          <p style="font-size: 11px; color: var(--text-muted);">Pega esta URL en reproductores externos para reproducir el flujo continuo de alta definición.</p>
        </div>
      </div>

      <ul class="steps-list" style="margin-top: 18px;">
        <li><span class="step-num">1</span> Asegúrate de que el otro dispositivo esté conectado a la misma red Wi-Fi o cableada.</li>
        <li><span class="step-num">2</span> Para Smart TVs: abre VLC ("Abrir red"), TiviMate, SS IPTV o tu app IPTV preferida y pega el enlace directo.</li>
      </ul>
    </div>
  </div>

  <script>
    const streamUrl = '$mediaUrl';
    const video = document.getElementById('player');
    const statusBadge = document.getElementById('statusBadge');
    const unmuteBtn = document.getElementById('unmuteBtn');
    const isM3u8 = ${isM3u8 ? 'true' : 'false'};
    let mpegPlayer = null;
    let hlsPlayer = null;

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

      // MPEG-TS Playback via mpegts.js
      if (typeof mpegts !== 'undefined' && mpegts.getFeatureList().mseLivePlayback) {
        try {
          mpegPlayer = mpegts.createPlayer({
            type: 'mse',
            isLive: true,
            url: streamUrl
          }, {
            enableWorker: true,
            lazyLoad: false,
            stashInitialSize: 128,
            liveBufferLatencyChasing: true,
            autoCleanupSourceBuffer: true
          });
          mpegPlayer.attachMediaElement(video);
          mpegPlayer.load();
          attemptPlay();

          mpegPlayer.on(mpegts.Events.ERROR, (type, detail) => {
            console.warn('mpegts error:', type, detail);
            setStatus('Reconectando...', true);
          });
          mpegPlayer.on(mpegts.Events.MEDIA_INFO, () => {
            setStatus('En directo (MPEG-TS)');
          });
          return;
        } catch (e) {
          console.error('Failed to create mpegts player:', e);
        }
      }

      // Native fallback (Safari / iOS)
      video.src = streamUrl;
      attemptPlay();
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

  /// Serves the continuous raw media stream (MPEG-TS or HLS)
  Future<void> _serveMediaStream(HttpRequest request) async {
    if (_targetStreamUrl == null || _targetStreamUrl!.isEmpty) {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('No hay flujo activo para reenviar.');
      await request.response.close();
      return;
    }

    _activeClients++;
    _clientsController.add(_activeClients);

    final clientIp = request.connectionInfo?.remoteAddress.address ?? 'cliente';
    LogService.instance.info(
      LogCategory.server,
      'Cliente conectado al stream LAN ($clientIp). Clientes activos: $_activeClients',
    );

    final dio = Dio(
      BaseOptions(
        headers: {
          'User-Agent': 'IPTVPlay/1.0.0 (Darwin; Apple Silicon)',
          'Accept': '*/*',
        },
        responseType: ResponseType.stream,
      ),
    );

    CancelToken? cancelToken = CancelToken();

    try {
      final isM3u8 = _targetStreamUrl!.contains('.m3u8');
      final contentType = isM3u8 ? 'application/x-mpegURL' : 'video/mp2t';
      final filename = isM3u8 ? 'stream.m3u8' : 'stream.ts';

      request.response.headers.set('Content-Type', contentType);
      request.response.headers.set('Content-Disposition', 'inline; filename="$filename"');
      request.response.headers.set('Connection', 'keep-alive');
      request.response.headers.set('Cache-Control', 'no-cache, no-store, must-revalidate');

      final response = await dio.get<ResponseBody>(
        _targetStreamUrl!,
        cancelToken: cancelToken,
      );

      final stream = response.data?.stream;
      if (stream != null) {
        await request.response.addStream(stream);
      }
    } catch (_) {
      // Client disconnected or upstream ended
    } finally {
      cancelToken.cancel();
      try {
        await request.response.close();
      } catch (_) {}
      _activeClients = (_activeClients - 1).clamp(0, 999);
      _clientsController.add(_activeClients);

      LogService.instance.info(
        LogCategory.server,
        'Cliente desconectado del stream LAN ($clientIp). Clientes activos: $_activeClients',
      );
    }
  }

  /// Stop local streaming server
  Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      LogService.instance.info(
        LogCategory.server,
        'Servidor de reenvío LAN detenido',
      );
    }
    _activeClients = 0;
    _clientsController.add(0);
  }
}
