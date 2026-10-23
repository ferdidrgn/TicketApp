# Tasarım skill'leri — nasıl kullanılır

Kaynak: "Claude Code ile Tasarım Skill + MCP Kurulumu" rehberi (Talha Unuvai).
Bu bilgisayarda skill'ler **kullanıcı düzeyinde** (`C:\Users\<kullanıcı>\.claude\skills\`) kuruludur;
yani Claude Code hangi projede açılırsa açılsın görür. Yeni skill'ler için Claude Code'u kapatıp yeniden aç.

## Kurulu olanlar

| Skill | Ne işe yarar | Ne zaman tetiklenir |
| --- | --- | --- |
| `emil-animate`, `emil-animation-performance`, `emil-animation-vocabulary`, `emil-find-animation-opportunities`, `emil-improve-animations`, `emil-review-animations` | Hareket: ne zaman animasyon, hangi eğri/süre, performans, denetim | "animasyon ekle / düzelt / incele" dediğinde |
| `emil-apple-design`, `emil-emil-design-eng`, `emil-break-ui` | Apple tasarım ilkeleri, tasarım mühendisliği ayrıntıları, arayüzü bozup zayıf yerleri bulma | Arayüz kalitesi, cila |
| `design-taste-frontend` ("Taste") | Şablon/"yapay zekâ yapmış" hissini azaltır: yasaklı kalıplar, konudan çıkan fikir, bölüm düzeni | "sıkıcı/şablon görünüyor", yeni sayfa/ana sayfa |
| `impeccable` (yalnızca belgeler) | Denetim, eleştiri, cila, sadeleştirme, hareket, düzen, tipografi, renk, uç durumlar | "denetle", "polish", "critique" |

Not: Impeccable'ın orijinal paketi ayrıca bir çalıştırılabilir dosya indiriyor; güvenlik için bu kurulumda
**yalnızca belgeler** var, komutlar belgeleri okuyarak uygulanır. Taste'in betikleri (Node + Chrome gerekir)
çalışmadan önce izin ister.

## Nasıl istersin (örnek cümleler)

- "Ana sayfayı **Taste ve Impeccable** ilkelerine göre denetle, bulduğun sorunları düzelt."
- "**emil-review-animations** ile web ana sayfasındaki hareketleri incele."
- "Oyun detay sayfasına **impeccable polish** uygula."
- "Yeni 'Mekânlar' sayfasını Taste'e göre tasarla; önce iddiaları (claims) yaz."

## Rehberdeki diğer iki araç (kurulumu sen yaparsın)

- **Playwright MCP** (Claude'un siteyi gerçek tarayıcıda açıp farklı genişliklerde denemesi için):
  `claude mcp add playwright npx @playwright/mcp@latest` — sonra Claude Code'u yeniden başlat, `/mcp` ile `connected` gör.
  (Bu projede şimdilik Claude'un yerleşik tarayıcı paneli aynı işi görüyor.)
- **Figma MCP** (Figma çerçevesini okuyup birebir uygulamak için):
  `claude plugin install figma@claude-plugins-official` — sonra `/plugin` → figma → giriş yap → Allow access.

## Bu projede hangi kurallar önceliklidir?

1. `CLAUDE.md` ve `.claude/skills/tiyatrol-design/` (5 tema, renk/token, reddedilenler listesi) **önce** gelir.
2. Web için sahibinin kararı: Minar gibi **gerçek bir mağaza sitesi yoğunluğu** (başlık, arama, raflar, tablo, footer).
3. Skill'lerin yasakları web ana sayfasına uygulandı (13 Ekim sonrası): her bölümde aynı belirme animasyonu yok,
   üst etiket/pill yok, aynı boyutlu ikonlu kart ızgarası yok, "büyük sayı + küçük etiket" şeridi yok,
   her karta hover yükselmesi/gölge yok. Hareket yalnızca kullanıcı eyleminin sonucu (hover, seçim, geçiş).
