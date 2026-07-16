class Player {
  const Player({
    required this.id,
    required this.name,
    required this.teamId,
    this.leagueId,
    this.avatarUrl,
    this.position,
    this.jerseyNumber,
    this.teamName,
    this.teamLogo,
    this.goals = 0,
    this.assists = 0,
    this.matchesPlayed = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.mvpCount = 0,
  });

  final int id;
  final String name;
  final int? teamId;
  final int? leagueId;
  final String? avatarUrl;
  final String? position;
  final int? jerseyNumber;
  final String? teamName;
  final String? teamLogo;
  final int goals;
  final int assists;
  final int matchesPlayed;
  final int yellowCards;
  final int redCards;
  final int mvpCount;

  Player copyWith({
    int? goals,
    int? assists,
    int? matchesPlayed,
    int? yellowCards,
    int? redCards,
    int? mvpCount,
  }) {
    return Player(
      id: id,
      name: name,
      teamId: teamId,
      leagueId: leagueId,
      avatarUrl: avatarUrl,
      position: position,
      jerseyNumber: jerseyNumber,
      teamName: teamName,
      teamLogo: teamLogo,
      goals: goals ?? this.goals,
      assists: assists ?? this.assists,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      yellowCards: yellowCards ?? this.yellowCards,
      redCards: redCards ?? this.redCards,
      mvpCount: mvpCount ?? this.mvpCount,
    );
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    int? asInt(dynamic value) => value is num ? value.toInt() : int.tryParse('$value');
    final team = map['team'] is Map<String, dynamic>
        ? map['team'] as Map<String, dynamic>
        : null;

    return Player(
      id: asInt(map['id']) ?? 0,
      name: (map['name'] as String?) ?? 'Zawodnik',
      teamId: asInt(map['team_id']),
      leagueId: asInt(map['league_id']),
      avatarUrl: map['avatar_url'] as String?,
      position: map['position'] as String?,
      jerseyNumber: asInt(map['jersey_number']),
      teamName: team?['name'] as String?,
      teamLogo: team?['logo_url'] as String?,
    );
  }
}
