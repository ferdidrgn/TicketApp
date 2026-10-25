// Favoriler (tarayıcıda saklanır) + küçük bildirim + paylaşım. Giriş gerekmez.
const KEY = 'tiyatrol.fav.v1';
const oku = () => { try { return new Set(JSON.parse(localStorage.getItem(KEY) || '[]')); } catch { return new Set(); } };
const yaz = (s) => { try { localStorage.setItem(KEY, JSON.stringify([...s])); } catch {} };

export const favMi = (id) => oku().has(id);
export const favListe = () => [...oku()];
export function favDegistir(id) {
  const s = oku(); const var_ = s.has(id);
  var_ ? s.delete(id) : s.add(id); yaz(s);
  addEventListener('fav-degisti', () => {}, { once: true });
  document.dispatchEvent(new CustomEvent('fav-degisti', { detail: { id, acik: !var_ } }));
  return !var_;
}

let tt;
export function bildir(m) {
  let t = document.getElementById('bildirim');
  if (!t) { t = document.createElement('div'); t.id = 'bildirim'; t.setAttribute('role', 'status'); t.setAttribute('aria-live', 'polite'); document.body.append(t); }
  t.textContent = m; t.classList.add('on');
  clearTimeout(tt); tt = setTimeout(() => t.classList.remove('on'), 2400);
}

export async function paylas(baslik, metin = '') {
  const url = location.href.split('#')[0];
  try { if (navigator.share) { await navigator.share({ title: baslik, text: metin, url }); return; } } catch { return; }
  try { await navigator.clipboard.writeText(url); bildir('Bağlantı kopyalandı'); }
  catch { bildir(url); }
}

export const KALP = '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M12 20s-7.5-4.6-9.3-9.2C1.6 7.6 3.4 4.5 6.5 4.5c2 0 3.5 1.1 4.5 2.7h2c1-1.6 2.5-2.7 4.5-2.7 3.1 0 4.9 3.1 3.8 6.3C19.500 15.400 12 20 12 20Z"/></svg>';
export const kalpDugme = (id, sinif = 'kalp') => `<button type="button" class="${sinif} ${favMi(id) ? 'on' : ''}" data-fav="${id}" aria-label="Favorilere ekle" aria-pressed="${favMi(id)}">${KALP}</button>`;

// Tüm sayfada: kalp düğmeleri (kart üzerindekiler dahil)
document.addEventListener('click', (e) => {
  const b = e.target.closest('[data-fav]');
  if (!b) return;
  e.preventDefault(); e.stopPropagation();
  const acik = favDegistir(b.dataset.fav);
  document.querySelectorAll(`[data-fav="${b.dataset.fav}"]`).forEach((x) => { x.classList.toggle('on', acik); x.setAttribute('aria-pressed', acik); x.classList.remove('pat'); void x.offsetWidth; if (acik) x.classList.add('pat'); });
  bildir(acik ? 'Favorilerine eklendi' : 'Favorilerden çıkarıldı');
}, true);
