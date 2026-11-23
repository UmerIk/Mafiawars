import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mafia_ui.dart';
import 'providers/auth_providers.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  late TextEditingController _nameController;
  int _selectedAvatarIndex = 1; // Default to Raven avatar (index 1)
  bool _isLoading = false;

  final List<Map<String, dynamic>> _avatarList = const [
    {
      'name': 'Boss',
      'image': 'assets/images/character_cigar_boss.png',
      'icon': Icons.person_pin
    },
    {
      'name': 'Raven',
      'image': 'assets/images/avatar_raven.png',
      'icon': Icons.pets
    },
    {
      'name': 'AgentX',
      'image': 'assets/images/avatar_agentx.png',
      'icon': Icons.security
    },
    {
      'name': 'Femme',
      'image': 'assets/images/character_femme_fatale.png',
      'icon': Icons.face_5
    },
    {
      'name': 'Friday13',
      'image': 'assets/images/avatar_friday13.png',
      'icon': Icons.masks
    },
    {
      'name': 'PandaRed',
      'image': 'assets/images/avatar_pandared.png',
      'icon': Icons.pets
    },
    {
      'name': 'Detective',
      'image': 'assets/images/character_detective.png',
      'icon': Icons.search
    },
    {
      'name': 'Doctor',
      'image': 'assets/images/character_doctor.png',
      'icon': Icons.medical_services
    },
    {
      'name': 'Noble',
      'image': 'assets/images/character_noble_portrait.png',
      'icon': Icons.psychology
    },
    {
      'name': 'Ajax',
      'image': 'assets/images/avatar_ajax.png',
      'icon': Icons.face_retouching_natural
    },
    {
      'name': 'Cypork',
      'image': 'assets/images/avatar_cypork.png',
      'icon': Icons.smart_toy
    },
    {
      'name': 'Rayven',
      'image': 'assets/images/avatar_rayven.png',
      'icon': Icons.face_6
    },
    {
      'name': 'SciDude',
      'image': 'assets/images/avatar_scidude.png',
      'icon': Icons.science
    },
    {
      'name': 'Darkling',
      'image': 'assets/images/avatar_darkling.png',
      'icon': Icons.shield_moon
    },
    {'name': 'Ninja', 'image': null, 'icon': Icons.sports_kabaddi},
    {'name': 'Agent', 'image': null, 'icon': Icons.support_agent},
    {'name': 'Owl', 'image': null, 'icon': Icons.visibility},
    {'name': 'Mask', 'image': null, 'icon': Icons.theater_comedy},
    {'name': 'Demon', 'image': null, 'icon': Icons.coronavirus_sharp},
    {'name': 'Cat', 'image': null, 'icon': Icons.pets},
    {'name': 'Spectre', 'image': null, 'icon': Icons.shield},
    {'name': 'Ghost', 'image': null, 'icon': Icons.coronavirus},
    {'name': 'Viper', 'image': null, 'icon': Icons.smart_toy},
    {'name': 'Cipher', 'image': null, 'icon': Icons.lock},
  ];

  final List<String> _codenames = const [
    'Agent47',
    'Raven',
    'Shadow',
    'Falcon',
    'Cipher',
    'Viper',
    'Spectre',
    'Ghost',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Agent47');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _generateRandomName() {
    final random = Random();
    final name = _codenames[random.nextInt(_codenames.length)];
    final number = random.nextInt(900) + 100;
    _nameController.text = '$name$number';
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            displayName: name,
            avatarUrl: 'avatar_$_selectedAvatarIndex',
          );
      if (mounted) {
        context.go('/lobby');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAvatar = _avatarList[_selectedAvatarIndex];

    return Scaffold(
      body: Stack(
        children: [
          // High-Res Noir Skyline Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_skyline.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF43275A),
                      Color(0xFF301C40),
                      Color(0xFF191024),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.15)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Let's setup your agent profile",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFEF0E6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Selected Avatar Preview Circle
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0x80689EEA), Color(0x8043275A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border:
                          Border.all(color: const Color(0xFF7DD6FC), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonCrimson.withOpacity(0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: currentAvatar['image'] != null
                          ? Image.asset(
                              currentAvatar['image'] as String,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                currentAvatar['icon'] as IconData,
                                size: 50,
                                color: const Color(0xFFFEF0E6),
                              ),
                            )
                          : Icon(
                              currentAvatar['icon'] as IconData,
                              size: 50,
                              color: const Color(0xFFFEF0E6),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select your avatar',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFFEF0E6),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Grid of Avatars
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: _avatarList.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == _selectedAvatarIndex;
                        final item = _avatarList[index];

                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedAvatarIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? const Color(0xFF689EEA)
                                  : const Color(0x8043275A),
                              border: isSelected
                                  ? Border.all(
                                      color: const Color(0xFF7DD6FC),
                                      width: 2.5)
                                  : Border.all(color: Colors.transparent),
                              boxShadow: isSelected
                                  ? [
                                      const BoxShadow(
                                        color: Colors.white,
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: ClipOval(
                              child: item['image'] != null
                                  ? Image.asset(
                                      item['image'] as String,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        item['icon'] as IconData,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    )
                                  : Icon(
                                      item['icon'] as IconData,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Choose your codename',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFFEF0E6),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Codename Input Field (Height 54px, rounded 30px, #301C40 fill, #7DD6FC border)
                  Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF301C40),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFF7DD6FC)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.security,
                            color: Color(0xFF7DD6FC), size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            style: const TextStyle(
                              color: Color(0xFFFEF0E6),
                              fontSize: 16,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              hintText: 'Enter agent codename',
                              hintStyle: TextStyle(color: Color(0xFF689EEA)),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFF7DD6FC),
                            size: 22,
                          ),
                          onPressed: _generateRandomName,
                          tooltip: 'Generate random codename',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Continue Button
                  MafiaUi.gradientButton(
                    label: 'Continue',
                    loading: _isLoading,
                    onPressed: _isLoading ? null : _saveProfile,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
