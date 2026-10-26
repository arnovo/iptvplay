import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iptv_play/providers/user_activity_provider.dart';
import 'package:iptv_play/models/channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserActivityProvider Behavioral Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Toggles live channel favorite and updates state reactively', () async {
      final provider = UserActivityProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.isFavorite('ch_1', 'live'), isFalse);

      await provider.toggleFavorite('ch_1', 'live');
      expect(provider.isFavorite('ch_1', 'live'), isTrue);
      expect(provider.favLive.contains('ch_1'), isTrue);

      await provider.toggleFavorite('ch_1', 'live');
      expect(provider.isFavorite('ch_1', 'live'), isFalse);
    });

    test('Adds and removes recent channels correctly', () async {
      final provider = UserActivityProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final channelA = Channel(
        id: 'ch_a',
        name: 'Canal A',
        url: 'http://example.com/a.m3u8',
        categoryId: 'all',
      );

      final channelB = Channel(
        id: 'ch_b',
        name: 'Canal B',
        url: 'http://example.com/b.m3u8',
        categoryId: 'all',
      );

      await provider.addRecentChannel(channelA);
      await provider.addRecentChannel(channelB);

      expect(provider.recentChannels.length, 2);
      expect(provider.recentChannels.first.id, 'ch_b'); // Most recent first

      await provider.removeRecentChannel('ch_b');
      expect(provider.recentChannels.length, 1);
      expect(provider.recentChannels.first.id, 'ch_a');

      await provider.clearRecentChannels();
      expect(provider.recentChannels.isEmpty, isTrue);
    });

    test('Records playback progress for resume watching', () async {
      final provider = UserActivityProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.saveProgress(
        id: 'vod_99',
        title: 'Matrix',
        type: 'vod',
        positionSeconds: 1800, // 30 minutes
        durationSeconds: 7200, // 2 hours
        url: 'http://example.com/matrix.mp4',
        posterUrl: 'http://example.com/poster.jpg',
      );

      final progress = provider.getProgress('vod_99');
      expect(progress, isNotNull);
      expect(progress!.positionSeconds, 1800);
      expect(progress.progressFraction, 0.25);
      expect(provider.continueWatching.length, 1);
      expect(provider.continueWatching.first.id, 'vod_99');
    });
  });
}
