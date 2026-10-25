import 'package:flutter/foundation.dart';
import '../models/playlist_profile.dart';
import '../models/channel.dart';
import '../models/vod_item.dart';
import '../models/series_item.dart';
import '../services/iptv_repository.dart';

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

  LoadedContent get content => _content;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get selectedLiveCategoryId => _selectedLiveCategoryId;
  String get selectedVodCategoryId => _selectedVodCategoryId;
  String get selectedSeriesCategoryId => _selectedSeriesCategoryId;

  String get liveSearchQuery => _liveSearchQuery;
  String get vodSearchQuery => _vodSearchQuery;
  String get seriesSearchQuery => _seriesSearchQuery;

  // Filtered lists
  List<Channel> get filteredChannels {
    return _content.channels.where((channel) {
      final matchesCategory = _selectedLiveCategoryId == 'all' ||
          channel.categoryId == _selectedLiveCategoryId;
      final matchesQuery = _liveSearchQuery.isEmpty ||
          channel.name.toLowerCase().contains(_liveSearchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<VodItem> get filteredVods {
    return _content.vods.where((vod) {
      final matchesCategory = _selectedVodCategoryId == 'all' ||
          vod.categoryId == _selectedVodCategoryId;
      final matchesQuery = _vodSearchQuery.isEmpty ||
          vod.name.toLowerCase().contains(_vodSearchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<SeriesItem> get filteredSeries {
    return _content.series.where((series) {
      final matchesCategory = _selectedSeriesCategoryId == 'all' ||
          series.categoryId == _selectedSeriesCategoryId;
      final matchesQuery = _seriesSearchQuery.isEmpty ||
          series.name.toLowerCase().contains(_seriesSearchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  Future<void> loadCatalog(PlaylistProfile profile, {bool forceRefresh = false}) async {
    _errorMessage = null;

    // 1. Try to load local disk cache first for instant startup
    if (!forceRefresh) {
      final cached = await _repository.getCachedContent(profile.id);
      if (cached != null && (cached.channels.isNotEmpty || cached.vods.isNotEmpty || cached.series.isNotEmpty)) {
        _content = cached;
        _isLoading = false;
        notifyListeners();
        return;
      }
    }

    // 2. If no cache or forceRefresh is true, fetch from network
    _isLoading = true;
    notifyListeners();

    try {
      _content = await _repository.loadProfileContent(profile);
      await _repository.saveCachedContent(profile.id, _content);
      _selectedLiveCategoryId = 'all';
      _selectedVodCategoryId = 'all';
      _selectedSeriesCategoryId = 'all';
    } catch (e) {
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
