import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

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

  String? get streamUrl {
    if (_server == null || _localIp == null) return null;
    return 'http://$_localIp:$_port/stream';
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
      return null;
    }

    _server!.listen(_handleHttpRequest);

    return streamUrl;
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

    if (path == '/stream' || path == '/live' || path == '/video.ts') {
      if (_targetStreamUrl == null || _targetStreamUrl!.isEmpty) {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('No hay flujo activo para reenviar.');
        await request.response.close();
        return;
      }

      _activeClients++;
      _clientsController.add(_activeClients);

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
        // Forward content headers based on source
        final isM3u8 = _targetStreamUrl!.contains('.m3u8');
        final contentType = isM3u8 ? 'application/x-mpegURL' : 'video/mp2t';
        request.response.headers.set('Content-Type', contentType);
        request.response.headers.set('Connection', 'keep-alive');
        request.response.headers.set('Cache-Control', 'no-cache, no-store');

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
      }
    } else {
      // Default info page
      request.response.headers.contentType = ContentType.html;
      request.response.write('''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>IPTV Play LAN Stream</title>
  <style>
    body { font-family: -apple-system, sans-serif; background: #0f172a; color: #f8fafc; padding: 40px; text-align: center; }
    h1 { color: #00e5ff; }
    .box { background: #1e293b; padding: 20px; border-radius: 12px; display: inline-block; margin-top: 20px; }
    code { background: #000; padding: 8px 16px; border-radius: 6px; color: #00e5ff; font-size: 16px; }
  </style>
</head>
<body>
  <h1>📡 Reenvío de Vídeo Activo</h1>
  <p>Canal / Vídeo: <strong>${_targetTitle ?? 'IPTV Stream'}</strong></p>
  <div class="box">
    <p>URL del Stream en Red Local:</p>
    <code>$streamUrl</code>
  </div>
  <p style="margin-top: 20px; color: #94a3b8;">Copia esta URL en VLC, Smart TV, Infuse o cualquier reproductor.</p>
</body>
</html>
''');
      await request.response.close();
    }
  }

  /// Stop local streaming server
  Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
    _activeClients = 0;
    _clientsController.add(0);
  }
}
