import 'dart:convert';

enum PlaylistType {
  m3u,
  xtream,
}

class PlaylistProfile {
  final String id;
  final String name;
  final PlaylistType type;
  
  // M3U fields
  final String? m3uUrl;
  
  // Xtream Codes fields
  final String? serverUrl;
  final String? username;
  final String? password;

  final DateTime createdAt;
  final DateTime? lastUpdated;

  PlaylistProfile({
    required this.id,
    required this.name,
    required this.type,
    this.m3uUrl,
    this.serverUrl,
    this.username,
    this.password,
    required this.createdAt,
    this.lastUpdated,
  });

  PlaylistProfile copyWith({
    String? id,
    String? name,
    PlaylistType? type,
    String? m3uUrl,
    String? serverUrl,
    String? username,
    String? password,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return PlaylistProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      m3uUrl: m3uUrl ?? this.m3uUrl,
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'm3uUrl': m3uUrl,
      'serverUrl': serverUrl,
      'username': username,
      'password': password,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory PlaylistProfile.fromMap(Map<String, dynamic> map) {
    return PlaylistProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      type: PlaylistType.values.byName(map['type'] as String? ?? 'm3u'),
      m3uUrl: map['m3uUrl'] as String?,
      serverUrl: map['serverUrl'] as String?,
      username: map['username'] as String?,
      password: map['password'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastUpdated: map['lastUpdated'] != null ? DateTime.parse(map['lastUpdated'] as String) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory PlaylistProfile.fromJson(String source) =>
      PlaylistProfile.fromMap(json.decode(source) as Map<String, dynamic>);
}
