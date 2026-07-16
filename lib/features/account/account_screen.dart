import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../features/captain/captain_panel_screen.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/app_services.dart';
import '../../state/app_scope.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final session = controller.session;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (session == null) _buildLogin(context) else _buildProfile(context, controller.role),
      ],
    );
  }

  Widget _buildLogin(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Logowanie', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Dla administratorów, kapitanów i sędziów GLO.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(labelText: 'Hasło'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: GloColors.danger)),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _signIn,
                icon: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.login),
                label: const Text('Zaloguj'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, UserRole role) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  child: const Icon(Icons.person, size: 34),
                ),
                const SizedBox(height: 14),
                Text(role.email ?? 'Użytkownik GLO', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Chip(label: Text(role.label)),
                if (role.team != null) ...[
                  const SizedBox(height: 8),
                  Text('Drużyna: ${role.team!.name}'),
                ],
                if ((role.refereeName ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Sędzia: ${role.refereeName}'),
                ],
              ],
            ),
          ),
        ),

        if (role.type == UserRoleType.captain || role.type == UserRoleType.admin) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Panel kapitana')),
                      body: const CaptainPanelScreen(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.shield_outlined),
              label: const Text('Otwórz panel kapitana'),
            ),
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Wyloguj'),
          ),
        ),
      ],
    );
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final services = RepositoryScope.of(context);
      await services.authRepository.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await AppScope.of(context).refreshRole();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      final services = RepositoryScope.of(context);
      await services.authRepository.signOut();
      await AppScope.of(context).refreshRole();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
