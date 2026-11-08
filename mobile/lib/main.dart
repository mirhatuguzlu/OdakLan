import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/router.dart';
import 'app/services.dart';
import 'app/theme.dart';
import 'features/account/account.dart';
import 'features/account/gate.dart';

/// Local game data from before progress moved to the server (step 6).
const _legacyKeys = [
  'wallet.energy',
  'wallet.xp',
  'city.levels',
  'progress.log',
  'progress.frozen',
  'progress.freezes',
  'progress.claimed',
  'progress.settled',
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  for (final k in _legacyKeys) {
    await prefs.remove(k);
  }
  await initBackend();
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
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'OdakLan',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    routerConfig: ref.watch(routerProvider),
    builder: (context, child) => Gate(child: child!),
  );
}
