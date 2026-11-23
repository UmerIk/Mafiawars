import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../features/audio/presentation/webrtc_test_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/profile_setup_screen.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/lobby/presentation/lobby_screen.dart';
import '../../features/game/presentation/game_screen.dart';
import '../../features/social/presentation/social_screen.dart';
import '../../features/social/presentation/friend_chat_screen.dart';
import '../../features/social/presentation/new_chat_screen.dart';
import '../../features/in_person/domain/entities/in_person_game_config.dart';
import '../../features/in_person/presentation/screens/in_person_select_screen.dart';
import '../../features/in_person/presentation/screens/in_person_config_screen.dart';
import '../../features/in_person/presentation/screens/pass_reveal_screen.dart';
import '../../features/in_person/presentation/screens/in_person_digital_game_screen.dart';
import '../../features/in_person/presentation/screens/in_person_assistant_game_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateChangesProvider, (_, __) {
      notifyListeners();
    });
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) => RouterNotifier(ref));

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/profile_setup',
        name: 'profile_setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/lobby',
        name: 'lobby',
        builder: (context, state) => const LobbyScreen(),
      ),
      GoRoute(
        path: '/social',
        name: 'social',
        builder: (context, state) => const SocialScreen(),
      ),
      GoRoute(
        path: '/new_chat',
        name: 'new_chat',
        builder: (context, state) => const NewChatScreen(),
      ),
      GoRoute(
        path: '/social/chat/:friendUid',
        name: 'friend_chat',
        builder: (context, state) {
          final friendUid = state.pathParameters['friendUid'] ?? '';
          final friendName = state.uri.queryParameters['name'] ?? 'Agent';
          return FriendChatScreen(friendUid: friendUid, friendName: friendName);
        },
      ),
      GoRoute(
        path: '/webrtc_test',
        name: 'webrtc_test',
        builder: (context, state) => const WebRtcTestScreen(),
      ),
      GoRoute(
        path: '/in_person',
        name: 'in_person_select',
        builder: (context, state) => const InPersonSelectScreen(),
      ),
      GoRoute(
        path: '/in_person/config',
        name: 'in_person_config',
        builder: (context, state) {
          final mode = (state.extra as InPersonGameMode?) ?? InPersonGameMode.fullDigital;
          return InPersonConfigScreen(mode: mode);
        },
      ),
      GoRoute(
        path: '/in_person/pass_reveal',
        name: 'pass_reveal',
        builder: (context, state) => const PassRevealScreen(),
      ),
      GoRoute(
        path: '/in_person/digital_game',
        name: 'in_person_digital_game',
        builder: (context, state) => const InPersonDigitalGameScreen(),
      ),
      GoRoute(
        path: '/in_person/assistant_game',
        name: 'in_person_assistant_game',
        builder: (context, state) => const InPersonAssistantGameScreen(),
      ),
      GoRoute(
        path: '/game/:gameId',
        name: 'game',
        builder: (context, state) {
          final gameId = state.pathParameters['gameId'] ?? '';
          return GameScreen(gameId: gameId);
        },
      ),
    ],
    redirect: (context, state) {
      try {
        if (Firebase.apps.isEmpty) return null;
        final user = FirebaseAuth.instance.currentUser;
        final isSplashRoute = state.uri.path == '/splash';
        final isAuthRoute = state.uri.path == '/';
        final isInPersonRoute = state.uri.path.startsWith('/in_person');

        if (isSplashRoute || isInPersonRoute) return null;

        if (user == null && !isAuthRoute) {
          return '/';
        }
        if (user != null && isAuthRoute) {
          return '/lobby';
        }
      } catch (_) {
        // Ignore during test initialization without firebase mock
      }
      return null;
    },
  );
});
