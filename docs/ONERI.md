# "Senin için" önerileri (web) — nasıl çalışır, KVKK notu

Dosya: `site/js/oneri.js` (vitrinde `home.js` çağırır). Mobil karşılığı: `recommended_shows_provider.dart` (aynı fikir: favori/izlenen türler).

## Kural tabanlı skor (sunucu/LLM yok)
Yalnızca `store.js` verisi + kullanıcının kendi favorileri (`fav.js`) + (girişliyse) kendi biletleri kullanılır; **ek Firestore okuması yoktur** (biletler zaten "Biletlerim" kuralıyla okunan `Ticket where customerId == uid`).

| Sinyal | Puan | Etiket |
|---|---|---|
| Favori oyun (seansı var) | +4 | Favori oyunun |
| Favori ekibin oyunu | +3 | Favori ekibin |
| Favori oyuncu kadroda | +3 | Favori oyuncun X |
| Favori sahnede seans | +2,5 | Favori sahnende |
| İzlediğin (geçmiş bilet) tür | +1 … +2,5 (adede göre) | İzlediğin türden: X |
| Favori oyunların türü | +1 | Favori türlerinden: X |
| Seçili il | +1,5 | Şehrinde / Şehrinde bu hafta |
| Seans yakınlığı (<7 / <14 / <30 gün) | +1,5 / +0,8 / +0,3 | — |
| Zaten bileti olan, bitmiş, seansı olmayan oyun | önerilmez | — |

Kişisel sinyal yoksa (girişsiz, favori/bilet yok) oyun **önerilmez**; hiç aday yoksa şerit gizli kalır. Uydurma "popüler" listesi gösterilmez.

## Gizlilik politikası taslak notu (KVKK)
> Web sitesinde "Senin için" bölümü, favorilerinize ve (giriş yapmışsanız) satın aldığınız/rezerve ettiğiniz biletlerin türlerine göre tarayıcınızda hesaplanır. Bu, otomatik kişiselleştirme (profilleme) niteliğindedir; sonuçlar sunucuya gönderilmez, saklanmaz, üçüncü kişilerle paylaşılmaz ve hukuki sonuç doğurmaz. Favorilerinizi kaldırarak öneriyi etkileyebilir, giriş yapmayarak biletlerinizin kullanılmasını önleyebilirsiniz. Dayanak: sözleşmenin ifası / meşru menfaat; itiraz için iletişim sayfasındaki adrese yazabilirsiniz.

`gizlilik.html` metnine eklenmesi hukuki incelemeden sonra sahibin kararıdır (bu işte metne dokunulmadı; şeritte kısa bilgi notu ve gizlilik bağlantısı var).
