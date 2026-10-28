// Canlı parçalar: doluluk göstergesi, "Bu akşam" şeridi. Yalnızca Event.seats'ten türetilen SAYILAR kullanılır
// (store.js › dolulukHesapla); kişisel veri yok. Veri yoksa (koltuk planı kurulmamış) hiçbir şey çizilmez.
import { esc, linkOf, tl, saat, tarihUzun, gunKisa, ayniGun } from './util.js';
import { resim, afis, DIS_IKON } from './ui.js';

/** Doluluk durumu: { sinif, etiket, kalan, oran } | null */
export function dolulukDurumu(e) {
  const d = e?.doluluk;
  if (!d) return null;
  if (d.kalan <= 0) return { sinif: 'tukendi', etiket: 'Tükendi', ...d };
  if (d.kalan <= 20 || d.oran >= 0.85) return { sinif: 'son', etiket: `Son ${d.kalan} bilet`, ...d };
  if (d.oran >= 0.6) return { sinif: 'hizli', etiket: 'Hızlı doluyor', ...d };
  return { sinif: 'rahat', etiket: 'Yer var', ...d };
}

/** Doluluk çubuğu (transform ile dolar). kucuk: yalnız çubuk + kısa etiket. */
export function dolulukHtml(e, { kucuk = false } = {}) {
  const x = dolulukDurumu(e);
  if (!x) return '';
  const yuzde = Math.round(x.oran * 100);
  return `<span class="dl dl-${x.sinif}${kucuk ? ' dl-k' : ''}" role="img" aria-label="Doluluk yüzde ${yuzde}, ${x.kalan} koltuk kaldı"><i class="dl-ray"><b style="--o:${x.oran.toFixed(3)}"></b></i><span class="dl-et">${esc(x.etiket)}${kucuk ? '' : ` <small>· ${yuzde}% dolu</small>`}</span></span>`;
}

/** "Son N bilet" kart rozeti için etiket (yalnız gerçekten azsa). */
export function sonBiletEtiketi(e) {
  const x = dolulukDurumu(e);
  return x && (x.sinif === 'son') ? x.etiket : '';
}

const kalanMetin = (ms) => {
  if (ms <= 0) return 'Başladı';
  const dk = Math.floor(ms / 6e4), sa = Math.floor(dk / 60);
  if (sa >= 24) return `${Math.floor(sa / 24)} gün ${sa % 24} sa kaldı`;
  return sa >= 1 ? `${sa} sa ${String(dk % 60).padStart(2, '0')} dk kaldı` : `${Math.max(1, dk)} dk kaldı`;
};

/** Vitrin şeridi: bugünkü seanslar; yoksa sıradaki en yakın perde. Veri yoksa ''. */
export function buAksamHtml(d, now = new Date()) {
  const bugun = d.events.filter((e) => e.show && e.show.state === 'aktif' && ayniGun(e.when, now) && e.when - now > -30 * 6e4)
    .sort((a, b) => a.when - b.when);
  let liste = bugun, baslik = 'Bu akşam sahnede', alt = 'Bugün perde açan seanslar; geri sayım seansa kalan süreyi gösterir.';
  if (!liste.length) {
    const sonraki = d.events.filter((e) => e.show && e.show.state === 'aktif' && e.when > now).sort((a, b) => a.when - b.when).slice(0, 4);
    if (!sonraki.length) return '';
    liste = sonraki; baslik = 'Sıradaki perdeler'; alt = 'Bugün seans yok; en yakın seanslar burada.';
  }
  const kart = (e) => {
    const s = e.show, ucretsiz = e.priceNum === 0;
    const fiyat = e.priceNum ? `${tl(e.priceNum)}` : ucretsiz ? 'Ücretsiz' : '';
    return `<article class="as-kart"><a class="as-pic" href="${linkOf('oyun', s)}" tabindex="-1" aria-hidden="true">${resim(afis(s), s.name)}</a>
      <div class="as-in"><div class="as-saat"><b>${saat(e.when)}</b><small>${ayniGun(e.when, now) ? 'Bugün' : `${tarihUzun(e.when)}`}</small></div>
        <h3><a href="${linkOf('oyun', s)}">${esc(s.name)}</a></h3>
        <p class="as-yer">${esc(e.stage?.name || s.cat)}${fiyat ? ` · ${fiyat}` : ''}</p>
        <p class="as-say" data-as="${e.when.getTime()}" aria-live="off">${kalanMetin(e.when - now)}</p>
        ${dolulukHtml(e)}
        ${s.external ? `<a class="btn btn-ghost btn-sm" target="_blank" rel="noopener sponsored" href="${esc(s.externalTicketUrl)}">Biletler dışarıda ${DIS_IKON.replace('<svg', '<svg width="14" height="14"')}</a>` : `<a class="btn btn-primary btn-sm" href="${linkOf('oyun', s)}">Seansı gör</a>`}</div></article>`;
  };
  return `<section class="sec aksam-sec" aria-label="${esc(baslik)}"><div class="sec-head"><div><h2>${esc(baslik)}${bugun.length ? '<span class="canli-nokta" aria-hidden="true"></span>' : ''}</h2><p>${esc(alt)}</p></div><a class="link-more" href="/takvim">Takvim →</a></div>
    <div class="as-serit">${liste.slice(0, 8).map(kart).join('')}</div></section>`;
}

/** Geri sayımları dakikada bir günceller (yalnız sayfa görünürken; kök DOM'dan çıkınca durur). */
export function buAksamBaglan(kok = document) {
  const ciz = () => {
    const l = kok.querySelectorAll('[data-as]');
    if (!l.length) { clearInterval(t); return; }
    if (document.hidden) return;
    const n = Date.now();
    l.forEach((el) => { const m = kalanMetin(+el.dataset.as - n); if (el.textContent !== m) el.textContent = m; });
  };
  const t = setInterval(ciz, 30000);
}

export { gunKisa };
