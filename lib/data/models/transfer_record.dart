class TransferRecord {
  const TransferRecord({
    required this.id,
    this.playerId,
    this.playerName,
    this.fromTeamId,
    this.fromTeamName,
    this.fromLeagueId,
    this.toTeamId,
    this.toTeamName,
    this.toLeagueId,
    this.seasonId,
    this.seasonName,
    this.transferDate,
    this.notes,
    this.type,
  });

  final int id;
  final int? playerId;
  final String? playerName;
  final int? fromTeamId;
  final String? fromTeamName;
  final int? fromLeagueId;
  final int? toTeamId;
  final String? toTeamName;
  final int? toLeagueId;
  final int? seasonId;
  final String? seasonName;
  final DateTime? transferDate;
  final String? notes;
  final String? type;

  int? get leagueId => toLeagueId ?? fromLeagueId;

  String get typeLabel {
    final normalized = (type ?? '').trim().toLowerCase();
    final toName = (toTeamName ?? '').trim().toLowerCase();
    if (toName == 'wolni zawodnicy') return 'Wolny zawodnik';
    if (normalized == 'loan' || normalized == 'wypożyczenie') return 'Wypożyczenie';
    if (normalized == 'loan_end' || normalized.contains('koniec')) return 'Koniec wypoż.';
    return 'Transfer';
  }

  factory TransferRecord.fromMap(Map<String, dynamic> map) {
    int? asInt(dynamic value) => value is num ? value.toInt() : int.tryParse('$value');
    DateTime? asDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse('$value');
    }

    final player = map['player'] is Map<String, dynamic>
        ? map['player'] as Map<String, dynamic>
        : null;
    final fromTeam = map['from_team'] is Map<String, dynamic>
        ? map['from_team'] as Map<String, dynamic>
        : null;
    final toTeam = map['to_team'] is Map<String, dynamic>
        ? map['to_team'] as Map<String, dynamic>
        : null;
    final season = map['season'] is Map<String, dynamic>
        ? map['season'] as Map<String, dynamic>
        : null;

    return TransferRecord(
      id: asInt(map['id']) ?? 0,
      playerId: asInt(player?['id'] ?? map['player_id']),
      playerName: player?['name'] as String?,
      fromTeamId: asInt(fromTeam?['id'] ?? map['from_team_id']),
      fromTeamName: fromTeam?['name'] as String?,
      fromLeagueId: asInt(fromTeam?['league_id']),
      toTeamId: asInt(toTeam?['id'] ?? map['to_team_id']),
      toTeamName: toTeam?['name'] as String?,
      toLeagueId: asInt(toTeam?['league_id']),
      seasonId: asInt(season?['id'] ?? map['season_id']),
      seasonName: season?['name'] as String?,
      transferDate: asDate(map['transfer_date'] ?? map['created_at']),
      notes: map['notes'] as String?,
      type: map['type'] as String?,
    );
  }
}
