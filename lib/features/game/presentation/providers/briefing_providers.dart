// Created by Hamza Ali on 2026-11-25.
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/logic/role_allocator.dart';
import '../../domain/entities/game_room_entity.dart';

// Screen-scoped dismissal is reset when the room returns to its lobby.
final briefingDismissedProvider =
    StateProvider.autoDispose.family<bool, String>((ref, session) => false);
final briefingRevealedProvider =
    StateProvider.autoDispose.family<bool, String>((ref, room) => false);
final briefingSpeakerProvider =
    StateProvider.autoDispose.family<bool?, String>((ref, room) => null);
final briefingAudioBusyProvider =
    StateProvider.autoDispose.family<bool, String>((ref, room) => false);

/// Reuse the actual allocator with synthetic IDs; never read other agents' roles.
final briefingRoleCountsProvider =
    Provider.autoDispose.family<Map<PlayerRole, int>, int>((ref, total) {
  if (total == 0) return {};
  final roles = RoleAllocator.allocateRoles(
      List.generate(total, (i) => 'count_$i'),
      randomOverride: Random(0));
  return {
    for (final role in PlayerRole.values)
      role: roles.values.where((value) => value == role).length
  };
});
