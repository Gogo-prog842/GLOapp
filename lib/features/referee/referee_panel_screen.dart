import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/match_card.dart';
import '../../data/models/glo_match.dart';
import '../../data/models/team.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/app_services.dart';
import '../../features/matches/match_details_screen.dart';
import '../../state/app_scope.dart';

class RefereePanelScreen extends StatefulWidget {
  const RefereePanelScreen({super.key});

  @override
  State<RefereePanelScreen> createState() => _RefereePanelScreenState();
}

class _RefereePanelScreenState extends State<RefereePanelScreen> {
  Future<_RefereeSnapshot>? _future;
  String? _key;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.of(context);
    final key = '${controller.selectedLeagueId}:${controller.selectedSeasonId}:${controller.role.email}:${controller.role.type.name}';
    if (_key == key) return;
    _key = key;
    _future = _loadSnapshot();
  }

  @override
  Widget build(BuildContext context) {
    final role = AppScope.of(context).role;
    if ((role.email ?? '').isEmpty && role.type != UserRoleType.admin) {
      return GloError(
        message: 'Zaloguj się jako sędzia lub admin, żeby zobaczyć panel LIVE.',
        onRetry: _reload,
      );
    }

    return FutureBuilder<_RefereeSnapshot>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const GloLoading();
        if (snapshot.hasError) {
          return GloError(message: '${snapshot.error}', onRetry: _reload);
        }
        final data = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _RefereeHero(activeCount: data.liveMatches.length, assignedCount: data.matches.length),
              const SizedBox(height: 18),
              const SectionHeader(title: 'Mecze LIVE'),
              const SizedBox(height: 10),
              if (data.liveMatches.isEmpty)
                const _EmptyCard(text: 'Aktualnie nie masz meczu LIVE.')
              else
                ...data.liveMatches.map((match) => _MatchButton(match: match, teams: data.teams, onTap: () => _openMatch(match, data.teams))),
              const SizedBox(height: 22),
              const SectionHeader(title: 'Przypisane / najbliższe mecze'),
              const SizedBox(height: 10),
              if (data.matches.isEmpty)
                const _EmptyCard(text: 'Brak przypisanych meczów w tej lidze/sezonie.')
              else
                ...data.matches.take(12).map((match) => _MatchButton(match: match, teams: data.teams, onTap: () => _openMatch(match, data.teams))),
            ],
          ),
        );
      },
    );
  }

  Future<_RefereeSnapshot> _loadSnapshot() async {
    final services = RepositoryScope.of(context);
    final controller = AppScope.of(context);
    final role = controller.role;
    final teams = await services.teamRepository.fetchTeamMap(
      leagueId: controller.selectedLeagueId,
      seasonId: controller.selectedSeasonId,
    );
    final matches = await services.matchRepository.fetchMatches(
      leagueId: controller.selectedLeagueId,
      seasonId: controller.selectedSeasonId,
    );
    final email = (role.email ?? '').trim().toLowerCase();
    final filtered = role.type == UserRoleType.admin
        ? matches.where((match) => match.isLive || match.isScheduled).toList(growable: false)
        : matches.where((match) => (match.refereeEmail ?? '').trim().toLowerCase() == email).toList(growable: false);
    filtered.sort((a, b) {
      if (a.isLive != b.isLive) return a.isLive ? -1 : 1;
      return _dateTime(a).compareTo(_dateTime(b));
    });
    return _RefereeSnapshot(matches: filtered, teams: teams);
  }

  void _reload() {
    setState(() => _future = _loadSnapshot());
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

class _RefereeSnapshot {
  const _RefereeSnapshot({required this.matches, required this.teams});

  final List<GloMatch> matches;
  final Map<int, Team> teams;

  List<GloMatch> get liveMatches => matches.where((match) => match.isLive).toList(growable: false);
}

class _RefereeHero extends StatelessWidget {
  const _RefereeHero({required this.activeCount, required this.assignedCount});

  final int activeCount;
  final int assignedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0D1426)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: GloColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sports_outlined, size: 34),
          const SizedBox(height: 12),
          Text('Panel sędziego', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text('$activeCount LIVE • $assignedCount przypisanych/najbliższych', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MatchButton extends StatelessWidget {
  const _MatchButton({required this.match, required this.teams, required this.onTap});

  final GloMatch match;
  final Map<int, Team> teams;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MatchCard(match: match, teams: teams, onTap: onTap),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(text, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}
