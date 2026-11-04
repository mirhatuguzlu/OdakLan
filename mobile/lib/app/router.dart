import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/city/city_screen.dart';
import '../features/focus/focus_screen.dart';
import '../features/shell/home_shell.dart';
import '../features/shell/placeholder_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/focus',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          _branch('/focus', const FocusScreen()),
          _branch('/city', const CityScreen()),
          _branch(
            '/clan',
            const PlaceholderScreen(
              title: 'Odak Klanı',
              hint: 'Klan kalesi — adım 6',
              icon: Icons.shield_outlined,
            ),
          ),
          _branch(
            '/profile',
            const PlaceholderScreen(
              title: 'Profil',
              hint: 'Hesap ve istatistikler — adım 4',
              icon: Icons.person_outline,
            ),
          ),
        ],
      ),
    ],
  );
});

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (context, state) => screen)],
);
