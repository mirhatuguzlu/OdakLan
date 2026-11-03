import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odaklan/app/services.dart';
import 'package:odaklan/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('start a session, give up, see result; tabs switch', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var now = DateTime(2026, 11, 4, 10);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(() => now),
        ],
        child: const OdakLanApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Ne kadar odaklanacaksın?'), findsOneWidget);

    await tester.tap(find.text('10 dk'));
    await tester.pump();
    await tester.tap(find.text('Odaklanmaya başla'));
    await tester.pump(const Duration(milliseconds: 500));
    // The 350 ms switch transition starts on the frame after the tap.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Odaktasın'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);

    now = now.add(const Duration(minutes: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('07:00'), findsOneWidget);

    await tester.tap(find.text('Vazgeç'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Vazgeç').last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Seansı bitirdin'), findsOneWidget);

    await tester.tap(find.text('Tamam'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Ne kadar odaklanacaksın?'), findsOneWidget);

    await tester.tap(find.text('Klan'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Klan kalesi — adım 6'), findsOneWidget);

    // Unmount so flutter_animate's start timers don't outlive the test.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
