import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../game/domain/entities/chat_message_entity.dart';
import '../../../game/domain/entities/game_room_entity.dart';
import '../../domain/entities/friend_entity.dart';
import '../../domain/entities/friend_request_entity.dart';
import '../../domain/repositories/social_repository.dart';
import '../models/friend_model.dart';
import '../models/friend_request_model.dart';

class SocialRepositoryImpl implements SocialRepository {
  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;

  SocialRepositoryImpl({
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

  @override
  Stream<List<FriendEntity>> getFriendsStream() {
    try {
      if (Firebase.apps.isEmpty) return Stream.value([]);
      final uid = _auth.currentUser?.uid;
      if (uid == null) return Stream.value([]);

      return _firestore
          .collection('users')
          .doc(uid)
          .collection('friends')
          .snapshots()
          .asyncMap((snapshot) async {
        final List<FriendEntity> friends = [];
        for (final doc in snapshot.docs) {
          final friendUid = doc.id;
          final friendData = doc.data();

          String userStatus = 'offline';
          try {
            final userDoc = await _firestore.collection('users').doc(friendUid).get();
            if (userDoc.exists && userDoc.data() != null) {
              userStatus = userDoc.data()!['status'] ?? 'offline';
            }
          } catch (_) {}

          friends.add(FriendEntity(
            uid: friendUid,
            displayName: friendData['displayName'] ?? 'Agent',
            avatarUrl: friendData['avatarUrl'] ?? '',
            addedAt: (friendData['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            status: userStatus,
          ));
        }
        return friends;
      });
    } catch (_) {
      return Stream.value([]);
    }
  }

  @override
  Stream<List<FriendRequestEntity>> getPendingRequestsStream() {
    try {
      if (Firebase.apps.isEmpty) return Stream.value([]);
      final uid = _auth.currentUser?.uid;
      if (uid == null) return Stream.value([]);

      return _firestore
          .collection('users')
          .doc(uid)
          .collection('friend_requests')
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => FriendRequestModel.fromFirestore(doc))
              .toList());
    } catch (_) {
      return Stream.value([]);
    }
  }

  @override
  Future<List<UserEntity>> searchUsers(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final snapshot = await _firestore
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: trimmed)
        .where('displayName', isLessThanOrEqualTo: '$trimmed\zf8ff')
        .limit(10)
        .get();

    final currentUid = _auth.currentUser?.uid;
    return snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .where((user) => user.uid != currentUid)
        .toList();
  }

  @override
  Future<void> sendFriendRequest(UserEntity targetUser) async {
    final currentUid = _currentUserId;
    if (currentUid.isEmpty) throw Exception('User not authenticated.');

    String senderName = 'Agent';
    String senderAvatar = '';
    try {
      final currentUserDoc = await _firestore.collection('users').doc(currentUid).get();
      if (currentUserDoc.exists && currentUserDoc.data() != null) {
        final model = UserModel.fromFirestore(currentUserDoc);
        senderName = model.displayName;
        senderAvatar = model.avatarUrl;
      }
    } catch (e) {
      debugPrint('Error loading sender profile: $e');
    }

    final requestRef = _firestore
        .collection('users')
        .doc(targetUser.uid)
        .collection('friend_requests')
        .doc(currentUid);

    final request = FriendRequestModel(
      id: currentUid,
      senderId: currentUid,
      senderDisplayName: senderName,
      senderAvatarUrl: senderAvatar,
      receiverId: targetUser.uid,
      status: FriendRequestStatus.pending,
      createdAt: DateTime.now(),
    );

    await requestRef.set(request.toFirestore());
  }

  @override
  Future<void> sendFriendRequestToPlayer(RoomPlayerEntity player) async {
    final targetUser = UserEntity(
      uid: player.userId,
      displayName: player.displayName,
      avatarUrl: player.avatarUrl,
      createdAt: player.joinedAt,
    );
    await sendFriendRequest(targetUser);
  }

  @override
  Future<void> acceptFriendRequest(FriendRequestEntity request) async {
    final currentUid = _currentUserId;

    final batch = _firestore.batch();

    // Add sender to current user's friends list
    final myFriendRef = _firestore
        .collection('users')
        .doc(currentUid)
        .collection('friends')
        .doc(request.senderId);

    final myFriend = FriendModel(
      uid: request.senderId,
      displayName: request.senderDisplayName,
      avatarUrl: request.senderAvatarUrl,
      addedAt: DateTime.now(),
    );
    batch.set(myFriendRef, myFriend.toFirestore());

    // Add current user to sender's friends list
    final currentUserDoc = await _firestore.collection('users').doc(currentUid).get();
    final currentUserModel = UserModel.fromFirestore(currentUserDoc);

    final senderFriendRef = _firestore
        .collection('users')
        .doc(request.senderId)
        .collection('friends')
        .doc(currentUid);

    final senderFriend = FriendModel(
      uid: currentUid,
      displayName: currentUserModel.displayName,
      avatarUrl: currentUserModel.avatarUrl,
      addedAt: DateTime.now(),
    );
    batch.set(senderFriendRef, senderFriend.toFirestore());

    // Remove pending request
    final requestRef = _firestore
        .collection('users')
        .doc(currentUid)
        .collection('friend_requests')
        .doc(request.senderId);
    batch.delete(requestRef);

    await batch.commit();
  }

  @override
  Future<void> rejectFriendRequest(String requestId) async {
    final currentUid = _currentUserId;
    await _firestore
        .collection('users')
        .doc(currentUid)
        .collection('friend_requests')
        .doc(requestId)
        .delete();
  }

  String _getDirectChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  @override
  Stream<List<ChatMessageEntity>> getDirectChatStream(String friendUid) {
    try {
      final currentUid = _currentUserId;
      if (currentUid.isEmpty) return Stream.value([]);
      final chatId = _getDirectChatId(currentUid, friendUid);

      return _firestore
          .collection('direct_chats')
          .doc(chatId)
          .collection('messages')
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
  Future<void> sendDirectMessage({required String friendUid, required String message, String? audioUrl}) async {
    final currentUid = _currentUserId;
    if (currentUid.isEmpty) return;
    final chatId = _getDirectChatId(currentUid, friendUid);

    String senderName = 'Agent';
    String senderAvatar = '';
    try {
      final userDoc = await _firestore.collection('users').doc(currentUid).get();
      if (userDoc.exists) {
        senderName = userDoc.data()?['displayName'] ?? 'Agent';
        senderAvatar = userDoc.data()?['avatarUrl'] ?? '';
      }
    } catch (_) {}

    final msgId = _firestore.collection('direct_chats').doc(chatId).collection('messages').doc().id;
    final msg = ChatMessageEntity(
      id: msgId,
      senderId: currentUid,
      senderDisplayName: senderName,
      senderAvatarUrl: senderAvatar,
      message: message,
      channelType: 'direct',
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection('direct_chats')
        .doc(chatId)
        .collection('messages')
        .doc(msgId)
        .set(msg.toJson());
  }

  @override
  Future<void> sendGameInvite({required String friendUid, required String roomCode, required String roomId}) async {
    final currentUid = _currentUserId;
    if (currentUid.isEmpty) return;

    String senderName = 'Agent';
    try {
      final userDoc = await _firestore.collection('users').doc(currentUid).get();
      if (userDoc.exists) {
        senderName = userDoc.data()?['displayName'] ?? 'Agent';
      }
    } catch (_) {}

    await _firestore
        .collection('users')
        .doc(friendUid)
        .collection('game_invites')
        .add({
      'senderId': currentUid,
      'senderName': senderName,
      'roomCode': roomCode,
      'roomId': roomId,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> getGameInvitesStream() {
    try {
      final currentUid = _currentUserId;
      if (currentUid.isEmpty) return Stream.value([]);

      return _firestore
          .collection('users')
          .doc(currentUid)
          .collection('game_invites')
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList());
    } catch (_) {
      return Stream.value([]);
    }
  }

  @override
  Future<void> updateUserPresence(String status) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null || uid.isEmpty) return;

      await _firestore.collection('users').doc(uid).set({
        'status': status,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating presence: $e');
    }
  }

  @override
  Stream<UserEntity?> getUserStream(String userId) {
    try {
      if (Firebase.apps.isEmpty) return Stream.value(null);
      return _firestore
          .collection('users')
          .doc(userId)
          .snapshots()
          .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
    } catch (_) {
      return Stream.value(null);
    }
  }

  @override
  Future<void> removeFriend(String friendId) async {
    final currentUid = _currentUserId;
    final batch = _firestore.batch();

    final myFriendRef = _firestore
        .collection('users')
        .doc(currentUid)
        .collection('friends')
        .doc(friendId);
    batch.delete(myFriendRef);

    final otherFriendRef = _firestore
        .collection('users')
        .doc(friendId)
        .collection('friends')
        .doc(currentUid);
    batch.delete(otherFriendRef);

    await batch.commit();
  }
}
