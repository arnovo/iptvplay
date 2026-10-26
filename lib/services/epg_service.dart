import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';
import '../models/epg_program.dart';
import 'url_sanitizer_service.dart';

class EpgService {
  final Dio _dio;

  EpgService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 40),
                headers: {
                  'User-Agent': 'IPTVPlay/1.0.0 (Darwin; Apple Silicon)',
                },
                responseType: ResponseType.bytes,
              ),
            ) {
    _dio.interceptors.add(UrlSanitizerService.createSsrfInterceptor(allowInternalRelay: false));
  }

  /// Parse XMLTV timestamp: "20261025220000 +0100" or "20261025220000"
  DateTime? parseXmltvDate(String dateStr) {
    try {
      final clean = dateStr.trim();
      if (clean.length < 14) return null;
      final year = int.parse(clean.substring(0, 4));
      final month = int.parse(clean.substring(4, 6));
      final day = int.parse(clean.substring(6, 8));
      final hour = int.parse(clean.substring(8, 10));
      final minute = int.parse(clean.substring(10, 12));
      final second = int.parse(clean.substring(12, 14));

      // Check timezone offset if present
      if (clean.length >= 19 && (clean[14] == ' ' || clean[14] == '+' || clean[14] == '-')) {
        final sign = clean.contains('-') ? -1 : 1;
        final tzPart = clean.replaceAll(RegExp(r'[^0-9]'), '');
        if (tzPart.length >= 18) {
          final tzHour = int.parse(tzPart.substring(14, 16));
          final tzMin = int.parse(tzPart.substring(16, 18));
          final utc = DateTime.utc(year, month, day, hour, minute, second);
          final offset = Duration(hours: tzHour * sign, minutes: tzMin * sign);
          return utc.subtract(offset).toLocal();
        }
      }
      return DateTime(year, month, day, hour, minute, second);
    } catch (_) {
      return null;
    }
  }

  /// Downloads and parses XMLTV file (supports both raw .xml and compressed .xml.gz)
  Future<Map<String, List<EpgProgram>>> fetchAndParseXmltv(String url, {String? profileId}) async {
    try {
      final response = await _dio.get<List<int>>(url);
      if (response.data == null) return {};

      List<int> bytes = response.data!;
      // Check if gzipped (magic bytes 0x1F, 0x8B) or url ends with .gz
      if ((bytes.length > 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) || url.toLowerCase().endsWith('.gz')) {
        try {
          bytes = gzip.decode(bytes);
        } catch (_) {}
      }

      final xmlString = utf8.decode(bytes, allowMalformed: true);
      final programs = parseXmlString(xmlString);

      if (profileId != null && programs.isNotEmpty) {
        await saveEpgCache(profileId, programs);
      }

      return programs;
    } catch (e) {
      return {};
    }
  }

  /// Parses XML string into `Map<String, List<EpgProgram>>`
  Map<String, List<EpgProgram>> parseXmlString(String xmlString) {
    final Map<String, List<EpgProgram>> channelPrograms = {};
    try {
      final document = XmlDocument.parse(xmlString);
      final programmeElements = document.findAllElements('programme');

      int count = 0;
      for (final prog in programmeElements) {
        final channel = prog.getAttribute('channel') ?? '';
        final startStr = prog.getAttribute('start') ?? '';
        final stopStr = prog.getAttribute('stop') ?? '';

        final start = parseXmltvDate(startStr);
        final end = parseXmltvDate(stopStr);
        if (channel.isEmpty || start == null || end == null) continue;

        final title = prog.findElements('title').firstOrNull?.innerText.trim() ?? 'Sin título';
        final desc = prog.findElements('desc').firstOrNull?.innerText.trim();
        final icon = prog.findElements('icon').firstOrNull?.getAttribute('src');
        final category = prog.findElements('category').firstOrNull?.innerText.trim();

        final item = EpgProgram(
          id: '${channel}_${start.millisecondsSinceEpoch}',
          channelId: channel,
          title: title,
          description: desc,
          start: start,
          end: end,
          posterUrl: icon,
          category: category,
        );

        channelPrograms.putIfAbsent(channel, () => []).add(item);
        count++;
        // Limit to 5000 programs to keep memory snappy on low-end systems
        if (count > 5000) break;
      }

      // Sort programs by start time for each channel
      for (final list in channelPrograms.values) {
        list.sort((a, b) => a.start.compareTo(b.start));
      }
    } catch (_) {}

    return channelPrograms;
  }

  /// Fetches short EPG directly from Xtream Codes server
  Future<List<EpgProgram>> fetchXtreamShortEpg({
    required String serverUrl,
    required String username,
    required String password,
    required String streamId,
  }) async {
    try {
      final cleanServer = serverUrl.endsWith('/') ? serverUrl.substring(0, serverUrl.length - 1) : serverUrl;
      final apiUrl = '$cleanServer/player_api.php?username=$username&password=$password&action=get_short_epg&stream_id=$streamId&limit=10';

      final resp = await _dio.get(apiUrl, options: Options(responseType: ResponseType.json));
      if (resp.data != null && resp.data is Map && resp.data['epg_listings'] != null) {
        final listings = resp.data['epg_listings'] as List;
        final List<EpgProgram> result = [];

        for (final item in listings) {
          final titleRaw = item['title']?.toString() ?? '';
          final titleDecoded = _decodeBase64OrUtf8(titleRaw);
          final descRaw = item['description']?.toString() ?? '';
          final descDecoded = _decodeBase64OrUtf8(descRaw);
          final start = DateTime.tryParse(item['start']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch((int.tryParse(item['start_timestamp']?.toString() ?? '0') ?? 0) * 1000);
          final end = DateTime.tryParse(item['end']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch((int.tryParse(item['stop_timestamp']?.toString() ?? '0') ?? 0) * 1000);

          result.add(
            EpgProgram(
              id: item['id']?.toString() ?? '${streamId}_${start.millisecondsSinceEpoch}',
              channelId: streamId,
              title: titleDecoded.isNotEmpty ? titleDecoded : 'Programa',
              description: descDecoded.isNotEmpty ? descDecoded : null,
              start: start,
              end: end,
            ),
          );
        }

        result.sort((a, b) => a.start.compareTo(b.start));
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

  /// Disk Caching
  Future<void> saveEpgCache(String profileId, Map<String, List<EpgProgram>> programs) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${dir.path}/iptv_cache');
      if (!await cacheDir.exists()) await cacheDir.create(recursive: true);

      final file = File('${cacheDir.path}/epg_$profileId.json');
      final Map<String, dynamic> serializable = {};
      programs.forEach((channelId, list) {
        serializable[channelId] = list.map((p) => p.toJson()).toList();
      });

      await file.writeAsString(jsonEncode(serializable));
    } catch (_) {}
  }

  Future<Map<String, List<EpgProgram>>> loadEpgCache(String profileId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/iptv_cache/epg_$profileId.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> decoded = jsonDecode(content);
        final Map<String, List<EpgProgram>> result = {};
        decoded.forEach((channelId, list) {
          if (list is List) {
            result[channelId] = list.map((json) => EpgProgram.fromJson(json)).toList();
          }
        });
        return result;
      }
    } catch (_) {}
    return {};
  }
}
