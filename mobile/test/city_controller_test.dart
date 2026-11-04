import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odaklan/app/services.dart';
import 'package:odaklan/features/city/city_controller.dart';
import 'package:odaklan/features/focus/focus_controller.dart';
import 'package:odaklan/features/focus/wallet.dart';
import 'package:odaklan_core/odaklan_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final home = buildingById('home');
  final library = buildingById('library');
  var now = DateTime(2026, 11, 10, 12);

  Future<ProviderContainer> make(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final p = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(p),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() => now = DateTime(2026, 11, 10, 12));

  test('new players own a house; upgrade spends Enerji and persists', () async {
    final c = await make({'wallet.energy': 5, 'wallet.xp': 0});
    final city = c.read(cityProvider.notifier);
    expect(c.read(cityProvider).levelOf('home'), 1);

    expect(city.upgrade(home), UpgradeCheck.ok); // costs 4
    expect(c.read(walletProvider).energy, 1);
    expect(city.upgrade(home), UpgradeCheck.notEnoughEnergy);
    expect(city.upgrade(library), UpgradeCheck.locked); // needs level 2

    final prefs = c.read(prefsProvider);
    final c2 = ProviderContainer(
      overrides: [prefsProvider.overrideWithValue(prefs)],
    );
    addTearDown(c2.dispose);
    expect(c2.read(cityProvider).levelOf('home'), 2);
  });

  test('corrupt stored city starts empty', () async {
    final c = await make({'city.levels': '{oops'});
    expect(c.read(cityProvider).levels, isEmpty);
  });

  test('days away decay the city on open and report it', () async {
    final c = await make({
      'city.levels': jsonEncode(
        const City({'home': 1}, {}, {'home': 1}).toJson()
          ..['settled'] = '2026-11-06',
      ),
    });
    // 7, 8, 9 untended → 3 × 22.
    expect(c.read(cityProvider).conditionOf('home'), 34);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(cityNewsProvider).whereType<Damaged>(), hasLength(3));
  });

  test('giving up cracks the city; finishing pays the city bonus', () async {
    final c = await make({
      'wallet.xp': 200, // level 3
      'city.levels': jsonEncode(
        const City({'home': 1, 'library': 2}, {}, {}).toJson()
          ..['settled'] = '2026-11-09',
      ),
    });
    final focus = c.read(focusProvider.notifier);

    expect(focus.start(const Duration(minutes: 10)), isTrue);
    focus.giveUp();
    // Library (worth 6) is the most valuable: 30 damage.
    expect(c.read(cityProvider).conditionOf('library'), 70);
    expect(c.read(cityNewsProvider).single, isA<Damaged>());

    expect(focus.start(const Duration(minutes: 10)), isTrue);
    now = now.add(const Duration(minutes: 10, seconds: 1));
    // Let the 1 s ticker see the finished session.
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    final s = c.read(focusProvider);
    expect(s.lastEnded?.phase, FocusPhase.completed);
    // 2 Enerji, 20 XP base; library lvl2 (condition 70, working) → +20% XP.
    expect(s.credited, const FocusReward(energy: 2, xp: 24));
    expect(c.read(cityProvider).conditionOf('library'), 80); // 1 block +10
  });
}
