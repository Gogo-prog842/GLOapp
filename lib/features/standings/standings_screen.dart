import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/models/glo_match.dart';
import '../../data/models/standing_row.dart';
import '../../data/models/team.dart';
import '../../data/repositories/app_services.dart';
import '../../state/app_scope.dart';
import 'standings_calculator.dart';

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  Future<List<StandingRow>>? _future;
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

  Future<List<StandingRow>> _load() async {
    final controller = AppScope.of(context);
    final services = RepositoryScope.of(context);
    final results = await Future.wait<dynamic>([
      services.teamRepository.fetchTeams(
        leagueId: controller.selectedLeagueId,
        seasonId: controller.selectedSeasonId,
      ),
      services.matchRepository.fetchMatches(
        leagueId: controller.selectedLeagueId,
        seasonId: controller.selectedSeasonId,
      ),
    ]);
    return StandingsCalculator.calculate(
      results[0] as List<Team>,
      results[1] as List<GloMatch>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StandingRow>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const GloLoading();
        if (snapshot.hasError) return GloError(message: '${snapshot.error}', onRetry: _reload);
        final rows = snapshot.data ?? const [];
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
            children: [
              const SectionHeader(title: 'Tabela ligowa'),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    const _TableHeader(),
                    for (var index = 0; index < rows.length; index++) ...[
                      _StandingTile(position: index + 1, row: rows[index]),
                      if (index != rows.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Kolejność: punkty, bilans bramek, gole strzelone.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('#')),
          Expanded(child: Text('DRUŻYNA')),
          SizedBox(width: 30, child: Text('M', textAlign: TextAlign.center)),
          SizedBox(width: 42, child: Text('BR', textAlign: TextAlign.center)),
          SizedBox(width: 34, child: Text('PKT', textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _StandingTile extends StatelessWidget {
  const _StandingTile({required this.position, required this.row});

  final int position;
  final StandingRow row;

  @override
  Widget build(BuildContext context) {
    final difference = row.goalDifference;
    final differenceColor = difference > 0
        ? GloColors.success
        : difference < 0
            ? GloColors.danger
            : GloColors.muted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('$position', style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
          TeamLogo(team: row.team, size: 30),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              row.team.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(width: 30, child: Text('${row.played}', textAlign: TextAlign.center)),
          SizedBox(
            width: 42,
            child: Column(
              children: [
                Text('${row.goalsFor}:${row.goalsAgainst}', style: const TextStyle(fontSize: 12)),
                Text(
                  difference > 0 ? '+$difference' : '$difference',
                  style: TextStyle(fontSize: 10, color: differenceColor, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 34,
            child: Text('${row.points}', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
