# Rive assets (TiyatRol)

## Gerçekten duran dosyalar

| Dosya | Kullanım |
|-------|----------|
| `loader.riv` | Keşfet / Yakındakiler ilk yükleme (`TiyatrolRiveLoader`) |
| `vehicles.riv` | Örnek paket — henüz UI’ya bağlı değil |
| `2195-4346-avatar-pack-use-case.riv` | Örnek paket — henüz UI’ya bağlı değil |

Çoğu hareket **Rive’siz**: `stage_moments.dart` (gül, üç gong, kıvılcım),
`sahne_kit` (PressScale / Reveal), `confetti`, Playfair wipe, alt menü orb.

## Marketplace (isteğe bağlı)

İndirip bu klasöre koyarsan `TiyatrolRiveAssets`’e sabit ekleyip bağlarız:
`like.riv`, `bell.riv`, `clock.riv`, `tape.riv`, `boards.riv`, `action.riv`,
`pigeons.riv`. Dosya yokken path yazmak runtime’da kırılır — ekleme.
