import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/glo_match.dart';
import '../models/match_event.dart';

class MatchRepository {
  MatchRepository(this._client);

  final SupabaseClient _client;

  static const columns = '''
    id,league_id,season_id,status,match_type,round_number,date,time,venue,
    referee,referee_email,home_team_id,away_team_id,home_score,away_score,
    mvp_player_id,mvp_away_player_id,live_period,live_clock_started_at,
    live_elapsed_seconds,live_break_started_at,live_break_seconds,
    live_added_first_seconds,live_added_second_seconds
  ''';

  Future<List<GloMatch>> fetchMatches({
    required int leagueId,
    int? seasonId,
  }) async {
    final dynamic response;
    if (seasonId == null) {
      response = await _client
          .from('matches')
          .select(columns)
          .eq('league_id', leagueId)
          .order('round_number')
          .order('date')
          .order('time');
    } else {
      response = await _client
          .from('matches')
          .select(columns)
          .eq('league_id', leagueId)
          .eq('season_id', seasonId)
          .order('round_number')
          .order('date')
          .order('time');
    }
    return _asRows(response).map(GloMatch.fromMap).toList(growable: false);
  }

  Stream<List<GloMatch>> watchMatches({
    required int leagueId,
    int? seasonId,
  }) {
    // Supabase stream filters do not support chaining multiple eq() calls in
    // every supabase_flutter version. Keep one server-side filter, then apply
    // the optional season filter locally so CI works across SDK updates.
    return _client
        .from('matches')
        .stream(primaryKey: const ['id'])
        .eq('league_id', leagueId)
        .order('date')
        .order('time')
        .map((rows) {
          final filtered = seasonId == null
              ? rows
              : rows.where((row) {
                  final value = row['season_id'];
                  if (value is num) return value.toInt() == seasonId;
                  return int.tryParse('$value') == seasonId;
                });
          return filtered.map(GloMatch.fromMap).toList(growable: false);
        });
  }

  Stream<GloMatch?> watchMatch(int matchId) {
    return _client
        .from('matches')
        .stream(primaryKey: const ['id'])
        .eq('id', matchId)
        .map((rows) => rows.isEmpty ? null : GloMatch.fromMap(rows.first));
  }

  Stream<List<MatchEvent>> watchGoals(int matchId) {
    return _client
        .from('match_goals')
        .stream(primaryKey: const ['id'])
        .eq('match_id', matchId)
        .order('minute')
        .map(
          (rows) => rows
              .where((row) => (row['type'] as String?) != 'assist_only')
              .map(MatchEvent.goal)
              .toList(growable: false),
        );
  }

  Stream<List<MatchEvent>> watchCards(int matchId) {
    return _client
        .from('match_cards')
        .stream(primaryKey: const ['id'])
        .eq('match_id', matchId)
        .order('minute')
        .map(
          (rows) => rows.map(MatchEvent.card).toList(growable: false),
        );
  }

  Future<void> startLiveMatch(GloMatch match) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _client.from('matches').update({
      'status': 'live',
      'home_score': match.homeScore ?? 0,
      'away_score': match.awayScore ?? 0,
      'live_period': 'first_half',
      'live_clock_started_at': now,
      'live_elapsed_seconds': 0,
      'live_break_started_at': null,
      'live_break_seconds': 600,
      'live_added_first_seconds': 0,
      'live_added_second_seconds': 0,
      'live_started_at': now,
    }).eq('id', match.id);
  }

  Future<void> startBreak(GloMatch match) async {
    await _client.from('matches').update({
      'live_period': 'half_time',
      'live_elapsed_seconds': 1800,
      'live_clock_started_at': null,
      'live_break_started_at': DateTime.now().toUtc().toIso8601String(),
      'live_break_seconds': 600,
    }).eq('id', match.id);
  }

  Future<void> startSecondHalf(GloMatch match) async {
    await _client.from('matches').update({
      'live_period': 'second_half',
      'live_elapsed_seconds': 1800,
      'live_clock_started_at': DateTime.now().toUtc().toIso8601String(),
      'live_break_started_at': null,
    }).eq('id', match.id);
  }

  Future<void> addAddedMinute(GloMatch match) async {
    final period = match.livePeriod?.toLowerCase();
    if (period == 'first_half') {
      await _client.from('matches').update({
        'live_added_first_seconds': match.liveAddedFirstSeconds + 60,
      }).eq('id', match.id);
      return;
    }
    if (period == 'second_half') {
      await _client.from('matches').update({
        'live_added_second_seconds': match.liveAddedSecondSeconds + 60,
      }).eq('id', match.id);
      return;
    }
    throw StateError('Doliczony czas można dodać tylko podczas połowy.');
  }

  Future<void> finishLiveMatch(GloMatch match) async {
    final score = await recalculateScore(match);
    await _client.from('matches').update({
      'status': 'completed',
      'home_score': score.$1,
      'away_score': score.$2,
      'live_period': 'finished',
      'live_clock_started_at': null,
      'live_break_started_at': null,
      'live_finished_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', match.id);
  }

  Future<(int, int)> recalculateScore(GloMatch match) async {
    final response = await _client
        .from('match_goals')
        .select('team_id,type')
        .eq('match_id', match.id);
    var home = 0;
    var away = 0;
    for (final row in _asRows(response)) {
      if ((row['type'] as String?) == 'assist_only') continue;
      final teamId = _asInt(row['team_id']);
      if (teamId == match.homeTeamId) home++;
      if (teamId == match.awayTeamId) away++;
    }
    await _client.from('matches').update({
      'home_score': home,
      'away_score': away,
    }).eq('id', match.id);
    return (home, away);
  }

  Future<void> addGoal({
    required GloMatch match,
    required int playerId,
    required int playerTeamId,
    int? assistPlayerId,
    String type = 'normal',
  }) async {
    final normalizedType = switch (type) {
      'penalty' => 'penalty',
      'own_goal' => 'own_goal',
      _ => 'normal',
    };
    final scoringTeamId = normalizedType == 'own_goal'
        ? (playerTeamId == match.homeTeamId
            ? match.awayTeamId
            : match.homeTeamId)
        : playerTeamId;
    final minute = currentEventMinute(match);

    await _client.from('match_goals').insert({
      'match_id': match.id,
      'player_id': playerId,
      'team_id': scoringTeamId,
      'assist_player_id': normalizedType == 'own_goal' ? null : assistPlayerId,
      'minute': minute.$1,
      'live_period': minute.$2,
      'extra_minute': minute.$3,
      'type': normalizedType,
    });
    await recalculateScore(match);
  }

  Future<void> addCard({
    required GloMatch match,
    required int playerId,
    required int playerTeamId,
    required String type,
  }) async {
    final minute = currentEventMinute(match);
    await _client.from('match_cards').insert({
      'match_id': match.id,
      'player_id': playerId,
      'team_id': playerTeamId,
      'type': type == 'red' ? 'red' : 'yellow',
      'minute': minute.$1,
      'live_period': minute.$2,
      'extra_minute': minute.$3,
    });
  }

  Future<void> deleteGoal(GloMatch match, int goalId) async {
    await _client.from('match_goals').delete().eq('id', goalId);
    await recalculateScore(match);
  }

  Future<void> deleteCard(int cardId) async {
    await _client.from('match_cards').delete().eq('id', cardId);
  }

  static (int?, String?, int?) currentEventMinute(
    GloMatch match, {
    DateTime? now,
  }) {
    final clock = LiveClockState.fromMatch(match, now: now);
    if (clock.period == 'first_half') {
      if (clock.elapsedSeconds > 1800) return (30, 'first_half', clock.extraMinute);
      return (
        (clock.elapsedSeconds / 60).ceil().clamp(1, 30).toInt(),
        'first_half',
        null,
      );
    }
    if (clock.period == 'second_half') {
      if (clock.elapsedSeconds > 3600) return (60, 'second_half', clock.extraMinute);
      return (
        (clock.elapsedSeconds / 60).ceil().clamp(31, 60).toInt(),
        'second_half',
        null,
      );
    }
    return (null, clock.period, null);
  }

  static int? _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value');

  static List<Map<String, dynamic>> _asRows(dynamic value) {
    return (value as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }
}

class LiveClockState {
  const LiveClockState({
    required this.period,
    required this.phase,
    required this.display,
    required this.elapsedSeconds,
    required this.extraMinute,
    required this.breakRemainingSeconds,
  });

  final String period;
  final String phase;
  final String display;
  final int elapsedSeconds;
  final int extraMinute;
  final int breakRemainingSeconds;

  factory LiveClockState.fromMatch(GloMatch match, {DateTime? now}) {
    final current = (now ?? DateTime.now()).toUtc();
    final period = (match.livePeriod ?? (match.isLive ? 'first_half' : 'not_started'))
        .toLowerCase();
    var elapsed = match.liveElapsedSeconds;
    if (match.isLive &&
        (period == 'first_half' || period == 'second_half') &&
        match.liveClockStartedAt != null) {
      elapsed += current
          .difference(match.liveClockStartedAt!.toUtc())
          .inSeconds
          .clamp(0, 1 << 30)
          .toInt();
    }
    if (period == 'half_time') elapsed = 1800;

    var breakRemaining = match.liveBreakSeconds;
    if (period == 'half_time' && match.liveBreakStartedAt != null) {
      final passed = current.difference(match.liveBreakStartedAt!.toUtc()).inSeconds;
      breakRemaining = (match.liveBreakSeconds - passed)
          .clamp(0, match.liveBreakSeconds)
          .toInt();
    }

    String phase = 'Nie rozpoczęto';
    String display = '00:00';
    var extra = 0;

    if (period == 'first_half') {
      phase = 'I połowa';
      if (elapsed <= 1800) {
        display = _clock(elapsed);
      } else {
        extra = ((elapsed - 1800) / 60).ceil();
        display = '30+$extra';
      }
    } else if (period == 'half_time') {
      phase = 'Przerwa';
      display = _clock(breakRemaining);
    } else if (period == 'second_half') {
      phase = 'II połowa';
      if (elapsed <= 3600) {
        display = _clock(elapsed);
      } else {
        extra = ((elapsed - 3600) / 60).ceil();
        display = '60+$extra';
      }
    } else if (match.isCompleted || period == 'finished') {
      phase = 'Zakończony';
      display = '60:00';
    }

    return LiveClockState(
      period: period,
      phase: phase,
      display: display,
      elapsedSeconds: elapsed,
      extraMinute: extra,
      breakRemainingSeconds: breakRemaining,
    );
  }

  String get label => period == 'half_time' ? 'Przerwa $display' : '$phase $display';

  static String _clock(int seconds) {
    final safe = seconds.clamp(0, 1 << 30).toInt();
    final minutes = (safe ~/ 60).toString().padLeft(2, '0');
    final rest = (safe % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }
}
