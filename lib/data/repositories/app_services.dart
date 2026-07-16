import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_repository.dart';
import 'league_repository.dart';
import 'match_repository.dart';
import 'player_repository.dart';
import 'team_repository.dart';
import 'transfer_repository.dart';

class AppServices {
  AppServices(SupabaseClient client)
      : leagueRepository = LeagueRepository(client),
        teamRepository = TeamRepository(client),
        matchRepository = MatchRepository(client),
        playerRepository = PlayerRepository(client),
        authRepository = AuthRepository(client),
        transferRepository = TransferRepository(client);

  final LeagueRepository leagueRepository;
  final TeamRepository teamRepository;
  final MatchRepository matchRepository;
  final PlayerRepository playerRepository;
  final AuthRepository authRepository;
  final TransferRepository transferRepository;
}

class RepositoryScope extends InheritedWidget {
  const RepositoryScope({
    required this.services,
    required super.child,
    super.key,
  });

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RepositoryScope>();
    assert(scope != null, 'RepositoryScope is missing above this context.');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(RepositoryScope oldWidget) => services != oldWidget.services;
}
