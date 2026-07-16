import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/team.dart';
import '../models/user_role.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email.trim(), password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<UserRole> resolveRole() async {
    final session = currentSession;
    if (session == null) return const UserRole(type: UserRoleType.guest);
    final email = (session.user.email ?? '').trim().toLowerCase();

    final admin = await _client
        .from('admins')
        .select('email')
        .ilike('email', email)
        .maybeSingle();
    if (admin != null) {
      return UserRole(type: UserRoleType.admin, email: email);
    }

    try {
      final referee = await _client
          .from('referee_accounts')
          .select('email,name')
          .ilike('email', email)
          .maybeSingle();
      if (referee != null) {
        return UserRole(
          type: UserRoleType.referee,
          email: email,
          refereeName: referee['name'] as String?,
        );
      }
    } on PostgrestException catch (_) {
      // Stary projekt może nie mieć jeszcze tabeli referee_accounts.
    }

    Map<String, dynamic>? captain;
    try {
      captain = await _client
          .from('team_captains')
          .select('team:teams(id,name,logo_url,league_id,season_id)')
          .eq('user_id', session.user.id)
          .limit(1)
          .maybeSingle();
      captain ??= await _client
          .from('team_captains')
          .select('team:teams(id,name,logo_url,league_id,season_id)')
          .ilike('email', email)
          .limit(1)
          .maybeSingle();
    } on PostgrestException catch (_) {
      captain = null;
    }

    final captainTeam = captain?['team'];
    if (captainTeam is Map<String, dynamic>) {
      return UserRole(
        type: UserRoleType.captain,
        email: email,
        team: Team.fromMap(captainTeam),
      );
    }

    final legacyTeam = await _client
        .from('teams')
        .select('id,name,logo_url,league_id,season_id')
        .ilike('captain_email', email)
        .limit(1)
        .maybeSingle();
    if (legacyTeam != null) {
      return UserRole(
        type: UserRoleType.captain,
        email: email,
        team: Team.fromMap(legacyTeam),
      );
    }

    return UserRole(type: UserRoleType.player, email: email);
  }
}
