class VodItem {
  final String id;
  final String name;
  final String url;
  final String? posterUrl;
  final String categoryId;
  final String? rating;
  final String? releaseDate;
  final String? containerExtension;

  VodItem({
    required this.id,
    required this.name,
    required this.url,
    this.posterUrl,
    required this.categoryId,
    this.rating,
    this.releaseDate,
    this.containerExtension,
  });

  factory VodItem.fromXtreamJson(Map<String, dynamic> json, String serverUrl, String username, String password) {
    final streamId = json['stream_id']?.toString() ?? json['num']?.toString() ?? '';
    final ext = json['container_extension']?.toString() ?? 'mp4';
    final rawUrl = '$serverUrl/movie/$username/$password/$streamId.$ext';

    return VodItem(
      id: streamId,
      name: json['name']?.toString() ?? 'Película',
      url: rawUrl,
      posterUrl: json['stream_icon']?.toString(),
      categoryId: json['category_id']?.toString() ?? 'all',
      rating: json['rating']?.toString(),
      releaseDate: json['added']?.toString(),
      containerExtension: ext,
    );
  }
}
