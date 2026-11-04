# OdakLan oyun tasarımı: kayıp, strateji, rekabet

Kurallar `packages/odaklan_core/lib/src/city.dart` içinde; site sayıları `manifest.json` üzerinden aynen alır.

## Sorun (kullanıcı geri bildirimi, 2026-11-04)
- Enerjiyle +/− basmak bir "emek/güç" hissi vermiyor.
- Binaları kaybetme korkusu yok → geri gelmek için sebep yok.
- Tek optimum yol var; strateji yok.

## Araştırmadan çıkanlar
| Bulgu | Kaynak | Tasarıma etkisi |
|---|---|---|
| Kayıplar kazançlardan ~2 kat ağır hissedilir (λ ≈ 1,96, 607 tahmin) | Brown ve ark. 2024, *J. Econ. Literature* | Hasar sayıları onarım sayılarından büyük (30 hasar ve 10 onarım) |
| Duolingo: 7 günlük seriden sonra tutunma sıçrıyor; seri bahsi D7 +%14 (şirket verisi) | Lenny's Podcast / Duolingo PM | Sahip olunan bir şeyin (şehir) değeri zamanla birikmeli |
| Seri bozulunca kullanıcılar tamamen bırakma eğiliminde; "onarılabilir" olduğunu bilmek motivasyonu düşürüyor | The Decision Lab'in aktardığı JCR çalışması | Kayıp **kısmi** (bir seviye), harabe yarı fiyat → bırakmak yerine geri dönüş |
| Seri kaygısı gerçek (Snapchat genç anketi, Pokémon Go n=1540) | Bits of Freedom 2026; BI tezi | Yumuşak sınırlar: ilk gün geriye dönük kayıp yok, Seri Kalkanı çürümeyi de durdurur, 60 gün tavan |
| Kendi yaptığın şeye daha çok değer verirsin (IKEA etkisi) | Norton, Mochon ve Ariely 2012 | Binalar yalnızca odakla kurulur ve onarılır; satın alma yok |
| Sahiplik başlangıcı hedefi hızlandırır (2 hediye damga) | Kivetz ve ark. 2006 | Yeni oyuncu Ev Sv1 ile başlar |
| Rekabet kolu, adım sayısında kalıcı tek etkiye sahip koldu (STEP UP RKÇ, n=602) | Patel ve ark. 2019, *JAMA Intern Med* | Karşılaştırılabilir tek sayı: Şehir Gücü (klan/arkadaş tablosu, adım 7) |
| Para cezası çerçevesi, ödül çerçevesinden zayıf çıktı (RKÇ) | JMIR 2022 | Kayıp, ceza değil "bakım" olarak sunulur; her zaman gösterilen yol "odaklan" |
| Ödül odaklı tasarım içsel motivasyonu zayıflatabilir | Deci, Koestner ve Ryan 1999 | Etkiler yeterlilik ve özerklik verir (strateji seçimi), sadece puan değil |
| Telefonun masada olmasının "beyin boşaltma" etkisi çoğunlukla tekrarlanamadı | Ruiz Pardo ve Minda 2022 | Pazarlamada "telefon yanındaysa zekân düşer" iddiası kullanılmaz |

## Mekanikler (yapıldı)
- **Sağlık ve çürüme:** Günde 20 dk altında odaklanılan her gün, her bina −25 sağlık kaybeder (Ev her seviyede −3).
- **Yarıda bırakma hasarı:** Bozulan ya da vazgeçilen seans en değerli binaya −30 vurur (Kule her seviyede −4). Uyarı, başlat ekranında karar anında gösterilir.
- **Çöküş:** Sağlık 0 olunca bina bir seviye düşer ve %60 sağlıkla kalır. Seviye 0 olursa harabe kalır.
- **Harabe:** Kaybedilen seviyeleri yeniden kurmak yarı fiyattır, böylece kayıp bir geri dönüş daveti olur.
- **Hasarlı bina:** Sağlık %40 altına inince binanın etkisi kapanır, yani ihmal ekonomiyi de vurur.
- **Strateji, her binanın farklı etkisiyle gelir:**
  - Ev: savunma (çürüme)
  - Kütüphane: XP +%10 / seviye
  - Park: onarım +3 / blok
  - Atölye: tamamlanan seansta Enerji +%20 / seviye
  - Kule: hasar savunması ve Şehir Gücü +%10 / seviye
  - Örnek yollar: "ekonomi önce" (Atölye), "seviye koşusu" (Kütüphane), "tank" (Ev + Kule), "düzensiz programlı" (Park).
- **Şehir Gücü:** Σ seviye × taban maliyet × sağlık / 100 × (1 + %10 × Kule). Çürüdükçe düşer.

## Sonraki adımlar (plan)
- Adım 6: çürüme, hasar ve bonuslar sunucuda hesaplanmalı. Bugün yerel ve güvenilmez.
- Adım 7: Klan Kuşatması. Haftalık, klan Şehir Gücü toplamına dayalı lig (bronz/gümüş/altın; düşme riski = kayıp). Üyenin bozduğu seans kale sağlığını düşürür (Forest grup ağacı mantığı).
- Adım 8: "Şehrin bu gece yıpranacak" akşam bildirimi. Günde en fazla 1 kez, sessiz saatlere uyar.
- Etik sınırlar: ücretli onarım yok, ganimet kutusu yok, 13 yaş altı yok. Tatil modu (önceden ilan edilen, ayda 7 güne kadar) adım 7 ile birlikte gelecek.
