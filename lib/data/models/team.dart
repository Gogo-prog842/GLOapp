class Team {
  const Team({
    required this.id,
    required this.name,
    required this.leagueId,
    this.seasonId,
    this.logoUrl,
  });

  final int id;
  final String name;
  final int leagueId;
  final int? seasonId;
  final String? logoUrl;

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: (map['id'] as num).toInt(),
      name: (map['name'] as String?) ?? 'Drużyna',
      leagueId: ((map['league_id'] as num?) ?? 1).toInt(),
      seasonId: (map['season_id'] as num?)?.toInt(),
      logoUrl: map['logo_url'] as String?,
    );
  }
}
