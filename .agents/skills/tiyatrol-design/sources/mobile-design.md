---
name: mobile-design
source: https://github.com/davila7/claude-code-templates
path: cli-tool/components/skills/creative-design/mobile-design/SKILL.md
license: Apache 2.0 — bkz. ../LICENSE.txt
adapted: Flutter / TiyatRol (06.10.2026)
---

# Mobile Design → Flutter

Felsefe: dokunma önce, pil bilinçli, platform saygılı, çevrimdışı mümkün.
Mobil küçültülmüş masaüstü değildir.

Bu projede platform **iOS + Android + web**; çerçeve **Flutter**; durum
**Riverpod**; gezinme **go_router + tab shell**; tablet ayrı kırılma.

## Yasak (AI mobil varsayılanları)

- Uzun listede tüm çocukları çizen `Column`/`SingleChildScrollView.map`
  → `ListView.builder` / `SliverList`.
- `build` içinde her seferinde yeni `AnimationController`.
- Dokunma alanı < 48dp; hedefler arası < 8dp.
- Jest tek yol (buton alternatifi yok).
- Yükleme/hata/boş durum yok.
- Token'ı paylaşılan prefs'te düz metin.
- `@riverpod` codegen'e bu sandbox'ta yeni provider (build_runner yok).

## Flutter kuralları

```dart
const MyWidget({super.key}); // rebuild kes
ListView.builder(itemBuilder: ..., key: ValueKey(item.id));
FadeTransition(opacity: animation, child: child); // Opacity animasyonu değil
```

GPU: transform + opacity. CPU: width/height/margin animasyonu kaçın.

## Dokunma (touch-psychology)

- iOS 44pt / Android 48dp / bu projede **48dp**.
- Birincil CTA başparmak yayı (oyun detayında yapışkan "Bilet al").
- Geri bildirim < 50ms (`InkWell` + gerekirse `HapticFeedback`).
- Yükleme 100ms içinde skeleton.

## Checkpoint (her mobil ekran öncesi)

```
Platform: iOS + Android
Framework: Flutter + Riverpod
3 ilke: 48dp, thumb-zone CTA, gerçek Firebase verisi
3 yasak: ScrollView+map, her karta hover büyüme, perde/spot süsü
```
