// Writes the feature manifest for the website.
// Run from packages/odaklan_core: dart run tool/export_manifest.dart
import 'dart:io';

import 'package:odaklan_core/odaklan_core.dart';

const manifestPath = '../../site/src/content/manifest.json';

void main() {
  File(manifestPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(manifestJson());
  stdout.writeln('Wrote $manifestPath');
}
