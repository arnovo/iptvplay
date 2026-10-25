import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/local_stream_server.dart';

class StreamServerProvider extends ChangeNotifier {
  final LocalStreamServer _server = LocalStreamServer();
  StreamSubscription<int>? _clientsSub;
  int _clientCount = 0;

  bool get isRunning => _server.isRunning;
  String? get streamUrl => _server.streamUrl;
  String? get targetTitle => _server.targetTitle;
  int get clientCount => _clientCount;
  String? get localIp => _server.localIp;
  int get port => _server.port;

  StreamServerProvider() {
    _clientsSub = _server.activeClientsStream.listen((count) {
      _clientCount = count;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _clientsSub?.cancel();
    _server.stopServer();
    super.dispose();
  }

  Future<String?> startSharing({
    required String targetStreamUrl,
    required String title,
  }) async {
    final url = await _server.startServer(
      targetStreamUrl: targetStreamUrl,
      title: title,
    );
    notifyListeners();
    return url;
  }

  Future<void> stopSharing() async {
    await _server.stopServer();
    _clientCount = 0;
    notifyListeners();
  }
}
