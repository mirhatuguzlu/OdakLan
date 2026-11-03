# OdakLan

Anti-doomscroll focus RPG. Telefona dokunmadan geçen her dakika şehrini büyütür; Odak Klanı ile arkadaşlarınla birlikte odaklanırsın.

- `mobile/` — Flutter uygulaması (Android/iOS). Mağazaya giden tek parça budur.
- `site/` — Tanıtım sitesi: Next.js (statik çıktı) + Tailwind + Motion. GitHub Pages'e ayrı yayınlanır.
- `packages/odaklan_core/` — Dart ortak kod; özellik listesi ve yol haritasının tek kaynağı.

## Site uygulamayı nasıl takip eder?

`packages/odaklan_core/lib/src/features.dart` değişince:

```bash
cd packages/odaklan_core && dart run tool/export_manifest.dart
```

Bu komut `site/src/content/manifest.json` dosyasını yazar. Güncel değilse `dart test` başarısız olur.

## Komutlar

```bash
flutter pub get                       # Dart workspace (mobile + core)
cd mobile && flutter run              # uygulama
cd site && npm install && npm run dev # site, http://localhost:3000
cd site && npm run build              # site, statik çıktı: site/out
```

`site/out/index.html` dosyasına çift tıklamak çalışmaz (dosya yolları sunucu ister). Derlenmiş siteyi görmek için: `npx serve site/out`.

## Yayın

Site adresi: https://mirhatuguzlu.github.io/OdakLan/ — `.github/workflows/site.yml` her push'ta `site/` klasörünü derleyip GitHub Pages'e yükler. Bir kerelik ayar: repo → Settings → Pages → Source: **GitHub Actions**.
