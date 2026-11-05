# Backend kurulumu (Supabase + Google ile giriş)

Anahtarsız derlenen uygulama tamamen çevrimdışı çalışır; Profil'de "Hesaplar bu sürümde kapalı" yazar.

## 1. Supabase projesi
1. supabase.com → yeni proje (bölge: Frankfurt, KVKK için AB).
2. Şemayı yükle: `supabase login`, `supabase link --project-ref <ref>`, `supabase db push`
   (`supabase/migrations/` içindeki SQL'ler).
3. Project Settings → API Keys: proje URL'si ve **publishable** key (`sb_publishable_…`).
   Secret/service_role key uygulamaya asla girmez.

## 2. Google Cloud OAuth istemcileri
console.cloud.google.com → APIs & Services → Credentials → Create OAuth client ID:
- **Web application** → bu `GOOGLE_WEB_CLIENT_ID`. Client secret'ı Supabase'e girilecek.
- **Android** → paket `com.odaklan.odaklan`, SHA-1:
  `cd mobile/android && ./gradlew signingReport` (debug ve ileride release anahtarı için ayrı ayrı).
- **iOS** → bundle id `com.odaklan.odaklan` → bu `GOOGLE_IOS_CLIENT_ID`.
  `mobile/ios/Runner/Info.plist` içine `CFBundleURLTypes` ile ters client id
  (`com.googleusercontent.apps.…`) URL şeması eklenmeli.
- OAuth consent screen: scope'lar yalnızca `email`, `profile`, `openid`.

## 3. Supabase'de Google sağlayıcısı
Authentication → Sign In / Providers → Google: aç, Web client id + secret gir,
"Authorized Client IDs" alanına Web, Android ve iOS client id'lerini virgülle ekle.
(iOS'ta giriş "nonce" hatası verirse "Skip nonce checks" seçeneğini aç.)

## 4. Uygulamayı anahtarlarla çalıştır
`mobile/env.example.json` → `mobile/env.json` olarak kopyala ve doldur (git'e girmez):

```
flutter run --dart-define-from-file=env.json
```
