// "Senin için": kural tabanlı, tarayıcıda çalışan öneri şeridi (docs/ONERI.md).
// Sunucu ve yapay zekâ YOK; ek Firestore okuması YOK: yalnızca store.js verisi + kullanıcının kendi favorileri
// (fav.js) + (girişliyse) kendi biletleri. Mobil karşılığı: recommended_shows_provider.dart (aynı fikir: favori/izlenen türler).
// Gerçek kişisel sinyal yoksa şerit hiç çizilmez; uydurma "senin için seçtik" listesi gösterilmez.
import { favListe, favHazir } from './fav.js';
import { oturumBekle } from './auth.js';
import { biletleriDinle, gecmisMi } from './bilet-ortak.js';
import { oyunKarti, ray, bolumBasligi } from './ui.js';
import { esc } from './util.js';

const GUN = 864e5;

/**
 * Saf skor fonksiyonu (DOM yok, test edilebilir).
 * d: store verisi · ctx: { favOyun, favSahne, favOyuncu, favEkip: Set, izlenenOyun: Set (bileti olan oyun id),
 *   izlenenTurler: Map(tür -> adet), favTurler: Map(tür -> adet), il: string, now: Date }
 * Döner: [{ show, skor, neden: string[] }] — yalnızca en az bir KİŞİSEL sinyali olanlar, skora göre azalan.
 */
export function oneriHesapla(d, ctx) {
  const now = ctx.now || new Date();
  const out = [];
  for (const s of d.shows) {
    if (s.state !== 'aktif' || !s.next) continue;      // bitmiş / taslak / seansı yok: önerilmez (−)
    if (ctx.izlenenOyun.has(s.id)) continue;           // zaten bileti olan / izlenen oyun: önerilmez (−)
    let kisisel = 0, genel = 0;
    const neden = [];
    if (ctx.favOyun.has(s.id)) { kisisel += 4; neden.push('Favori oyunun'); }
    if (s.teamId && ctx.favEkip.has(s.teamId)) { kisisel += 3; neden.push('Favori ekibin'); }
    const oyuncu = s.cast.find((p) => ctx.favOyuncu.has(p.id));
    if (oyuncu) { kisisel += 3; neden.push(`Favori oyuncun ${oyuncu.fullName}`); }
    if (s.upcoming.some((e) => e.stage && ctx.favSahne.has(e.stage.id))) { kisisel += 2.5; neden.push('Favori sahnende'); }
    const izTur = ctx.izlenenTurler.get(s.cat) || 0;
    if (izTur) { kisisel += Math.min(2.5, 1 + 0.5 * izTur); neden.push(`İzlediğin türden: ${s.cat}`); }
    else if (ctx.favTurler.get(s.cat)) { kisisel += 1; neden.push(`Favori türlerinden: ${s.cat}`); }
    if (!kisisel) continue;                            // kişisel sinyal yoksa yalnız yakınlıkla öneri çıkmaz
    const ms = s.next.when - now;
    if (ms < 7 * GUN) genel += 1.5; else if (ms < 14 * GUN) genel += 0.8; else if (ms < 30 * GUN) genel += 0.3;
    if (ctx.il && s.iller.includes(ctx.il)) { genel += 1.5; neden.push(ms < 7 * GUN ? 'Şehrinde bu hafta' : 'Şehrinde'); }
    else if (ms < 7 * GUN) neden.push('Bu hafta sahnede');
    if (s.upcoming.length <= 2) genel += 0.2;
    out.push({ show: s, skor: kisisel + genel, neden });
  }
  return out.sort((a, b) => b.skor - a.skor || a.show.next.when - b.show.next.when);
}

const sayac = (liste) => { const m = new Map(); liste.forEach((x) => x && m.set(x, (m.get(x) || 0) + 1)); return m; };

/** Girişli kullanıcının biletlerinden izlenen oyun/tür bilgisi. Okunamazsa (kural/ağ/zaman aşımı) boş döner. */
let biletOnbellek = null;
function biletleriOku(uid) {
  if (biletOnbellek?.uid === uid) return biletOnbellek.p;
  const p = new Promise((coz) => {
    let iptal = null, bitti = false;
    const son = (v) => { if (bitti) return; bitti = true; try { iptal?.(); } catch {} coz(v); };
    const t = setTimeout(() => son(null), 4000);
    iptal = biletleriDinle(uid, (l) => { clearTimeout(t); son(l); }, () => { clearTimeout(t); son(null); });
    if (bitti) { try { iptal?.(); } catch {} }
  });
  biletOnbellek = { uid, p };
  return p;
}

async function baglamKur(d, il) {
  await favHazir().catch(() => {});
  const kume = (tur) => new Set(favListe(tur));
  const favOyun = kume('oyun');
  const ctx = { favOyun, favSahne: kume('sahne'), favOyuncu: kume('oyuncu'), favEkip: kume('topluluk'), izlenenOyun: new Set(), izlenenTurler: new Map(), favTurler: new Map(), il, now: new Date() };
  ctx.favTurler = sayac([...favOyun].map((id) => d.showById.get(id)?.cat));
  const u = await oturumBekle().catch(() => null);
  if (u?.uid) {
    const biletler = await biletleriOku(u.uid);
    if (biletler) {
      const gecerli = biletler.filter((b) => !b.iptalEdildi && b.show);
      gecerli.forEach((b) => ctx.izlenenOyun.add(b.show.id));
      ctx.izlenenTurler = sayac(gecerli.filter(gecmisMi).map((b) => b.show.cat));
    }
  }
  return ctx;
}

/** Şeridin yer tutucusu: boş ve gizli; veri hazır olunca oneriKur doldurur. */
export const oneriYerTutucu = () => '<section class="sec oneri-sec" id="oneri-sec" hidden aria-label="Senin için"></section>';

export function oneriHtml(sonuc) {
  const kart = ({ show, neden }) => `<div class="on-kart">${oyunKarti(show, { fiyat: false })}<span class="on-neden">${esc(neden.slice(0, 2).join(' · '))}</span></div>`;
  return `${bolumBasligi('Senin için', 'Favorilerine ve izlediğin türlere göre seçildi.')}${ray(sonuc.slice(0, 10).map(kart).join(''))}
    <p class="tiny on-not">Öneriler tarayıcında, favorilerin ve biletlerin kullanılarak hesaplanır; sunucuya ek veri gönderilmez. <a href="/gizlilik">Gizlilik</a></p>`;
}

/** Vitrine bağlar. home: ana kök; d: store verisi (ilSuz öncesi tam veri geçilmeli: show.iller zaten hesaplı). */
export function oneriKur(home, d, il) {
  const kok = () => home.querySelector('#oneri-sec');
  let sira = 0;
  const ciz = async () => {
    const bu = ++sira;
    let ctx;
    try { ctx = await baglamKur(d, il); } catch (e) { console.warn('oneri', e?.code || e?.message || ''); return; }
    const k = kok();
    if (bu !== sira || !k) return;
    const sonuc = oneriHesapla(d, ctx);
    if (!sonuc.length) { k.hidden = true; k.innerHTML = ''; return; }
    k.innerHTML = oneriHtml(sonuc); k.hidden = false;
  };
  ciz();
  let t;
  document.addEventListener('fav-degisti', () => { clearTimeout(t); t = setTimeout(ciz, 250); });
}
