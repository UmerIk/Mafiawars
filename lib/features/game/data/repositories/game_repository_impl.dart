import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/game_room_entity.dart';
import '../../domain/repositories/game_repository.dart';
import '../logic/game_state_machine.dart';
import '../logic/role_allocator.dart';
import '../models/game_room_model.dart';

class GameRepositoryImpl implements GameRepository {
  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;

  GameRepositoryImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _authOverride = auth,
        _firestoreOverride = firestore;

  FirebaseAuth get _auth {
    if (_authOverride != null) return _authOverride;
    if (Firebase.apps.isEmpty) throw Exception('Firebase App not initialized');
    return FirebaseAuth.instance;
  }

  FirebaseFirestore get _firestore {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (Firebase.apps.isEmpty) throw Exception('Firebase App not initialized');
    return FirebaseFirestore.instance;
  }

  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  String _getSubcollectionName(String channel) {
    switch (channel.toLowerCase()) {
      case 'mafia':
        return 'mafia_chat';
      case 'ghost':
        return 'ghost_chat';
      case 'public':
      default:
        return 'public_chat';
    }
  }

  @override
  Future<GameRoomEntity> createRoom({int maxPlayers = 12}) async {
    final uid = _currentUserId;
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userModel = UserModel.fromFirestore(userDoc);

    final roomRef = _firestore.collection('rooms').doc();
    final code = _generateRoomCode();
    final now = DateTime.now();

    final roomModel = GameRoomModel(
      roomId: roomRef.id,
      code: code,
      hostId: uid,
      status: GameRoomStatus.lobby,
      phase: GamePhase.lobby,
      maxPlayers: maxPlayers,
      playerCount: 1,
      createdAt: now,
    );

    final hostPlayer = RoomPlayerModel(
      userId: uid,
      displayName: userModel.displayName,
      avatarUrl: userModel.avatarUrl,
      slotIndex: 0,
      isHost: true,
      isReady: true,
      isAlive: true,
      joinedAt: now,
    );

    final batch = _firestore.batch();
    batch.set(roomRef, roomModel.toFirestore());
    batch.set(
      roomRef.collection('public_players').doc(uid),
      hostPlayer.toFirestore(),
    );

    await batch.commit();
    return roomModel;
  }

  @override
  Future<GameRoomEntity> joinRoomByCode(String code) async {
    final trimmedCode = code.trim().toUpperCase();
    if (trimmedCode.isEmpty) throw Exception('Please enter a valid room code.');

    final query = await _firestore
        .collection('rooms')
        .where('code', isEqualTo: trimmedCode)
        .where('status', isEqualTo: 'lobby')
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('No active room found with code "$trimmedCode".');
    }

    final roomDoc = query.docs.first;
    final room = GameRoomModel.fromFirestore(roomDoc);
    final uid = _currentUserId;

    final playersSnapshot = await roomDoc.reference.collection('public_players').get();
    final players = playersSnapshot.docs.map((d) => RoomPlayerModel.fromFirestore(d)).toList();

    final existingPlayer = players.cast<RoomPlayerModel?>().firstWhere(
          (p) => p?.userId == uid,
          orElse: () => null,
        );

    if (existingPlayer != null) {
      return room;
    }

    if (players.length >= room.maxPlayers) {
      throw Exception('Room is full (Maximum ${room.maxPlayers} players).');
    }

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userModel = UserModel.fromFirestore(userDoc);

    final usedSlots = players.map((p) => p.slotIndex).toSet();
    int availableSlot = 0;
    while (usedSlots.contains(availableSlot)) {
      availableSlot++;
    }

    final newPlayer = RoomPlayerModel(
      userId: uid,
      displayName: userModel.displayName,
      avatarUrl: userModel.avatarUrl,
      slotIndex: availableSlot,
      isHost: false,
      isReady: false,
      isAlive: true,
      joinedAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    batch.set(
      roomDoc.reference.collection('public_players').doc(uid),
      newPlayer.toFirestore(),
    );
    batch.update(roomDoc.reference, {
      'playerCount': FieldValue.increment(1),
    });

    await batch.commit();
    return room.copyWith(playerCount: room.playerCount + 1);
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    final uid = _currentUserId;
    final roomRef = _firestore.collection('rooms').doc(roomId);

    final playersSnapshot = await roomRef.collection('public_players').get();
    final players = playersSnapshot.docs.map((d) => RoomPlayerModel.fromFirestore(d)).toList();

    final playerInRoom = players.cast<RoomPlayerModel?>().firstWhere(
          (p) => p?.userId == uid,
          orElse: () => null,
        );

    if (playerInRoom == null) return;

    final batch = _firestore.batch();
    batch.delete(roomRef.collection('public_players').doc(uid));

    if (players.length <= 1) {
      batch.delete(roomRef);
    } else {
      batch.update(roomRef, {'playerCount': FieldValue.increment(-1)});
      if (playerInRoom.isHost) {
        final nextHost = players.firstWhere((p) => p.userId != uid);
        batch.update(
          roomRef.collection('public_players').doc(nextHost.userId),
          {'isHost': true, 'isReady': true},
        );
        batch.update(roomRef, {'hostId': nextHost.userId});
      }
    }

    await batch.commit();
  }

  @override
  Future<void> toggleReadyStatus(String roomId) async {
    final uid = _currentUserId;
    final playerRef = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('public_players')
        .doc(uid);

    final doc = await playerRef.get();
    if (!doc.exists) return;

    final currentReady = doc.data()?['isReady'] ?? false;
    await playerRef.update({'isReady': !currentReady});
  }

  @override
  Future<void> startGame(String roomId) async {
    final uid = _currentUserId;
    final roomRef = _firestore.collection('rooms').doc(roomId);
    final roomDoc = await roomRef.get();

    if (!roomDoc.exists) throw Exception('Room does not exist.');
    final room = GameRoomModel.fromFirestore(roomDoc);

    if (room.hostId != uid) {
      throw Exception('Only the room host can start the game.');
    }

    final playersSnapshot = await roomRef.collection('public_players').get();
    final players = playersSnapshot.docs.map((d) => RoomPlayerModel.fromFirestore(d)).toList();

    if (players.length < 5) {
      throw Exception('A minimum of 5 players is required to start a game.');
    }

    final playerIds = players.map((p) => p.userId).toList();
    final roleAssignments = RoleAllocator.allocateRoles(playerIds);

    final batch = _firestore.batch();
    final now = DateTime.now();
    final nightEnd = now.add(GameStateMachine.nightPhaseDuration);

    batch.update(roomRef, {
      'status': GameRoomStatus.inGame.name,
      'phase': GamePhase.nightMafia.name,
      'phaseEndTime': Timestamp.fromDate(nightEnd),
      'alivePlayerIds': playerIds,
      'eliminatedPlayerIds': [],
      'readyToVoteUserIds': [],
    });

    roleAssignments.forEach((userId, role) {
      final roleEntity = PlayerRoleEntity(
        userId: userId,
        role: role,
        faction: role.faction,
      );

      final privateRoleRef = roomRef.collection('private_roles').doc(userId);
      batch.set(privateRoleRef, roleEntity.toJson());

      if (role == PlayerRole.mafia) {
        final playerObj = players.firstWhere((p) => p.userId == userId);
        final mafiaTeamRef = roomRef.collection('mafia_team').doc(userId);
        batch.set(mafiaTeamRef, {
          'userId': userId,
          'displayName': playerObj.displayName,
          'avatarUrl': playerObj.avatarUrl,
        });
      }
    });

    await batch.commit();
  }

  @override
  Stream<GameRoomEntity?> getRoomStream(String roomId) {
    try {
      if (Firebase.apps.isEmpty) return Stream.value(null);
      return _firestore
          .collection('rooms')
          .doc(roomId)
          .snapshots()
          .map((doc) => doc.exists ? GameRoomModel.fromFirestore(doc) : null);
    } catch (_) {
      return Stream.value(null);
    }
  }

  @override
  Stream<List<RoomPlayerEntity>> getRoomPlayersStream(String roomId) {
    try {
      if (Firebase.apps.isEmpty) return Stream.value([]);
      return _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('public_players')
          .orderBy('slotIndex')
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => RoomPlayerModel.fromFirestore(doc)).toList());
    } catch (_) {
      return Stream.value([]);
    }
  }

  @override
  Future<PlayerRoleEntity?> getMyRole(String roomId) async {
    final uid = _currentUserId;
    final doc = await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('private_roles')
        .doc(uid)
        .get();

    if (!doc.exists) return null;
    return PlayerRoleEntity.fromJson(doc.data()!);
  }

  @override
  Stream<PlayerRoleEntity?> getMyRoleStream(String roomId) {
    try {
      if (Firebase.apps.isEmpty) return Stream.value(null);
      final uid = _auth.currentUser?.uid;
      if (uid == null) return Stream.value(null);

      return _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('private_roles')
          .doc(uid)
          .snapshots()
          .map((doc) => doc.exists ? PlayerRoleEntity.fromJson(doc.data()!) : null);
    } catch (_) {
      return Stream.value(null);
    }
  }

  @override
  Future<void> submitPhaseAction({
    required String roomId,
    required String targetUserId,
  }) async {
    final uid = _currentUserId;
    final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
    if (!roomDoc.exists) return;

    final room = GameRoomModel.fromFirestore(roomDoc);
    debugPrint('👉 [GameRepository] submitPhaseAction called: actor=$uid -> target=$targetUserId in phase: ${room.phase.name}');

    if (room.phase == GamePhase.dayVoting) {
      await submitDayVote(roomId: roomId, targetUserId: targetUserId);
    } else {
      final actionDocId = (room.phase == GamePhase.nightMafia)
          ? 'nightMafia_$uid'
          : room.phase.name;

      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('actions')
          .doc(actionDocId)
          .set({'actorId': uid, 'targetId': targetUserId, 'timestamp': FieldValue.serverTimestamp()});
    }
  }

  @override
  Future<void> submitDayVote({
    required String roomId,
    required String targetUserId,
  }) async {
    final uid = _currentUserId;
    debugPrint('🗳️ [GameRepository] Submitting Day Vote: voter=$uid -> target=$targetUserId in room $roomId');

    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('votes')
        .doc(uid)
        .set({
      'voterId': uid,
      'targetId': targetUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> toggleReadyToVote(String roomId) async {
    final uid = _currentUserId;
    final roomRef = _firestore.collection('rooms').doc(roomId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;

      final room = GameRoomModel.fromFirestore(snapshot);
      if (room.phase != GamePhase.dayDiscussion) return;

      final currentList = List<String>.from(room.readyToVoteUserIds);
      if (currentList.contains(uid)) {
        currentList.remove(uid);
      } else {
        currentList.add(uid);
      }

      transaction.update(roomRef, {'readyToVoteUserIds': currentList});

      if (currentList.length >= room.alivePlayerIds.length && room.alivePlayerIds.isNotEmpty) {
        final now = DateTime.now();
        final votingEnd = now.add(GameStateMachine.dayVotingDuration);
        transaction.update(roomRef, {
          'phase': GamePhase.dayVoting.name,
          'phaseEndTime': Timestamp.fromDate(votingEnd),
          'readyToVoteUserIds': [],
        });
      }
    });
  }

  @override
  Future<void> sendMafiaChatMessage({
    required String roomId,
    required String message,
  }) async {
    await sendMultiChannelChatMessage(
      roomId: roomId,
      message: message,
      channel: 'mafia',
    );
  }

  @override
  Stream<List<MafiaChatMessageEntity>> getMafiaChatStream(String roomId) {
    return getMultiChannelChatStream(roomId: roomId, channel: 'mafia').map(
      (messages) => messages
          .map((m) => MafiaChatMessageEntity(
                id: m.id,
                senderId: m.senderId,
                senderDisplayName: m.senderDisplayName,
                message: m.message,
                timestamp: m.timestamp,
              ))
          .toList(),
    );
  }

  @override
  Future<void> sendMultiChannelChatMessage({
    required String roomId,
    required String message,
    required String channel,
  }) async {
    final uid = _currentUserId;
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userModel = UserModel.fromFirestore(userDoc);

    final subcollection = _getSubcollectionName(channel);
    final chatRef = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection(subcollection)
        .doc();

    final chatMsg = ChatMessageEntity(
      id: chatRef.id,
      senderId: uid,
      senderDisplayName: userModel.displayName,
      senderAvatarUrl: userModel.avatarUrl,
      message: trimmed,
      channelType: channel,
      timestamp: DateTime.now(),
    );

    await chatRef.set(chatMsg.toJson());
  }

  @override
  Stream<List<ChatMessageEntity>> getMultiChannelChatStream({
    required String roomId,
    required String channel,
  }) {
    try {
      if (Firebase.apps.isEmpty) return Stream.value([]);
      final subcollection = _getSubcollectionName(channel);

      return _firestore
          .collection('rooms')
          .doc(roomId)
          .collection(subcollection)
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ChatMessageEntity.fromJson(doc.data()))
              .toList());
    } catch (_) {
      return Stream.value([]);
    }
  }

  @override
  Stream<Map<String, String>> getRoomVotesStream(String roomId) {
    try {
      if (Firebase.apps.isEmpty) return Stream.value({});
      return _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('votes')
          .snapshots()
          .map((snapshot) {
        final Map<String, String> votes = {};
        for (final doc in snapshot.docs) {
          votes[doc.id] = doc.data()['targetId'] ?? '';
        }
        return votes;
      });
    } catch (_) {
      return Stream.value({});
    }
  }

  @override
  Stream<Map<String, String>> getRoomActionsStream(String roomId) {
    try {
      if (Firebase.apps.isEmpty) return Stream.value({});
      return _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('actions')
          .snapshots()
          .map((snapshot) {
        final Map<String, String> actions = {};
        for (final doc in snapshot.docs) {
          actions[doc.id] = doc.data()['targetId'] ?? '';
        }
        return actions;
      });
    } catch (_) {
      return Stream.value({});
    }
  }

  @override
  Future<void> advanceGamePhase(String roomId) async {
    try {
      final roomRef = _firestore.collection('rooms').doc(roomId);
      final roomDoc = await roomRef.get();
      if (!roomDoc.exists) return;

      final room = GameRoomModel.fromFirestore(roomDoc);

      final rolesSnapshot = await roomRef.collection('private_roles').get();
      final Map<String, PlayerRole> playerRoles = {};
      for (final doc in rolesSnapshot.docs) {
        final roleObj = PlayerRoleEntity.fromJson(doc.data());
        playerRoles[doc.id] = roleObj.role;
      }

      final actionsSnapshot = await roomRef.collection('actions').get();

      // Only guard during nightDetective if actions were already processed and cleared
      if (room.phase == GamePhase.nightDetective && actionsSnapshot.docs.isEmpty && room.nightFacts != null) {
        debugPrint('🛡️ [GameRepository] advanceGamePhase ignored: nightDetective already processed.');
        return;
      }

      final Map<String, String> phaseActions = {};
      for (final doc in actionsSnapshot.docs) {
        phaseActions[doc.id] = doc.data()['targetId'] ?? '';
      }

      final votesSnapshot = await roomRef.collection('votes').get();
      final Map<String, String> dayVotes = {};
      for (final doc in votesSnapshot.docs) {
        dayVotes[doc.id] = doc.data()['targetId'] ?? '';
      }

      final result = GameStateMachine.advancePhase(
        currentPhase: room.phase,
        playerRoles: playerRoles,
        currentAliveIds: room.alivePlayerIds,
        currentEliminatedIds: room.eliminatedPlayerIds,
        phaseActions: phaseActions,
        dayVotes: dayVotes,
      );

      final now = DateTime.now();
      final nextEndTime = now.add(result.phaseDuration);

      final batch = _firestore.batch();
      final updateData = <String, dynamic>{
        'phase': result.nextPhase.name,
        'phaseEndTime': Timestamp.fromDate(nextEndTime),
        'alivePlayerIds': result.alivePlayerIds,
        'eliminatedPlayerIds': result.eliminatedPlayerIds,
        'winningFaction': result.winningFaction,
        'status': result.nextPhase == GamePhase.gameOver
            ? GameRoomStatus.completed.name
            : GameRoomStatus.inGame.name,
        'readyToVoteUserIds': [],
      };

      if (result.nextPhase == GamePhase.nightMafia) {
        updateData['nightFacts'] = FieldValue.delete();
      } else if (result.nightFacts != null) {
        updateData['nightFacts'] = result.nightFacts;
      }

      batch.update(roomRef, updateData);

      final newlyEliminated = result.eliminatedPlayerIds
          .where((uid) => !room.eliminatedPlayerIds.contains(uid))
          .toList();

      for (final uid in newlyEliminated) {
        final elimType = (room.phase == GamePhase.dayVoting) ? 'eliminated' : 'killed';
        batch.update(roomRef.collection('public_players').doc(uid), {
          'isAlive': false,
          'eliminationType': elimType,
        });
      }

      // Clear night actions only when Night phases complete
      if (room.phase == GamePhase.nightDetective) {
        for (final doc in actionsSnapshot.docs) {
          batch.delete(doc.reference);
        }
      }

      // Clear votes only when Voting phase completes
      if (room.phase == GamePhase.dayVoting) {
        for (final doc in votesSnapshot.docs) {
          batch.delete(doc.reference);
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error advancing phase: $e');
      rethrow;
    }
  }

  @override
  Future<void> resetRoomToLobby(String roomId) async {
    try {
      final roomRef = _firestore.collection('rooms').doc(roomId);
      final roomDoc = await roomRef.get();
      if (!roomDoc.exists) return;

      final playersSnapshot = await roomRef.collection('public_players').get();
      final allPlayerIds = playersSnapshot.docs.map((d) => d.id).toList();

      final batch = _firestore.batch();
      batch.update(roomRef, {
        'status': GameRoomStatus.lobby.name,
        'phase': GamePhase.lobby.name,
        'winningFaction': FieldValue.delete(),
        'nightFacts': FieldValue.delete(),
        'alivePlayerIds': allPlayerIds,
        'eliminatedPlayerIds': [],
        'readyToVoteUserIds': [],
      });

      for (final doc in playersSnapshot.docs) {
        batch.update(doc.reference, {'isAlive': true, 'isReady': false});
      }

      final actionsSnapshot = await roomRef.collection('actions').get();
      for (final doc in actionsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      final votesSnapshot = await roomRef.collection('votes').get();
      for (final doc in votesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('🔄 [GameRepository] Room $roomId reset to Lobby for Rematch!');
    } catch (e) {
      debugPrint('Error resetting room to lobby: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, PlayerRole>> getAllRoomRoles(String roomId) async {
    try {
      final snapshot = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('private_roles')
          .get();

      final Map<String, PlayerRole> map = {};
      for (final doc in snapshot.docs) {
        final roleObj = PlayerRoleEntity.fromJson(doc.data());
        map[doc.id] = roleObj.role;
      }
      return map;
    } catch (e) {
      debugPrint('Error fetching all room roles: $e');
      return {};
    }
  }
}
