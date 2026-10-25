import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist_profile.dart';
import '../models/channel.dart';
import '../models/vod_item.dart';
import '../models/series_item.dart';
import '../models/sort_option.dart';
import '../models/app_log.dart';
import '../services/iptv_repository.dart';
import '../services/log_service.dart';

class CatalogProvider extends ChangeNotifier {
  final IptvRepository _repository = IptvRepository();

  LoadedContent _content = LoadedContent.empty();
  bool _isLoading = false;
  String? _errorMessage;

  // Selected categories
  String _selectedLiveCategoryId = 'all';
  String _selectedVodCategoryId = 'all';
  String _selectedSeriesCategoryId = 'all';

  // Search queries
  String _liveSearchQuery = '';
  String _vodSearchQuery = '';
  String _seriesSearchQuery = '';

  // Sort options
  SortOption _liveSort = SortOption.defaultOrder;
  SortOption _vodSort = SortOption.defaultOrder;
  SortOption _seriesSort = SortOption.defaultOrder;

  CatalogProvider() {
    _loadSavedSortOptions();
  }

  Future<void> _loadSavedSortOptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final liveKey = prefs.getString('pref_live_sort');
      final vodKey = prefs.getString('pref_vod_sort');
      final seriesKey = prefs.getString('pref_series_sort');

      if (liveKey != null) _liveSort = SortOption.fromKey(liveKey);
      if (vodKey != null) _vodSort = SortOption.fromKey(vodKey);
      if (seriesKey != null) _seriesSort = SortOption.fromKey(seriesKey);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setLiveSort(SortOption option) async {
    _liveSort = option;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_live_sort', option.key);
  }

  Future<void> setVodSort(SortOption option) async {
    _vodSort = option;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_vod_sort', option.key);
  }

  Future<void> setSeriesSort(SortOption option) async {
    _seriesSort = option;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_series_sort', option.key);
  }

  LoadedContent get content => _content;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get selectedLiveCategoryId => _selectedLiveCategoryId;
  String get selectedVodCategoryId => _selectedVodCategoryId;
  String get selectedSeriesCategoryId => _selectedSeriesCategoryId;

  String get liveSearchQuery => _liveSearchQuery;
  String get vodSearchQuery => _vodSearchQuery;
  String get seriesSearchQuery => _seriesSearchQuery;

  SortOption get liveSort => _liveSort;
  SortOption get vodSort => _vodSort;
  SortOption get seriesSort => _seriesSort;

  // Helpers for date/rating sorting
  int _parseDateOrTimestamp(String? val) {
    if (val == null || val.isEmpty) return 0;
    final timestamp = int.tryParse(val);
    if (timestamp != null) return timestamp;
    final dt = DateTime.tryParse(val);
    if (dt != null) return dt.millisecondsSinceEpoch ~/ 1000;
    return 0;
  }

  List<Channel> sortChannels(List<Channel> list) {
    final copy = List<Channel>.from(list);
    switch (_liveSort) {
      case SortOption.nameAsc:
        copy.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOption.nameDesc:
        copy.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      default:
        break;
    }
    return copy;
  }

  List<VodItem> sortVods(List<VodItem> list) {
    final copy = List<VodItem>.from(list);
    switch (_vodSort) {
      case SortOption.nameAsc:
        copy.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOption.nameDesc:
        copy.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case SortOption.dateDesc:
        copy.sort((a, b) => _parseDateOrTimestamp(b.releaseDate).compareTo(_parseDateOrTimestamp(a.releaseDate)));
        break;
      case SortOption.dateAsc:
        copy.sort((a, b) => _parseDateOrTimestamp(a.releaseDate).compareTo(_parseDateOrTimestamp(b.releaseDate)));
        break;
      case SortOption.ratingDesc:
        copy.sort((a, b) => (double.tryParse(b.rating ?? '') ?? 0.0).compareTo(double.tryParse(a.rating ?? '') ?? 0.0));
        break;
      default:
        break;
    }
    return copy;
  }

  List<SeriesItem> sortSeries(List<SeriesItem> list) {
    final copy = List<SeriesItem>.from(list);
    switch (_seriesSort) {
      case SortOption.nameAsc:
        copy.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOption.nameDesc:
        copy.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case SortOption.dateDesc:
        copy.sort((a, b) => _parseDateOrTimestamp(b.releaseDate).compareTo(_parseDateOrTimestamp(a.releaseDate)));
        break;
      case SortOption.dateAsc:
        copy.sort((a, b) => _parseDateOrTimestamp(a.releaseDate).compareTo(_parseDateOrTimestamp(b.releaseDate)));
        break;
      case SortOption.ratingDesc:
        copy.sort((a, b) => (double.tryParse(b.rating ?? '') ?? 0.0).compareTo(double.tryParse(a.rating ?? '') ?? 0.0));
        break;
      default:
        break;
    }
    return copy;
  }

  // Filtered lists
  List<Channel> get filteredChannels {
    final filtered = _content.channels.where((channel) {
      final matchesCategory = _selectedLiveCategoryId == 'all' ||
          channel.categoryId == _selectedLiveCategoryId;
      final matchesQuery = _liveSearchQuery.isEmpty ||
          channel.name.toLowerCase().contains(_liveSearchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
    return sortChannels(filtered);
  }

  List<VodItem> get filteredVods {
    final filtered = _content.vods.where((vod) {
      final matchesCategory = _selectedVodCategoryId == 'all' ||
          vod.categoryId == _selectedVodCategoryId;
      final matchesQuery = _vodSearchQuery.isEmpty ||
          vod.name.toLowerCase().contains(_vodSearchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
    return sortVods(filtered);
  }

  List<SeriesItem> get filteredSeries {
    final filtered = _content.series.where((series) {
      final matchesCategory = _selectedSeriesCategoryId == 'all' ||
          series.categoryId == _selectedSeriesCategoryId;
      final matchesQuery = _seriesSearchQuery.isEmpty ||
          series.name.toLowerCase().contains(_seriesSearchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
    return sortSeries(filtered);
  }

  Future<void> loadCatalog(PlaylistProfile profile, {bool forceRefresh = false}) async {
    _errorMessage = null;

    // 1. Try to load local disk cache first for instant startup
    if (!forceRefresh) {
      final cached = await _repository.getCachedContent(profile.id);
      if (cached != null && (cached.channels.isNotEmpty || cached.vods.isNotEmpty || cached.series.isNotEmpty)) {
        _content = cached;
        _isLoading = false;
        LogService.instance.info(
          LogCategory.network,
          'Catálogo cargado desde caché local para perfil "${profile.name}"',
          details: '${cached.channels.length} canales • ${cached.vods.length} películas • ${cached.series.length} series',
        );
        notifyListeners();
        return;
      }
    }

    // 2. If no cache or forceRefresh is true, fetch from network
    _isLoading = true;
    notifyListeners();

    LogService.instance.info(
      LogCategory.network,
      'Sincronizando catálogo desde servidor IPTV para perfil "${profile.name}"...',
      details: 'Servidor: ${profile.serverUrl ?? profile.m3uUrl ?? "M3U"}',
    );

    try {
      _content = await _repository.loadProfileContent(profile);
      await _repository.saveCachedContent(profile.id, _content);
      _selectedLiveCategoryId = 'all';
      _selectedVodCategoryId = 'all';
      _selectedSeriesCategoryId = 'all';
      LogService.instance.success(
        LogCategory.network,
        'Catálogo sincronizado con éxito para "${profile.name}"',
        details: '${_content.channels.length} canales • ${_content.vods.length} películas • ${_content.series.length} series',
      );
    } catch (e) {
      LogService.instance.error(
        LogCategory.network,
        'Fallo al sincronizar catálogo para "${profile.name}"',
        details: e.toString(),
      );
      final cached = await _repository.getCachedContent(profile.id);
      if (cached != null) {
        _content = cached;
      } else {
        _errorMessage = 'Error al cargar contenido: $e';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCatalog(PlaylistProfile profile) async {
    await loadCatalog(profile, forceRefresh: true);
  }

  void setLiveCategory(String categoryId) {
    _selectedLiveCategoryId = categoryId;
    notifyListeners();
  }

  void setVodCategory(String categoryId) {
    _selectedVodCategoryId = categoryId;
    notifyListeners();
  }

  void setSeriesCategory(String categoryId) {
    _selectedSeriesCategoryId = categoryId;
    notifyListeners();
  }

  void setLiveSearch(String query) {
    _liveSearchQuery = query;
    notifyListeners();
  }

  void setVodSearch(String query) {
    _vodSearchQuery = query;
    notifyListeners();
  }

  void setSeriesSearch(String query) {
    _seriesSearchQuery = query;
    notifyListeners();
  }

  Future<List<SeriesEpisode>> loadEpisodesForSeries(PlaylistProfile profile, SeriesItem series) async {
    if (series.episodes.isNotEmpty && series.episodes.first.url.isNotEmpty) {
      return series.episodes;
    }
    try {
      final episodes = await _repository.loadSeriesEpisodes(profile, series.id);
      final index = _content.series.indexWhere((s) => s.id == series.id);
      if (index >= 0) {
        _content.series[index] = series.copyWithEpisodes(episodes);
        notifyListeners();
      }
      return episodes;
    } catch (_) {
      return [];
    }
  }
}
