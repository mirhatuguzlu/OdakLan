import 'package:odaklan_core/odaklan_core.dart';
import 'package:test/test.dart';

void main() {
  test('feature ids are unique (website maps them to icons)', () {
    final ids = features.map((f) => f.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('roadmap is numbered 1..n and done steps form a prefix', () {
    for (var i = 0; i < roadmap.length; i++) {
      expect(roadmap[i].number, i + 1);
    }
    final firstOpen = roadmap.indexWhere((s) => !s.done);
    if (firstOpen != -1) {
      expect(roadmap.skip(firstOpen).any((s) => s.done), isFalse);
    }
  });
}
