import '../entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;
  UserEntity? get currentUser;
  Future<UserEntity> signInAnonymously({required String displayName});
  Future<void> updateProfile({required String displayName, required String avatarUrl});
  Future<void> signOut();
  Future<UserEntity?> getUserProfile(String uid);
}
