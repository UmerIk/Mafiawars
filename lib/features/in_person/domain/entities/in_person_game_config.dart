enum InPersonGameMode { fullDigital, moderatorAssistant }

class InPersonGameConfig {
  final InPersonGameMode mode;
  final List<String> playerNames;
  final int mafiaCount;
  final bool includeDoctor;
  final bool includeDetective;
  final int civilianCount;
  final int discussionSeconds;
  final int votingSeconds;
  final bool revealRoleOnElimination;

  const InPersonGameConfig({
    required this.mode,
    required this.playerNames,
    this.mafiaCount = 1,
    this.includeDoctor = true,
    this.includeDetective = true,
    this.civilianCount = 1,
    this.discussionSeconds = 240,
    this.votingSeconds = 45,
    this.revealRoleOnElimination = true,
  });

  int get totalPlayers => playerNames.length;
  int get totalRoles =>
      mafiaCount +
      (includeDoctor ? 1 : 0) +
      (includeDetective ? 1 : 0) +
      civilianCount;

  bool get isValid =>
      totalPlayers >= 5 &&
      totalPlayers == totalRoles &&
      mafiaCount >= 1 &&
      mafiaCount < (totalPlayers / 2) &&
      playerNames.every((name) => name.trim().isNotEmpty);

  String? get validationError {
    if (playerNames.any((name) => name.trim().isEmpty)) {
      return 'All player names must be non-empty.';
    }
    if (totalPlayers < 5) {
      return 'A minimum of 5 players is required.';
    }
    if (totalPlayers != totalRoles) {
      return 'Total players ($totalPlayers) must equal total assigned roles ($totalRoles).';
    }
    if (mafiaCount < 1) {
      return 'At least 1 Mafia role is required.';
    }
    if (mafiaCount >= (totalPlayers / 2)) {
      return 'Mafia count must be less than half of total players.';
    }
    return null;
  }

  InPersonGameConfig copyWith({
    InPersonGameMode? mode,
    List<String>? playerNames,
    int? mafiaCount,
    bool? includeDoctor,
    bool? includeDetective,
    int? civilianCount,
    int? discussionSeconds,
    int? votingSeconds,
    bool? revealRoleOnElimination,
  }) {
    return InPersonGameConfig(
      mode: mode ?? this.mode,
      playerNames: playerNames ?? this.playerNames,
      mafiaCount: mafiaCount ?? this.mafiaCount,
      includeDoctor: includeDoctor ?? this.includeDoctor,
      includeDetective: includeDetective ?? this.includeDetective,
      civilianCount: civilianCount ?? this.civilianCount,
      discussionSeconds: discussionSeconds ?? this.discussionSeconds,
      votingSeconds: votingSeconds ?? this.votingSeconds,
      revealRoleOnElimination:
          revealRoleOnElimination ?? this.revealRoleOnElimination,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'playerNames': playerNames,
      'mafiaCount': mafiaCount,
      'includeDoctor': includeDoctor,
      'includeDetective': includeDetective,
      'civilianCount': civilianCount,
      'discussionSeconds': discussionSeconds,
      'votingSeconds': votingSeconds,
      'revealRoleOnElimination': revealRoleOnElimination,
    };
  }

  factory InPersonGameConfig.fromJson(Map<String, dynamic> json) {
    return InPersonGameConfig(
      mode: InPersonGameMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => InPersonGameMode.fullDigital,
      ),
      playerNames: List<String>.from(json['playerNames'] ?? []),
      mafiaCount: json['mafiaCount'] ?? 1,
      includeDoctor: json['includeDoctor'] ?? true,
      includeDetective: json['includeDetective'] ?? true,
      civilianCount: json['civilianCount'] ?? 1,
      discussionSeconds: json['discussionSeconds'] ?? 240,
      votingSeconds: json['votingSeconds'] ?? 45,
      revealRoleOnElimination: json['revealRoleOnElimination'] ?? true,
    );
  }
}
