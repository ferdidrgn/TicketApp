# Flutter Web + Responsive (TiyatRol)

premium-web-design / frontend-design'daki web ilkelerinin Flutter karşılıkları.

## Kırılma noktaları (projenin kendi değerleri)

`lib/core/util/responsive_utils.dart`:

| Aralık | Genişlik | Beklenen kompozisyon |
|---|---|---|
| mobil | < 768 | tek sütun, dikey akış, birincil aksiyon altta |
| tablet | 768 – 1023 | 2 sütun ızgara ya da içerik + dar yan bilgi; dokunma boyutları mobil gibi |
| masaüstü | 1024 – 1439 | çok sütun, yan panel/filtre, hover durumları |
| geniş | ≥ 1440 | içerik 1280–1440'ta sınırlanır, kenarlar nefes alır |

`context.isMobile / isTablet / isDesktop` (app_context_ui_extension) aynı
değerleri kullanır. `context.titleSize` gibi iki kademeli (mobil/değil)
eski yardımcılar tablet'i ayırt etmez — yeni kodda akışkan ölçek kullan.

## Kompozisyon değişir, boyut değil

Yanlış: `if (width > 600) fontSize = 24 else 18` ile aynı widget'ı büyütmek.
Doğru: her aralıkta yerleşim fikri değişir. Örnek oyun listesi:
- mobil: yatay kaydırmalı afiş şeridi + altında liste
- tablet: 2–3 sütun ızgara
- masaüstü: solda filtre paneli (sticky), sağda 4–5 sütun ızgara

```dart
LayoutBuilder(builder: (context, c) {
  if (c.maxWidth >= ResponsiveUtils.tabletBreakpoint) return _DesktopLayout();
  if (c.maxWidth >= ResponsiveUtils.mobileBreakpoint) return _TabletLayout();
  return _MobileLayout();
});
```

Izgara: sabit `crossAxisCount` değil —
`SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 260, childAspectRatio: ...)`.

## Akışkan ölçek (CSS clamp() karşılığı)

```dart
double fluid(BuildContext context, double min, double max,
    {double minW = 375, double maxW = 1440}) {
  final w = MediaQuery.sizeOf(context).width;
  final t = ((w - minW) / (maxW - minW)).clamp(0.0, 1.0);
  return min + (max - min) * t;
}
// başlık: fluid(context, 32, 64)  · bölüm boşluğu: fluid(context, 32, 96)
```

## İçerik genişliği

- Okuma sütunu (oyun açıklaması, hikâye): `ConstrainedBox(maxWidth: 680)`.
- Izgara/sayfa: `Center(child: ConstrainedBox(maxWidth: 1360, ...))`.
- Geniş ekranda tam genişliğe yayılan sadece hero görseli olabilir.

## Web'e özgü zorunluluklar

- **Material atası:** `BasePageWrapper` kullanmayan her web sayfası kendi
  `Scaffold`'unu kurar. Yoksa TextField çöker, metinler sarı çift alt çizgili.
- **Hover + odak + imleç:** tıklanabilir her şey `InkWell`/`FocusableActionDetector`
  ile klavyeden erişilebilir, `focusColor` görünür, imleç `click`. Hover
  efekti sade (renk/altı çizgi/küçük yükselme) — her karta aynı "büyü" değil.
- **Yatay kaydırma mouse ile:** Flutter web'de mouse sürüklemesi varsayılan
  kapalı; yatay şeritlerde:
  ```dart
  ScrollConfiguration(
    behavior: ScrollConfiguration.of(context).copyWith(
      dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad}),
    child: ListView(scrollDirection: Axis.horizontal, ...));
  ```
  + masaüstünde ok butonları (klavye/erişilebilirlik).
- **Görseller:** Firebase Storage (CORS `cors.json` ile açık) ya da
  `assets/images/`. Dış stok site hotlink'i web'de CORS ile kırılır.
- **Metin seçimi:** açıklama/adres gibi kopyalanacak metinlerde
  `SelectableText` ya da `SelectionArea`.
- **Performans:** web'de `BackdropFilter`, büyük gölgeler, çok katmanlı
  `Opacity` pahalı; ilk boyamada ağır animasyon yok.

## Yapısal DNA (premium-web-design'dan)

Her sayfa aynı "hero → 3'lü ızgara → CTA → footer" kalıbına girmesin.
Sayfanın yapısını tek bir isimle söyle ve ona bağlı kal; örnekler:
- **İki bölmeli kalıcı ayrım:** biri yapışkan, diğeri kayan (oyun detayı:
  solda yapışkan afiş + "Bilet al", sağda kayan hikâye/kadro/seanslar).
- **Kenar çubuğu + sütun:** sabit filtre/tarih çubuğu, sağda sonuçlar (keşfet).
- **Sabitlenmiş anlatı:** tek bir bölüm kaydırmayla sabitlenir, içeriği
  adım adım değişir (ana sayfada "bu hafta sahnede" günleri).
Bir sayfada iki yapıyı karıştırma.
