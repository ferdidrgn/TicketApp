---
name: frontend-design
source: https://github.com/davila7/claude-code-templates
path: cli-tool/components/skills/creative-design/frontend-design/SKILL.md
license: Apache 2.0 — bkz. ../LICENSE.txt
adapted: Flutter / TiyatRol (06.10.2026)
---

# Frontend Design → Flutter

Tasarım stüdyosu gibi çalış: her ürünün kimliği başkasınınkine karışmasın.
Konu (tiyatro bileti, afiş, seans) malzemeyi verir; şablon palet vermez.

## İlkeler (web)

- Hero: konunun en karakteristik şeyi (TiyatRol: gerçek afiş + oyun adı +
  en yakın seans). Büyük sayı + etiket + gradyan varsayılanını kullanma.
- Tipografi kişilik taşır. En fazla iki aile; display ile gövde arasında
  net ölçek. Flutter: `google_fonts` + `latin-ext`.
- Hareket az ve bilinçli. Sayfa başına tek koreografi. Kullanıcı aksiyonuna
  cevap veren hareket iyi. Her bölüme fade-in = yapay zekâ işareti.
- Yapı bilgidir: çerçeve/numara sadece gerçek sıra varsa.

## Yapay zekâ varsayılanları (kaçın; brief özellikle istemedikçe)

1. Krem zemin + serif + kiremit vurgu (Claude etkileşim rengi).
2. Siyaha yakın zemin + tek asit yeşil / vermilyon.
3. Broadsheet: sıfır radius, gazete sütunları.
4. SaaS kart kiti: aynı radius, aynı gri gölge, süs gradyan.
5. Tracked ALL-CAPS eyebrow, `A · B · C` meta, `WORD — fragment`,
   monospace etiket, buton sonu `→`.

TiyatRol istisnası: Playfair + soldan sağa wipe **sahip onaylı**. Bilet
alanlarında bilinçli BÜYÜK HARF etiket var; her başlığın üstünde yok.

## Flutter karşılıkları

| Web | Flutter |
|---|---|
| CSS clamp | `homeFluid` / `browseFluid` / `ResponsiveUtils` |
| hover | `InkWell.onHover` / `MouseRegion` (web); mobilde yok |
| cubic-bezier | `AppMotion.overshoot` / `elegant` / `sharp` |
| max-width okuma sütunu | `ConstrainedBox` ~680–1440 |
| reduced motion | `MediaQuery.disableAnimations` |

Süreç: plan (renk/tip/yerleşim/ilke) → brief'e karşı gözden geçir → HTML
maket büyük kararda → kod → bir aksesuarı çıkar.
