#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# TiyatRol — birleşik deploy script'i
#
# Statik landing sitesini (landing/) VE Flutter web uygulamasını
# (build/web) AYNI domain KÖKÜNDE yayınlamak için "deploy/" klasöründe
# birleştirir — artık "/app" alt yolu YOK, uygulama rotaları
# (/show/x, /discover, /nearby, ...) doğrudan kökte çalışır:
#
#   deploy/
#     index.html, style.css, app.js, legal.js, logo-mark.png,
#     robots.txt, sitemap.xml, app-ads.txt, .well-known/, ...
#                                    ← landing/ birebir kopyası (öncelikli)
#     app-shell.html                ← Flutter'ın KENDİ index.html'i, ayrı
#                                      isimle (landing/index.html ile
#                                      kökte ÇAKIŞMASIN diye)
#     main.dart.js, flutter.js, assets/, canvaskit/, icons/,
#     manifest.json, version.json, ...
#                                    ← flutter build web çıktısının GERİ
#                                      KALANI (index.html HARİÇ), kökte
#
# Flutter build'i "--base-href /" ile derleniyor (kök dizin) — bu yüzden
# main.dart.js gibi asset referansları zaten "/main.dart.js" gibi kök-
# mutlak, hangi rotada (app-shell.html) servis edildiğinden bağımsız
# doğru çalışıyor.
#
# firebase.json'daki rota-bazlı rewrite kuralları (/show/**, /discover,
# /nearby, /profile, ... → /app-shell.html) her gerçek uygulama rotasını
# app-shell.html'e yönlendiriyor; landing'in KENDİ sayfaları (/,
# /privacy.html, /terms.html, ...) rewrite'a hiç girmeden birebir dosya
# olarak servis ediliyor (Firebase Hosting önce tam eşleşen dosyayı arar).
#
# NOT — web/robots.txt, web/sitemap.xml, web/app-ads.txt ve
# web/yandex_*.html Flutter projesinin İÇİNDE hâlâ duruyor ama BİLEREK
# deploy/'a kopyalanmıyor (aşağıdaki "rm -f" adımı): bunlar artık
# landing/'deki (kökte servis edilen, doğru/güncel) sürümleriyle birebir
# aynı isimde olduğundan üzerine yazarlarsa yanlış/eski içerik köke
# sızardı. Kaynak ağacında bırakıldı (silmek gerekmiyor), sadece deploy
# aşamasında bilerek atlanıyor.
#
# Kullanım:
#   ./scripts/deploy.sh            # sadece deploy/ klasörünü üretir
#   ./scripts/deploy.sh --publish  # üretir VE firebase deploy'u çalıştırır
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

# Windows'ta Git Bash (MSYS/MinGW), "/" ile başlayan argümanları native
# (Unix olmayan) programlara geçirirken otomatik olarak Windows yoluna
# çevirir (ör. "/" -> "D:/Program Files/Git/"), `flutter build web
# --base-href /` çağrısını bozar. Bu değişken bu otomatik dönüşümü kapatır;
# Linux/macOS'ta zaten hiçbir etkisi yok.
export MSYS_NO_PATHCONV=1

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

DEPLOY_DIR="$ROOT_DIR/deploy"

echo "→ deploy/ temizleniyor…"
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR"

echo "→ landing/ (statik site) deploy/ köküne kopyalanıyor…"
cp -R "$ROOT_DIR/landing/." "$DEPLOY_DIR/"

echo "→ Flutter web derleniyor (base-href: /, kök dizin)…"
flutter build web --release --base-href /

echo "→ Flutter'ın kendi index.html'i \"app-shell.html\" olarak ayrı saklanıyor…"
cp "$ROOT_DIR/build/web/index.html" "$DEPLOY_DIR/app-shell.html"

echo "→ Flutter build çıktısının geri kalanı deploy/ köküne kopyalanıyor…"
cp -R "$ROOT_DIR/build/web/." "$DEPLOY_DIR/"

echo "→ landing/ ile çakışan Flutter dosyaları deploy/'dan temizleniyor (landing/ sürümü tek doğru kaynak)…"
rm -f "$DEPLOY_DIR/robots.txt" "$DEPLOY_DIR/sitemap.xml" "$DEPLOY_DIR/app-ads.txt" "$DEPLOY_DIR/yandex_60ebe5ae9f1940b7.html"

echo "→ landing/'in kendi index.html'i geri yükleniyor (Flutter'ın index.html kopyası onu ezmiş olabilir)…"
cp "$ROOT_DIR/landing/index.html" "$DEPLOY_DIR/index.html"

echo "✓ deploy/ hazır: $DEPLOY_DIR"

if [[ "${1:-}" == "--publish" ]]; then
  echo "→ firebase deploy çalıştırılıyor (hosting)…"
  firebase deploy --only hosting
  echo "✓ Yayınlandı."
else
  echo "İncelemek için: (cd deploy && python3 -m http.server 8000)"
  echo "Yayınlamak için: firebase deploy --only hosting"
  echo "(ya da bu script'i --publish ile tekrar çalıştır)"
fi
