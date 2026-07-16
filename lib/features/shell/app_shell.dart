import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/widgets/common.dart';
import '../../features/account/account_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/matches/matches_screen.dart';
import '../../features/players/players_screen.dart';
import '../../features/standings/standings_screen.dart';
import '../../state/app_scope.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  var _index = 0;

  static const _screens = [
    HomeScreen(),
    MatchesScreen(),
    StandingsScreen(),
    PlayersScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    if (controller.isLoading && controller.leagues.isEmpty) {
      return const Scaffold(body: GloLoading(label: 'Łączenie z bazą GLO…'));
    }
    if (controller.error != null && controller.leagues.isEmpty) {
      return Scaffold(
        body: GloError(message: controller.error!, onRetry: controller.retry),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppConfig.appName, style: TextStyle(fontWeight: FontWeight.w900)),
            Text(
              AppConfig.fullName,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Zmień ligę i sezon',
            onPressed: () => _showCompetitionSheet(context),
            icon: const Icon(Icons.tune),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: IndexedStack(index: _index, children: _screens),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Start'),
          NavigationDestination(icon: Icon(Icons.sports_soccer_outlined), selectedIcon: Icon(Icons.sports_soccer), label: 'Mecze'),
          NavigationDestination(icon: Icon(Icons.leaderboard_outlined), selectedIcon: Icon(Icons.leaderboard), label: 'Tabela'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Gracze'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Konto'),
        ],
      ),
    );
  }

  Future<void> _showCompetitionSheet(BuildContext context) async {
    final controller = AppScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rozgrywki', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: controller.selectedLeagueId,
                  decoration: const InputDecoration(labelText: 'Liga'),
                  items: controller.leagues
                      .map((league) => DropdownMenuItem(value: league.id, child: Text(league.name)))
                      .toList(growable: false),
                  onChanged: (value) async {
                    if (value == null) return;
                    await controller.selectLeague(value);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: controller.selectedSeasonId,
                  decoration: const InputDecoration(labelText: 'Sezon'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Wszystkie sezony')),
                    ...controller.seasons.map(
                      (season) => DropdownMenuItem<int?>(
                        value: season.id,
                        child: Text(season.isActive ? '${season.name} • aktywny' : season.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    controller.selectSeason(value);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
