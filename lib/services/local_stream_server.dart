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

  /// Raw media stream URL for VLC, Smart TV, Kodi, Infuse (stream.ts)
  String? get rawStreamUrl {
    if (_server == null || _localIp == null) return null;
    final isM3u8 = _targetStreamUrl?.contains('.m3u8') ?? false;
    final ext = isM3u8 ? 'm3u8' : 'ts';
    return 'http://$_localIp:$_port/stream.$ext';
  }

  /// Default stream URL (points directly to stream.ts)
  String? get streamUrl => rawStreamUrl;

  /// Web player URL backwards-compatibility (points to rawStreamUrl)
  String? get webPlayerUrl => rawStreamUrl;

  /// Localhost stream URL for local player loopback
  String? get localStreamUrl {
    if (_server == null) return null;
    final isM3u8 = _targetStreamUrl?.contains('.m3u8') ?? false;
    final ext = isM3u8 ? 'm3u8' : 'ts';
    return 'http://127.0.0.1:$_port/stream.$ext';
  }

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
      'Servidor de reenvío LAN iniciado en $rawStreamUrl',
      details: 'Canal: "$title" | Destino: $targetStreamUrl',
    );

    return rawStreamUrl;
  }

  void _handleHttpRequest(HttpRequest request) async {
    // Add CORS headers for media players and Smart TVs
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

    // Direct all requests (/, /stream, /stream.ts, /stream.m3u8, etc.) to the media stream
    await _handleMediaRequest(request);
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
