// Created by Hamza Ali on 2026-11-25.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/core/widgets/design/design_components.dart';
import 'package:my_flutter_app/features/auth/domain/entities/user_entity.dart';
import 'package:my_flutter_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_flutter_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:my_flutter_app/features/game/domain/entities/chat_message_entity.dart';
import 'package:my_flutter_app/features/game/domain/entities/game_room_entity.dart';
import 'package:my_flutter_app/features/game/presentation/providers/briefing_providers.dart';
import 'package:my_flutter_app/features/game/presentation/providers/game_providers.dart';
import 'package:my_flutter_app/features/game/presentation/widgets/room_lobby_view.dart';
import 'package:my_flutter_app/features/game/presentation/widgets/room_briefing_view.dart';
import 'package:my_flutter_app/features/game/presentation/widgets/room_player_tile.dart';
import 'package:my_flutter_app/features/audio/providers/audio_providers.dart';
import 'package:my_flutter_app/features/audio/livekit_audio_service.dart';
import 'package:my_flutter_app/features/social/domain/entities/friend_entity.dart';
import 'package:my_flutter_app/features/social/domain/repositories/social_repository.dart';
import 'package:my_flutter_app/features/social/presentation/providers/chat_providers.dart';
import 'package:my_flutter_app/features/social/presentation/providers/social_providers.dart';
import 'package:my_flutter_app/features/social/presentation/chats_list_screen.dart';
import 'package:my_flutter_app/features/social/presentation/new_chat_screen.dart';
import 'package:my_flutter_app/features/social/presentation/friend_chat_screen.dart';

class _Auth extends Fake implements AuthRepository {
  @override
  UserEntity get currentUser => UserEntity(
      uid: 'self',
      displayName: 'Hamza',
      avatarUrl: 'avatar_16',
      createdAt: DateTime(2026));
}

class _Social extends Fake implements SocialRepository {
  bool failSend = false;
  int sends = 0;
  Completer<void>? gate;
  @override
  Stream<UserEntity?> getUserStream(String uid) => Stream.value(UserEntity(
      uid: uid,
      displayName: 'Cypork',
      avatarUrl: 'avatar_19',
      createdAt: DateTime(2026),
      userStatus: 'online'));
  @override
  Stream<List<ChatMessageEntity>> getDirectChatStream(String uid) =>
      Stream.value([_message(uid, 'Hello, agent', 1)]);
  @override
  Future<void> sendDirectMessage(
      {required String friendUid,
      required String message,
      String? audioUrl}) async {
    sends++;
    if (gate != null) await gate!.future;
    if (failSend) throw Exception('offline');
  }
}

class _Audio extends Fake implements LiveKitAudioService {
  @override
  bool get isSpeakerphoneOn => true;
  @override
  bool get isConnected => false;
  @override
  bool get isMuted => true;
}

final _friends = List.generate(
    6,
    (i) => FriendEntity(
        uid: 'real_$i',
        displayName: [
          'AgentX',
          'Ajax',
          'Cypork',
          'Friday13',
          'PandaRed',
          'Rayven'
        ][i],
        avatarUrl: 'avatar_${[10, 21, 19, 4, 7, 11][i]}',
        addedAt: DateTime(2026),
        status: 'online'));
final _players = List.generate(
    5,
    (i) => RoomPlayerEntity(
        userId: i == 0 ? 'self' : 'player_$i',
        displayName: [
          'Agent47',
          'Sci-dude',
          'Rayven',
          'PandaRed',
          'itsyobro'
        ][i],
        avatarUrl: 'avatar_${[16, 12, 11, 7, 13][i]}',
        slotIndex: i,
        isHost: i == 0,
        isReady: i < 4,
        joinedAt: DateTime(2026)));
final _room = GameRoomEntity(
    roomId: 'room', code: '2QR13T', hostId: 'self', createdAt: DateTime(2026));
ChatMessageEntity _message(String sender, String text, int minute) =>
    ChatMessageEntity(
        id: '$sender$minute',
        senderId: sender,
        senderDisplayName: sender,
        senderAvatarUrl: 'avatar_10',
        message: text,
        timestamp: DateTime(2026, 11, 25, 10, minute));
const _captureKey = ValueKey('capture');

Future<void> _pump(WidgetTester tester, Widget screen,
    {Size size = const Size(440, 956),
    double scale = 1,
    double keyboard = 0,
    _Social? social,
    List<Override> overrides = const []}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_Auth()),
        socialRepositoryProvider.overrideWithValue(social ?? _Social()),
        friendsStreamProvider.overrideWith((ref) => Stream.value(_friends)),
        ...overrides
      ],
      child: MaterialApp(
          theme: ThemeData(fontFamily: 'MafiaInter'),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!),
          home: RepaintBoundary(key: _captureKey, child: screen))));
  await tester.runAsync(() async {
    final context = tester.element(find.byKey(_captureKey));
    await Future.wait([
      precacheImage(const AssetImage(AppAssets.background), context),
      precacheImage(const AssetImage(AppAssets.avatars), context)
    ]);
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Widget _lobby(
        {String uid = 'self',
        List<RoomPlayerEntity>? players,
        AsyncValue<void> action = const AsyncData(null),
        VoidCallback? start,
        VoidCallback? ready}) =>
    RoomLobbyView(
        room: _room,
        players: AsyncData(players ?? _players),
        currentUid: uid,
        action: action,
        onLeave: () {},
        onCopy: () {},
        onInvite: () {},
        onChat: () {},
        onStart: start ?? () {},
        onReady: ready ?? () {},
        onRetry: () {},
        onPlayerTap: (_) {});
Future<void> _preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('UI_PREVIEWS')) return;
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_captureKey));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('/tmp/mafia-second-row-previews')
      ..createSync(recursive: true);
    File('${directory.path}/$name.png')
        .writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    final inter = FontLoader('MafiaInter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([inter.load(), icons.load()]);
  });
  for (final size in [
    const Size(320, 640),
    const Size(440, 956),
    const Size(800, 1024)
  ]) {
    testWidgets('second row responsive at ${size.width}', (tester) async {
      for (final entry in <String, Widget>{
        'inbox': const ChatsListScreen(),
        'new-chat': const NewChatScreen(),
        'direct-chat':
            const FriendChatScreen(friendUid: 'real_2', friendName: 'Cypork'),
        'host-lobby': _lobby(),
        'player-lobby': _lobby(uid: 'player_1')
      }.entries) {
        await _pump(tester, entry.value, size: size);
        expect(tester.takeException(), isNull, reason: entry.key);
        await _preview(tester, '${entry.key}-${size.width.toInt()}');
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      }
    });
  }
  testWidgets('large text and keyboard keep chat composer visible',
      (tester) async {
    await _pump(
        tester,
        const FriendChatScreen(
            friendUid: 'real_2', friendName: 'A very long agent codename'),
        size: const Size(320, 640),
        scale: 1.5,
        keyboard: 280);
    expect(tester.takeException(), isNull);
    expect(tester.getBottomRight(find.byType(AppTextField)).dy,
        lessThanOrEqualTo(360));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await _pump(tester, _lobby(), size: const Size(320, 640), scale: 1.5);
    expect(tester.takeException(), isNull);
  });
  testWidgets('new chat searches actual friends', (tester) async {
    await _pump(tester, const NewChatScreen());
    await tester.enterText(find.byType(TextField), 'Cypork');
    await tester.pump();
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('real_2')),
            matching: find.text('Cypork')),
        findsOneWidget);
    expect(find.text('AgentX'), findsNothing);
    expect(find.byKey(const ValueKey('real_2')), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pump();
    expect(find.text('No agents match that codename.'), findsOneWidget);
  });
  testWidgets(
      'failed send retains draft and busy sender prevents duplicate sends',
      (tester) async {
    final social = _Social()..failSend = true;
    await _pump(tester,
        const FriendChatScreen(friendUid: 'real_2', friendName: 'Cypork'),
        social: social);
    await tester.enterText(find.byType(TextField), 'Keep this draft');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();
    expect(find.text('Keep this draft'), findsOneWidget);
    expect(find.textContaining('Message could not be sent'), findsOneWidget);
    social.failSend = false;
    social.gate = Completer<void>();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    expect(social.sends, 2);
    social.gate!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Keep this draft'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('host minimum, start, readiness and failed action states',
      (tester) async {
    var starts = 0;
    var readiness = 0;
    await _pump(tester,
        _lobby(players: _players.take(4).toList(), start: () => starts++));
    await tester.tap(find.text('Start Game'));
    await tester.pump();
    expect(starts, 0);
    expect(find.textContaining('At least 5'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await _pump(tester, _lobby(start: () => starts++));
    await tester.tap(find.text('Start Game'));
    expect(starts, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await _pump(
        tester,
        _lobby(
            uid: 'player_4',
            ready: () => readiness++,
            action: AsyncError(Exception('offline'), StackTrace.current)));
    await tester.tap(find.text('Mark As Ready'));
    expect(readiness, 1);
    expect(find.textContaining('Could not update the room'), findsOneWidget);
    final ownTile =
        tester.widget<RoomPlayerTile>(find.byKey(const ValueKey('player_4')));
    expect(ownTile.isMe, isTrue);
  });
  testWidgets('briefing uses real countdown and private role flip',
      (tester) async {
    final audio = _Audio();
    await _pump(
        tester,
        RoomBriefingView(
            room: _room,
            players: AsyncData(_players),
            currentUid: 'self',
            speakers: const {'player_1'},
            seconds: 17,
            onLeave: () {},
            onChat: () {},
            onContinue: () {},
            onRetry: () {}),
        overrides: [
          liveKitAudioServiceProvider.overrideWithValue(audio),
          isAudioConnectedProvider.overrideWith((ref) => Stream.value(false)),
          isMicMutedProvider.overrideWith((ref) => Stream.value(true)),
          myRoleStreamProvider('room').overrideWith((ref) => Stream.value(
              const PlayerRoleEntity(
                  userId: 'self', role: PlayerRole.doctor, faction: 'TOWN')))
        ]);
    expect(find.text('00:17'), findsOneWidget);
    expect(find.text('Speaking…'), findsOneWidget);
    await _preview(tester, 'briefing-440');
    await tester.tap(find.byTooltip('Secret role'));
    await tester.pumpAndSettle();
    expect(find.text('DOCTOR'), findsNothing);
    await tester.tap(find.byTooltip('Reveal secret role'));
    await tester.pumpAndSettle();
    expect(find.text('DOCTOR'), findsOneWidget);
    expect(find.text('MAFIA'), findsNothing);
    await tester.tap(find.byTooltip('Hide secret role'));
    await tester.pumpAndSettle();
    expect(find.text('DOCTOR'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('empty, loading and failed conversations provide useful feedback',
      (tester) async {
    await _pump(tester, const ChatsListScreen(), overrides: [
      friendsStreamProvider.overrideWith((ref) => Stream.value([]))
    ]);
    expect(find.textContaining('No conversations yet'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    final pending = StreamController<List<ChatMessageEntity>>();
    await _pump(tester,
        const FriendChatScreen(friendUid: 'pending', friendName: 'Agent'),
        overrides: [
          directMessagesProvider('pending')
              .overrideWith((ref) => pending.stream)
        ]);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.addError(Exception('offline'));
    await tester.pump();
    expect(find.text('Could not load this conversation.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.runAsync(() => pending.close());
    await _pump(
        tester, const FriendChatScreen(friendUid: 'empty', friendName: 'Agent'),
        overrides: [
          directMessagesProvider('empty')
              .overrideWith((ref) => Stream.value([]))
        ]);
    expect(find.text('No messages yet. Say hello!'), findsOneWidget);
  });
  testWidgets('briefing stays usable on a narrow screen with large text',
      (tester) async {
    await _pump(
        tester,
        RoomBriefingView(
            room: _room,
            players: AsyncData(_players),
            currentUid: 'self',
            speakers: const {},
            seconds: 17,
            onLeave: () {},
            onChat: () {},
            onContinue: () {},
            onRetry: () {}),
        size: const Size(320, 640),
        scale: 1.5,
        overrides: [
          liveKitAudioServiceProvider.overrideWithValue(_Audio()),
          isAudioConnectedProvider.overrideWith((ref) => Stream.value(false)),
          isMicMutedProvider.overrideWith((ref) => Stream.value(true))
        ]);
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Secret role'), findsOneWidget);
  });
  test(
      'inbox orders live previews, exposes partial errors, cancels subscriptions',
      () async {
    final first = StreamController<List<ChatMessageEntity>>();
    final second = StreamController<List<ChatMessageEntity>>();
    var cancelled = 0;
    first.onCancel = () {
      cancelled++;
    };
    second.onCancel = () {
      cancelled++;
    };
    final container = ProviderContainer(overrides: [
      friendsStreamProvider
          .overrideWith((ref) => Stream.value(_friends.take(2).toList())),
      directMessagesProvider('real_0').overrideWith((ref) => first.stream),
      directMessagesProvider('real_1').overrideWith((ref) => second.stream)
    ]);
    final sub = container.listen(inboxProvider, (_, __) {});
    await Future<void>.delayed(Duration.zero);
    first.add([_message('real_0', 'first', 1)]);
    second.add([_message('real_1', 'second', 2)]);
    await Future<void>.delayed(Duration.zero);
    expect(
        container
            .read(inboxProvider)
            .requireValue
            .conversations
            .first
            .friend
            .uid,
        'real_1');
    first.add([_message('real_0', 'latest', 3)]);
    await Future<void>.delayed(Duration.zero);
    expect(
        container
            .read(inboxProvider)
            .requireValue
            .conversations
            .first
            .message
            .message,
        'latest');
    second.addError(Exception('offline'));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(inboxProvider).requireValue.failedIds, ['real_1']);
    sub.close();
    container.dispose();
    await Future.wait([first.close(), second.close()]);
    expect(cancelled, 2);
  });
  test('briefing counts preserve existing allocation rules', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    for (final total in [5, 6, 8, 9, 12]) {
      final counts = container.read(briefingRoleCountsProvider(total));
      expect(counts.values.fold<int>(0, (sum, n) => sum + n), total);
      expect(
          counts[PlayerRole.mafia],
          total >= 9
              ? 3
              : total >= 6
                  ? 2
                  : 1);
      expect(counts[PlayerRole.snitch], total > 8 ? 1 : 0);
    }
  });
}
