import '../../../auth/domain/entities/user_entity.dart';
import '../../../game/domain/entities/chat_message_entity.dart';
import '../../../game/domain/entities/game_room_entity.dart';
import '../entities/friend_entity.dart';
import '../entities/friend_request_entity.dart';

abstract class SocialRepository {
  Stream<List<FriendEntity>> getFriendsStream();
  Stream<List<FriendRequestEntity>> getPendingRequestsStream();
  Future<List<UserEntity>> searchUsers(String query);
  Future<void> sendFriendRequest(UserEntity targetUser);
  Future<void> sendFriendRequestToPlayer(RoomPlayerEntity player);
  Future<void> acceptFriendRequest(FriendRequestEntity request);
  Future<void> rejectFriendRequest(String requestId);
  Future<void> removeFriend(String friendId);

  Stream<List<ChatMessageEntity>> getDirectChatStream(String friendUid);
  Future<void> sendDirectMessage({required String friendUid, required String message, String? audioUrl});

  Future<void> sendGameInvite({required String friendUid, required String roomCode, required String roomId});
  Stream<List<Map<String, dynamic>>> getGameInvitesStream();

  Future<void> updateUserPresence(String status);
  Stream<UserEntity?> getUserStream(String userId);
}
