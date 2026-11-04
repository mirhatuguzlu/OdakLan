import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/router.dart';
import 'app/services.dart';
import 'app/theme.dart';
import 'features/focus/focus_controller.dart';
import 'features/progress/progress_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: const OdakLanApp(),
    ),
  );
}

class OdakLanApp extends ConsumerWidget {
  const OdakLanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the focus session (and its lifecycle listener) alive app-wide
    // without rebuilding the app on every tick.
    ref.listen(focusProvider, (_, _) {});
    // Auto-collects yesterday's unclaimed quest rewards on open.
    ref.listen(progressProvider, (_, _) {});
    return MaterialApp.router(
      title: 'OdakLan',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
