import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_log.dart';
import '../services/log_service.dart';

class LogProvider extends ChangeNotifier {
  final LogService _service = LogService.instance;
  StreamSubscription? _sub;

  LogLevel? _filterLevel;
  LogCategory? _filterCategory;
  String _searchQuery = '';

  LogLevel? get filterLevel => _filterLevel;
  LogCategory? get filterCategory => _filterCategory;
  String get searchQuery => _searchQuery;

  List<AppLog> get allLogs => _service.logs;

  int get totalCount => _service.logs.length;
  int get errorCount => _service.logs.where((l) => l.level == LogLevel.error).length;
  int get warningCount => _service.logs.where((l) => l.level == LogLevel.warning).length;
  int get infoCount => _service.logs.where((l) => l.level == LogLevel.info).length;
  int get successCount => _service.logs.where((l) => l.level == LogLevel.success).length;

  List<AppLog> get filteredLogs {
    return _service.logs.where((log) {
      if (_filterLevel != null && log.level != _filterLevel) return false;
      if (_filterCategory != null && log.category != _filterCategory) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesMsg = log.message.toLowerCase().contains(q);
        final matchesDet = log.details?.toLowerCase().contains(q) ?? false;
        final matchesCat = log.category.label.toLowerCase().contains(q);
        if (!matchesMsg && !matchesDet && !matchesCat) return false;
      }
      return true;
    }).toList();
  }

  LogProvider() {
    _sub = _service.logStream.listen((_) {
      notifyListeners();
    });
  }

  void setFilterLevel(LogLevel? level) {
    _filterLevel = level;
    notifyListeners();
  }

  void setFilterCategory(LogCategory? category) {
    _filterCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> clearLogs() async {
    await _service.clearLogs();
    notifyListeners();
  }

  String exportFormattedText() {
    return _service.exportFormattedText();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
