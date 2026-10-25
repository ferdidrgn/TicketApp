// Harita: mekânlar afiş küçük resimleriyle işaretlenir; yakın mekânlar afiş destesi olarak kümelenir.
// Süzgeçler (zaman, tür, kaynak), "bu alanda ara", Yakınımda 50 km, liste ↔ harita eşleşmesi, favori.
import '../theme.js';
import { yukle } from '../store.js';
import { kabukCiz, hataKutusu, DIS_IKON, alanAdi } from '../ui.js';
import { ilOku, ilYaz, enYakinIl, ILLER } from '../iller.js';
import { favMi, kalpDugme } from '../fav.js';
import { $, $$, esc, linkOf, tl, tarihUzun, saat, gunBasi, kisalt, baslangic } from '../util.js';

kabukCiz('harita');
const kok = $('#harita');
const L = window.L;
const az = matchMedia('(prefers-reduced-motion: reduce)').matches;

const km = (a, b, c, d) => { const r = Math.PI / 180, x = (d - b) * r * Math.cos(((a + c) / 2) * r), y = (c - a) * r; return Math.sqrt(x * x + y * y) * 6371; };
const st = { zaman: '', tur: '', kaynak: '', konum: null, alanda: true };

yukle().then(ciz).catch((e) => { kok.innerHTML = hataKutusu(e.message); });

function mekanlar(d) {
  const m = new Map();
  const ekle = (id, ad, adres, lat, lng, il, ext, sahne) => { if (!m.has(id)) m.set(id, { id, ad, adres, lat, lng, il, ext, ogeler: [], sahne }); return m.get(id); };
  for (const g of d.stages) {
    if (g.lat == null || g.lng == null || !g.lat) continue;
    const v = ekle('s' + g.id, g.name, g.address, g.lat, g.lng, g.il, false, g);
    g.upcoming.forEach((e) => e.show && v.ogeler.push({ show: e.show, when: e.when, price: e.priceNum }));
  }
  for (const s of d.shows) {
    if ((s.state !== 'vitrin' && s.state !== 'aktif') || s.extLat == null || s.extLng == null || !s.extLat) continue;
    const id = 'x' + (s.externalVenueName || `${s.extLat.toFixed(3)},${s.extLng.toFixed(3)}`);
    const v = ekle(id, s.externalVenueName || 'Harici mekân', s.externalVenueAddress, s.extLat, s.extLng, s.extIl, true, null);
    if (!v.ogeler.some((o) => o.show === s && !o.when)) v.ogeler.push({ show: s, when: null, price: s.minPrice, dis: true });
  }
  return [...m.values()].filter((v) => v.ogeler.length);
}

const afisler = (v, n = 3) => [...new Map(v.ogeler.map((o) => [o.show.id, o.show])).values()].filter((s) => s.imageUrl).slice(0, n);
const deste = (l) => `<div class="pm-stack">${l.map((s, i) => `<img src="${esc(s.imageUrl)}" alt="" style="--i:${i}" loading="lazy">`).join('') || '<span class="pm-bos"></span>'}</div>`;

function ciz(d) {
  const tum = mekanlar(d);
  const turler = d.kategoriler;
  kok.innerHTML = `<div class="hr-wrap">
    <aside class="hr-liste" id="hr-liste">
      <div class="hr-ust"><h1>Haritada oyunlar</h1><p class="muted" id="hr-sayi"></p>
        <div class="hr-filtre"><div class="chips" id="hr-zaman">${[['', 'Hepsi'], ['bugun', 'Bu akşam'], ['yarin', 'Yarın'], ['haftasonu', 'Hafta sonu'], ['hafta', 'Bu hafta'], ['ay', 'Bu ay']].map(([k, a]) => `<button class="chip ${k === '' ? 'on' : ''}" data-z="${k}">${a}</button>`).join('')}</div>
          <div class="hr-sat"><select id="hr-tur" class="in-s" aria-label="Tür"><option value="">Tüm türler</option>${turler.map((t) => `<option>${esc(t)}</option>`).join('')}</select>
            <select id="hr-kay" class="in-s" aria-label="Bilet kaynağı"><option value="">Tüm mekânlar</option><option value="sahne">Seanslı sahneler</option><option value="dis">Başka platformdakiler</option></select></div>
          <label class="hr-tik"><input type="checkbox" id="hr-alan" checked> Yalnızca harita alanındakileri listele</label>
          <div class="hr-sat"><button class="btn btn-ghost btn-sm" id="hr-yakin">Yakınımda (50 km)</button><button class="btn btn-ghost btn-sm" id="hr-rastgele">Beni şaşırt</button></div></div></div>
      <div id="hr-kartlar"></div></aside>
    <div class="hr-harita"><div id="map" role="application" aria-label="Oyunların haritası"></div>
      <div class="hr-lej"><span><i class="lj"></i>Seanslı sahne</span><span><i class="lj dis"></i>Biletler başka platformda</span></div></div></div>`;
  if (!L) { $('#map').innerHTML = hataKutusu('Harita yüklenemedi.'); return; }

  const map = L.map('map', { zoomControl: true, scrollWheelZoom: true, minZoom: 5 }).setView([39, 35], 6);
  L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 19, attribution: '© OpenStreetMap katkıda bulunanlar' }).addTo(map);
  const kume = L.markerClusterGroup({
    showCoverageOnHover: false, maxClusterRadius: 58, disableClusteringAtZoom: 12, spiderfyOnMaxZoom: true, animate: !az,
    iconCreateFunction: (c) => {
      const ch = c.getAllChildMarkers(); const vs = ch.map((m) => m.options.v);
      const posterler = [...new Map(vs.flatMap((v) => afisler(v, 3)).map((s) => [s.id, s])).values()].slice(0, 3);
      const topla = vs.reduce((t, v) => t + v.ogeler.length, 0);
      return L.divIcon({ className: 'pin-w', html: `<div class="pm pm-c">${deste(posterler)}<b class="pm-n">${topla}</b><i class="pm-tip"></i></div>`, iconSize: [60, 86], iconAnchor: [30, 84] });
    },
  });
  map.addLayer(kume);
  let halka = null, konumNokta = null, ilkFit = true;
  const isaret = new Map();

  const uygun = (v) => {
    const il = ilOku(); if (il && v.il !== il) return null;
    if (st.kaynak === 'sahne' && v.ext) return null;
    if (st.kaynak === 'dis' && !v.ext) return null;
    const now = new Date(), bas = gunBasi(now);
    const bit = new Date(bas); bit.setDate(bit.getDate() + (st.zaman === 'bugun' ? 1 : st.zaman === 'hafta' ? 7 : 31));
    const yarin = new Date(bas); yarin.setDate(yarin.getDate() + 1);
    const zamanOk = (e) => {
      if (!st.zaman) return true; if (!e) return false;
      if (st.zaman === 'yarin') return gunBasi(e).getTime() === yarin.getTime();
      if (st.zaman === 'haftasonu') { const wd = e.getDay(); return e >= now && (wd === 0 || wd === 6 || (wd === 5 && e.getHours() >= 17)) && (e - bas) < 8 * 864e5; }
      return e >= (st.zaman === 'bugun' ? now : bas) && e < bit;
    };
    let o = v.ogeler.filter((x) => (!st.tur || x.show.cat === st.tur) && zamanOk(x.when));
    if (!o.length) return null;
    o = o.slice().sort((a, b) => (a.when ?? 8.64e15) - (b.when ?? 8.64e15));
    return { ...v, ogeler: o, mesafe: st.konum ? km(st.konum.lat, st.konum.lng, v.lat, v.lng) : null };
  };

  const ikon = (v, i) => `<div class="pm ${v.ext ? 'dis' : ''}" style="animation-delay:${Math.min(i * 60, 600)}ms">${deste(afisler(v))}<b class="pm-n">${v.ogeler.length}</b>${v.ext ? `<span class="pm-dis">${DIS_IKON}</span>` : ''}<i class="pm-tip"></i></div>`;

  const popup = (v) => {
    const el = document.createElement('div'); el.className = 'pop';
    el.innerHTML = `<div class="pop-b"><b>${esc(v.ad)}</b>${v.il ? `<span class="tag">${esc(v.il)}</span>` : ''}</div><div class="tiny">${esc(kisalt(v.adres, 80))}${v.mesafe != null ? ` · ${v.mesafe.toFixed(1)} km` : ''}</div>
      <div class="pop-sc">${v.ogeler.slice(0, 8).map((o) => `<a class="pp" href="${linkOf('oyun', o.show)}"><div class="pp-i">${o.show.imageUrl ? `<img src="${esc(o.show.imageUrl)}" alt="" loading="lazy">` : ''}${o.dis ? `<span class="pp-d">↗</span>` : ''}</div><b>${esc(o.show.name)}</b><span>${o.when ? `${tarihUzun(o.when).split(' ').slice(0, 2).join(' ')} · ${saat(o.when)}` : esc(alanAdi(o.show.externalTicketUrl) || 'Başka platform')}</span>${o.price ? `<em>${tl(o.price)}</em>` : ''}</a>`).join('')}</div>
      <div class="pop-a"><a class="btn btn-primary btn-sm" target="_blank" rel="noopener" href="https://www.google.com/maps/dir/?api=1&destination=${v.lat},${v.lng}">Yol tarifi</a>${v.sahne ? `<a class="btn btn-ghost btn-sm" href="${linkOf('sahne', v.sahne)}">Sahne sayfası</a>` : ''}</div>`;
    return el;
  };

  const goster = (fit) => {
    const il = ilOku();
    let l = tum.map(uygun).filter(Boolean);
    if (st.konum) l = l.filter((v) => v.mesafe <= 50);
    // işaretler
    kume.clearLayers(); isaret.clear();
    const kapsam = [];
    l.forEach((v, i) => {
      const mk = L.marker([v.lat, v.lng], { v, icon: L.divIcon({ className: 'pin-w', html: ikon(v, i), iconSize: [56, 82], iconAnchor: [28, 80], popupAnchor: [0, -76] }) });
      mk.bindPopup(() => popup(v), { maxWidth: 360, minWidth: 260, className: 'hr-popup', autoPanPadding: [30, 30] });
      mk.on('click', () => vurgula(v.id, false));
      kume.addLayer(mk); isaret.set(v.id, mk); kapsam.push([v.lat, v.lng]);
    });
    if (fit) {
      if (kapsam.length) map.fitBounds(kapsam, { padding: [70, 70], maxZoom: il ? 13 : (kapsam.length > 1 ? (kapsam.length <= 8 ? 11 : 9) : 12), animate: !ilkFit && !az });
      else if (il) { const i = ILLER.find((x) => x.ad === il); if (i) map.setView([i.lat, i.lng], 10); }
      ilkFit = false;
    }
    liste(l);
  };

  const liste = (l = null) => {
    if (!l) l = tum.map(uygun).filter(Boolean).filter((v) => !st.konum || v.mesafe <= 50);
    const il = ilOku();
    let gor = l;
    if (st.alanda && !st.konum) { const b = map.getBounds(); gor = l.filter((v) => b.contains([v.lat, v.lng])); }
    gor = gor.slice().sort((a, b) => st.konum ? a.mesafe - b.mesafe : (a.ogeler[0].when ?? 8.64e15) - (b.ogeler[0].when ?? 8.64e15));
    const topOyun = new Set(gor.flatMap((v) => v.ogeler.map((o) => o.show.id))).size;
    $('#hr-sayi').textContent = `${gor.length} mekân · ${topOyun} oyun${il ? ` · ${il}` : ''}${st.alanda && gor.length < l.length ? ` (haritada ${l.length} mekân var)` : ''}`;
    $('#hr-kartlar').innerHTML = gor.map((v) => `<article class="hr-kart ${v.ext ? 'dis' : ''}" data-id="${esc(v.id)}"><div class="hr-k-i">${deste(afisler(v, 2))}</div><div class="hr-k-g"><div class="hr-b"><h3>${esc(v.ad)}</h3>${v.mesafe != null ? `<span class="tag">${v.mesafe.toFixed(1)} km</span>` : (v.il ? `<span class="tag">${esc(v.il)}</span>` : '')}</div><p class="tiny">${esc(kisalt(v.adres, 64))}</p>
      <ul>${v.ogeler.slice(0, 3).map((o) => `<li><a href="${linkOf('oyun', o.show)}">${esc(o.show.name)}</a><span>${o.when ? `${tarihUzun(o.when).split(' ').slice(0, 2).join(' ')} · ${saat(o.when)}` : 'Bilet: ' + esc(alanAdi(o.show.externalTicketUrl) || 'başka platform')}</span></li>`).join('')}</ul>${v.ogeler.length > 3 ? `<p class="tiny">+${v.ogeler.length - 3} oyun daha</p>` : ''}</div></article>`).join('')
      || `<div class="empty"><h3>Bu alanda oyun yok</h3><p>Haritayı kaydır, süzgeçleri gevşet ya da ilini değiştir.</p></div>`;
    $$('.hr-kart').forEach((k) => {
      k.addEventListener('mouseenter', () => isaret.get(k.dataset.id)?._icon?.classList.add('vurgu'));
      k.addEventListener('mouseleave', () => isaret.get(k.dataset.id)?._icon?.classList.remove('vurgu'));
      k.addEventListener('click', (e) => { if (e.target.closest('a')) return; vurgula(k.dataset.id, true); });
    });
  };

  const vurgula = (id, uc) => {
    $$('.hr-kart').forEach((k) => k.classList.toggle('on', k.dataset.id === id));
    const mk = isaret.get(id); if (!mk) return;
    if (uc) kume.zoomToShowLayer(mk, () => { map.flyTo(mk.getLatLng(), Math.max(map.getZoom(), 14), { duration: az ? 0 : 0.8 }); setTimeout(() => mk.openPopup(), az ? 0 : 750); });
    $('.hr-kart.on')?.scrollIntoView({ block: 'nearest', behavior: az ? 'auto' : 'smooth' });
  };

  $$('#hr-zaman .chip').forEach((b) => b.addEventListener('click', () => { st.zaman = b.dataset.z; $$('#hr-zaman .chip').forEach((c) => c.classList.toggle('on', c === b)); goster(true); }));
  $('#hr-tur').addEventListener('change', (e) => { st.tur = e.target.value; goster(true); });
  $('#hr-kay').addEventListener('change', (e) => { st.kaynak = e.target.value; goster(true); });
  $('#hr-alan').addEventListener('change', (e) => { st.alanda = e.target.checked; liste(); });
  let t; map.on('moveend', () => { clearTimeout(t); t = setTimeout(() => liste(), 180); });
  $('#hr-rastgele').addEventListener('click', () => {
    const l = [...isaret.keys()]; if (!l.length) return;
    vurgula(l[Math.floor(Math.random() * l.length)], true);
  });
  $('#hr-yakin').addEventListener('click', () => {
    if (st.konum) { st.konum = null; halka?.remove(); konumNokta?.remove(); halka = konumNokta = null; $('#hr-yakin').classList.remove('btn-primary'); $('#hr-yakin').textContent = 'Yakınımda (50 km)'; goster(true); return; }
    if (!navigator.geolocation) return alert('Tarayıcın konum özelliğini desteklemiyor.');
    $('#hr-yakin').textContent = 'Konum alınıyor…';
    navigator.geolocation.getCurrentPosition((p) => {
      st.konum = { lat: p.coords.latitude, lng: p.coords.longitude };
      halka = L.circle([st.konum.lat, st.konum.lng], { radius: 50000, color: getComputedStyle(document.documentElement).getPropertyValue('--accent').trim() || '#c50337', weight: 2, fillOpacity: .06 }).addTo(map);
      konumNokta = L.circleMarker([st.konum.lat, st.konum.lng], { radius: 7, color: '#fff', weight: 2, fillColor: '#2563eb', fillOpacity: 1 }).addTo(map);
      map.fitBounds(halka.getBounds());
      const il = enYakinIl(st.konum.lat, st.konum.lng); if (il && !ilOku()) ilYaz(il.ad);
      $('#hr-yakin').textContent = 'Yakınımda: açık'; $('#hr-yakin').classList.add('btn-primary'); goster(false);
    }, () => { $('#hr-yakin').textContent = 'Yakınımda (50 km)'; alert('Konum izni verilmedi.'); }, { timeout: 9000 });
  });
  document.addEventListener('il-degisti', () => goster(true));
  goster(true);
  setTimeout(() => map.invalidateSize(), 300);
}
