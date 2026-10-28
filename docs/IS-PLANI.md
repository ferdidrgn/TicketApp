# TiyatRol — İş Planı (Jira benzeri backlog)

Durum: `TODO` · `DOING` · `REVIEW` · `DONE` · `BLOCKED` (sahibi bekleniyor)
Boyut: S (≤1 gün) · M (2–4 gün) · L (5+ gün). Her iş ayrı ajanla, ayrı worktree'de yapılır, `tiyatrol-web-perde` dalına rebase ile gelir; `main`'e yalnız sahibinin onayıyla çıkar.
Çakışma kuralı: `firestore.rules`, `functions/index.js`, `site/js/admin/*`, `site/js/pages/oyun.js` ortak noktalardır; aynı dalgada yalnız bir iş bunlara geniş dokunur, diğerleri yalnız kendi ayrı dosyasını ekler.
Kaynak raporlar: telefon kimliği (docs/TELEFON-DOGRULAMA.md), hesap silme (docs/HESAP-SILME.md), bildirim (docs/BILDIRIM-ISTATISTIK.md), deploy (docs/DEPLOY-SIRASI.md); araştırma bulguları bu plan.

## EPİK 0 — Yayın hattı (sahibi + ben)
| ID | İş | Durum | Not |
|---|---|---|---|
| R-1 | Telefon kimliği + hesap silme + favori + sessiz-alarm paketini birleştir, sürüm artır, main'e gönder | TODO | Önce W1-W2 güvenlik işleri bitsin |
| R-2 | Firebase: Phone sağlayıcı, Authorized domains, SHA parmak izleri, Blaze, bütçe (TL), `PHONE_HASH_SALT` | BLOCKED (sahip) | docs/DEPLOY-SIRASI.md |
| R-3 | Deploy sırası: functions → mobil → rules | BLOCKED (sahip) | rules en son |
| R-4 | Play'e `.aab` yükleme, Android Publisher API etkinleştirme | BLOCKED (sahip) | |

## DALGA 1 (hemen, paralel; ortak dosya çakışması yok)
| ID | İş | Alan | Boyut | Bağımlılık | Kabul ölçütü |
|---|---|---|---|---|---|
| S-1 | Güvenlik sertleştirme + saldırı simülasyonu: `Review`/`Notification`/`ReviewReport` kuralları, yazma yolu callable, rol yükseltme red-team testleri, `storage.rules` dosyası, App Check (web SDK + mobil kontrol, kademeli zorlama) | rules, functions/test, site/js/firebase.js | M | — | Emülatörde tüm saldırı senaryoları reddedilir; test yeşil |
| T-1 | Ekip yöneticisi rolü: `TeamManager` modeli, kapsam doğrulama (`resolveEventTeam`), `team*` callable'lar (bildirim/kapı/istatistik), admin'de atama, web `/ekip` sayfası | functions/src/team.js, rules (ek blok), site/ekip | L | S-1 ile rules koordinasyonu | Başka ekibe işlem reddedilir; kişisel veri sızmaz; limitler çalışır |
| O-1 | Otomasyon/altyapı: Telegram/e-posta sağlık uyarısı (Actions cron), site otomatik yenileme (cron + panel düğmesi), Dependabot, CI'ye functions testi | .github/, site/tools | M | — | Cron çalışır; deploy tetiklenir |
| U-1 | Web arayüz cilası: animasyon, interaktif bileşenler, zengin içerik (vitrin, oyun/oyuncu/sahne sayfaları) | site/css, fx.js, pages | L | — | Tema bozulmaz, 390px taşma yok, reduced-motion |

## DALGA 2 (Dalga 1 + rules birleşince)
| ID | İş | Boyut | Bağımlılık |
|---|---|---|---|
| N-1 | Etkinliğe gelen kişilere mesaj/push: admin + ekip yöneticisi için seans bazlı gönderim ekranı (şablon + kısa metin, alıcı sayısı önizleme), otomatik "seans iptal" bildirimi, bilet sahiplerine seans sonrası teşekkür | M | T-1 · **REVIEW** (28.10: otomatik iptal/erteleme + teşekkür + alarm2h bayrağı; docs/BILDIRIM-TERCIHLERI.md) |
| N-2 | Bildirim tercihleri (`User.notifPrefs`: kategori aç/kapa, sessiz saat), işlemsel/pazarlama ayrımı | M | sessiz-alarm işi · **REVIEW** (28.10: şema+kurallar+mobil+web+sunucu süzgeci) |
| N-3 | `fcmTokens` çoklu cihaz (dizi), ölü token temizliği | S | — |
| Q-1 | Doğrulanmış yorum (bilet sahibi, `verified`, sunucudan yazım) + seans sonrası "nasıldı?" | M | S-1 |
| Q-2 | Ekibe soru sor (Q&A, ön onaylı) + kural tabanlı SSS botu | M | S-1, T-1 |
| M-1 | Moderasyon: şikâyet et, kullanıcı engelle, otomatik gizleme eşiği, panel, `ModerationLog` (Play/App Store UGC şartı) | M | Q-1 |

## DALGA 3
| ID | İş | Boyut |
|---|---|---|
| F-1 | Takip et (oyuncu/sahne/topluluk) + yeni oyun bildirimi (FCM topic) | M |
| F-2 | "Yer açılınca haber ver" bekleme listesi | M |
| F-3 | İzledim koleksiyonu + Tiyatro Pasaportu + paylaşılabilir kart | M |
| F-4 | "Senin için" kural tabanlı öneri | S |
| F-5 | Anket/oylama (haftanın oyunu, hesap başına tek oy) | S |
| F-6 | Arkadaşa gönder / grup planı linki | S |
| F-7 | Bağış + gönüllü başvuru linkleri (Team alanları, harici bağlantı) | S |
| F-8 | Google Cüzdan bileti | L |
| A-1 | Haftalık özet raporu (Telegram/e-posta), TTL/yedekleme | M |

## ERTELENEN / ONAY BEKLEYEN
Canlı herkese açık sohbet (24 saat moderasyon sorumlusu gerekir), LLM botu, hediye bilet/piyango, e-bülten, uygulama içi bağış, Apple Cüzdan.

## Sürekli kurallar (her iş için)
1. Kabul ölçütü olmadan "bitti" denmez; test ve gerçek tarayıcı/emülatör kanıtı rapora yazılır.
2. Yeni koleksiyon: rules (istemci yazamaz varsayılanı) + `processAccountDeletions` kapsamı + KVKK notu.
3. Yeni kullanıcı içeriği: şikâyet/engel/filtre olmadan yayına çıkmaz.
4. Yeni zamanlanmış iş açılmaz (3 ücretsiz iş dolu); mevcut işe görev eklenir.
5. Deploy sırası bozulmaz: functions → istemciler → rules.

## EK İŞLER (sohbette önerilen, plana sonradan eklenen)
| ID | İş | Dalga | Durum | Not |
|---|---|---|---|---|
| AD-1 | Yönetim paneli formları: "Erişilebilir performans" kısaltma kutusu → Türkçe onay kutuları (Sesli betimleme/Altyazılı/İşaret dili/Rahat gösterim; AD,CAP,BSL,R saklanır), "Haftanın oyunu" → onay kutusu | 2 | TODO | admin.js/schema.js; T-1 sonrası |
| AD-2 | Panelde sessiz-alarm tercihi göstergesi (`loudAlarm.optedIn/of`, `loudCount`) ve hesap silme sağlık kutusu cilası | 2 | TODO | admin; T-1 sonrası |
| N-3 | Çoklu cihaz: `fcmTokens` dizisi (mobil yazım + notify.js alıcı çözümü + ölü token temizliği + eski `fcmToken` geçişi) | 1b | DOING | lib/ + notify.js (minimal) |
| N-4 | 2 saatlik otomatik hatırlatmayı `loudAlarm` tercihine bağlama (karar: sahibi onaylayınca) | 2 | BLOCKED (karar) | |
| M-3 | Mobil: misafir (anonim) kullanıcı koltuk ekranında doğrudan telefon doğrulama sheet'i (anonim hesabı telefona bağla); Firebase'de Anonymous kapalıysa misafir girişi davranışı | 1b | DOING | lib/ |
| F-9 | Biletlere telefon özeti (`phoneKey`) alanı: destek/arama kolaylığı (KVKK notuyla; sahibi onayı) | 3 | BLOCKED (karar) | |
| G-1 | Gizlilik/şartlar metinleri: telefon doğrulama, hesap silme (30 gün, anonimleştirme), bildirim tercihi, UGC/moderasyon, yurt dışı aktarım | — | BLOCKED (sahip+avukat) | taslaklar docs'ta |
| G-2 | Mağaza formları: Play Data Safety/UGC, Apple App Privacy/inceleme notu | — | BLOCKED (sahip) | |
| H-1 | Eksik sahip adımları listesi: Authorized domains, Phone provider, SHA, Blaze, bütçe (TL), PHONE_HASH_SALT, Storage kuralı kontrolü, 2FA | — | BLOCKED (sahip) | docs/GUVENLIK-DENETIMI.md (S-1) |
| L-1 | Etkinlik başına bilet limiti (telefon bazlı, Config/satis.etkinlikBasinaLimit), getEventQuota, web+mobil uyarı şeridi, mobil onay sonrası çıkış, mobil hata eşleme tablosu | 2 | DONE (dalda; deploy yok) | docs/ODEME-GUVENLIK.md §16. KARAR BEKLİYOR: global toplam limitler (ücretsiz 3 / rezervasyon 3) etkinlik başına limitle birlikte mi? Tarayıcıda uçtan uca doğrulanmadı. |

## DURUM TABLOSU (ajan başına)
Tamamlandı ve dalda: telefon kimliği (backend+web+mobil+denetim), hesap silme (backend+web+mobil+denetim), web favorileri hesaba bağlı (main'de), sessizde sesli hatırlatma (izinli, 869a9e2b), maliyet/güvenlik/UX/otomasyon araştırmaları.
Çalışıyor (Dalga 1): S-1, T-1, O-1, U-1; (1b): N-3 + M-3.
