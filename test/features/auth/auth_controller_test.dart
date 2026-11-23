import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_flutter_app/features/auth/domain/entities/user_entity.dart';
import 'package:my_flutter_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_flutter_app/features/auth/presentation/providers/auth_providers.dart';

class FakeAuthRepository implements AuthRepository {
  UserEntity? mockUser;

  @override
  Stream<UserEntity?> get authStateChanges => Stream.value(mockUser);

  @override
  UserEntity? get currentUser => mockUser;

  @override
  Future<UserEntity> signInAnonymously({required String displayName}) async {
    mockUser = UserEntity(
      uid: 'fake_uid',
      displayName: displayName,
      avatarUrl: '',
      createdAt: DateTime.now(),
    );
    return mockUser!;
  }

  @override
  Future<void> updateProfile({required String displayName, required String avatarUrl}) async {
    if (mockUser != null) {
      mockUser = mockUser!.copyWith(displayName: displayName, avatarUrl: avatarUrl);
    }
  }

  @override
  Future<void> signOut() async {
    mockUser = null;
  }

  @override
  Future<UserEntity?> getUserProfile(String uid) async {
    return mockUser;
  }
}

void main() {
  late ProviderContainer container;
  late FakeAuthRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('signInAnonymously sets state loading then data', () async {
    final controller = container.read(authControllerProvider.notifier);
    expect(container.read(authControllerProvider).hasError, false);

    await controller.signInAnonymously(displayName: 'TestAgent');
    expect(container.read(authControllerProvider).hasError, false);
    expect(fakeRepo.currentUser?.displayName, 'TestAgent');
  });

  test('updateProfile updates repo and invalidates authStateChangesProvider', () async {
    final controller = container.read(authControllerProvider.notifier);
    await controller.signInAnonymously(displayName: 'OriginalName');

    await controller.updateProfile(displayName: 'NewName', avatarUrl: 'new_url');
    expect(fakeRepo.currentUser?.displayName, 'NewName');
    expect(fakeRepo.currentUser?.avatarUrl, 'new_url');
  });
}
