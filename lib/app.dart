import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/app_services.dart';
import 'features/shell/app_shell.dart';
import 'state/app_controller.dart';
import 'state/app_scope.dart';

class GloBootstrap extends StatefulWidget {
  const GloBootstrap({required this.client, super.key});

  final SupabaseClient client;

  @override
  State<GloBootstrap> createState() => _GloBootstrapState();
}

class _GloBootstrapState extends State<GloBootstrap> {
  late final AppServices _services;
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _services = AppServices(widget.client);
    _controller = AppController(_services)..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryScope(
      services: _services,
      child: AppScope(
        controller: _controller,
        child: const GloApp(),
      ),
    );
  }
}

class GloApp extends StatelessWidget {
  const GloApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final primary = controller.selectedLeagueId == 2
        ? GloColors.leagueTwo
        : GloColors.leagueOne;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Grudziądzka Liga Orlikowa',
      theme: AppTheme.dark(primary: primary),
      home: const AppShell(),
    );
  }
}
