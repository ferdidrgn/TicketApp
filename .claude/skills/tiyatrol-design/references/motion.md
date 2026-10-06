# Hareket (Flutter)

## Ne zaman

Sadece şu dört amaçtan birine hizmet ediyorsa: **yön gösterme** (nereden
nereye gittim), **geri bildirim** (dokunduğum şey cevap verdi), **süreklilik**
(afiş → detay aynı nesne), **tek bir keyif anı**. Kendiliğinden (kullanıcı
tetiklemeden) oynayan hareket seyrek: sayfa başına tek bir koreografili an.

YAPMA: her bölüme "aşağıdan fade-in", her karta aynı hover büyütmesi,
sürekli dönen/parlayan süsler, her şeye aynı süre ve eğri.

## Araçlar

| İhtiyaç | Flutter |
|---|---|
| Tek değer değişimi (renk, boyut, konum) | `AnimatedContainer`, `AnimatedOpacity`, `AnimatedSlide`, `AnimatedScale`, `TweenAnimationBuilder` |
| Sıralı giriş (stagger) | tek `AnimationController` + her öğeye `CurvedAnimation(curve: Interval(a, b, curve: ...))` |
| İçerik değişimi | `AnimatedSwitcher` (+ `layoutBuilder` ile `StackFit.expand` gerekiyorsa) |
| Sayfalar arası süreklilik | `Hero` (afiş → detay afişi), go_router `CustomTransitionPage` |
| Kaydırmaya bağlı | `ScrollController` / `NotificationListener<ScrollNotification>` → `AnimatedBuilder`; `SliverAppBar`/`SliverPersistentHeader` ile yapışkan/küçülen başlık |
| Metin/görsel açılışı (clip reveal) | `ClipRect` + `Align(widthFactor: t)` (projede `AuthWipeReveal`) |

`AnimationController` ve `CurvedAnimation`'ları `late final` alan olarak
bir kez oluştur, `build` içinde her seferinde yaratma; `dispose` et.

## Süre ve eğri

Tokenlar: `AppMotion.fast` (200ms, geri bildirim), `normal` (500ms, geçiş),
`slow` (700ms, sayfa açılışı). Hız farkı canlılık verir: hızlı giriş +
yavaş yerleşme.

CSS `cubic-bezier` karşılıkları (`AppMotion`):
- yumuşak taşma: `AppMotion.overshoot` (`Cubic(0.16, 1, 0.3, 1)`)
- zarif çıkış: `AppMotion.elegant` (`Cubic(0.33, 1, 0.68, 1)`)
- keskin: `AppMotion.sharp` (`Cubic(0.77, 0, 0.175, 1)`)

## Azaltılmış hareket (zorunlu)

```dart
final reduce = MediaQuery.of(context).disableAnimations;
if (reduce) controller.value = 1; else controller.forward();
```
`MediaQuery`'ye `initState`'te değil `didChangeDependencies`'te (bir kez)
eriş. Otomatik dönen içerik (afiş karuseli) azaltılmış harekette durur.

## Kaydırma deneyimi (scroll-experience'tan, ölçülü)

- Parallax: sadece hero görselinde, hafif (arka plan 0.2–0.5x). Metin
  parallax yapmaz (okunabilirlik).
- Yapışkan bölüm: tek bir "sabitlenmiş anlatı" bölümü bir sayfada en fazla
  bir kez.
- İlerleme göstergesi: uzun okuma sayfalarında üstte ince çizgi olabilir.
- Mobilde ağır kaydırma efekti yok; 60fps önce gelir.
