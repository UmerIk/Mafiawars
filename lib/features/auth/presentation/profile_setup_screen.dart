import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/design/agent_avatar.dart';
import '../../../core/widgets/design/app_icon_button.dart';
import '../../../core/widgets/design/mafia_page.dart';
import '../domain/entities/user_entity.dart';
import 'providers/auth_providers.dart';
import 'providers/profile_form_provider.dart';

/// Shared profile creation/editor. All drafts live in Riverpod, not widget state.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key, this.user, this.isEditing = false});
  final UserEntity? user;
  final bool isEditing;
  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  late final ProfileFormSeed _seed;
  late final TextEditingController _nameController;
  @override
  void initState() {
    super.initState();
    _seed = (
      name: widget.isEditing ? widget.user?.displayName ?? '' : '',
      avatar: widget.isEditing && widget.user != null
          ? widget.user!.avatarUrl
          : AppAssets.avatarId(11)
    );
    _nameController = TextEditingController(text: _seed.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final notifier = ref.read(profileFormProvider(_seed).notifier);
    if (!notifier.validate()) return;
    FocusScope.of(context).unfocus();
    final draft = ref.read(profileFormProvider(_seed));
    await ref
        .read(authControllerProvider.notifier)
        .updateProfile(displayName: draft.name.trim(), avatarUrl: draft.avatar);
    if (!mounted || ref.read(authControllerProvider).hasError) return;
    if (widget.isEditing && context.canPop()) {
      context.pop();
    } else {
      context.go('/lobby');
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(profileFormProvider(_seed));
    final auth = ref.watch(authControllerProvider);
    final form = ref.read(profileFormProvider(_seed).notifier);
    return MafiaPage(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (widget.isEditing) ...[
        Align(
            alignment: Alignment.centerLeft,
            child: AppIconButton(
                icon: Icons.arrow_back,
                label: 'Back',
                size: 48,
                onPressed: auth.isLoading
                    ? null
                    : () => context.canPop()
                        ? context.pop()
                        : context.go('/lobby'))),
        const SizedBox(height: 20)
      ],
      Text(
          widget.isEditing
              ? 'Edit your agent profile'
              : 'Let’s setup your agent profile',
          textAlign: TextAlign.center,
          style: AppTypography.uiTitle),
      const SizedBox(height: 44),
      Center(
          child: AgentAvatar(
              value: draft.avatar, size: 100, label: 'Selected avatar')),
      const SizedBox(height: 8),
      Text('Select your avatar',
          textAlign: TextAlign.center, style: AppTypography.uiCaption),
      const SizedBox(height: 20),
      LayoutBuilder(builder: (context, constraints) {
        final gap = constraints.maxWidth * .025;
        return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, crossAxisSpacing: gap, mainAxisSpacing: gap),
            itemCount: AppAssets.avatarNames.length,
            itemBuilder: (context, position) {
              final index = AppAssets.avatarDisplayOrder[position];
              return Semantics(
                  button: true,
                  label: 'Choose ${AppAssets.avatarNames[index]} avatar',
                  selected: draft.avatar == AppAssets.avatarId(index),
                  child: InkWell(
                      key: ValueKey(AppAssets.avatarId(index)),
                      onTap: auth.isLoading
                          ? null
                          : () => form.selectAvatar(index),
                      borderRadius: BorderRadius.circular(40),
                      child: AgentAvatar(
                          value: AppAssets.avatarId(index),
                          size: (constraints.maxWidth - 4 * gap) / 5,
                          selected:
                              draft.avatar == AppAssets.avatarId(index))));
            });
      }),
      const SizedBox(height: 22),
      AppTextField(
          controller: _nameController,
          labelText: 'Choose your codename',
          hintText: 'Enter your name',
          autofillHints: const [AutofillHints.nickname],
          prefixIcon: const Icon(Icons.badge_outlined,
              color: AppColors.figmaCyan, size: 20),
          suffixIcon: IconButton(
              tooltip: 'Suggest a codename',
              onPressed: auth.isLoading
                  ? null
                  : () {
                      final name =
                          '${AppAssets.avatarNames[Random().nextInt(AppAssets.avatarNames.length)]}${Random().nextInt(900) + 100}';
                      _nameController.text = name;
                      form.setName(name);
                    },
              icon: const Icon(Icons.casino_outlined,
                  color: AppColors.figmaPink, size: 20)),
          enabled: !auth.isLoading,
          onChanged: form.setName,
          errorText: draft.submitted ? draft.nameError : null,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!auth.isLoading) _save();
          }),
      if (auth.hasError)
        Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text('Couldn’t save your profile. Please try again.',
                style: AppTypography.uiBody.copyWith(color: AppColors.error),
                textAlign: TextAlign.center)),
      const SizedBox(height: 48),
      AppButton(
          text: 'Continue',
          isFullWidth: true,
          isLoading: auth.isLoading,
          onPressed: auth.isLoading ? null : _save),
    ]));
  }
}
