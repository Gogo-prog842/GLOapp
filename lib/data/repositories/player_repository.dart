import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/player.dart';
import '../models/team.dart';

class PlayerRepository {
  PlayerRepository(this._client);

  final SupabaseClient _client;

  Future<List<Player>> fetchPlayersWithStats({
    required int leagueId,
    required List<Team> teams,
    int? seasonId,
  }) async {
    final teamIds = teams.map((team) => team.id).toList(growable: false);
    if (teamIds.isEmpty) return const [];

    var playerIds = <int>[];
    if (seasonId != null) {
      try {
        final memberships = await _client
            .from('season_players')
            .select('player_id')
            .eq('season_id', seasonId)
            .eq('league_id', leagueId);
        playerIds = _asRows(memberships)
            .map((row) => _asInt(row['player_id']))
            .whereType<int>()
            .toSet()
            .toList(growable: false);
      } on PostgrestException catch (error) {
        if (!_isMissingSchema(error)) rethrow;
      }
    }

    final dynamic playerResponse;
    if (playerIds.isNotEmpty) {
      playerResponse = await _client
          .from('players')
          .select(
            'id,name,team_id,league_id,avatar_url,position,jersey_number,is_hidden,'
            'team:teams!players_team_id_fkey(id,name,logo_url)',
          )
          .inFilter('id', playerIds)
          .order('name');
    } else {
      playerResponse = await _client
          .from('players')
          .select(
            'id,name,team_id,league_id,avatar_url,position,jersey_number,is_hidden,'
            'team:teams!players_team_id_fkey(id,name,logo_url)',
          )
          .inFilter('team_id', teamIds)
          .order('name');
    }

    final basePlayers = _asRows(playerResponse)
        .where((row) => row['is_hidden'] != true)
        .map(Player.fromMap)
        .toList(growable: false);
    if (basePlayers.isEmpty) return const [];

    final dynamic matchResponse;
    if (seasonId == null) {
      matchResponse = await _client
          .from('matches')
          .select(
            'id,status,match_type,home_team_id,away_team_id,mvp_player_id,mvp_away_player_id',
          )
          .eq('league_id', leagueId)
          .eq('status', 'completed');
    } else {
      matchResponse = await _client
          .from('matches')
          .select(
            'id,status,match_type,home_team_id,away_team_id,mvp_player_id,mvp_away_player_id',
          )
          .eq('league_id', leagueId)
          .eq('season_id', seasonId)
          .eq('status', 'completed');
    }

    final matches = _asRows(matchResponse).where(_isLeagueMatch).toList(growable: false);
    final matchIds = matches
        .map((row) => _asInt(row['id']))
        .whereType<int>()
        .toList(growable: false);
    if (matchIds.isEmpty) return basePlayers;

    final results = await Future.wait<dynamic>([
      _client
          .from('match_goals')
          .select('match_id,player_id,assist_player_id,type')
          .inFilter('match_id', matchIds),
      _client
          .from('match_lineups')
          .select('match_id,player_id')
          .inFilter('match_id', matchIds),
      _client
          .from('match_cards')
          .select('match_id,player_id,type')
          .inFilter('match_id', matchIds),
    ]);

    final goals = <int, int>{};
    final assists = <int, int>{};
    for (final row in _asRows(results[0])) {
      if ((row['type'] as String?) != 'assist_only' &&
          (row['type'] as String?) != 'own_goal') {
        final playerId = _asInt(row['player_id']);
        if (playerId != null) goals[playerId] = (goals[playerId] ?? 0) + 1;
      }
      final assistId = _asInt(row['assist_player_id']);
      if (assistId != null) assists[assistId] = (assists[assistId] ?? 0) + 1;
    }

    final appearances = <int, Set<int>>{};
    for (final row in _asRows(results[1])) {
      final playerId = _asInt(row['player_id']);
      final matchId = _asInt(row['match_id']);
      if (playerId != null && matchId != null) {
        appearances.putIfAbsent(playerId, () => <int>{}).add(matchId);
      }
    }

    final yellow = <int, int>{};
    final red = <int, int>{};
    for (final row in _asRows(results[2])) {
      final playerId = _asInt(row['player_id']);
      if (playerId == null) continue;
      if ((row['type'] as String?)?.toLowerCase() == 'red') {
        red[playerId] = (red[playerId] ?? 0) + 1;
      } else {
        yellow[playerId] = (yellow[playerId] ?? 0) + 1;
      }
    }

    final mvp = <int, int>{};
    for (final row in matches) {
      for (final value in [row['mvp_player_id'], row['mvp_away_player_id']]) {
        final playerId = _asInt(value);
        if (playerId != null) mvp[playerId] = (mvp[playerId] ?? 0) + 1;
      }
    }

    final decorated = basePlayers.map((player) {
      return player.copyWith(
        goals: goals[player.id] ?? 0,
        assists: assists[player.id] ?? 0,
        matchesPlayed: appearances[player.id]?.length ?? 0,
        yellowCards: yellow[player.id] ?? 0,
        redCards: red[player.id] ?? 0,
        mvpCount: mvp[player.id] ?? 0,
      );
    }).toList(growable: false);

    decorated.sort((a, b) {
      final byGoals = b.goals.compareTo(a.goals);
      if (byGoals != 0) return byGoals;
      final byAssists = b.assists.compareTo(a.assists);
      if (byAssists != 0) return byAssists;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return decorated;
  }

  Future<Map<int, Player>> fetchPlayersForTeams(List<int> teamIds) async {
    if (teamIds.isEmpty) return const {};
    final response = await _client
        .from('players')
        .select(
          'id,name,team_id,league_id,avatar_url,position,jersey_number,'
          'team:teams!players_team_id_fkey(id,name,logo_url)',
        )
        .inFilter('team_id', teamIds)
        .order('name');
    final players = _asRows(response).map(Player.fromMap);
    return {for (final player in players) player.id: player};
  }

  static bool _isLeagueMatch(Map<String, dynamic> row) {
    final type = (row['match_type'] as String?)?.trim().toLowerCase();
    return type == null || type.isEmpty || type == 'league';
  }

  static bool _isMissingSchema(PostgrestException error) {
    final message = '${error.message} ${error.details}'.toLowerCase();
    return message.contains('does not exist') ||
        message.contains('schema cache') ||
        message.contains('could not find');
  }

  static int? _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value');

  static List<Map<String, dynamic>> _asRows(dynamic value) {
    return (value as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }
}
