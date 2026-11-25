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
import 'package:my_flutter_app/features/audio/livekit_audio_service.dart';
import 'package:my_flutter_app/features/audio/providers/audio_providers.dart';
import 'package:my_flutter_app/features/game/domain/entities/game_room_entity.dart';
import 'package:my_flutter_app/features/game/domain/repositories/game_repository.dart';
import 'package:my_flutter_app/features/game/presentation/providers/game_providers.dart';
import 'package:my_flutter_app/features/game/presentation/widgets/day_game_view.dart';
import 'package:my_flutter_app/features/game/presentation/providers/day_game_provider.dart';

class _Game extends Fake implements GameRepository {
  bool fail = false;
  int readiness = 0;
  @override
  Future<void> toggleReadyToVote(String roomId) async {
    readiness++;
    if (fail) throw Exception("offline");
  }

  @override
  Future<void> submitDayVote(
          {required String roomId, required String targetUserId}) =>
      submitPhaseAction(roomId: roomId, targetUserId: targetUserId);
  Completer<void>? gate;
  final targets = <String>[];
  @override
  Future<void> submitPhaseAction(
      {required String roomId, required String targetUserId}) async {
    targets.add(targetUserId);
    if (gate != null) await gate!.future;
    if (fail) throw Exception('offline');
  }
}

class _Audio extends Fake implements LiveKitAudioService {
  bool muted = false, speaker = true;
  int micCalls = 0;
  @override
  bool get isConnected => true;
  @override
  bool get isMuted => muted;
  @override
  bool get isSpeakerphoneOn => speaker;
  @override
  Future<void> toggleMicrophone() async {
    micCalls++;
    muted = !muted;
  }

  @override
  Future<void> setSpeakerphoneEnabled(bool enabled) async {
    speaker = enabled;
  }
}

final _players = List.generate(
    8,
    (i) => RoomPlayerEntity(
        userId: 'p$i',
        displayName: [
          'Agent47',
          'Sci-dude',
          'Rayven',
          'PandaRed',
          'Cypork',
          'itsyobro',
          'itsyoboy',
          'Faceless'
        ][i],
        avatarUrl: 'avatar_${[16, 12, 11, 7, 19, 13, 4, 20][i]}',
        slotIndex: i,
        isHost: i == 0,
        joinedAt: DateTime(2026)));
final _deadline = DateTime(2026, 11, 25, 12);
GameRoomEntity _room(GamePhase phase, {String? summary}) => GameRoomEntity(
    roomId: 'room',
    code: '2QR13T',
    hostId: 'p0',
    createdAt: DateTime(2026),
    status: GameRoomStatus.inGame,
    phase: phase,
    phaseEndTime: _deadline,
    nightFacts: summary == null ? null : {'summary': summary});
const _capture = ValueKey('capture');
Widget _view(
        {GamePhase phase = GamePhase.dayDiscussion,
        List<RoomPlayerEntity>? players,
        AsyncValue<List<RoomPlayerEntity>>? playersState,
        AsyncValue<Map<String, String>> votes = const AsyncData({}),
        VoteDecision? decision,
        int seconds = 150,
        VoidCallback? next,
        VoidCallback? advance}) =>
    DayGameView(
        room: _room(phase),
        players: playersState ?? AsyncData(players ?? _roster),
        votes: votes,
        currentUid: 'p0',
        speakers: const {'p1'},
        seconds: seconds,
        onLeave: () {},
        onChat: () {},
        onRetryPlayers: () {},
        decision: decision,
        onDismissDecision: next ?? () {},
        onAdvance: advance);
final _roster = [
  ..._players.take(6),
  _players[6].copyWith(isAlive: false, eliminationType: 'killed'),
  _players[7].copyWith(isAlive: false, eliminationType: 'eliminated')
];
Future<void> _pump(WidgetTester tester, Widget view,
    {Size size = const Size(440, 956),
    double scale = 1,
    _Game? game,
    _Audio? audio}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ProviderScope(
      overrides: [
        gameRepositoryProvider.overrideWithValue(game ?? _Game()),
        liveKitAudioServiceProvider.overrideWithValue(audio ?? _Audio()),
        isAudioConnectedProvider
            .overrideWith((ref) => const Stream<bool>.empty()),
        isMicMutedProvider.overrideWith((ref) => const Stream<bool>.empty()),
        currentNarrationTextProvider.overrideWith((ref) => Stream.value(null)),
      ],
      child: MaterialApp(
          theme: ThemeData(fontFamily: 'MafiaInter'),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!),
          home: RepaintBoundary(key: _capture, child: view))));
  await tester.runAsync(() async {
    final context = tester.element(find.byKey(_capture));
    await Future.wait([
      precacheImage(const AssetImage(AppAssets.background), context),
      precacheImage(const AssetImage(AppAssets.avatars), context),
      precacheImage(const AssetImage(AppAssets.eliminationBlood), context),
      precacheImage(const AssetImage(AppAssets.eliminationJail), context),
      precacheImage(const AssetImage(AppAssets.actionKnife), context),
      precacheImage(const AssetImage(AppAssets.actionStethoscope), context),
      precacheImage(const AssetImage(AppAssets.actionSyringe), context),
      precacheImage(const AssetImage(AppAssets.actionSearch), context)
    ]);
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('UI_PREVIEWS')) return;
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_capture));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('/tmp/mafia-fourth-row-previews')
      ..createSync(recursive: true);
    File('${directory.path}/$name.png')
        .writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    final font = FontLoader('MafiaInter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([font.load(), icons.load()]);
  });
  for (final size in [
    const Size(320, 640),
    const Size(440, 956),
    const Size(800, 1024)
  ]) {
    testWidgets('all last-row variants fit ${size.width}', (tester) async {
      final dead = [..._roster];
      dead[0] = dead[0].copyWith(isAlive: false, eliminationType: 'killed');
      final variants = <String, Widget>{
        'discussion': _view(),
        'voting': _view(
            phase: GamePhase.dayVoting,
            votes: const AsyncData({'p0': 'p2', 'p1': 'p3', 'p4': 'p3'}),
            seconds: 45),
        'decision': _view(
            phase: GamePhase.nightMafia,
            decision: const VoteDecision(playerId: 'p7', voters: {
              'p0': 'p7',
              'p1': 'p7',
              'p2': 'p7',
              'p3': 'p7',
              'p4': 'p7'
            }),
            seconds: 20),
        'eliminated-roster': _view(players: _roster),
        'eliminated-self': _view(players: dead),
      };
      for (final entry in variants.entries) {
        await _pump(tester, entry.value, size: size);
        expect(tester.takeException(), isNull, reason: entry.key);
        await _preview(tester, '${entry.key}-${size.width.toInt()}');
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      }
    });
  }
  testWidgets('large text scrolls discussion and voting without overflow',
      (tester) async {
    for (final phase in [GamePhase.dayDiscussion, GamePhase.dayVoting]) {
      await _pump(tester, _view(phase: phase),
          size: const Size(320, 640), scale: 1.5);
      expect(tester.takeException(), isNull);
      await tester.drag(
          find.byType(SingleChildScrollView).last, const Offset(0, -500));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Game chat'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }
  });
  testWidgets('readiness calls existing action and retries errors',
      (tester) async {
    final game = _Game()..fail = true;
    await _pump(tester, _view(), game: game);
    await tester.tap(find.text('Ready to vote (0/6)'));
    await tester.pump();
    expect(game.readiness, 1);
    expect(find.text('Could not update readiness. Please try again.'),
        findsOneWidget);
    game.fail = false;
    await tester.tap(find.text('Ready to vote (0/6)'));
    await tester.pump();
    expect(game.readiness, 2);
    expect(find.text('Could not update readiness. Please try again.'),
        findsNothing);
  });
  testWidgets(
      'votes retain prior choice on failure and prevent pending duplicates',
      (tester) async {
    final game = _Game()..fail = true;
    await _pump(tester, _view(phase: GamePhase.dayVoting), game: game);
    await tester.tap(find.byKey(const ValueKey('vote_p2')));
    await tester.pump();
    expect(game.targets, ['p2']);
    expect(find.textContaining('Your vote could not be saved'), findsOneWidget);
    game.fail = false;
    game.gate = Completer<void>();
    await tester.tap(find.byKey(const ValueKey('vote_p2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('vote_p3')));
    await tester.pump();
    expect(game.targets, ['p2', 'p2']);
    game.gate!.complete();
    await tester.pump();
    await tester.pump();
    expect(find.text('Vote submitted.'), findsOneWidget);
  });
  testWidgets('dead, self and expired targets cannot receive votes',
      (tester) async {
    final game = _Game();
    await _pump(tester, _view(phase: GamePhase.dayVoting), game: game);
    expect(
        tester.widget<AgentChip>(find.byKey(const ValueKey('vote_p0'))).enabled,
        isFalse);
    expect(
        tester.widget<AgentChip>(find.byKey(const ValueKey('vote_p7'))).enabled,
        isFalse);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await _pump(tester, _view(phase: GamePhase.dayVoting, seconds: 0),
        game: game);
    await tester.tap(find.byKey(const ValueKey('vote_p2')));
    await tester.pump();
    expect(game.targets, isEmpty);
  });
  testWidgets('eliminated self has no readiness, vote or microphone action',
      (tester) async {
    final dead = [..._roster];
    dead[0] = dead[0].copyWith(isAlive: false);
    final game = _Game();
    final audio = _Audio();
    await _pump(tester, _view(players: dead), game: game, audio: audio);
    expect(find.textContaining('Ready to vote'), findsNothing);
    await tester.tap(find.byTooltip('Microphone unavailable while eliminated'));
    await tester.pump();
    expect(audio.micCalls, 0);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await _pump(tester, _view(phase: GamePhase.dayVoting, players: dead),
        game: game);
    await tester.tap(find.byKey(const ValueKey('vote_p2')));
    await tester.pump();
    expect(game.targets, isEmpty);
    expect(find.text('Voting is read only for eliminated agents.'),
        findsOneWidget);
  });
  testWidgets('decision shows public voter identities and dismisses',
      (tester) async {
    var next = 0;
    await _pump(
        tester,
        _view(
            phase: GamePhase.nightMafia,
            decision: const VoteDecision(
                playerId: 'p7', voters: {'p0': 'p7', 'p1': 'p7'}),
            next: () => next++));
    expect(find.text('Has been eliminated due to 2 votes against them'),
        findsOneWidget);
    expect(find.text('Voted against them'), findsOneWidget);
    await tester.drag(
        find.byType(SingleChildScrollView).last, const Offset(0, -500));
    await tester.pump();
    await tester.tap(find.text('Continue to game'));
    await tester.pump();
    expect(next, 1);
  });
  testWidgets('tie or missing vote data does not invent a total',
      (tester) async {
    await _pump(tester,
        _view(decision: const VoteDecision(playerId: null, voters: {})));
    expect(find.text('No agent was eliminated in this vote.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await _pump(tester,
        _view(decision: const VoteDecision(playerId: 'p7', voters: {})));
    expect(find.textContaining('Vote totals are unavailable'), findsOneWidget);
  });
  testWidgets('loading and stream errors expose feedback', (tester) async {
    await _pump(tester, _view(playersState: const AsyncLoading()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await _pump(
        tester,
        _view(
            phase: GamePhase.dayVoting,
            votes: AsyncError(Exception('offline'), StackTrace.current)));
    expect(find.text('Votes could not be loaded.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
  test(
      'decision derives from published eliminated IDs and an observed voting transition',
      () {
    final before =
        _room(GamePhase.dayVoting).copyWith(eliminatedPlayerIds: ['p6']);
    final after =
        _room(GamePhase.nightMafia).copyWith(eliminatedPlayerIds: ['p6', 'p7']);
    final decision =
        decisionFromTransition(before, after, {'p0': 'p7', 'p1': 'p7'})!;
    expect(decision.playerId, 'p7');
    expect(decision.count, 2);
    expect(
        decisionFromTransition(
                before, after.copyWith(eliminatedPlayerIds: ['p6']), {})!
            .playerId,
        isNull);
    expect(decisionFromTransition(_room(GamePhase.nightDoctor), after, {}),
        isNull);
    expect(
        decisionFromTransition(
            before, after.copyWith(status: GameRoomStatus.lobby), {}),
        isNull);
  });
  test(
      'failed replacement vote keeps successful selection and disposed sends are safe',
      () async {
    final game = _Game();
    final controller = DayActionController(game, 'room');
    await controller.vote('p2');
    expect(controller.state.requireValue, 'p2');
    game.fail = true;
    await controller.vote('p3');
    expect(controller.state.hasError, isTrue);
    expect(controller.state.valueOrNull, 'p2');
    controller.dispose();
    final pendingGame = _Game()..gate = Completer<void>();
    final pendingController = DayActionController(pendingGame, 'room');
    final first = pendingController.vote('p2');
    await pendingController.vote('p3');
    expect(pendingGame.targets, ['p2']);
    pendingController.dispose();
    pendingGame.gate!.complete();
    await first;
  });
}
