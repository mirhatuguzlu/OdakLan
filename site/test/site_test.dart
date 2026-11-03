import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odaklan_core/odaklan_core.dart';
import 'package:odaklan_site/main.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  testWidgets('renders every manifest feature and roadmap step', (tester) async {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    // Tall viewport so every lazily built sliver section is laid out.
    tester.view.physicalSize = const Size(1400, 9000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Reduce motion so looping animations don't keep the test pumping.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(const OdakLanSite());
    await tester.pump(const Duration(seconds: 1));

    for (final f in features) {
      expect(find.text(f.title, skipOffstage: false), findsOneWidget);
    }
    for (final s in roadmap) {
      expect(
        find.textContaining(s.title, findRichText: true, skipOffstage: false),
        findsOneWidget,
      );
    }
  });
}
