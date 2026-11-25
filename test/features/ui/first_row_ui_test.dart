// Created by Hamza Ali on 2026-11-25.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_flutter_app/core/design/app_assets.dart';
import 'package:my_flutter_app/core/router/app_router.dart';
import 'package:my_flutter_app/features/auth/domain/entities/user_entity.dart';
import 'package:my_flutter_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_flutter_app/features/auth/presentation/auth_screen.dart';
import 'package:my_flutter_app/features/auth/presentation/profile_setup_screen.dart';
import 'package:my_flutter_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:my_flutter_app/features/auth/presentation/providers/profile_form_provider.dart';
import 'package:my_flutter_app/features/lobby/presentation/lobby_screen.dart';
import 'package:my_flutter_app/features/social/domain/entities/friend_entity.dart';
import 'package:my_flutter_app/features/social/domain/entities/friend_request_entity.dart';
import 'package:my_flutter_app/features/social/domain/repositories/social_repository.dart';
import 'package:my_flutter_app/features/social/presentation/providers/social_providers.dart';
import 'package:my_flutter_app/features/social/presentation/social_screen.dart';
import 'package:my_flutter_app/features/social/presentation/widgets/invite_friends_dialog.dart';
import 'package:my_flutter_app/features/social/presentation/widgets/user_profile_dialog.dart';

class _Auth extends Fake implements AuthRepository {
  UserEntity user = UserEntity(
      uid: 'self',
      displayName: 'Hamza',
      avatarUrl: 'avatar_16',
      createdAt: DateTime(2026));
  bool failSave = false;
  int saves = 0;
  Completer<void>? saveGate;
  @override
  UserEntity get currentUser => user;
  @override
  Stream<UserEntity?> get authStateChanges => Stream.value(user);
  @override
  Future<UserEntity?> getUserProfile(String uid) async => user;
  @override
  Future<void> updateProfile(
      {required String displayName, required String avatarUrl}) async {
    saves++;
    if (saveGate != null) await saveGate!.future;
    if (failSave) throw Exception('offline');
    user = user.copyWith(displayName: displayName, avatarUrl: avatarUrl);
  }
}

class _Social extends Fake implements SocialRepository {
  int invitesSent = 0;
  bool failInvite = false;
  @override
  Future<void> sendGameInvite(
      {required String friendUid,
      required String roomCode,
      required String roomId}) async {
    invitesSent++;
    if (failInvite) throw Exception('offline');
  }

  @override
  Stream<List<Map<String, dynamic>>> getGameInvitesStream() => Stream.value([]);
  @override
  Stream<UserEntity?> getUserStream(String uid) => Stream.value(null);
}

final _friends = List.generate(
    6,
    (i) => FriendEntity(
        uid: 'friend_$i',
        displayName: [
          'AgentX',
          'Ajax',
          'Cypork',
          'Friday13',
          'PandaRed',
          'Rayven'
        ][i],
        avatarUrl: 'avatar_${[2, 13, 19, 4, 8, 11][i]}',
        addedAt: DateTime(2026),
        status: 'online'));

Future<GlobalKey> _pump(WidgetTester tester, Widget screen, _Auth auth,
    {Size size = const Size(440, 956),
    double textScale = 1,
    bool useRouter = false,
    _Social? social}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final boundary = GlobalKey();
  final router = GoRouter(initialLocation: '/', routes: [
    GoRoute(path: '/', builder: (_, __) => screen),
    GoRoute(
        path: '/lobby',
        builder: (_, __) => const Scaffold(body: Text('Saved dashboard'))),
  ]);
  addTearDown(router.dispose);
  final theme = ThemeData.dark(useMaterial3: true).copyWith(
      textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'MafiaInter'),
      iconTheme: const IconThemeData(color: Color(0xFFFEF0E6)));
  await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        socialRepositoryProvider.overrideWithValue(social ?? _Social()),
        friendsStreamProvider.overrideWith((ref) => Stream.value(_friends)),
        pendingRequestsStreamProvider
            .overrideWith((ref) => Stream.value(<FriendRequestEntity>[])),
      ],
      child: RepaintBoundary(
          key: boundary,
          child: useRouter
              ? MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  theme: theme,
                  routerConfig: router,
                  builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(textScaler: TextScaler.linear(textScale)),
                      child: child!))
              : MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: theme,
                  home: screen,
                  builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(textScaler: TextScaler.linear(textScale)),
                      child: child!)))));
  await tester.runAsync(() async {
    for (final asset in [
      AppAssets.background,
      AppAssets.logo,
      AppAssets.characters,
      AppAssets.avatars,
      AppAssets.joinRoom,
      AppAssets.createRoom,
      AppAssets.party
    ]) {
      await precacheImage(
          AssetImage(asset), tester.element(find.byType(MaterialApp)));
    }
  });
  await tester.pumpAndSettle();
  return boundary;
}

Future<void> _preview(WidgetTester tester, GlobalKey key, String name) async {
  if (!const bool.fromEnvironment('UI_PREVIEWS')) return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('/tmp/mafia-first-row-previews')
      ..createSync(recursive: true);
    File('${directory.path}/$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('MafiaInter')
          ..addFont(rootBundle.load('assets/fonts/Inter.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  for (final size in [
    const Size(320, 640),
    const Size(440, 956),
    const Size(800, 1024)
  ]) {
    for (final entry in <String, Widget Function()>{
      'login': () => const AuthScreen(),
      'profile': () => const ProfileSetupScreen(),
      'dashboard': () => const LobbyScreen(),
      'network': () => const SocialScreen(),
    }.entries) {
      testWidgets('${entry.key} fits ${size.width.toInt()}px without overflow',
          (tester) async {
        final boundary =
            await _pump(tester, entry.value(), _Auth(), size: size);
        expect(tester.takeException(), isNull);
        await _preview(tester, boundary, '${entry.key}_${size.width.toInt()}');
      });
    }
  }

  testWidgets(
      'profile requires a name and saves trimmed input before navigating',
      (tester) async {
    final auth = _Auth();
    await _pump(tester, const ProfileSetupScreen(), auth, useRouter: true);
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter your name to continue.'), findsOneWidget);
    expect(auth.saves, 0);
    await tester.enterText(find.byType(TextField), '  Hamza Ali  ');
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(auth.user.displayName, 'Hamza Ali');
    expect(auth.saves, 1);
    expect(find.text('Saved dashboard'), findsOneWidget);
  });

  testWidgets('failed profile save preserves name and avatar for retry',
      (tester) async {
    final auth = _Auth()..failSave = true;
    await _pump(tester, const ProfileSetupScreen(), auth, useRouter: true);
    await tester.tap(find.byKey(const ValueKey('avatar_4')));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'New name');
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Couldn’t save your profile. Please try again.'),
        findsOneWidget);
    expect(find.text('Saved dashboard'), findsNothing);
    expect(find.text('New name'), findsOneWidget);
    auth.failSave = false;
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(auth.user.avatarUrl, 'avatar_4');
    expect(find.text('Saved dashboard'), findsOneWidget);
  });

  testWidgets('profile editor preserves current values and returns after save',
      (tester) async {
    final auth = _Auth();
    await _pump(
        tester, ProfileSetupScreen(user: auth.user, isEditing: true), auth,
        useRouter: true);
    expect(find.text('Hamza'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Updated name');
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(auth.user.avatarUrl, 'avatar_16');
    expect(auth.user.displayName, 'Updated name');
    expect(find.text('Saved dashboard'), findsOneWidget);
  });

  testWidgets('large text and keyboard do not overflow profile or network',
      (tester) async {
    await _pump(tester, const ProfileSetupScreen(), _Auth(),
        size: const Size(320, 640), textScale: 1.5);
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue'));
    expect(tester.takeException(), isNull);
    tester.view.resetViewInsets();
    await _pump(tester, const SocialScreen(), _Auth(),
        size: const Size(320, 640), textScale: 1.5);
    expect(tester.takeException(), isNull);
  });

  for (final type in ProfileDialogType.values) {
    testWidgets('profile dialog ${type.name} fits a small phone',
        (tester) async {
      final boundary = await _pump(
          tester,
          Scaffold(
              body: Center(
                  child: Dialog(
                      backgroundColor: Colors.transparent,
                      child: SingleChildScrollView(
                          child: UserProfileDialog(
                              displayName: 'Rayven',
                              avatarUrl: 'avatar_11',
                              type: type,
                              onPrimaryAction: () {},
                              onSecondaryAction: () {}))))),
          _Auth(),
          size: const Size(320, 640),
          textScale: 1.5);
      expect(tester.takeException(), isNull);
      await _preview(tester, boundary, 'dialog_${type.name}_320');
    });
  }

  testWidgets('friend invitations search real friends and mark sent once',
      (tester) async {
    final social = _Social();
    await _pump(
        tester,
        const Scaffold(
            body: Center(
                child: Dialog(
                    backgroundColor: Colors.transparent,
                    child: InviteFriendsDialog(
                        roomId: 'room', roomCode: 'ABC123')))),
        _Auth(),
        social: social);
    await tester.enterText(find.byType(TextField), 'rayven');
    await tester.pump();
    expect(find.text('Rayven'), findsOneWidget);
    expect(find.text('AgentX'), findsNothing);
    await tester.tap(find.text('Invite'));
    await tester.pumpAndSettle();
    expect(find.text('Invited'), findsOneWidget);
    await tester.tap(find.text('Invited'));
    await tester.pumpAndSettle();
    expect(social.invitesSent, 1);
  });

  testWidgets('failed invitation stays available for retry', (tester) async {
    final social = _Social()..failInvite = true;
    await _pump(
        tester,
        const Scaffold(
            body: Center(
                child: Dialog(
                    backgroundColor: Colors.transparent,
                    child: InviteFriendsDialog(
                        roomId: 'room', roomCode: 'ABC123')))),
        _Auth(),
        social: social);
    await tester.enterText(find.byType(TextField), 'rayven');
    await tester.pump();
    await tester.tap(find.text('Invite'));
    await tester.pumpAndSettle();
    expect(find.text('Couldn’t send the invitation. Please try again.'),
        findsOneWidget);
    expect(find.text('Invite'), findsOneWidget);
    social.failInvite = false;
    await tester.tap(find.text('Invite'));
    await tester.pumpAndSettle();
    expect(social.invitesSent, 2);
    expect(find.text('Invited'), findsOneWidget);
  });

  testWidgets('larger text fits login and dashboard on a small phone',
      (tester) async {
    await _pump(tester, const AuthScreen(), _Auth(),
        size: const Size(320, 640), textScale: 1.5);
    expect(tester.takeException(), isNull);
    await _pump(tester, const LobbyScreen(), _Auth(),
        size: const Size(320, 640), textScale: 1.5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pending profile blocks direct lobby navigation',
      (tester) async {
    final auth = _Auth()
      ..user = UserEntity(
          uid: 'self',
          displayName: 'Agent_self',
          avatarUrl: '',
          createdAt: DateTime(2026));
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(auth)]);
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child:
            MaterialApp.router(routerConfig: router, theme: ThemeData.dark())));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileSetupScreen), findsOneWidget);
    router.go('/lobby');
    await tester.pumpAndSettle();
    expect(find.byType(ProfileSetupScreen), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/profile_setup');
  });

  testWidgets('profile save ignores repeat taps while pending', (tester) async {
    final auth = _Auth()..saveGate = Completer<void>();
    await _pump(tester, const ProfileSetupScreen(), auth, useRouter: true);
    await tester.enterText(find.byType(TextField), 'Hamza');
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.tap(find.byType(CircularProgressIndicator));
    await tester.pump();
    expect(auth.saves, 1);
    auth.saveGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Saved dashboard'), findsOneWidget);
  });

  test(
      'generated defaults need setup; existing named profiles remain compatible',
      () {
    final user = _Auth().user;
    expect(hasCompletedProfile(user), isTrue);
    expect(
        hasCompletedProfile(user.copyWith(
            displayName: 'Agent47',
            avatarUrl: 'https://api.dicebear.com/avatar.svg')),
        isFalse);
    expect(
        hasCompletedProfile(user.copyWith(
            displayName: 'Existing agent',
            avatarUrl: 'https://example.com/avatar.png')),
        isTrue);
  });
}
