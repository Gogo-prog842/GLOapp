import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/league.dart';
import '../models/season.dart';

class LeagueRepository {
  LeagueRepository(this._client);

  final SupabaseClient _client;

  Future<List<League>> fetchLeagues() async {
    final response = await _client.from('leagues').select('id,name').order('id');
    return _asRows(response).map(League.fromMap).toList(growable: false);
  }

  Future<List<Season>> fetchSeasons(int leagueId) async {
    final response = await _client
        .from('seasons')
        .select('id,name,league_id,start_date,end_date,is_active')
        .eq('league_id', leagueId)
        .order('start_date', ascending: false);
    return _asRows(response).map(Season.fromMap).toList(growable: false);
  }

  static List<Map<String, dynamic>> _asRows(dynamic value) {
    return (value as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }
}
