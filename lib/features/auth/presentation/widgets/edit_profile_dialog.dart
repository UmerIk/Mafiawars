import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';
import '../profile_setup_screen.dart';

/// Compatibility entry point; creation and editing share the full profile page.
@Deprecated('Navigate to /profile_setup?edit=true instead.')
class EditProfileDialog extends StatelessWidget {
  const EditProfileDialog({super.key, required this.user});
  final UserEntity user;
  @override
  Widget build(BuildContext context) =>
      ProfileSetupScreen(user: user, isEditing: true);
}
