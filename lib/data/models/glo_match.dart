class GloMatch {
  const GloMatch({
    required this.id,
    required this.leagueId,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.status,
    this.seasonId,
    this.roundNumber,
    this.date,
    this.time,
    this.venue,
    this.referee,
    this.refereeEmail,
    this.matchType,
    this.homeScore,
    this.awayScore,
    this.mvpPlayerId,
    this.mvpAwayPlayerId,
    this.livePeriod,
    this.liveClockStartedAt,
    this.liveElapsedSeconds = 0,
    this.liveBreakStartedAt,
    this.liveBreakSeconds = 600,
    this.liveAddedFirstSeconds = 0,
    this.liveAddedSecondSeconds = 0,
  });

  final int id;
  final int leagueId;
  final int? seasonId;
  final int homeTeamId;
  final int awayTeamId;
  final String status;
  final int? roundNumber;
  final DateTime? date;
  final String? time;
  final String? venue;
  final String? referee;
  final String? refereeEmail;
  final String? matchType;
  final int? homeScore;
  final int? awayScore;
  final int? mvpPlayerId;
  final int? mvpAwayPlayerId;
  final String? livePeriod;
  final DateTime? liveClockStartedAt;
  final int liveElapsedSeconds;
  final DateTime? liveBreakStartedAt;
  final int liveBreakSeconds;
  final int liveAddedFirstSeconds;
  final int liveAddedSecondSeconds;

  bool get isLive => status.toLowerCase() == 'live';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isScheduled => status.toLowerCase() == 'scheduled';
  bool get isLeagueMatch {
    final normalized = matchType?.trim().toLowerCase();
    return normalized == null || normalized.isEmpty || normalized == 'league';
  }

  factory GloMatch.fromMap(Map<String, dynamic> map) {
    int? asInt(dynamic value) => value is num ? value.toInt() : int.tryParse('$value');

    return GloMatch(
      id: asInt(map['id']) ?? 0,
      leagueId: asInt(map['league_id']) ?? 1,
      seasonId: asInt(map['season_id']),
      homeTeamId: asInt(map['home_team_id']) ?? 0,
      awayTeamId: asInt(map['away_team_id']) ?? 0,
      status: (map['status'] as String?) ?? 'scheduled',
      roundNumber: asInt(map['round_number']),
      date: DateTime.tryParse((map['date'] as String?) ?? ''),
      time: map['time'] as String?,
      venue: map['venue'] as String?,
      referee: map['referee'] as String?,
      refereeEmail: map['referee_email'] as String?,
      matchType: map['match_type'] as String?,
      homeScore: asInt(map['home_score']),
      awayScore: asInt(map['away_score']),
      mvpPlayerId: asInt(map['mvp_player_id']),
      mvpAwayPlayerId: asInt(map['mvp_away_player_id']),
      livePeriod: map['live_period'] as String?,
      liveClockStartedAt:
          DateTime.tryParse((map['live_clock_started_at'] as String?) ?? ''),
      liveElapsedSeconds: asInt(map['live_elapsed_seconds']) ?? 0,
      liveBreakStartedAt:
          DateTime.tryParse((map['live_break_started_at'] as String?) ?? ''),
      liveBreakSeconds: asInt(map['live_break_seconds']) ?? 600,
      liveAddedFirstSeconds: asInt(map['live_added_first_seconds']) ?? 0,
      liveAddedSecondSeconds: asInt(map['live_added_second_seconds']) ?? 0,
    );
  }
}
