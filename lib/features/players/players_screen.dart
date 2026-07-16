import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/models/player.dart';
import '../../data/repositories/app_services.dart';
import '../../state/app_scope.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  Future<List<Player>>? _future;
  String? _selectionKey;
  String _query = '';

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

  Future<List<Player>> _load() async {
    final controller = AppScope.of(context);
    final services = RepositoryScope.of(context);
    final teams = await services.teamRepository.fetchTeams(
      leagueId: controller.selectedLeagueId,
      seasonId: controller.selectedSeasonId,
    );
    return services.playerRepository.fetchPlayersWithStats(
      leagueId: controller.selectedLeagueId,
      seasonId: controller.selectedSeasonId,
      teams: teams,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Player>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const GloLoading();
        if (snapshot.hasError) return GloError(message: '${snapshot.error}', onRetry: _reload);
        final allPlayers = snapshot.data ?? const [];
        final normalized = _query.trim().toLowerCase();
        final players = normalized.isEmpty
            ? allPlayers
            : allPlayers
                .where(
                  (player) => player.name.toLowerCase().contains(normalized) ||
                      (player.teamName ?? '').toLowerCase().contains(normalized),
                )
                .toList(growable: false);

        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
            children: [
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Szukaj zawodnika lub drużyny',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 18),
              SectionHeader(title: 'Zawodnicy (${players.length})'),
              const SizedBox(height: 12),
              if (players.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(child: Text('Brak pasujących zawodników.')),
                  ),
                )
              else
                Card(
                  child: Column(
                    children: [
                      for (var index = 0; index < players.length; index++) ...[
                        _PlayerTile(rank: index + 1, player: players[index]),
                        if (index != players.length - 1) const Divider(height: 1),
                      ],
                    ],
                  ),
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

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.rank, required this.player});

  final int rank;
  final Player player;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('$rank', style: const TextStyle(fontWeight: FontWeight.w900))),
          CircleAvatar(
            radius: 22,
            backgroundColor: GloColors.surfaceStrong,
            backgroundImage: (player.avatarUrl ?? '').isNotEmpty ? NetworkImage(player.avatarUrl!) : null,
            child: (player.avatarUrl ?? '').isEmpty
                ? Text(player.name.isEmpty ? '?' : player.name[0].toUpperCase())
                : null,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  '${player.teamName ?? 'Bez drużyny'} • ${player.matchesPlayed} meczów',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          _Stat(value: player.goals, label: 'G'),
          const SizedBox(width: 10),
          _Stat(value: player.assists, label: 'A'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
