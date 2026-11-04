import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/city/city_screen.dart';
import '../features/focus/focus_screen.dart';
import '../features/progress/progress_screen.dart';
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
              hint: 'Klan kalesi — adım 7',
              icon: Icons.shield_outlined,
            ),
          ),
          _branch('/profile', const ProgressScreen()),
        ],
      ),
    ],
  );
});

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (context, state) => screen)],
);
