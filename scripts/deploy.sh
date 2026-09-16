#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# TiyatRol — birleşik deploy script'i
#
# Domain kökünde statik landing sitesini (landing/), "/app" altında
# ise Flutter web uygulamasını (build/web) tek bir Firebase Hosting
# sitesi altında yayınlamak için ikisini "deploy/" klasöründe birleştirir:
#
#   deploy/
#     index.html, style.css, app.js, legal.js, logo-mark.png,
#     privacy.html, terms.html      ← landing/ birebir kopyası
#     app/
#       index.html, main.dart.js, ...  ← flutter build web çıktısı
#
# Firebase Hosting bu klasörü olduğu gibi yayınlar; firebase.json'daki
# "/app/**" rewrite'ı sayesinde /app altındaki her adres (ör.
# /app/show/metafor-abc123) Flutter'ın kendi index.html'ine düşer ve
# GoRouter istemci tarafında doğru sayfayı açar.
#
# Kullanım:
#   ./scripts/deploy.sh            # sadece deploy/ klasörünü üretir
#   ./scripts/deploy.sh --publish  # üretir VE firebase deploy'u çalıştırır
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

DEPLOY_DIR="$ROOT_DIR/deploy"

echo "→ deploy/ temizleniyor…"
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR"

echo "→ landing/ (statik site) deploy/ köküne kopyalanıyor…"
cp -R "$ROOT_DIR/landing/." "$DEPLOY_DIR/"

echo "→ Flutter web derleniyor (base-href: /app/)…"
flutter build web --release --base-href /app/

echo "→ Flutter build çıktısı deploy/app/ altına kopyalanıyor…"
mkdir -p "$DEPLOY_DIR/app"
cp -R "$ROOT_DIR/build/web/." "$DEPLOY_DIR/app/"

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
