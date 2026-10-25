class Channel {
  final String id;
  final String name;
  final String url;
  final String? logoUrl;
  final String categoryId;
  final String? groupTitle;
  final String? epgChannelId;
  final int? channelNumber;

  Channel({
    required this.id,
    required this.name,
    required this.url,
    this.logoUrl,
    required this.categoryId,
    this.groupTitle,
    this.epgChannelId,
    this.channelNumber,
  });

  factory Channel.fromXtreamJson(Map<String, dynamic> json, String serverUrl, String username, String password) {
    final streamId = json['stream_id']?.toString() ?? json['num']?.toString() ?? '';
    final rawUrl = '$serverUrl/live/$username/$password/$streamId.ts';
    
    return Channel(
      id: streamId,
      name: json['name']?.toString() ?? 'Canal sin nombre',
      url: rawUrl,
      logoUrl: json['stream_icon']?.toString(),
      categoryId: json['category_id']?.toString() ?? 'all',
      epgChannelId: json['epg_channel_id']?.toString(),
      channelNumber: int.tryParse(json['num']?.toString() ?? ''),
    );
  }
}
