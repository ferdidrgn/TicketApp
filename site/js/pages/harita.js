// Harita: sahneler ve harici mekânlar, yaklaşan oyunlarıyla. İl süzgeci, "Yakınımda" (50 km halka), liste ↔ harita eşleşmesi.
import '../theme.js';
import { yukle } from '../store.js';
import { kabukCiz, hataKutusu } from '../ui.js';
import { ilOku, ilYaz, enYakinIl, ILLER } from '../iller.js';
import { $, $$, esc, linkOf, tl, tarihUzun, saat, gunBasi, kisalt } from '../util.js';

kabukCiz('harita');
const kok = $('#harita');
const L = window.L;

const km = (a, b, c, d) => { const r = Math.PI / 180, x = (d - b) * r * Math.cos(((a + c) / 2) * r), y = (c - a) * r; return Math.sqrt(x * x + y * y) * 6371; };
const st = { zaman: '', tur: '', konum: null, aktif: null };

yukle().then(ciz).catch((e) => { kok.innerHTML = hataKutusu(e.message); });

function mekanlar(d) {
  const now = new Date(), m = new Map();
  const ekle = (id, ad, adres, lat, lng, il, ext) => { if (!m.has(id)) m.set(id, { id, ad, adres, lat, lng, il, ext, ogeler: [], sahne: null }); return m.get(id); };
  for (const g of d.stages) {
    if (g.lat == null || g.lng == null || !g.lat) continue;
    const v = ekle('s' + g.id, g.name, g.address, g.lat, g.lng, g.il, false); v.sahne = g;
    g.upcoming.forEach((e) => e.show && v.ogeler.push({ show: e.show, when: e.when, price: e.priceNum }));
  }
  for (const s of d.shows) {
    if ((s.state !== 'vitrin' && s.state !== 'aktif') || s.extLat == null || s.extLng == null || !s.extLat) continue;
    const id = 'x' + (s.externalVenueName || `${s.extLat},${s.extLng}`);
    const v = ekle(id, s.externalVenueName || 'Harici mekân', s.externalVenueAddress, s.extLat, s.extLng, s.extIl, true);
    if (!v.ogeler.some((o) => o.show === s && !o.when)) v.ogeler.push({ show: s, when: null, price: s.minPrice, dis: true });
  }
  return [...m.values()].filter((v) => v.ogeler.length);
}

function ciz(d) {
  const tum = mekanlar(d);
  const turler = d.kategoriler;
  kok.innerHTML = `<div class="hr-wrap">
    <aside class="hr-liste" id="hr-liste">
      <div class="hr-ust"><h1>Haritada oyunlar</h1><p class="muted" id="hr-sayi"></p>
        <div class="hr-filtre"><div class="chips" id="hr-zaman">${[['', 'Hepsi'], ['bugun', 'Bu akşam'], ['hafta', 'Bu hafta'], ['ay', 'Bu ay']].map(([k, a]) => `<button class="chip ${k === '' ? 'on' : ''}" data-z="${k}">${a}</button>`).join('')}</div>
          <select id="hr-tur" class="in-s" aria-label="Tür"><option value="">Tüm türler</option>${turler.map((t) => `<option>${esc(t)}</option>`).join('')}</select>
          <button class="btn btn-ghost btn-sm" id="hr-yakin">Yakınımda (50 km)</button></div></div>
      <div id="hr-kartlar"></div></aside>
    <div class="hr-harita"><div id="map" role="application" aria-label="Oyunların haritası"></div></div></div>`;
  if (!L) { $('#map').innerHTML = hataKutusu('Harita yüklenemedi.'); return; }

  const map = L.map('map', { zoomControl: true, scrollWheelZoom: true }).setView([39, 35], 6);
  L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 19, attribution: '© OpenStreetMap katkıda bulunanlar' }).addTo(map);
  const katman = L.layerGroup().addTo(map);
  let halka = null;
  const isaretler = new Map();

  const uygun = (v) => {
    const il = ilOku(); if (il && v.il !== il) return null;
    const now = new Date(), bas = gunBasi(now), bit = new Date(bas); bit.setDate(bit.getDate() + (st.zaman === 'bugun' ? 1 : st.zaman === 'hafta' ? 7 : 31));
    let o = v.ogeler.filter((x) => (!st.tur || x.show.cat === st.tur) && (!st.zaman || (x.when && x.when >= (st.zaman === 'bugun' ? now : bas) && x.when < bit)));
    if (!o.length) return null;
    o = o.slice().sort((a, b) => (a.when ?? 8.64e15) - (b.when ?? 8.64e15));
    return { ...v, ogeler: o, mesafe: st.konum ? km(st.konum.lat, st.konum.lng, v.lat, v.lng) : null };
  };

  const liste = () => {
    const il = ilOku();
    let l = tum.map(uygun).filter(Boolean);
    if (st.konum) l = l.filter((v) => v.mesafe <= 50).sort((a, b) => a.mesafe - b.mesafe);
    else l.sort((a, b) => (a.ogeler[0].when ?? 8.64e15) - (b.ogeler[0].when ?? 8.64e15));
    katman.clearLayers(); isaretler.clear();
    const kapsam = [];
    l.forEach((v) => {
      const ikon = L.divIcon({ className: 'pin-w', html: `<span class="pin ${v.ext ? 'dis' : ''}"><b>${v.ogeler.length}</b></span>`, iconSize: [38, 46], iconAnchor: [19, 44], popupAnchor: [0, -40] });
      const mk = L.marker([v.lat, v.lng], { icon: ikon }).addTo(katman);
      mk.bindPopup(popup(v), { maxWidth: 320, className: 'hr-popup' });
      mk.on('click', () => vurgula(v.id, false));
      isaretler.set(v.id, mk); kapsam.push([v.lat, v.lng]);
    });
    $('#hr-sayi').textContent = `${l.length} mekân · ${l.reduce((s, v) => s + v.ogeler.length, 0)} oyun/seans${il ? ` · ${il}` : ''}`;
    $('#hr-kartlar').innerHTML = l.map((v) => `<article class="hr-kart" data-id="${esc(v.id)}"><div class="hr-b"><h3>${esc(v.ad)}</h3>${v.mesafe != null ? `<span class="tag">${v.mesafe.toFixed(1)} km</span>` : (v.il ? `<span class="tag">${esc(v.il)}</span>` : '')}</div><p class="tiny">${esc(kisalt(v.adres, 70))}</p>
      <ul>${v.ogeler.slice(0, 3).map((o) => `<li><a href="${linkOf('oyun', o.show)}">${esc(o.show.name)}</a><span>${o.when ? `${tarihUzun(o.when).split(' ').slice(0, 2).join(' ')} · ${saat(o.when)}` : 'Bilet: başka platform'}</span></li>`).join('')}</ul>${v.ogeler.length > 3 ? `<p class="tiny">+${v.ogeler.length - 3} oyun daha</p>` : ''}</article>`).join('') || '<div class="empty"><h3>Bu süzgeçle mekân yok</h3><p>Süzgeçleri gevşet ya da ilini değiştir.</p></div>';
    $$('.hr-kart').forEach((k) => {
      k.addEventListener('mouseenter', () => isaretler.get(k.dataset.id)?._icon?.classList.add('vurgu'));
      k.addEventListener('mouseleave', () => isaretler.get(k.dataset.id)?._icon?.classList.remove('vurgu'));
      k.addEventListener('click', (e) => { if (e.target.closest('a')) return; vurgula(k.dataset.id, true); });
    });
    if (kapsam.length && !st.konum) map.fitBounds(kapsam, { padding: [50, 50], maxZoom: il ? 13 : 8 });
    else if (!kapsam.length && il) { const i = ILLER.find((x) => x.ad === il); if (i) map.setView([i.lat, i.lng], 10); }
  };
  const popup = (v) => `<div class="pop"><b>${esc(v.ad)}</b><div class="tiny">${esc(kisalt(v.adres, 80))}</div><ul>${v.ogeler.slice(0, 5).map((o) => `<li><a href="${linkOf('oyun', o.show)}">${esc(o.show.name)}</a><br><span>${o.when ? `${tarihUzun(o.when)} · ${saat(o.when)}` : 'Bilet: başka platform'}${o.price ? ` · ${tl(o.price)}` : ''}</span></li>`).join('')}</ul><a class="tiny" target="_blank" rel="noopener" href="https://www.google.com/maps/dir/?api=1&destination=${v.lat},${v.lng}">Yol tarifi ↗</a></div>`;
  const vurgula = (id, uc) => {
    $$('.hr-kart').forEach((k) => k.classList.toggle('on', k.dataset.id === id));
    const mk = isaretler.get(id); if (!mk) return;
    if (uc) { map.flyTo(mk.getLatLng(), Math.max(map.getZoom(), 14), { duration: 0.8 }); setTimeout(() => mk.openPopup(), 700); }
    $('.hr-kart.on')?.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
  };

  $$('#hr-zaman .chip').forEach((b) => b.addEventListener('click', () => { st.zaman = b.dataset.z; $$('#hr-zaman .chip').forEach((c) => c.classList.toggle('on', c === b)); liste(); }));
  $('#hr-tur').addEventListener('change', (e) => { st.tur = e.target.value; liste(); });
  $('#hr-yakin').addEventListener('click', () => {
    if (st.konum) { st.konum = null; halka?.remove(); halka = null; $('#hr-yakin').classList.remove('btn-primary'); liste(); return; }
    if (!navigator.geolocation) return alert('Tarayıcın konum özelliğini desteklemiyor.');
    $('#hr-yakin').textContent = 'Konum alınıyor…';
    navigator.geolocation.getCurrentPosition((p) => {
      st.konum = { lat: p.coords.latitude, lng: p.coords.longitude };
      halka = L.circle([st.konum.lat, st.konum.lng], { radius: 50000, color: getComputedStyle(document.documentElement).getPropertyValue('--accent').trim() || '#c50337', weight: 2, fillOpacity: .06 }).addTo(map);
      L.circleMarker([st.konum.lat, st.konum.lng], { radius: 7, color: '#fff', weight: 2, fillColor: '#2563eb', fillOpacity: 1 }).addTo(map);
      map.fitBounds(halka.getBounds());
      const il = enYakinIl(st.konum.lat, st.konum.lng); if (il && !ilOku()) ilYaz(il.ad);
      $('#hr-yakin').textContent = 'Yakınımda: açık'; $('#hr-yakin').classList.add('btn-primary'); liste();
    }, () => { $('#hr-yakin').textContent = 'Yakınımda (50 km)'; alert('Konum izni verilmedi.'); }, { enableHighAccuracy: false, timeout: 9000 });
  });
  document.addEventListener('il-degisti', () => liste());
  liste();
  setTimeout(() => map.invalidateSize(), 300);
}
