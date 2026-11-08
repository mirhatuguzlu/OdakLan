import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('the Edge Function runs the current rules (core.js is fresh)', () {
    final tmp = Directory.systemTemp.createTempSync('odaklan_core_js');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final out = '${tmp.path}/core.js';
    final r = Process.runSync(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O2',
      '--no-source-maps',
      '-o',
      out,
      'bin/game_server.dart',
    ]);
    expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
    // Git may check the file out with CRLF on Windows.
    final committed = File(
      '../../supabase/functions/game/core.js',
    ).readAsStringSync().replaceAll('\r\n', '\n');
    expect(
      committed,
      File(out).readAsStringSync(),
      reason: 'Run: sh tool/build_server.sh',
    );
  });
}
