# OdakLan

Anti-doomscroll focus RPG. Telefona dokunmadan geçen her dakika şehrini büyütür; Odak Klanı ile arkadaşlarınla birlikte odaklanırsın.

Tamamı Flutter/Dart; tek bir pub workspace:

- `mobile/` — Flutter uygulaması (Android/iOS)
- `site/` — Flutter web tanıtım sitesi
- `packages/odaklan_core/` — uygulama ile sitenin paylaştığı saf Dart kodu

Sitenin özellik ızgarası ve yol haritası `packages/odaklan_core/lib/src/features.dart` dosyasından gelir; uygulamadaki her adımla birlikte güncellenir.

```bash
flutter pub get                                   # tüm workspace
cd mobile && flutter run                          # uygulama
cd site && flutter run -d chrome                  # site (geliştirme)
cd site && flutter build web --wasm --release     # site (yayın)
flutter analyze mobile site packages/odaklan_core
```
