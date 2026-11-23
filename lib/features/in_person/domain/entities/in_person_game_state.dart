import '../../../game/domain/entities/game_room_entity.dart';
import 'in_person_game_config.dart';

class InPersonGameState {
  final InPersonGameConfig config;
  final Map<String, PlayerRole> playerRoles;
  final List<String> alivePlayerNames;
  final List<String> eliminatedPlayerNames;
  final GamePhase currentPhase;
  final Map<String, String> nightActions;
  final Map<String, String> dayVotes;
  final List<String> readyToVotePlayerNames;
  final String? winningFaction;
  final List<String> historyLogs;
  final int currentPassIndex;

  const InPersonGameState({
    required this.config,
    required this.playerRoles,
    required this.alivePlayerNames,
    this.eliminatedPlayerNames = const [],
    this.currentPhase = GamePhase.lobby,
    this.nightActions = const {},
    this.dayVotes = const {},
    this.readyToVotePlayerNames = const [],
    this.winningFaction,
    this.historyLogs = const [],
    this.currentPassIndex = 0,
  });

  InPersonGameState copyWith({
    InPersonGameConfig? config,
    Map<String, PlayerRole>? playerRoles,
    List<String>? alivePlayerNames,
    List<String>? eliminatedPlayerNames,
    GamePhase? currentPhase,
    Map<String, String>? nightActions,
    Map<String, String>? dayVotes,
    List<String>? readyToVotePlayerNames,
    String? winningFaction,
    List<String>? historyLogs,
    int? currentPassIndex,
  }) {
    return InPersonGameState(
      config: config ?? this.config,
      playerRoles: playerRoles ?? this.playerRoles,
      alivePlayerNames: alivePlayerNames ?? this.alivePlayerNames,
      eliminatedPlayerNames: eliminatedPlayerNames ?? this.eliminatedPlayerNames,
      currentPhase: currentPhase ?? this.currentPhase,
      nightActions: nightActions ?? this.nightActions,
      dayVotes: dayVotes ?? this.dayVotes,
      readyToVotePlayerNames: readyToVotePlayerNames ?? this.readyToVotePlayerNames,
      winningFaction: winningFaction ?? this.winningFaction,
      historyLogs: historyLogs ?? this.historyLogs,
      currentPassIndex: currentPassIndex ?? this.currentPassIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'config': config.toJson(),
      'playerRoles': playerRoles.map((k, v) => MapEntry(k, v.name)),
      'alivePlayerNames': alivePlayerNames,
      'eliminatedPlayerNames': eliminatedPlayerNames,
      'currentPhase': currentPhase.name,
      'nightActions': nightActions,
      'dayVotes': dayVotes,
      'readyToVotePlayerNames': readyToVotePlayerNames,
      'winningFaction': winningFaction,
      'historyLogs': historyLogs,
      'currentPassIndex': currentPassIndex,
    };
  }

  factory InPersonGameState.fromJson(Map<String, dynamic> json) {
    final rolesMap = (json['playerRoles'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(
              k,
              PlayerRole.values.firstWhere(
                (e) => e.name == v,
                orElse: () => PlayerRole.civilian,
              ),
            ));

    return InPersonGameState(
      config: InPersonGameConfig.fromJson(json['config'] ?? {}),
      playerRoles: rolesMap,
      alivePlayerNames: List<String>.from(json['alivePlayerNames'] ?? []),
      eliminatedPlayerNames: List<String>.from(json['eliminatedPlayerNames'] ?? []),
      currentPhase: GamePhase.values.firstWhere(
        (e) => e.name == json['currentPhase'],
        orElse: () => GamePhase.lobby,
      ),
      nightActions: Map<String, String>.from(json['nightActions'] ?? {}),
      dayVotes: Map<String, String>.from(json['dayVotes'] ?? {}),
      readyToVotePlayerNames: List<String>.from(json['readyToVotePlayerNames'] ?? []),
      winningFaction: json['winningFaction'],
      historyLogs: List<String>.from(json['historyLogs'] ?? []),
      currentPassIndex: json['currentPassIndex'] ?? 0,
    );
  }
}
