import 'package:odaklan_core/odaklan_core.dart';

/// Turkish one-liner for an event.
String describeCityEvent(CityEvent e) {
  final name = buildingById(e.buildingId).name;
  return switch (e) {
    Damaged(:final amount) => '$name −$amount sağlık',
    Repaired(:final amount) => '$name +$amount onarıldı',
    Collapsed(level: 0) => '$name yıkıldı — harabe yarı fiyatına kurulur',
    Collapsed(:final level) => '$name çöktü: Sv $level’e düştü',
  };
}
