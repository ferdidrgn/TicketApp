import { yukle } from '../store.js';
import { kabukCiz, oyunKarti, ray, kelimeKelime } from '../ui.js';
import { baslikYaz, bulunamadi, hata, etkilesimler, sekmeler, sayAc, galeri } from '../detay.js';
import { favMi } from '../fav.js';
import { paylasMenusu } from '../ozellik.js';
import { $, esc, idFromPath, linkOf, baslangic, tarihUzun, saat, kisalt } from '../util.js';

kabukCiz('toplulukler');

/** Yalnız https:// adresleri kabul eder (harici bağlantı); geçersizse ''. */
const httpsUrl = (v) => { try { const u = new URL(String(v || '').trim()); return u.protocol === 'https:' ? u.href : ''; } catch { return ''; } };
/** "Ekibe destek ol" / "Gönüllü ol": Team.donationUrl / volunteerUrl varsa harici düğmeler. Uygulama içinde bağış toplanmaz. */
export function destekHtml(t) {
  const bagis = httpsUrl(t.donationUrl), gonullu = httpsUrl(t.volunteerUrl);
  if (!bagis && !gonullu) return '';
  const rel = 'noopener noreferrer nofollow';
  return `<div class="destek"><div class="destek-act">${bagis ? `<a class="btn btn-ghost" href="${esc(bagis)}" target="_blank" rel="${rel}" data-destek="bagis">Ekibe destek ol</a>` : ''}${gonullu ? `<a class="btn btn-ghost" href="${esc(gonullu)}" target="_blank" rel="${rel}" data-destek="gonullu">Gönüllü ol</a>` : ''}</div>
    <p class="tiny">Harici bağlantı: bu bağlantılar topluluğun kendi seçtiği sayfalara gider; TiyatRol üzerinden ödeme alınmaz.</p></div>`;
}
yukle().then((d) => {
  const t = d.teamById.get(idFromPath());
  if (!t) return bulunamadi('Topluluk');
  baslikYaz(t.name, t.description, t.imageUrl);
  const sahnede = t.shows.filter((s) => s.state === 'aktif' || s.state === 'vitrin');
  const gecmis = t.shows.filter((s) => s.state === 'bitti' || s.state === 'taslak');
  const kadro = [...new Map(t.shows.flatMap((s) => [...s.cast, ...s.pastCast]).map((p) => [p.id, p])).values()];
  const sonraki = t.shows.map((s) => s.next).filter(Boolean).sort((a, b) => a.when - b.when)[0];
  const sahneler = [...new Map(t.shows.flatMap((s) => s.sessions.map((e) => e.stage)).filter(Boolean).map((g) => [g.id, g])).values()];
  const kalpB = `<button type="button" class="kalp-b ${favMi(t.id, 'topluluk') ? 'on' : ''}" data-fav="${t.id}" data-fav-tur="topluluk" aria-pressed="${favMi(t.id, 'topluluk')}"><svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M12 20s-7.5-4.6-9.3-9.2C1.6 7.6 3.4 4.5 6.5 4.5c2 0 3.5 1.1 4.5 2.7h2c1-1.6 2.5-2.7 4.5-2.7 3.1 0 4.9 3.1 3.8 6.3C19.5 15.4 12 20 12 20Z"/></svg>Takip et</button>`;

  const yan = `<aside class="yan-kart">${sonraki ? `<h3>Sıradaki oyun</h3><div><b>${esc(sonraki.show.name)}</b><br><span class="muted">${tarihUzun(sonraki.when)} · ${saat(sonraki.when)}${sonraki.stage ? ` · ${esc(sonraki.stage.name)}` : ''}</span></div><a class="btn btn-primary" href="${linkOf('oyun', sonraki.show)}">Oyuna git</a>` : '<h3>Şu an sahnede değil</h3><p class="muted">Yeni oyun açıklanınca burada görünür.</p>'}${sahneler.length ? `<h3 style="margin-top:8px">Oynadığı sahneler</h3>${sahneler.map((g) => `<a class="ort" href="${linkOf('sahne', g)}"><b>${esc(g.name)}</b></a>`).join('')}` : ''}</aside>`;
  const tabHtml = [
    { id: 'hakkinda', ad: 'Hakkında', html: `<div class="pf-iki"><div>${t.description ? `<p class="story">${esc(t.description)}</p>` : '<div class="empty">Açıklama eklenmedi.</div>'}</div>${yan}</div>` },
    { id: 'sahnede', ad: 'Sahnede', sayi: sahnede.length, html: sahnede.length ? ray(sahnede.map((s) => oyunKarti(s)).join('')) : '' },
    { id: 'kadro', ad: 'Kadro', sayi: kadro.length, html: kadro.length ? `<div class="cast">${kadro.map((p) => `<a href="${linkOf('oyuncu', p)}"><div class="arch">${p.imageUrl ? `<img src="${esc(p.imageUrl)}" alt="${esc(p.fullName)}" loading="lazy">` : esc(baslangic(p.fullName))}</div><b>${esc(p.fullName)}</b></a>`).join('')}</div>` : '' },
    { id: 'galeri', ad: 'Galeri', sayi: t.photos.length, html: galeri(t.photos, t.name) },
    { id: 'gecmis', ad: 'Geçmiş oyunlar', sayi: gecmis.length, html: gecmis.length ? `<div class="grid">${gecmis.map((s) => oyunKarti(s)).join('')}</div>` : '' },
  ];
  $('#icerik').innerHTML = `
  <section class="pf-hero"><div class="wrap pf-grid">
    <div class="pf-foto kare">${t.imageUrl ? `<img src="${esc(t.imageUrl)}" alt="${esc(t.name)}">` : `<div class="yok">${esc(baslangic(t.name))}</div>`}</div>
    <div class="pf-info"><div class="crumbs"><a href="/vitrin">Vitrin</a> / <a href="/kesfet?tur=topluluklar">Topluluklar</a></div><h1>${kelimeKelime(t.name)}</h1>
      <div class="pf-sayilar"><div><b data-say="${sahnede.length}">0</b><span>Sahnede</span></div><div><b data-say="${t.shows.length}">0</b><span>Toplam oyun</span></div><div><b data-say="${kadro.length}">0</b><span>Oyuncu</span></div></div>
      <div class="op-act">${sonraki ? `<a class="btn btn-primary" href="${linkOf('oyun', sonraki.show)}">Sıradaki oyuna git</a>` : ''}${kalpB}<button class="btn btn-ghost" id="paylas">Paylaş</button></div>${destekHtml(t)}</div>
  </div></section>
  <div class="wrap"><div id="sekme-kap"></div></div>`;
  sekmeler($('#sekme-kap'), tabHtml);
  sayAc(); etkilesimler();
  $('#paylas').addEventListener('click', (ev) => paylasMenusu(ev.currentTarget, t.name, kisalt(t.description, 120)));
}).catch(hata);
