import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/team.dart';

class TeamRepository {
  TeamRepository(this._client);

  final SupabaseClient _client;

  Future<List<Team>> fetchTeams({
    required int leagueId,
    int? seasonId,
  }) async {
    final ids = <int>{};

    if (seasonId != null) {
      try {
        final memberships = await _client
            .from('season_teams')
            .select('team_id')
            .eq('season_id', seasonId)
            .eq('league_id', leagueId);
        for (final row in _asRows(memberships)) {
          final id = _asInt(row['team_id']);
          if (id != null) ids.add(id);
        }
      } on PostgrestException catch (error) {
        if (!_isMissingSchema(error)) rethrow;
      }

      final directRows = await _client
          .from('teams')
          .select('id')
          .eq('league_id', leagueId)
          .eq('season_id', seasonId);
      for (final row in _asRows(directRows)) {
        final id = _asInt(row['id']);
        if (id != null) ids.add(id);
      }
    }

    final dynamic response;
    if (ids.isNotEmpty) {
      response = await _client
          .from('teams')
          .select('id,name,logo_url,league_id,season_id')
          .inFilter('id', ids.toList())
          .order('name');
    } else if (seasonId != null) {
      response = await _client
          .from('teams')
          .select('id,name,logo_url,league_id,season_id')
          .eq('league_id', leagueId)
          .eq('season_id', seasonId)
          .order('name');
    } else {
      response = await _client
          .from('teams')
          .select('id,name,logo_url,league_id,season_id')
          .eq('league_id', leagueId)
          .order('name');
    }

    return _asRows(response).map(Team.fromMap).toList(growable: false);
  }

  Future<Map<int, Team>> fetchTeamMap({
    required int leagueId,
    int? seasonId,
  }) async {
    final teams = await fetchTeams(leagueId: leagueId, seasonId: seasonId);
    return {for (final team in teams) team.id: team};
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
