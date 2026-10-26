import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_play/services/m3u_parser_service.dart';

void main() {
  group('M3uParserService Unit Tests', () {
    late M3uParserService parser;

    setUp(() {
      parser = M3uParserService();
    });

    test('Parses live channels correctly with metadata', () {
      const rawM3u = '''#EXTM3U
#EXTINF:-1 tvg-id="antena3.es" tvg-name="Antena 3" tvg-logo="https://example.com/a3.png" group-title="Generalistas",Antena 3 HD
https://stream.example.com/antena3/live.m3u8
#EXTINF:-1 tvg-id="telecinco.es" tvg-logo="https://example.com/t5.png" group-title="Generalistas",Telecinco
https://stream.example.com/t5/live.m3u8
''';

      final result = parser.parseContent(rawM3u);

      expect(result.channels.length, 2);
      expect(result.channels[0].name, 'Antena 3 HD');
      expect(result.channels[0].epgChannelId, 'antena3.es');
      expect(result.channels[0].logoUrl, 'https://example.com/a3.png');
      expect(result.channels[0].groupTitle, 'Generalistas');
      expect(result.channels[0].url, 'https://stream.example.com/antena3/live.m3u8');

      expect(result.channels[1].name, 'Telecinco');
      expect(result.channels[1].groupTitle, 'Generalistas');
      expect(result.liveCategories.length, 1);
      expect(result.liveCategories.first.name, 'Generalistas');
    });

    test('Identifies VOD movies by video extension', () {
      const rawM3u = '''#EXTM3U
#EXTINF:-1 tvg-logo="https://example.com/gladiator.jpg" group-title="Películas Acción",Gladiator (2000)
https://stream.example.com/vod/gladiator.mp4
#EXTINF:-1 tvg-logo="https://example.com/interstellar.jpg" group-title="Películas Sci-Fi",Interstellar (2014)
https://stream.example.com/vod/interstellar.mkv
''';

      final result = parser.parseContent(rawM3u);

      expect(result.vods.length, 2);
      expect(result.vods[0].name, 'Gladiator (2000)');
      expect(result.vods[0].categoryId, 'películas_acción');
      expect(result.vods[1].name, 'Interstellar (2014)');
      expect(result.vodCategories.length, 2);
    });

    test('Identifies series entries properly', () {
      const rawM3u = '''#EXTM3U
#EXTINF:-1 group-title="Series Drama",Stranger Things S01E01
https://stream.example.com/series/st_s01e01.mp4
''';

      final result = parser.parseContent(rawM3u);

      expect(result.series.length, 1);
      expect(result.series.first.name, 'Stranger Things S01E01');
      expect(result.series.first.episodes.length, 1);
      expect(result.series.first.episodes[0].seasonNum, 1);
      expect(result.series.first.episodes[0].episodeNum, 1);
    });

    test('Gracefully ignores invalid lines and comments', () {
      const rawM3u = '''
#EXTM3U
# Un comentario cualquiera
#EXTINF:-1,Canal Válido
https://stream.example.com/live.m3u8

# Línea vacía siguiente
''';

      final result = parser.parseContent(rawM3u);
      expect(result.channels.length, 1);
      expect(result.channels.first.name, 'Canal Válido');
    });
  });
}
