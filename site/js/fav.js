// Favoriler: girişsizken tarayıcıda (localStorage), girişliyken HESAPTA (User/{uid}) — mobil uygulamayla aynı veri.
// Alanlar (mobil): favoriteShows / favoriteStages / favoritePlayers (id dizileri). Web'de ayrıca topluluk kalbi var:
// mobilde karşılığı olmadığı için `favoriteTeams` alanında tutulur (rules ek alanı engellemez; mobil bu alanı yok sayar).
// Akış: giriş -> yerel favoriler hesapla BİRLEŞTİRİLİR (küme birleşimi, arrayUnion) ve yerel depo temizlenir (tek seferlik,
// tekrar girişte yinelenmez); sonra doğruluk kaynağı hesap (onSnapshot ile canlı). Çıkış -> yerel depo da temizlenir
// (paylaşılan cihazda hesabın favorileri kalmaz). Yazımlar yalnız updateDoc + arrayUnion/arrayRemove (setDoc ile ezme YOK).
import { db, doc, onSnapshot, updateDoc, arrayUnion, arrayRemove } from './firebase.js';
import { oturumDinle, oturumBekle } from './auth.js';

const KEY_V1 = 'tiyatrol.fav.v1'; // eski biçim: türü belirsiz düz id dizisi
const KEY = 'tiyatrol.fav.v2';    // { oyun:[], sahne:[], oyuncu:[], topluluk:[], eski:[] }
export const FAV_TURLER = ['oyun', 'sahne', 'oyuncu', 'topluluk'];
const ALAN = { oyun: 'favoriteShows', sahne: 'favoriteStages', oyuncu: 'favoritePlayers', topluluk: 'favoriteTeams' };
const bosKume = () => ({ oyun: new Set(), sahne: new Set(), oyuncu: new Set(), topluluk: new Set(), eski: new Set() });
const str = (a) => (Array.isArray(a) ? a.filter((x) => typeof x === 'string' && x) : []);
const duz = (k) => Object.fromEntries(Object.entries(k).map(([t, s]) => [t, [...s]]));

function yerelOku() {
  const k = bosKume();
  try {
    const v2 = JSON.parse(localStorage.getItem(KEY) || 'null');
    if (v2 && typeof v2 === 'object') for (const t of Object.keys(k)) str(v2[t]).forEach((x) => k[t].add(x));
    const v1 = JSON.parse(localStorage.getItem(KEY_V1) || 'null');
    if (Array.isArray(v1)) { str(v1).forEach((x) => k.eski.add(x)); localStorage.setItem(KEY, JSON.stringify(duz(k))); localStorage.removeItem(KEY_V1); }
  } catch {}
  return k;
}
let yerel = yerelOku();
let hesap = null;   // { oyun:Set... } | null — ilk anlık görüntü gelene kadar null (yerel kip)
let uid = null;
let iptal = null;   // onSnapshot aboneliğini bırakır
let hazirCoz = null;
let hazirSoz = null;
const yerelYaz = () => { try { localStorage.setItem(KEY, JSON.stringify(duz(yerel))); } catch {} };
const yerelTemizle = () => { yerel = bosKume(); try { localStorage.removeItem(KEY); localStorage.removeItem(KEY_V1); } catch {} };
const yayinla = (detail = { senk: true }) => document.dispatchEvent(new CustomEvent('fav-degisti', { detail }));
const yerelDolu = () => Object.values(yerel).some((s) => s.size);

export function favMi(id, tur = 'oyun') {
  return !!((hesap && hesap[tur]?.has(id)) || yerel[tur]?.has(id) || yerel.eski.has(id));
}
/** Birleşik, tekrarsız id listesi (tür verilmezse hepsi): sayaç ve yedek bağlantısı için. */
export function favListe(tur) {
  const s = new Set();
  (tur ? [tur] : FAV_TURLER).forEach((x) => { hesap?.[x]?.forEach((i) => s.add(i)); yerel[x].forEach((i) => s.add(i)); });
  if (!tur) yerel.eski.forEach((i) => s.add(i));
  return [...s];
}
export const hesapKipinde = () => !!hesap;

/** Türü belirsiz (eski biçimdeki) id'leri sitedeki gerçek kayıtlara bakarak doğru türe taşır. */
async function eskiCoz() {
  if (!yerel.eski.size) return;
  try {
    const { yukle } = await import('./store.js');
    const d = await yukle();
    const kaynak = { oyun: d.shows, sahne: d.stages, oyuncu: d.players, topluluk: d.teams };
    for (const id of [...yerel.eski]) {
      const t = FAV_TURLER.find((x) => (kaynak[x] || []).some((r) => r.id === id));
      if (t) yerel[t].add(id);
      yerel.eski.delete(id); // veride yoksa (silinmiş kayıt) düşer
    }
    yerelYaz();
  } catch (e) { console.warn('fav eskiCoz', e?.code || ''); }
}

const denendi = new Set(); // uid: birleştirme yazımı sürüyor / bu oturumda başarısız (hata döngüsünü önler)
async function birlestir(u, uzak, beklemede) {
  if (u !== uid) return;
  await eskiCoz();
  if (u !== uid) return;
  const ekle = {};
  for (const t of FAV_TURLER) {
    const yeni = [...yerel[t]].filter((x) => !uzak[t].has(x));
    if (yeni.length) ekle[ALAN[t]] = arrayUnion(...yeni);
  }
  if (!Object.keys(ekle).length) { if (!beklemede && !denendi.has(u)) { yerelTemizle(); } return; }
  if (denendi.has(u)) return;
  denendi.add(u);
  try {
    await updateDoc(doc(db, 'User', u), ekle);
    if (u === uid) { yerelTemizle(); denendi.delete(u); }
  } catch (e) {
    console.warn('fav birlestir', e?.code || '');
    bildir('Yerel favorilerin hesabına aktarılamadı. Hesabına giriş yapmışken kalpleri kullanmaya devam edebilirsin.');
  }
}

function hazirBitir() { hazirCoz?.(); }
function anlik(u, snap) {
  if (u !== uid) return;
  if (!snap.exists()) { hazirBitir(); return; } // belge henüz yok (ilk giriş oluşturuyor); yerel kipte kal
  const v = snap.data() || {};
  const yeni = bosKume();
  for (const t of FAV_TURLER) str(v[ALAN[t]]).forEach((x) => yeni[t].add(x));
  const onceki = hesap ? JSON.stringify(duz(hesap)) : '';
  hesap = yeni;
  hazirBitir();
  if (JSON.stringify(duz(yeni)) !== onceki) yayinla();
  if (yerelDolu()) birlestir(u, yeni, snap.metadata.hasPendingWrites);
}

/** Hesap favorilerinin ilk yüklenmesini bekler (girişsizse hemen döner; en fazla ~3,5 sn). */
export async function favHazir() {
  await oturumBekle();
  if (!uid || hesap || !hazirSoz) return;
  await Promise.race([hazirSoz, new Promise((r) => setTimeout(r, 3500))]);
}

function hesapBagla(u) {
  uid = u.uid; hesap = null;
  hazirSoz = new Promise((r) => { hazirCoz = r; });
  iptal = onSnapshot(doc(db, 'User', uid), (s) => anlik(u.uid, s), (e) => {
    console.warn('fav dinleme', e?.code || ''); hesap = null; hazirBitir();
  });
}
function hesapBirak() {
  try { iptal?.(); } catch {}
  denendi.delete(uid);
  iptal = null; uid = null; hesap = null;
}
oturumDinle((u) => {
  const yeni = u?.uid || null;
  if (yeni === uid) return;
  if (uid) { hesapBirak(); yerelTemizle(); yayinla({ senk: true, cikis: true }); } // çıkış / hesap değişimi: önceki hesabın favorileri cihazda kalmaz
  if (yeni) hesapBagla(u);
});

export function favDegistir(id, tur = 'oyun') {
  const onceki = favMi(id, tur);
  const acik = !onceki;
  if (acik) (hesap || yerel)[tur].add(id);
  else { hesap?.[tur].delete(id); yerel[tur].delete(id); yerel.eski.delete(id); }
  if (!hesap || !acik) yerelYaz();
  yayinla({ id, tur, acik });
  if (hesap && uid) {
    const u = uid;
    updateDoc(doc(db, 'User', u), { [ALAN[tur]]: acik ? arrayUnion(id) : arrayRemove(id) }).catch((e) => {
      console.warn('fav yaz', e?.code || '');
      if (u !== uid || !hesap) return;
      if (onceki) hesap[tur].add(id); else hesap[tur].delete(id);
      yayinla({ id, tur, acik: onceki, geriAlindi: true });
      bildir(e?.code === 'permission-denied' ? 'Favori kaydedilemedi: hesabın şu an değişiklik kabul etmiyor.' : 'Favori kaydedilemedi. Bağlantını kontrol edip tekrar dene.');
    });
  }
  return acik;
}
/** Yedek bağlantısından gelen (türü belirsiz) id'leri ekler; yeni eklenen sayısını döner. */
export function favIceAl(ids) {
  const once = new Set(favListe());
  const yeni = str(ids).filter((x) => !once.has(x));
  yeni.forEach((x) => yerel.eski.add(x));
  yerelYaz();
  eskiCoz().then(() => { yayinla(); if (hesap && uid) { denendi.delete(uid); birlestir(uid, hesap, false); } });
  return yeni.length;
}
// Girişsiz açılışta eski biçimden kalan id'ler varsa türlerine ayır (tembel; sayfa verisi zaten yükleniyor)
if (yerel.eski.size) setTimeout(() => eskiCoz().then(() => yayinla()), 0);

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
export const kalpDugme = (id, sinif = 'kalp', tur = 'oyun') => `<button type="button" class="${sinif} ${favMi(id, tur) ? 'on' : ''}" data-fav="${id}" data-fav-tur="${tur}" aria-label="Favorilere ekle" aria-pressed="${favMi(id, tur)}">${KALP}</button>`;

// Sayfadaki tüm kalpleri geçerli duruma eşler (hesaptan / başka sekme veya cihazdan gelen değişiklikler dahil)
const boya = () => document.querySelectorAll('[data-fav]').forEach((x) => {
  const a = favMi(x.dataset.fav, x.dataset.favTur || 'oyun');
  x.classList.toggle('on', a); x.setAttribute('aria-pressed', String(a));
});
document.addEventListener('fav-degisti', boya);

// Tüm sayfada: kalp düğmeleri (kart üzerindekiler dahil)
document.addEventListener('click', (e) => {
  const b = e.target.closest('[data-fav]');
  if (!b) return;
  e.preventDefault(); e.stopPropagation();
  const id = b.dataset.fav, tur = b.dataset.favTur || 'oyun';
  const acik = favDegistir(id, tur);
  document.querySelectorAll(`[data-fav="${CSS.escape(id)}"]`).forEach((x) => { if ((x.dataset.favTur || 'oyun') !== tur) return; x.classList.remove('pat'); void x.offsetWidth; if (acik) x.classList.add('pat'); });
  bildir(acik ? 'Favorilerine eklendi' : 'Favorilerden çıkarıldı');
}, true);
