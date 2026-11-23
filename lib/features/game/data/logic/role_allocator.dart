import 'dart:math';
import '../../domain/entities/game_room_entity.dart';

class RoleAllocator {
  static Map<String, PlayerRole> allocateRoles(List<String> playerIds, {Random? randomOverride}) {
    if (playerIds.isEmpty) {
      throw ArgumentError('Cannot allocate roles for empty player list.');
    }

    final total = playerIds.length;
    int mafiaCount = 1;
    bool includeSnitch = total > 8;

    if (total >= 9) {
      mafiaCount = 3;
    } else if (total >= 6) {
      mafiaCount = 2;
    }

    final List<PlayerRole> roles = [];

    // Add Mafia
    for (int i = 0; i < mafiaCount; i++) {
      roles.add(PlayerRole.mafia);
    }

    // Add Snitch if total > 8
    if (includeSnitch) {
      roles.add(PlayerRole.snitch);
    }

    // Add Doctor & Detective if at least 5 players
    if (total >= 5) {
      roles.add(PlayerRole.doctor);
      roles.add(PlayerRole.detective);
    }

    // Fill remainder with Civilians
    while (roles.length < total) {
      roles.add(PlayerRole.civilian);
    }

    // Shuffle roles
    final random = randomOverride ?? Random();
    final shuffledPlayerIds = List<String>.from(playerIds)..shuffle(random);
    final Map<String, PlayerRole> roleMap = {};

    for (int i = 0; i < total; i++) {
      roleMap[shuffledPlayerIds[i]] = roles[i];
    }

    return roleMap;
  }
}
