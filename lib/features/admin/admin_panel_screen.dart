import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/match_card.dart';
import '../../data/models/glo_match.dart';
import '../../data/models/player.dart';
import '../../data/models/team.dart';
import '../../data/models/transfer_record.dart';
import '../../data/repositories/app_services.dart';
import '../../features/matches/match_details_screen.dart';
import '../../state/app_scope.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  Future<_AdminSnapshot>? _future;
  String? _key;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.of(context);
    final key = '${controller.selectedLeagueId}:${controller.selectedSeasonId}';
    if (_key == key) return;
    _key = key;
    _future = _loadSnapshot();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AdminSnapshot>(
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
              _AdminHero(snapshot: data),
              const SizedBox(height: 18),
              const SectionHeader(title: 'Szybki podgląd'),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.45,
                children: [
                  _MetricCard(label: 'Drużyny', value: '${data.teams.length}', icon: Icons.shield_outlined),
                  _MetricCard(label: 'Zawodnicy', value: '${data.assignedPlayers}', icon: Icons.groups_outlined),
                  _MetricCard(label: 'Mecze ligowe', value: '${data.leagueMatches.length}', icon: Icons.sports_soccer_outlined),
                  _MetricCard(label: 'LIVE teraz', value: '${data.liveMatches.length}', icon: Icons.bolt_outlined),
                ],
              ),
              const SizedBox(height: 22),
              const SectionHeader(title: 'Mecze wymagające uwagi'),
              const SizedBox(height: 10),
              if (data.focusMatches.isEmpty)
                const _EmptyCard(text: 'Brak meczów LIVE lub zaplanowanych na najbliższy czas.')
              else
                ...data.focusMatches.map(
                  (match) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: MatchCard(
                      match: match,
                      teams: data.teamMap,
                      onTap: () => _openMatch(match, data.teamMap),
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              const SectionHeader(title: 'Ostatnie transfery'),
              const SizedBox(height: 10),
              if (data.transfers.isEmpty)
                const _EmptyCard(text: 'Brak transferów dla wybranej ligi/sezonu.')
              else
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < data.transferPreview.length; i++) ...[
                        _TransferTile(transfer: data.transferPreview[i]),
                        if (i != data.transferPreview.length - 1) const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 22),
              const SectionHeader(title: 'Najlepsi statystycznie'),
              const SizedBox(height: 10),
              if (data.topPlayers.isEmpty)
                const _EmptyCard(text: 'Brak statystyk zawodników.')
              else
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < data.topPlayers.length; i++) ...[
                        _PlayerTile(index: i + 1, player: data.topPlayers[i]),
                        if (i != data.topPlayers.length - 1) const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 22),
              const _AdminNote(),
            ],
          ),
        );
      },
    );
  }

  Future<_AdminSnapshot> _loadSnapshot() async {
    final services = RepositoryScope.of(context);
    final controller = AppScope.of(context);
    final teams = await services.teamRepository.fetchTeams(
      leagueId: controller.selectedLeagueId,
      seasonId: controller.selectedSeasonId,
    );
    final matches = await services.matchRepository.fetchMatches(
      leagueId: controller.selectedLeagueId,
      seasonId: controller.selectedSeasonId,
    );
    final players = await services.playerRepository.fetchPlayersWithStats(
      leagueId: controller.selectedLeagueId,
      seasonId: controller.selectedSeasonId,
      teams: teams,
    );
    final List<TransferRecord> transfers;
    try {
      transfers = await services.transferRepository.fetchTransfers(
        leagueId: controller.selectedLeagueId,
        seasonId: controller.selectedSeasonId,
        limit: 80,
      );
    } catch (_) {
      // Transfer history should not block the whole admin dashboard.
      transfers = const [];
    }

    return _AdminSnapshot(
      teams: teams,
      matches: matches,
      players: players,
      transfers: transfers,
    );
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
}

class _AdminSnapshot {
  const _AdminSnapshot({
    required this.teams,
    required this.matches,
    required this.players,
    required this.transfers,
  });

  final List<Team> teams;
  final List<GloMatch> matches;
  final List<Player> players;
  final List<TransferRecord> transfers;

  Map<int, Team> get teamMap => {for (final team in teams) team.id: team};
  int get assignedPlayers => players.where((player) => player.teamId != null).length;
  List<GloMatch> get leagueMatches => matches.where((match) => match.roundNumber != null && (match.roundNumber ?? 0) > 0).toList(growable: false);
  List<GloMatch> get liveMatches => matches.where((match) => match.isLive).toList(growable: false);
  List<TransferRecord> get transferPreview => transfers.take(8).toList(growable: false);

  List<GloMatch> get focusMatches {
    final list = matches
        .where((match) => match.isLive || match.isScheduled)
        .toList(growable: false);
    list.sort((a, b) {
      if (a.isLive != b.isLive) return a.isLive ? -1 : 1;
      return _dateTime(a).compareTo(_dateTime(b));
    });
    return list.take(6).toList(growable: false);
  }

  List<Player> get topPlayers {
    final list = players.where((player) => player.goals > 0 || player.assists > 0 || player.mvpCount > 0).toList(growable: false);
    list.sort((a, b) {
      final byGoals = b.goals.compareTo(a.goals);
      if (byGoals != 0) return byGoals;
      final byAssists = b.assists.compareTo(a.assists);
      if (byAssists != 0) return byAssists;
      return b.mvpCount.compareTo(a.mvpCount);
    });
    return list.take(6).toList(growable: false);
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

class _AdminHero extends StatelessWidget {
  const _AdminHero({required this.snapshot});

  final _AdminSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF173B75), Color(0xFF0D1426)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: GloColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.admin_panel_settings_outlined, size: 34),
          const SizedBox(height: 12),
          Text('Panel admina', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Ligowe mecze: ${snapshot.leagueMatches.length} • zawodnicy z drużyną: ${snapshot.assignedPlayers}. Edycje krytyczne dalej powinny przechodzić przez RLS / Edge Functions.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: GloColors.primary),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
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

class _TransferTile extends StatelessWidget {
  const _TransferTile({required this.transfer});

  final TransferRecord transfer;

  @override
  Widget build(BuildContext context) {
    final date = transfer.transferDate == null ? '' : DateFormat('dd.MM.yyyy').format(transfer.transferDate!);
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.swap_horiz)),
      title: Text(transfer.playerName ?? 'Zawodnik #${transfer.playerId ?? '-'}'),
      subtitle: Text('${transfer.fromTeamName ?? 'Wolny'} → ${transfer.toTeamName ?? 'Wolny'}${date.isEmpty ? '' : ' • $date'}'),
      trailing: Text(transfer.typeLabel, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.index, required this.player});

  final int index;
  final Player player;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text('$index')),
      title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(player.teamName ?? 'Bez drużyny'),
      trailing: Text('${player.goals}G ${player.assists}A', style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

class _AdminNote extends StatelessWidget {
  const _AdminNote();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.security_outlined, color: GloColors.success),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ten panel korzysta z tych samych danych Supabase co strona. Ukrywanie przycisków w aplikacji nie zastępuje zabezpieczeń RLS w bazie.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
