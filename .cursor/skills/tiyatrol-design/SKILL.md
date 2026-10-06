---
name: tiyatrol-design
description: TiyatRol Flutter UI — yeni ekran, redesign, kart, animasyon, responsive, tema. frontend-design + mobile-design (claude-code-templates) Flutter uyarlaması. Kullan: arayüz işi, ana sayfa, keşfet, arama, yakındakiler.
---

# TiyatRol tasarım (Cursor)

**Tam metin:** `.claude/skills/tiyatrol-design/SKILL.md`

Okunacaklar (sırayla): `SKILL.md` → `references/history.md` → `references/motion.md` → `references/interaction.md` → `sources/frontend-design.md` + `sources/mobile-design.md`.

## Sahip kararları

- 5 tema bozulmaz; renk `context.colors` / `ThemeExtension`.
- Bilet dili: giriş, biletlerim, koltuk, ödeme, alt menü, arama damgası.
- Keşif: `HomePosterCard`, mozaiği, vitrin, harita — her yere koçan yok.
- Yasak: D-köşe, vesica, her ekranda perde/spot, hotlink stok foto.
- Etkileşim gerçek Firestore verisine bağlı; sahte GPS yok.
- `build_runner` yok: yeni `@riverpod` ekleme.
