import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/transfer_record.dart';

class TransferRepository {
  TransferRepository(this._client);

  final SupabaseClient _client;

  Future<List<TransferRecord>> fetchTransfers({
    int? leagueId,
    int? seasonId,
    int limit = 250,
  }) async {
    final response = await _client
        .from('player_transfers')
        .select('''
          id, player_id, from_team_id, to_team_id, transfer_date, created_at, notes, type, season_id,
          player:players(id,name,team_id),
          from_team:teams!player_transfers_from_team_id_fkey(id,name,league_id,logo_url),
          to_team:teams!player_transfers_to_team_id_fkey(id,name,league_id,logo_url),
          season:seasons(id,name)
        ''')
        .order('transfer_date', ascending: false)
        .order('id', ascending: false)
        .limit(limit);

    var records = _asRows(response)
        .map(TransferRecord.fromMap)
        .toList(growable: false);

    if (leagueId != null) {
      records = records.where((transfer) => transfer.leagueId == leagueId).toList(growable: false);
    }
    if (seasonId != null) {
      records = records
          .where((transfer) => transfer.seasonId == null || transfer.seasonId == seasonId)
          .toList(growable: false);
    }
    return records;
  }

  static List<Map<String, dynamic>> _asRows(dynamic value) {
    return (value as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }
}
