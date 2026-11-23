import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../data/repositories/social_repository_impl.dart';
import '../../domain/entities/friend_entity.dart';
import '../../domain/entities/friend_request_entity.dart';
import '../../domain/repositories/social_repository.dart';

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepositoryImpl();
});

final friendsStreamProvider = StreamProvider<List<FriendEntity>>((ref) {
  final socialRepo = ref.watch(socialRepositoryProvider);
  return socialRepo.getFriendsStream();
});

final pendingRequestsStreamProvider = StreamProvider<List<FriendRequestEntity>>((ref) {
  final socialRepo = ref.watch(socialRepositoryProvider);
  return socialRepo.getPendingRequestsStream();
});

class SocialController extends StateNotifier<AsyncValue<void>> {
  final SocialRepository _socialRepository;

  SocialController(this._socialRepository) : super(const AsyncValue.data(null));

  Future<List<UserEntity>> searchUsers(String query) async {
    return await _socialRepository.searchUsers(query);
  }

  Future<void> sendFriendRequest(UserEntity targetUser) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _socialRepository.sendFriendRequest(targetUser));
  }

  Future<void> acceptFriendRequest(FriendRequestEntity request) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _socialRepository.acceptFriendRequest(request));
  }

  Future<void> rejectFriendRequest(String requestId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _socialRepository.rejectFriendRequest(requestId));
  }

  Future<void> removeFriend(String friendId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _socialRepository.removeFriend(friendId));
  }
}

final socialControllerProvider = StateNotifierProvider<SocialController, AsyncValue<void>>((ref) {
  return SocialController(ref.watch(socialRepositoryProvider));
});
