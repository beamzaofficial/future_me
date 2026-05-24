import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../pages/detail_page.dart';
import '../../pages/home_page.dart';
import '../../pages/login_page.dart';
import '../../pages/settings_page.dart';
import '../../pages/vault_page.dart';
import '../../pages/write_page.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/main_scaffold.dart';

class AppRouter {
  static GoRouter create(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/home',
      refreshListenable: auth,
      debugLogDiagnostics: false,
      redirect: (context, state) {
        if (!auth.isInitialized) return null;
        final loggedIn = auth.isSignedIn;
        final atLogin = state.matchedLocation == '/login';
        if (!loggedIn && !atLogin) return '/login';
        if (loggedIn && atLogin) return '/home';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (_, __) => const LoginPage(),
        ),
        ShellRoute(
          builder: (context, state, child) =>
              MainScaffold(location: state.matchedLocation, child: child),
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              pageBuilder: (_, __) => const NoTransitionPage(child: HomePage()),
            ),
            GoRoute(
              path: '/vault',
              name: 'vault',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: VaultPage()),
            ),
            GoRoute(
              path: '/write',
              name: 'write',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: WritePage()),
            ),
            GoRoute(
              path: '/settings',
              name: 'settings',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: SettingsPage()),
            ),
          ],
        ),
        GoRoute(
          path: '/letter/:id',
          name: 'letter',
          builder: (_, state) =>
              DetailPage(letterId: state.pathParameters['id']!),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Page not found'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper for testing — exposes current AuthProvider via context
extension AuthContext on BuildContext {
  AuthProvider get auth => read<AuthProvider>();
}
