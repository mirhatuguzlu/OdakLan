import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odaklan/main.dart';

void main() {
  testWidgets('starts on Odak tab and switches tabs', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OdakLanApp()));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Odak zamanlayıcısı — adım 2'), findsOneWidget);

    await tester.tap(find.text('Klan'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Klan kalesi — adım 6'), findsOneWidget);

    // Unmount so flutter_animate's start timers don't outlive the test.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
