// Created by Hamza Ali on 2026-11-25.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design/app_assets.dart';
import '../../domain/entities/user_entity.dart';

/// Existing saved avatar IDs identify completed setup without a backend field.
/// Custom profiles from older clients remain valid; generated defaults do not.
bool hasCompletedProfile(UserEntity user) =>
    user.displayName.trim().isNotEmpty &&
    (AppAssets.avatarIndex(user.avatarUrl) != null ||
        user.avatarUrl.startsWith('assets/') ||
        (user.displayName != 'Agent47' &&
            user.displayName != 'Agent' &&
            !user.displayName.startsWith('Agent_')));

final profileSetupPendingProvider = StateProvider<bool>((ref) => false);

typedef ProfileFormSeed = ({String name, String avatar});

class ProfileFormState {
  const ProfileFormState(
      {required this.name, required this.avatar, this.submitted = false});
  final String name, avatar;
  final bool submitted;
  String? get nameError {
    if (name.trim().isEmpty) return 'Please enter your name to continue.';
    if (name.trim().runes.length > 30) return 'Use 30 characters or fewer.';
    return null;
  }

  ProfileFormState copyWith({String? name, String? avatar, bool? submitted}) =>
      ProfileFormState(
          name: name ?? this.name,
          avatar: avatar ?? this.avatar,
          submitted: submitted ?? this.submitted);
}

class ProfileFormController extends StateNotifier<ProfileFormState> {
  ProfileFormController(ProfileFormSeed seed)
      : super(ProfileFormState(name: seed.name, avatar: seed.avatar));
  void setName(String name) => state = state.copyWith(name: name);
  void selectAvatar(int index) =>
      state = state.copyWith(avatar: AppAssets.avatarId(index));
  bool validate() {
    state = state.copyWith(submitted: true);
    return state.nameError == null;
  }
}

final profileFormProvider = StateNotifierProvider.autoDispose
    .family<ProfileFormController, ProfileFormState, ProfileFormSeed>(
        (ref, seed) => ProfileFormController(seed));
