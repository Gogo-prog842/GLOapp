enum MatchEventKind { goal, yellowCard, redCard }

class MatchEvent {
  const MatchEvent({
    required this.id,
    required this.matchId,
    required this.teamId,
    required this.playerId,
    required this.kind,
    this.assistPlayerId,
    this.minute,
    this.extraMinute,
    this.goalType,
  });

  final int id;
  final int matchId;
  final int teamId;
  final int playerId;
  final int? assistPlayerId;
  final int? minute;
  final int? extraMinute;
  final MatchEventKind kind;
  final String? goalType;

  String get minuteLabel {
    if (minute == null) return '—';
    if ((extraMinute ?? 0) > 0) return '$minute+${extraMinute!}\'';
    return '$minute\'';
  }

  factory MatchEvent.goal(Map<String, dynamic> map) {
    return MatchEvent(
      id: _asInt(map['id']) ?? 0,
      matchId: _asInt(map['match_id']) ?? 0,
      teamId: _asInt(map['team_id']) ?? 0,
      playerId: _asInt(map['player_id']) ?? 0,
      assistPlayerId: _asInt(map['assist_player_id']),
      minute: _asInt(map['minute']),
      extraMinute: _asInt(map['extra_minute']),
      kind: MatchEventKind.goal,
      goalType: map['type'] as String?,
    );
  }

  factory MatchEvent.card(Map<String, dynamic> map) {
    final type = (map['type'] as String?)?.toLowerCase();
    return MatchEvent(
      id: _asInt(map['id']) ?? 0,
      matchId: _asInt(map['match_id']) ?? 0,
      teamId: _asInt(map['team_id']) ?? 0,
      playerId: _asInt(map['player_id']) ?? 0,
      minute: _asInt(map['minute']),
      extraMinute: _asInt(map['extra_minute']),
      kind: type == 'red' ? MatchEventKind.redCard : MatchEventKind.yellowCard,
    );
  }

  static int? _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value');
}
