# Denenenler ve sahibinin tepkisi (yeni tasarımdan ÖNCE oku)

Sahibi Türkçe ve doğrudan konuşur; "berbat", "iğrenç", "kullanışsız"
geri bildirimleri ciddi ret demektir. Beğendiği şeyler de not edildi —
onları koru.

## Beğenilenler (koru)
- **Metin perde açılışı (wipe reveal):** başlığın soldan sağa `ClipRect +
  Align(widthFactor)` ile açılması — "yazı animasyonu çok iyi".
- **Konser/kalabalık sahne fotoğrafı** (profil sayfası misafir hero'su,
  Unsplash `photo-1514525253161-7a46d19cd819`) — "bu foto çok iyi".
- 5 tema özelliği — "asla temalarımı bozma".

## Reddedilenler

### Genel (Eylül 2026)
- Web ve mobil sayfaların geneli: "çok berbat", "hiç gerçekçi tasarım hissi
  vermiyor, firmalara sunsam berbat der", "UI'lar birbirine karıştı,
  sadelik gitti".
- Renk paleti (koyu lacivert/siyah + koyu kırmızı `#C50337` + fildişi, pembe/
  mor gradyanlar): "renkler iğrenç". Sahibi paleti değiştirme izni verdi.
- Oyun detay sayfası: "bir sürü buton var, çok karmaşık".
- Hazır yönler (Biletix tarzı ticari, Netflix tarzı karanlık sinema, dergi
  tarzı editöryal) önerildi → hiçbiri seçilmedi: "bize özgü, bunlardan
  ayrı olsun".

### Oyun kartı (`lib/shared/widgets/theatre_show_card.dart`)
1. Tek büyük yuvarlak köşeli "taç yaprağı" kart, rozetler afiş üstünde iki
   köşede → dar kartta "BAŞKA PLATFORMDA" ile "YENİ" üst üste bindi.
2. Zeytin yaprağı/göz (vesica) şekli sadece afişte → "sen sadece fotoyu öyle
   yapmışsın, kart tasarımından bahsetmiştim… çok iğrenç".
3. Vesica şekli tüm kartta → dar bantta RenderFlex taşması, "çok kullanışsız".
4. İmza asimetrik köşe (`AppRadius.asymLg`) → **"D harfi şeklinde tasarımlar
   iğrenç"**. `asymSm/asymLg` ~10 dosyada daha kullanılıyor; temizlenmeli.

### Giriş / telefonla giriş
1. Üst yarı fotoğraf + alt yarı buton platformu (bottom sheet) → "berbat".
2. Web'de sol fotoğraf paneli + sağ form kartı → "berbat".
3. Fotoğrafsız editöryal tipografi + numaralı "01 02" satırlar → "berbat"
   (sadece başlık animasyonu beğenildi).
4. Referans afiş kompozisyonu (başlık + tam kanama foto + yüzen pill buton)
   → negatif margin çökmesi; mobilde üstte temanın açık şeridi; web'de
   Scaffold yok → çöktü; dış foto web'de yüklenmedi.
5. "Bilet gişesi" (fildişi fiziksel bilet, delikli koçan, yırtılma,
   koltuk sırası SMS kodu, gerçek afiş bandı) — sahibinin henüz net
   yorumu yok. NOT: bu tasarım da bu skill'in yapay zekâ işaretlerinden
   birkaçını taşıyor (her yerde BÜYÜK HARF aralıklı etiket, "A · B",
   monospace küçük etiketler) — yeniden ele alınırken bunlar temizlenmeli.

### Diğer
- Geri butonlu ortak başlıkta sabit pembe/kırmızı gradyan yazı → temaya
  bağlandı (düzeltildi).
- Her yerde perde/spot/parlama/vignette "tiyatro efekti" — gimmick.
