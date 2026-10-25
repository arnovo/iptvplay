import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/app_log.dart';

class LogService {
  static final LogService instance = LogService._internal();
  LogService._internal() {
    _init();
  }

  static const int _maxInMemoryLogs = 500;
  final List<AppLog> _logs = [];
  final StreamController<List<AppLog>> _logStreamController = StreamController<List<AppLog>>.broadcast();

  Stream<List<AppLog>> get logStream => _logStreamController.stream;
  List<AppLog> get logs => List.unmodifiable(_logs);

  Future<File> _getLogFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/iptv_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return File('${cacheDir.path}/system_logs.json');
  }

  Future<void> _init() async {
    try {
      final file = await _getLogFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final List list = jsonDecode(content);
        _logs.clear();
        _logs.addAll(list.map((j) => AppLog.fromJson(j)));
        _logStreamController.add(_logs);
      }
    } catch (_) {}

    // Add startup log
    log(
      level: LogLevel.info,
      category: LogCategory.system,
      message: 'IPTV Play iniciado',
      details: 'OS: ${Platform.operatingSystem} (${Platform.version})',
    );
  }

  void log({
    required LogLevel level,
    required LogCategory category,
    required String message,
    String? details,
  }) {
    final item = AppLog(
      id: '${DateTime.now().millisecondsSinceEpoch}_${_logs.length}',
      timestamp: DateTime.now(),
      level: level,
      category: category,
      message: message,
      details: details,
    );

    _logs.insert(0, item);
    if (_logs.length > _maxInMemoryLogs) {
      _logs.removeRange(_maxInMemoryLogs, _logs.length);
    }

    _logStreamController.add(_logs);
    _schedulePersist();
  }

  void info(LogCategory category, String message, {String? details}) {
    log(level: LogLevel.info, category: category, message: message, details: details);
  }

  void warning(LogCategory category, String message, {String? details}) {
    log(level: LogLevel.warning, category: category, message: message, details: details);
  }

  void error(LogCategory category, String message, {String? details}) {
    log(level: LogLevel.error, category: category, message: message, details: details);
  }

  void success(LogCategory category, String message, {String? details}) {
    log(level: LogLevel.success, category: category, message: message, details: details);
  }

  Timer? _persistDebounce;
  void _schedulePersist() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(seconds: 2), () async {
      try {
        final file = await _getLogFile();
        final raw = jsonEncode(_logs.map((e) => e.toJson()).toList());
        await file.writeAsString(raw);
      } catch (_) {}
    });
  }

  Future<void> clearLogs() async {
    _logs.clear();
    _logStreamController.add(_logs);
    try {
      final file = await _getLogFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  String exportFormattedText() {
    final buffer = StringBuffer();
    buffer.writeln('=== REGISTROS DE SISTEMA IPTV PLAY ===');
    buffer.writeln('Fecha de exportación: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total de registros: ${_logs.length}\n');

    for (final l in _logs) {
      buffer.writeln('[${l.formattedDateTime}] [${l.level.label}] [${l.category.label}] ${l.message}');
      if (l.details != null && l.details!.isNotEmpty) {
        buffer.writeln('   Detalles: ${l.details}');
      }
    }
    return buffer.toString();
  }
}
