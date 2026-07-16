import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/match_card.dart';
import '../../data/models/glo_match.dart';
import '../../data/models/player.dart';
import '../../data/models/standing_row.dart';
import '../../data/models/team.dart';
import '../../data/repositories/app_services.dart';
import '../../state/app_scope.dart';
import '../matches/match_details_screen.dart';
import '../standings/standings_calculator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<_HomeData>? _future;
  String? _selectionKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.of(context);
    final key = '${controller.selectedLeagueId}:${controller.selectedSeasonId}';
    if (_selectionKey != key) {
      _selectionKey = key;
      _future = _load();
    }
  }

  Future<_HomeData> _load() async {
    final controller = AppScope.of(context);
    final services = RepositoryScope.of(context);
    final teams = await services.teamRepository.fetchTeams(
      leagueId: controller.selectedLeagueId,
      seasonId: controller.selectedSeasonId,
    );
    final results = await Future.wait<dynamic>([
      services.matchRepository.fetchMatches(
        leagueId: controller.selectedLeagueId,
        seasonId: controller.selectedSeasonId,
      ),
      services.playerRepository.fetchPlayersWithStats(
        leagueId: controller.selectedLeagueId,
        seasonId: controller.selectedSeasonId,
        teams: teams,
      ),
    ]);
    final matches = results[0] as List<GloMatch>;
    final players = results[1] as List<Player>;
    return _HomeData(
      teams: teams,
      matches: matches,
      players: players,
      standings: StandingsCalculator.calculate(teams, matches),
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomeData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const GloLoading();
        if (snapshot.hasError) {
          return GloError(message: '${snapshot.error}', onRetry: _refresh);
        }
        final data = snapshot.requireData;
        final teamMap = {for (final team in data.teams) team.id: team};
        final live = data.matches.where((match) => match.isLive).toList(growable: false);
        final upcoming = data.matches
            .where((match) => match.isScheduled)
            .toList(growable: false)
          ..sort((a, b) => _dateTime(a).compareTo(_dateTime(b)));
        final recent = data.matches.where((match) => match.isCompleted).toList(growable: false)
          ..sort((a, b) => _dateTime(b).compareTo(_dateTime(a)));

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
            children: [
              _HeroCard(
                teamCount: data.teams.length,
                playerCount: data.players.length,
                liveCount: live.length,
                playedCount: data.matches.where((match) => match.isCompleted).length,
              ),
              if (live.isNotEmpty) ...[
                const SizedBox(height: 24),
                const SectionHeader(title: 'Teraz LIVE'),
                const SizedBox(height: 12),
                ...live.map(
                  (match) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: MatchCard(
                      match: match,
                      teams: teamMap,
                      onTap: () => _openMatch(match, teamMap),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const SectionHeader(title: 'Czołówka tabeli'),
              const SizedBox(height: 12),
              _CompactStandings(rows: data.standings.take(5).toList(growable: false)),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Najlepsi strzelcy'),
              const SizedBox(height: 12),
              _TopPlayers(players: data.players.take(5).toList(growable: false)),
              if (upcoming.isNotEmpty) ...[
                const SizedBox(height: 24),
                const SectionHeader(title: 'Najbliższe mecze'),
                const SizedBox(height: 12),
                ...upcoming.take(3).map(
                  (match) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: MatchCard(
                      match: match,
                      teams: teamMap,
                      onTap: () => _openMatch(match, teamMap),
                    ),
                  ),
                ),
              ],
              if (recent.isNotEmpty) ...[
                const SizedBox(height: 24),
                const SectionHeader(title: 'Ostatnie wyniki'),
                const SizedBox(height: 12),
                ...recent.take(3).map(
                  (match) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: MatchCard(
                      match: match,
                      teams: teamMap,
                      onTap: () => _openMatch(match, teamMap),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _openMatch(GloMatch match, Map<int, Team> teams) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchDetailsScreen(
          initialMatch: match,
          homeTeam: teams[match.homeTeamId],
          awayTeam: teams[match.awayTeamId],
        ),
      ),
    );
  }

  static DateTime _dateTime(GloMatch match) {
    final date = match.date ?? DateTime(2100);
    final parts = (match.time ?? '').split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0,
      parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.teamCount,
    required this.playerCount,
    required this.liveCount,
    required this.playedCount,
  });

  final int teamCount;
  final int playerCount;
  final int liveCount;
  final int playedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF102449), Color(0xFF0C1426)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: GloColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GRUDZIĄDZKA LIGA ORLIKOWA', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Wyniki, statystyki i mecze na żywo w jednej aplikacji.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Metric(label: 'Drużyny', value: '$teamCount'),
              _Metric(label: 'Zawodnicy', value: '$playerCount'),
              _Metric(label: 'Rozegrane', value: '$playedCount'),
              _Metric(label: 'LIVE', value: '$liveCount', danger: liveCount > 0),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.danger = false});

  final String label;
  final String value;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GloColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: danger ? GloColors.danger : null)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _CompactStandings extends StatelessWidget {
  const _CompactStandings({required this.rows});

  final List<StandingRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  SizedBox(width: 24, child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w900))),
                  TeamLogo(team: rows[index].team, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(rows[index].team.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  Text('${rows[index].played}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 16),
                  SizedBox(width: 32, child: Text('${rows[index].points}', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w900))),
                ],
              ),
            ),
            if (index != rows.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _TopPlayers extends StatelessWidget {
  const _TopPlayers({required this.players});

  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (var index = 0; index < players.length; index++) ...[
            ListTile(
              leading: CircleAvatar(
                backgroundImage: (players[index].avatarUrl ?? '').isNotEmpty ? NetworkImage(players[index].avatarUrl!) : null,
                child: (players[index].avatarUrl ?? '').isEmpty ? Text('${index + 1}') : null,
              ),
              title: Text(players[index].name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(players[index].teamName ?? 'Bez drużyny'),
              trailing: Text('${players[index].goals} ⚽', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ),
            if (index != players.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _HomeData {
  const _HomeData({required this.teams, required this.matches, required this.players, required this.standings});

  final List<Team> teams;
  final List<GloMatch> matches;
  final List<Player> players;
  final List<StandingRow> standings;
}
