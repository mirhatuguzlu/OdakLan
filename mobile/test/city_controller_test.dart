import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odaklan/app/services.dart';
import 'package:odaklan/features/city/city_controller.dart';
import 'package:odaklan/features/focus/wallet.dart';
import 'package:odaklan_core/odaklan_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final home = buildings.firstWhere((b) => b.id == 'home');
  final library = buildings.firstWhere((b) => b.id == 'library');

  Future<ProviderContainer> make(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final p = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [prefsProvider.overrideWithValue(p)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('upgrade spends Enerji and persists the city', () async {
    final c = await make({'wallet.energy': 5, 'wallet.xp': 0});
    final city = c.read(cityProvider.notifier);

    expect(city.upgrade(home), UpgradeCheck.ok);
    expect(c.read(walletProvider).energy, 3);
    expect(city.upgrade(home), UpgradeCheck.notEnoughEnergy); // costs 4
    expect(c.read(walletProvider).energy, 3);
    expect(city.upgrade(library), UpgradeCheck.locked); // needs level 2

    final prefs = c.read(prefsProvider);
    final c2 = ProviderContainer(
      overrides: [prefsProvider.overrideWithValue(prefs)],
    );
    addTearDown(c2.dispose);
    expect(c2.read(cityProvider).levelOf('home'), 1);
  });

  test('corrupt stored city starts empty', () async {
    final c = await make({'city.levels': '{oops'});
    expect(c.read(cityProvider).levels, isEmpty);
  });
}
