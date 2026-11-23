import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/features/game/data/logic/role_allocator.dart';
import 'package:my_flutter_app/features/game/domain/entities/game_room_entity.dart';

void main() {
  group('RoleAllocator', () {
    test('allocates 1 Mafia, 1 Doctor, 1 Detective, 2 Civilians for 5 players', () {
      final players = ['p1', 'p2', 'p3', 'p4', 'p5'];
      final roles = RoleAllocator.allocateRoles(players);

      expect(roles.length, 5);
      final mafiaCount = roles.values.where((r) => r == PlayerRole.mafia).length;
      final docCount = roles.values.where((r) => r == PlayerRole.doctor).length;
      final detCount = roles.values.where((r) => r == PlayerRole.detective).length;
      final civCount = roles.values.where((r) => r == PlayerRole.civilian).length;

      expect(mafiaCount, 1);
      expect(docCount, 1);
      expect(detCount, 1);
      expect(civCount, 2);
    });

    test('allocates 2 Mafia for 6 players', () {
      final players = ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'];
      final roles = RoleAllocator.allocateRoles(players);

      expect(roles.length, 6);
      final mafiaCount = roles.values.where((r) => r == PlayerRole.mafia).length;
      expect(mafiaCount, 2);
    });

    test('allocates 3 Mafia for 9 players', () {
      final players = List.generate(9, (i) => 'p$i');
      final roles = RoleAllocator.allocateRoles(players);

      expect(roles.length, 9);
      final mafiaCount = roles.values.where((r) => r == PlayerRole.mafia).length;
      expect(mafiaCount, 3);
    });
  });
}
