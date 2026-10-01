# Flutter Mobil (TiyatRol) — mobile-design skill'inin Flutter özeti

## Önce düşün (mobile-design-thinking)

Her ekran için koda başlamadan:

```
EKRAN: ...
├── BİRİNCİL AKSİYON: ...  → başparmak bölgesinde mi? (altta mı?)
├── DOKUNMA HEDEFLERİ: her biri ≥ 48dp mi? aralar ≥ 8dp mi?
├── KAYAN İÇERİK: liste mi? → ListView.builder / SliverList; kaç öğe?
├── DURUM: yerel state yeter mi? Riverpod provider gerçekten gerekli mi?
├── PLATFORM: iOS'ta (geri kaydırma, Cupertino hissi) ve Android'de
│   (geri tuşu, Material) farklı bir şey gerekiyor mu?
├── ÇEVRİMDIŞI / HATA / BOŞ / YÜKLENİYOR durumları nasıl görünüyor?
└── PERFORMANS: ağır widget, pahalı efekt, gereksiz rebuild var mı?
```

Varsayılanları sorgula: her projeye 5 sekmeli alt bar, her listeye
pull-to-refresh, her modala bottom sheet, sağ altta FAB… Bu uygulamada
gerçekten gerekli mi?

## Dokunma (touch-psychology)

| Öğe | Görsel | Dokunma alanı |
|---|---|---|
| İkon buton | 24–28 | ≥ 48×48 (padding ile) |
| Metin link | — | ≥ 44 yükseklik |
| Liste satırı | tam genişlik | 56–72 yükseklik |
| Birincil CTA | — | 52–56 yükseklik, tam genişlik |

- Başparmak bölgesi: birincil aksiyon altta/orta. Büyük telefonda üst %40
  tek elle zor → önemli aksiyon oraya konmaz. Yıkıcı aksiyon (sil, çıkış)
  kolay ulaşılan yere konmaz.
- Dokunmaya anında (<50ms) görsel cevap: `InkWell` splash/highlight ya da
  basılıyken hafif ölçek. Önemli onaylarda `HapticFeedback.lightImpact()`.
- Sadece jestle yapılan aksiyon olmaz; her jestin buton karşılığı olur.
- Parmak hedefi kapatır: seçim sonucunu parmağın altında değil üstünde göster
  (ör. koltuk seçince seçim özeti üstte/altta çubukta).

## Yerleşim

- Oyun detayı mobilde **dikey hikâye**: afiş (büyük) → ad, tür, süre →
  en yakın seanslar → hikâye → kadro → mekân. **Yapışkan alt çubuk**:
  fiyat + "Bilet al" (tek buton). Diğer aksiyonlar (paylaş, favori) üst
  bardaki ikonlarda, gövdede buton yığını yok.
- `SafeArea`: çentik + alt jest çubuğu. Tam ekran koyu/görselli sayfalarda
  durum çubuğu ikon rengini `AnnotatedRegion<SystemUiOverlayStyle>` ile ayarla.
- Klavye: form içeren sayfa `SingleChildScrollView` + Scaffold'un
  `resizeToAvoidBottomInset: true`; dışarı dokununca klavye kapanır.
- Geri: `PopScope` ile çok adımlı akışta önce bir önceki adıma dön.
- Tablet (native): içerik `ConstrainedBox(maxWidth: ~560–720)` ile ortalanır
  ya da iki sütuna geçer; telefon düzeni esnetilmez.

## Performans (mobile-performance, Flutter kısmı)

- Uzun liste: `ListView.builder` / `SliverList.builder`; `children:` ile
  yüzlerce öğe yok. Sabit yükseklikte `itemExtent`/`prototypeItem`.
- `const` constructor'lar; liste öğesi ayrı `StatelessWidget`.
- Animasyonda `Opacity` widget'ı yerine `FadeTransition`/`AnimatedOpacity`;
  sık yeniden boyanan alanları `RepaintBoundary` ile ayır.
- `BackdropFilter`, büyük blur'lu gölge, `ShaderMask`, `saveLayer` pahalı —
  sadece gerçekten gerekiyorsa, tek bir yerde.
- Görseller: `cached_network_image` + `memCacheWidth`/`cacheWidth` ile
  ekrandaki boyutta çöz; dev PNG'yi (ör. 7.7MB `main_theatre.png`) doğrudan
  kullanma.
- `Timer`/`AnimationController`/listener'lar `dispose` edilir.

## Durumlar

- Yükleniyor: `shimmer`/`skeletonizer` ile içeriğin şeklinde iskelet;
  çıplak `CircularProgressIndicator` sadece buton içinde küçük.
- Hata: neden + ne yapılabilir + "Tekrar dene".
- Boş: anlamlı cümle + tek CTA ("Henüz favorin yok. Oyunlara göz at").
- Çevrimdışı: son önbellekteki veri + küçük bir uyarı.
