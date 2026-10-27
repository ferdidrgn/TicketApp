/* ═══════════════ Gizlilik Politikası / Kullanım Şartları sayfaları
   Flutter uygulamasıyla AYNI Firestore dokümanından ("AppTools" koleksiyonu,
   tek doküman) okuyor — tek kaynak, iki yerde de güncel içerik. ── */
const FIREBASE_PROJECT_ID = 'ticketappflutter';
const FIREBASE_API_KEY = 'AIzaSyDTszWHMEMHY1Ed2ZftOcNUlvXl03S7g-k';
const FIRESTORE_BASE = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents`;
const APP_TOOLS_DOC_ID = 'bgVYTTauB9gwd1qOyjix';

function unwrapValue(v) {
  if (v == null) return null;
  if ('stringValue' in v) return v.stringValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('doubleValue' in v) return Number(v.doubleValue);
  if ('booleanValue' in v) return v.booleanValue;
  if ('timestampValue' in v) return v.timestampValue;
  if ('nullValue' in v) return null;
  if ('arrayValue' in v) return (v.arrayValue.values || []).map(unwrapValue);
  if ('mapValue' in v) return unwrapFields(v.mapValue.fields || {});
  return null;
}
function unwrapFields(fields) {
  const out = {};
  for (const k of Object.keys(fields || {})) out[k] = unwrapValue(fields[k]);
  return out;
}

async function loadLegalContent() {
  const container = document.getElementById('legalContent');
  if (!container) return;
  const field = container.dataset.field;
  try {
    const url = `${FIRESTORE_BASE}/AppTools/${APP_TOOLS_DOC_ID}?key=${FIREBASE_API_KEY}`;
    const res = await fetch(url);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const json = await res.json();
    const data = unwrapFields(json.fields || {});
    const html = data[field];
    container.innerHTML = html
      ? html
      : `<p class="legal__empty">Bu içerik şu anda güncelleniyor. Sorularınız için bizimle <a href="index.html#iletisim">iletişime geçebilirsiniz</a>.</p>`;
  } catch (err) {
    console.error('Legal içerik okunamadı:', err);
    container.innerHTML = `<p class="legal__empty">İçerik yüklenirken bir sorun oluştu. Lütfen sayfayı yenileyin ya da bizimle <a href="index.html#iletisim">iletişime geçin</a>.</p>`;
  }
}

const yearEl = document.getElementById('year');
if (yearEl) yearEl.textContent = new Date().getFullYear();
loadLegalContent();
