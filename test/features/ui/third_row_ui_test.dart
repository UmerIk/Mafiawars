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
import 'package:my_flutter_app/features/game/presentation/providers/night_action_provider.dart';
import 'package:my_flutter_app/features/game/presentation/widgets/night_game_view.dart';
import 'package:my_flutter_app/features/game/presentation/widgets/sunrise_outcomes.dart';

class _Game extends Fake implements GameRepository {
  bool fail = false;
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
const _saved =
    'Mafia tried to kill someone but doctor saved that person and detective has made a right guess';
const _killed =
    'Mafia killed p5 , doctor saved the wrong person and detective has made a wrong guess';
const _capture = ValueKey('capture');
Widget _view(
        {GamePhase phase = GamePhase.nightMafia,
        PlayerRole? role = PlayerRole.mafia,
        AsyncValue<Map<String, String>> actions = const AsyncData({}),
        List<RoomPlayerEntity>? players,
        AsyncValue<List<RoomPlayerEntity>>? playersState,
        AsyncValue<PlayerRoleEntity?>? roleState,
        String? summary,
        int seconds = 20,
        VoidCallback? advance,
        VoidCallback? next}) =>
    NightGameView(
        room: _room(phase, summary: summary),
        players: playersState ?? AsyncData(players ?? _players),
        role: roleState ??
            AsyncData(role == null
                ? null
                : PlayerRoleEntity(
                    userId: 'p0', role: role, faction: role.faction)),
        actions: actions,
        currentUid: 'p0',
        speakers: const {'p1'},
        seconds: seconds,
        onLeave: () {},
        onChat: () {},
        onRetryPlayers: () {},
        onAdvance: advance,
        onContinue: next ?? () {});
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
    final directory = Directory('/tmp/mafia-third-row-previews')
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
    testWidgets('all six state variants fit ${size.width}', (tester) async {
      final variants = <String, Widget>{
        'attack-agree': _view(
            actions: const AsyncData(
                {'nightMafia_p0': 'p2', 'nightMafia_p1': 'p2'})),
        'attack-differ': _view(
            actions: const AsyncData(
                {'nightMafia_p0': 'p2', 'nightMafia_p1': 'p3'})),
        'protection': _view(
            phase: GamePhase.nightDoctor,
            role: PlayerRole.doctor,
            actions: const AsyncData({'nightDoctor': 'p0'})),
        'investigation': _view(
            phase: GamePhase.nightDetective,
            role: PlayerRole.detective,
            actions: const AsyncData({'nightDetective': 'p4'})),
        'sunrise-killed': _view(
            phase: GamePhase.dayDiscussion, summary: _killed, seconds: 240),
        'sunrise-saved': _view(
            phase: GamePhase.dayDiscussion, summary: _saved, seconds: 240),
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
  testWidgets('large text keeps panel scrollable and controls accessible',
      (tester) async {
    await _pump(tester, _view(), size: const Size(320, 640), scale: 1.5);
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Game chat'), findsOneWidget);
    await tester.drag(
        find.byType(SingleChildScrollView).last, const Offset(0, -600));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await _pump(tester,
        _view(phase: GamePhase.dayDiscussion, summary: _saved, seconds: 240),
        size: const Size(320, 640), scale: 1.5);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'failed night action retries and a pending action cannot be repeated',
      (tester) async {
    final game = _Game()..fail = true;
    await _pump(tester, _view(), game: game);
    await tester.tap(find.byKey(const ValueKey('target_p2')));
    await tester.pump();
    expect(game.targets, ['p2']);
    expect(find.textContaining('Selection could not be saved'), findsOneWidget);
    game.fail = false;
    game.gate = Completer<void>();
    await tester.tap(find.byKey(const ValueKey('target_p2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('target_p3')));
    await tester.pump();
    expect(game.targets, ['p2', 'p2']);
    game.gate!.complete();
    await tester.pump();
    await tester.pump();
    expect(find.text('Selection submitted.'), findsOneWidget);
    expect(
        tester
            .widget<AgentChip>(find.byKey(const ValueKey('target_p2')))
            .selected,
        isTrue);
  });
  testWidgets('wrong role and eliminated agents cannot select targets',
      (tester) async {
    final game = _Game();
    await _pump(
        tester,
        _view(
            role: PlayerRole.civilian,
            actions: const AsyncData({'nightMafia_p1': 'p2'})),
        game: game);
    expect(find.byType(AgentChip), findsNothing);
    expect(find.text('Wait while the Mafia acts.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    final dead = [..._players];
    dead[0] = dead[0].copyWith(isAlive: false);
    final audio = _Audio();
    await _pump(tester, _view(players: dead), game: game, audio: audio);
    expect(find.byType(AgentChip), findsNothing);
    await tester.tap(find.byTooltip('Microphone unavailable while eliminated'));
    await tester.pump();
    expect(game.targets, isEmpty);
    expect(audio.micCalls, 0);
  });
  testWidgets(
      'expired phase disables selection and host menu uses existing callback',
      (tester) async {
    final game = _Game();
    var advances = 0;
    await _pump(tester, _view(seconds: 0, advance: () => advances++),
        game: game);
    await tester.tap(find.byKey(const ValueKey('target_p2')));
    await tester.pump();
    expect(game.targets, isEmpty);
    expect(find.text('Awaiting next phase…'), findsOneWidget);
    await tester.tap(find.byTooltip('Host controls'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Advance phase (host)'));
    await tester.pumpAndSettle();
    expect(advances, 1);
  });
  testWidgets('loading, role errors and action errors have feedback',
      (tester) async {
    await _pump(tester, _view(playersState: const AsyncLoading()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await _pump(tester,
        _view(roleState: AsyncError(Exception('offline'), StackTrace.current)));
    expect(find.text('Your role could not be loaded.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await _pump(tester,
        _view(actions: AsyncError(Exception('offline'), StackTrace.current)));
    expect(find.text('Selections could not be loaded.'), findsOneWidget);
  });
  testWidgets('sunrise dismisses locally and uses current server deadline',
      (tester) async {
    var continued = 0;
    await _pump(
        tester,
        _view(
            phase: GamePhase.dayDiscussion,
            summary: _saved,
            seconds: 239,
            next: () => continued++));
    expect(find.text('03:59'), findsOneWidget);
    expect(find.text('239s'), findsOneWidget);
    expect(find.text('Saved the right agent'), findsOneWidget);
    await tester.tap(find.text('Continue to discussion'));
    await tester.pump();
    expect(continued, 1);
  });
  test('target eligibility preserves role, alive, and self-selection rules',
      () {
    for (final role in PlayerRole.values) {
      expect(
          canChooseNightTarget(
              phase: GamePhase.nightMafia,
              role: role,
              actor: _players[0],
              target: _players[1]),
          role == PlayerRole.mafia);
    }
    expect(
        canChooseNightTarget(
            phase: GamePhase.nightDoctor,
            role: PlayerRole.doctor,
            actor: _players[0],
            target: _players[0]),
        isTrue);
    expect(
        canChooseNightTarget(
            phase: GamePhase.nightDetective,
            role: PlayerRole.detective,
            actor: _players[0],
            target: _players[0]),
        isFalse);
    expect(
        canChooseNightTarget(
            phase: GamePhase.nightMafia,
            role: PlayerRole.mafia,
            actor: _players[0],
            target: _players[1].copyWith(isAlive: false)),
        isFalse);
    expect(
        canChooseNightTarget(
            phase: GamePhase.dayVoting,
            role: PlayerRole.mafia,
            actor: _players[0],
            target: _players[1]),
        isFalse);
  });
  test('sunrise parses only recognized summaries and public player identities',
      () {
    final saved = sunriseOutcomes(_saved, _players);
    expect(saved.length, 3);
    expect(saved[0].success, isFalse);
    expect(saved[1].success, isTrue);
    expect(saved[2].success, isTrue);
    final killed = sunriseOutcomes(_killed, _players);
    expect(killed.first.player?.userId, 'p5');
    expect(killed[1].success, isFalse);
    expect(killed[2].success, isFalse);
    expect(
        sunriseOutcomes(
            'Mafia killed Someone , doctor saved the wrong person and detective has made a wrong guess',
            _players),
        isEmpty);
    expect(sunriseOutcomes('New server summary', _players), isEmpty);
    expect(sunriseOutcomes(null, _players), isEmpty);
  });
  test('phase deadline scopes selection and disposal during send is safe',
      () async {
    final game = _Game()..gate = Completer<void>();
    final controller = NightActionController(game, 'room');
    final pending = controller.submit('p2');
    controller.dispose();
    game.gate!.complete();
    await pending;
    final container = ProviderContainer(
        overrides: [gameRepositoryProvider.overrideWithValue(_Game())]);
    addTearDown(container.dispose);
    final first =
        (roomId: 'room', phase: GamePhase.nightMafia, deadline: _deadline);
    final second = (
      roomId: 'room',
      phase: GamePhase.nightMafia,
      deadline: _deadline.add(const Duration(minutes: 5))
    );
    final sub = container.listen(nightActionProvider(first), (_, __) {});
    addTearDown(sub.close);
    await container.read(nightActionProvider(first).notifier).submit('p2');
    expect(container.read(nightActionProvider(first)).requireValue, 'p2');
    expect(container.read(nightActionProvider(second)).requireValue, isNull);
  });
}
