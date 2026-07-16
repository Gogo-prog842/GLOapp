import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/models/glo_match.dart';
import '../../data/models/player.dart';
import '../../data/models/team.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/app_services.dart';
import '../../state/app_scope.dart';

class CaptainPanelScreen extends StatefulWidget {
  const CaptainPanelScreen({super.key});

  @override
  State<CaptainPanelScreen> createState() => _CaptainPanelScreenState();
}

class _CaptainPanelScreenState extends State<CaptainPanelScreen> {
  late Future<_CaptainPanelData> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future = _load();
  }

  Future<_CaptainPanelData> _load() async {
    final controller = AppScope.of(context);
    final services = RepositoryScope.of(context);
    final role = controller.role;
    final team = role.team;

    if (team == null || role.type == UserRoleType.guest || role.type == UserRoleType.player) {
      return const _CaptainPanelData();
    }

    final leagueId = team.leagueId ?? controller.selectedLeagueId;
    final results = await Future.wait<dynamic>([
      services.playerRepository.fetchPlayersForTeam(team.id),
      services.matchRepository.fetchMatches(
        leagueId: leagueId,
        seasonId: controller.selectedSeasonId,
      ),
      services.teamRepository.fetchTeamMap(
        leagueId: leagueId,
        seasonId: controller.selectedSeasonId,
      ),
    ]);

    final players = results[0] as List<Player>;
    final matches = results[1] as List<GloMatch>;
    final teamMap = results[2] as Map<int, Team>;
    final teamMatches = matches
        .where((match) => match.homeTeamId == team.id || match.awayTeamId == team.id)
        .toList(growable: false);
    teamMatches.sort((a, b) => (a.date ?? DateTime(2100)).compareTo(b.date ?? DateTime(2100)));

    return _CaptainPanelData(
      team: team,
      players: players,
      matches: teamMatches,
      teamMap: teamMap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = AppScope.of(context).role;
    if (role.type != UserRoleType.captain && role.type != UserRoleType.admin) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('Panel kapitana pojawi się po zalogowaniu na konto kapitana lub admina.'),
            ),
          ),
        ],
      );
    }

    return FutureBuilder<_CaptainPanelData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const GloLoading(label: 'Ładowanie panelu kapitana…');
        }
        if (snapshot.hasError) {
          return GloError(
            message: snapshot.error.toString(),
            onRetry: () => setState(() => _future = _load()),
          );
        }
        final data = snapshot.data ?? const _CaptainPanelData();
        if (data.team == null) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('Nie znaleziono drużyny przypisanej do tego konta.'),
                ),
              ),
            ],
          );
        }

        final upcoming = data.matches
            .where((match) => !match.isCompleted)
            .take(5)
            .toList(growable: false);
        final completed = data.matches
            .where((match) => match.isCompleted)
            .take(5)
            .toList(growable: false);

        return RefreshIndicator(
          onRefresh: () async => setState(() => _future = _load()),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _TeamHeader(team: data.team!, playerCount: data.players.length),
              const SizedBox(height: 14),
              SectionHeader(title: 'Kadra'),
              const SizedBox(height: 8),
              if (data.players.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Brak zawodników w drużynie.'),
                  ),
                )
              else
                ...data.players.map(_PlayerTile.new),
              const SizedBox(height: 18),
              SectionHeader(title: 'Najbliższe mecze'),
              const SizedBox(height: 8),
              if (upcoming.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Brak nadchodzących meczów.'),
                  ),
                )
              else
                ...upcoming.map((match) => _MatchMiniCard(
                      match: match,
                      teamId: data.team!.id,
                      teamMap: data.teamMap,
                    )),
              const SizedBox(height: 18),
              SectionHeader(title: 'Ostatnie mecze'),
              const SizedBox(height: 8),
              if (completed.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Brak zakończonych meczów.'),
                  ),
                )
              else
                ...completed.map((match) => _MatchMiniCard(
                      match: match,
                      teamId: data.team!.id,
                      teamMap: data.teamMap,
                    )),
            ],
          ),
        );
      },
    );
  }
}

class _CaptainPanelData {
  const _CaptainPanelData({
    this.team,
    this.players = const [],
    this.matches = const [],
    this.teamMap = const {},
  });

  final Team? team;
  final List<Player> players;
  final List<GloMatch> matches;
  final Map<int, Team> teamMap;
}

class _TeamHeader extends StatelessWidget {
  const _TeamHeader({required this.team, required this.playerCount});

  final Team team;
  final int playerCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            TeamLogo(team: team, size: 58),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(team.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('$playerCount zawodników w kadrze', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile(this.player);

  final Player player;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: GloColors.primary.withValues(alpha: 0.16),
          backgroundImage: (player.avatarUrl ?? '').isEmpty ? null : NetworkImage(player.avatarUrl!),
          child: (player.avatarUrl ?? '').isEmpty ? Text(_initials(player.name)) : null,
        ),
        title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text([
          if ((player.position ?? '').isNotEmpty) player.position,
          if (player.jerseyNumber != null) '#${player.jerseyNumber}',
        ].whereType<String>().join(' · ')),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((part) => part.isEmpty ? '' : part[0]).join().toUpperCase();
  }
}

class _MatchMiniCard extends StatelessWidget {
  const _MatchMiniCard({
    required this.match,
    required this.teamId,
    required this.teamMap,
  });

  final GloMatch match;
  final int teamId;
  final Map<int, Team> teamMap;

  @override
  Widget build(BuildContext context) {
    final isHome = match.homeTeamId == teamId;
    final opponentId = isHome ? match.awayTeamId : match.homeTeamId;
    final opponent = teamMap[opponentId]?.name ?? 'Drużyna #$opponentId';
    final score = match.homeScore != null && match.awayScore != null
        ? '${match.homeScore}:${match.awayScore}'
        : '—';
    final homeAway = isHome ? 'Dom' : 'Wyjazd';
    final round = match.roundNumber == null ? 'bez kolejki' : '${match.roundNumber}. kolejka';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(isHome ? Icons.home_outlined : Icons.flight_takeoff_outlined),
        title: Text(opponent, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('$homeAway · $round · ${_statusLabel(match.status)}'),
        trailing: Text(score, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }

  String _statusLabel(String status) {
    final value = status.toLowerCase();
    if (value == 'completed' || value == 'finished') return 'zakończony';
    if (value == 'live') return 'LIVE';
    if (value == 'postponed') return 'przełożony';
    if (value == 'cancelled') return 'odwołany';
    return 'zaplanowany';
  }
}
