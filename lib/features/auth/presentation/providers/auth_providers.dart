import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_form_provider.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final authStateChangesProvider = StreamProvider<UserEntity?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;
  final Ref _ref;

  AuthController(this._authRepository, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> signInAnonymously({required String displayName}) async {
    _ref.read(profileSetupPendingProvider.notifier).state = true;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _authRepository.signInAnonymously(displayName: displayName));
    if (state.hasError) {
      _ref.read(profileSetupPendingProvider.notifier).state = false;
    }
  }

  Future<void> updateProfile(
      {required String displayName, required String avatarUrl}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.updateProfile(
          displayName: displayName, avatarUrl: avatarUrl);
      _ref.invalidate(authStateChangesProvider);
      await _ref.read(authStateChangesProvider.future);
      _ref.read(profileSetupPendingProvider.notifier).state = false;
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.signOut());
    if (!state.hasError) {
      _ref.read(profileSetupPendingProvider.notifier).state = false;
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider), ref);
});
