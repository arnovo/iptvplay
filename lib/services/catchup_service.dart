import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/catchup_item.dart';
import '../models/playlist_profile.dart';
import 'url_sanitizer_service.dart';

class CatchupService {
  final Dio _dio;

  CatchupService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                headers: {
                  'User-Agent': 'IPTVPlay/1.0.0 (Darwin; Apple Silicon)',
                },
              ),
            ) {
    _dio.interceptors.add(UrlSanitizerService.createSsrfInterceptor(allowInternalRelay: false));
  }

  /// Fetch archived TV broadcasts from Xtream Codes
  Future<List<CatchupItem>> getXtreamCatchupPrograms({
    required PlaylistProfile profile,
    required String streamId,
  }) async {
    if (profile.type != PlaylistType.xtream || profile.serverUrl == null || profile.username == null || profile.password == null) {
      return [];
    }

    final server = profile.serverUrl!;
    final cleanServer = server.endsWith('/') ? server.substring(0, server.length - 1) : server;
    final apiUrl = '$cleanServer/player_api.php?username=${profile.username}&password=${profile.password}&action=get_simple_data_table&stream_id=$streamId';

    try {
      final response = await _dio.get(apiUrl);
      if (response.data != null && response.data is Map && response.data['epg_listings'] != null) {
        final List listings = response.data['epg_listings'];
        final List<CatchupItem> result = [];
        final now = DateTime.now();

        for (final item in listings) {
          final start = DateTime.tryParse(item['start']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch((int.tryParse(item['start_timestamp']?.toString() ?? '0') ?? 0) * 1000);
          final end = DateTime.tryParse(item['end']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch((int.tryParse(item['stop_timestamp']?.toString() ?? '0') ?? 0) * 1000);

          // Only past programs can be replayed
          if (start.isAfter(now)) continue;

          final durationMinutes = end.difference(start).inMinutes;
          if (durationMinutes <= 0) continue;

          String twoDigits(int n) => n.toString().padLeft(2, '0');
          final formattedStart = '${start.year}-${twoDigits(start.month)}-${twoDigits(start.day)}:${twoDigits(start.hour)}-${twoDigits(start.minute)}';
          final replayUrl = '$cleanServer/timeshift.php?username=${profile.username}&password=${profile.password}&duration=$durationMinutes&start=$formattedStart/$streamId.ts';

          final titleRaw = item['title']?.toString() ?? 'Programa Replay';
          final titleDecoded = _decodeBase64OrUtf8(titleRaw);
          final descRaw = item['description']?.toString() ?? '';
          final descDecoded = _decodeBase64OrUtf8(descRaw);

          result.add(
            CatchupItem(
              id: item['id']?.toString() ?? '${streamId}_${start.millisecondsSinceEpoch}',
              streamId: streamId,
              title: titleDecoded,
              description: descDecoded.isNotEmpty ? descDecoded : null,
              start: start,
              end: end,
              durationMinutes: durationMinutes,
              streamUrl: replayUrl,
            ),
          );
        }

        // Sort latest broadcast first
        result.sort((a, b) => b.start.compareTo(a.start));
        return result;
      }
    } catch (_) {}

    return [];
  }

  String _decodeBase64OrUtf8(String input) {
    try {
      return utf8.decode(base64Decode(input));
    } catch (_) {
      return input;
    }
  }
}
