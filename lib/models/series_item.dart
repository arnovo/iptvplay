class SeriesEpisode {
  final String id;
  final String title;
  final int episodeNum;
  final int seasonNum;
  final String url;
  final String? containerExtension;
  final String? info;

  SeriesEpisode({
    required this.id,
    required this.title,
    required this.episodeNum,
    required this.seasonNum,
    required this.url,
    this.containerExtension,
    this.info,
  });

  factory SeriesEpisode.fromXtreamJson(
    Map<String, dynamic> json,
    String serverUrl,
    String username,
    String password,
  ) {
    final epId = json['id']?.toString() ?? '';
    final ext = json['container_extension']?.toString() ?? 'mp4';
    final rawUrl = '$serverUrl/series/$username/$password/$epId.$ext';

    return SeriesEpisode(
      id: epId,
      title: json['title']?.toString() ?? 'Episodio ${json['episode_num']}',
      episodeNum: int.tryParse(json['episode_num']?.toString() ?? '1') ?? 1,
      seasonNum: int.tryParse(json['season']?.toString() ?? '1') ?? 1,
      url: rawUrl,
      containerExtension: ext,
      info: json['info']?['plot']?.toString(),
    );
  }
}

class SeriesItem {
  final String id;
  final String name;
  final String? posterUrl;
  final String categoryId;
  final String? rating;
  final String? releaseDate;
  final String? plot;
  final List<SeriesEpisode> episodes;

  SeriesItem({
    required this.id,
    required this.name,
    this.posterUrl,
    required this.categoryId,
    this.rating,
    this.releaseDate,
    this.plot,
    this.episodes = const [],
  });

  factory SeriesItem.fromXtreamJson(Map<String, dynamic> json) {
    return SeriesItem(
      id: json['series_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Serie',
      posterUrl: json['cover']?.toString(),
      categoryId: json['category_id']?.toString() ?? 'all',
      rating: json['rating']?.toString(),
      releaseDate: json['releaseDate']?.toString(),
      plot: json['plot']?.toString(),
    );
  }

  SeriesItem copyWithEpisodes(List<SeriesEpisode> newEpisodes) {
    return SeriesItem(
      id: id,
      name: name,
      posterUrl: posterUrl,
      categoryId: categoryId,
      rating: rating,
      releaseDate: releaseDate,
      plot: plot,
      episodes: newEpisodes,
    );
  }
}
