import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/app_log.dart';
import '../models/channel.dart';
import '../services/log_service.dart';

class MultiviewSlot {
  final int index;
  final Player player;
  final VideoController controller;
  Channel? channel;
  bool isMuted;
  bool isPlaying;

  MultiviewSlot({
    required this.index,
    required this.player,
    required this.controller,
    this.channel,
    this.isMuted = true,
    this.isPlaying = false,
  });
}

class MultiviewProvider extends ChangeNotifier {
  static const int maxSlots = 4;

  final List<MultiviewSlot> _slots = [];
  int _activeGridCount = 4; // 2, 3 or 4
  int _focusedSlotIndex = 0;

  List<MultiviewSlot> get slots => _slots.take(_activeGridCount).toList();
  int get activeGridCount => _activeGridCount;
  int get focusedSlotIndex => _focusedSlotIndex;

  MultiviewProvider() {
    for (int i = 0; i < maxSlots; i++) {
      final player = Player();
      final controller = VideoController(player);
      final isFirst = i == 0;

      // Only the first slot is unmuted by default
      if (!isFirst) {
        player.setVolume(0);
      }

      final slot = MultiviewSlot(
        index: i,
        player: player,
        controller: controller,
        isMuted: !isFirst,
      );

      player.stream.playing.listen((playing) {
        slot.isPlaying = playing;
        notifyListeners();
      });

      _slots.add(slot);
    }
  }

  void setGridCount(int count) {
    if (count < 1 || count > maxSlots) return;
    _activeGridCount = count;
    if (_focusedSlotIndex >= count) {
      setFocusedSlot(0);
    }
    notifyListeners();
  }

  Future<void> setFocusedSlot(int index) async {
    if (index < 0 || index >= _activeGridCount) return;
    _focusedSlotIndex = index;

    for (int i = 0; i < maxSlots; i++) {
      final slot = _slots[i];
      if (i == index) {
        slot.isMuted = false;
        await slot.player.setVolume(100);
      } else {
        slot.isMuted = true;
        await slot.player.setVolume(0);
      }
    }

    notifyListeners();
  }

  Future<void> playInSlot(int index, Channel channel) async {
    if (index < 0 || index >= maxSlots) return;
    final slot = _slots[index];
    slot.channel = channel;

    LogService.instance.info(
      LogCategory.player,
      'Multiview: Canal asignado al recuadro ${index + 1}',
      details: '${channel.name} (${channel.url})',
    );

    // Apply volume according to focus
    final shouldBeAudible = index == _focusedSlotIndex;
    slot.isMuted = !shouldBeAudible;
    await slot.player.setVolume(shouldBeAudible ? 100 : 0);
    await slot.player.open(Media(channel.url));

    notifyListeners();
  }

  Future<void> closeSlot(int index) async {
    if (index < 0 || index >= maxSlots) return;
    final slot = _slots[index];
    await slot.player.stop();
    slot.channel = null;
    slot.isPlaying = false;
    notifyListeners();
  }

  Future<void> stopAll() async {
    for (final slot in _slots) {
      await slot.player.stop();
      slot.channel = null;
      slot.isPlaying = false;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    for (final slot in _slots) {
      slot.player.dispose();
    }
    _slots.clear();
    super.dispose();
  }
}
