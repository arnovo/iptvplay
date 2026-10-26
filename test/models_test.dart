import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_play/models/channel.dart';
import 'package:iptv_play/models/vod_item.dart';
import 'package:iptv_play/models/series_item.dart';
import 'package:iptv_play/models/playlist_profile.dart';
import 'package:iptv_play/models/download_item.dart';
import 'package:iptv_play/models/epg_program.dart';
import 'package:iptv_play/models/sort_option.dart';

void main() {
  group('Models Unit Tests', () {
    test('Channel creation and Xtream parsing', () {
      final channel = Channel(
        id: 'ch_1',
        name: 'La 1 HD',
        url: 'http://stream.example.com/live/la1.m3u8',
        categoryId: 'cat_general',
        groupTitle: 'Generalistas',
        logoUrl: 'http://example.com/la1.png',
        epgChannelId: 'la1.es',
        channelNumber: 1,
      );

      expect(channel.id, 'ch_1');
      expect(channel.name, 'La 1 HD');
      expect(channel.categoryId, 'cat_general');
      expect(channel.groupTitle, 'Generalistas');

      final xtreamJson = {
        'stream_id': '101',
        'name': 'Antena 3',
        'stream_icon': 'http://example.com/a3.png',
        'category_id': '5',
        'num': '3',
      };

      final parsed = Channel.fromXtreamJson(
        xtreamJson,
        'http://server.com:80',
        'user',
        'pass',
      );

      expect(parsed.id, '101');
      expect(parsed.name, 'Antena 3');
      expect(parsed.url, 'http://server.com:80/live/user/pass/101.ts');
      expect(parsed.categoryId, '5');
      expect(parsed.channelNumber, 3);
    });

    test('VodItem creation and Xtream parsing', () {
      final vod = VodItem(
        id: 'vod_100',
        name: 'Inception (2010)',
        url: 'http://stream.example.com/movie/inception.mp4',
        categoryId: 'cat_action',
        posterUrl: 'http://image.tmdb.org/poster.jpg',
        rating: '8.8',
        releaseDate: '2010-07-16',
        containerExtension: 'mp4',
      );

      expect(vod.id, 'vod_100');
      expect(vod.name, 'Inception (2010)');
      expect(vod.rating, '8.8');
      expect(vod.categoryId, 'cat_action');

      final xtreamJson = {
        'stream_id': '505',
        'name': 'Interstellar',
        'stream_icon': 'http://example.com/interstellar.jpg',
        'category_id': '10',
        'rating': '8.6',
        'container_extension': 'mkv',
      };

      final parsed = VodItem.fromXtreamJson(
        xtreamJson,
        'http://server.com:80',
        'user',
        'pass',
      );

      expect(parsed.id, '505');
      expect(parsed.name, 'Interstellar');
      expect(parsed.url, 'http://server.com:80/movie/user/pass/505.mkv');
      expect(parsed.rating, '8.6');
      expect(parsed.containerExtension, 'mkv');
    });

    test('SeriesItem and SeriesEpisode structure and parsing', () {
      final episode = SeriesEpisode(
        id: 'ep_1',
        title: 'Piloto',
        episodeNum: 1,
        seasonNum: 1,
        url: 'http://stream.example.com/series/s01e01.mp4',
        containerExtension: 'mp4',
      );

      expect(episode.id, 'ep_1');
      expect(episode.episodeNum, 1);
      expect(episode.seasonNum, 1);

      final series = SeriesItem(
        id: 'series_1',
        name: 'Breaking Bad',
        categoryId: 'cat_drama',
        posterUrl: 'http://example.com/bb.jpg',
        rating: '9.5',
        episodes: [episode],
      );

      expect(series.id, 'series_1');
      expect(series.name, 'Breaking Bad');
      expect(series.episodes.length, 1);

      final xtreamJson = {
        'series_id': '777',
        'name': 'Stranger Things',
        'cover': 'http://example.com/st.jpg',
        'category_id': '3',
        'rating': '8.7',
      };

      final parsed = SeriesItem.fromXtreamJson(xtreamJson);
      expect(parsed.id, '777');
      expect(parsed.name, 'Stranger Things');
      expect(parsed.rating, '8.7');
    });

    test('PlaylistProfile M3U and Xtream toMap / fromMap', () {
      final now = DateTime.now();

      final m3uProfile = PlaylistProfile(
        id: 'p_m3u',
        name: 'Mi Lista M3U',
        type: PlaylistType.m3u,
        m3uUrl: 'http://example.com/lista.m3u',
        createdAt: now,
      );

      final map = m3uProfile.toMap();
      expect(map['id'], 'p_m3u');
      expect(map['type'], 'm3u');

      final fromMap = PlaylistProfile.fromMap(map);
      expect(fromMap.id, m3uProfile.id);
      expect(fromMap.name, m3uProfile.name);
      expect(fromMap.m3uUrl, 'http://example.com/lista.m3u');

      final xtreamProfile = PlaylistProfile(
        id: 'p_xc',
        name: 'Mi Servidor Xtream',
        type: PlaylistType.xtream,
        serverUrl: 'http://iptv.server:8080',
        username: 'user123',
        password: 'secret_password',
        createdAt: now,
      );

      final xcMap = xtreamProfile.toMap();
      final xcFromMap = PlaylistProfile.fromMap(xcMap);
      expect(xcFromMap.serverUrl, 'http://iptv.server:8080');
      expect(xcFromMap.username, 'user123');
      expect(xcFromMap.password, 'secret_password');
    });

    test('DownloadItem progress, formatted size, and copyWith', () {
      final item = DownloadItem(
        id: 'dl_1',
        title: 'Película HD',
        originalUrl: 'http://example.com/film.mp4',
        localFilePath: '/path/to/film.mp4',
        type: 'vod',
        totalBytes: 1000 * 1024 * 1024,
        downloadedBytes: 500 * 1024 * 1024,
        status: DownloadStatus.downloading,
        createdAt: DateTime.now(),
        speedBytesPerSecond: 5 * 1024 * 1024,
      );

      expect(item.progressFraction, 0.5);
      expect(item.formattedSize, '500.0 MB');
      expect(item.formattedSpeed, '5.0 MB/s');

      final completedItem = item.copyWith(
        status: DownloadStatus.completed,
        downloadedBytes: item.totalBytes,
      );
      expect(completedItem.progressFraction, 1.0);

      final json = item.toJson();
      final fromJson = DownloadItem.fromJson(json);
      expect(fromJson.id, item.id);
      expect(fromJson.title, item.title);
      expect(fromJson.status, DownloadStatus.downloading);
    });

    test('EpgProgram calculations for time range and progress', () {
      final now = DateTime.now();
      final program = EpgProgram(
        id: 'prog_1',
        channelId: 'ch_1',
        title: 'Telediario',
        start: now.subtract(const Duration(minutes: 15)),
        end: now.add(const Duration(minutes: 15)),
      );

      expect(program.isCurrent, isTrue);
      expect(program.isPast, isFalse);
      expect(program.isFuture, isFalse);
      expect(program.progressFraction, closeTo(0.5, 0.05));
      expect(program.durationText, '30 min');
      expect(program.formattedTimeRange, isNotEmpty);
    });

    test('SortOption labels and options check', () {
      expect(SortOption.defaultOrder.label, isNotEmpty);
      expect(SortOption.nameAsc.label, isNotEmpty);
      expect(SortOption.nameDesc.label, isNotEmpty);
      expect(SortOption.ratingDesc.label, isNotEmpty);
    });
  });
}
