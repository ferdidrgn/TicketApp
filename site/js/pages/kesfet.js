import '../theme.js';
import { yukle } from '../store.js';
import { kabukCiz, oyunKarti, kisi, iskelet, hataKutusu, bolumBasligi } from '../ui.js';
import { $, $$, esc, linkOf, tl, gunBasi, ayniGun, kisalt } from '../util.js';
import { baslikYaz } from '../detay.js';
import { ilOku } from '../iller.js';

kabukCiz('kesfet');
baslikYaz('Tüm oyunlar', 'Tiyatro oyunlarını türe, tarihe ve bütçeye göre süz.');
const ic = $('#icerik');
const url = new URLSearchParams(location.search);
const st = { q: url.get('q') || '', tur: url.get('tur') || '', zaman: url.get('zaman') || '', siralama: 'tarih', gecmis: false };
ic.innerHTML = `<div class="cat-layout"><div></div><div class="grid">${iskelet(8)}</div></div>`;

yukle().then(ciz).catch((e) => { ic.innerHTML = hataKutusu(e.message); });

document.addEventListener('il-degisti', () => location.reload());

function ciz(d) {
  const il = ilOku();
  const ozel = ['sahneler', 'topluluklar', 'oyuncular'].includes(st.tur);
  ic.innerHTML = `<div class="cat-layout"><aside class="side">
    <div class="box"><h4>Ara</h4><input type="search" id="f-q" placeholder="Oyun adı…" value="${esc(st.q)}"></div>
    <div class="box"><h4>Ne arıyorsun?</h4>${[['', 'Oyunlar'], ['oyuncular', 'Oyuncular'], ['sahneler', 'Sahneler'], ['topluluklar', 'Topluluklar']].map(([k, a]) => `<label><input type="radio" name="f-t" value="${k}" ${(ozel ? st.tur === k : k === '') ? 'checked' : ''}>${a}</label>`).join('')}</div>
    <div class="box" id="b-tur"><h4>Tür</h4><label><input type="radio" name="f-c" value="" ${!st.tur || ozel ? 'checked' : ''}>Tümü</label>${d.kategoriler.map((k) => `<label><input type="radio" name="f-c" value="${esc(k)}" ${st.tur === k ? 'checked' : ''}>${esc(k)}</label>`).join('')}</div>
    <div class="box" id="b-zaman"><h4>Zaman</h4>${[['', 'Hepsi'], ['bugun', 'Bu akşam'], ['yarin', 'Yarın'], ['hafta', 'Bu hafta'], ['haftasonu', 'Hafta sonu'], ['ay', 'Bu ay']].map(([k, a]) => `<label><input type="radio" name="f-z" value="${k}" ${st.zaman === k ? 'checked' : ''}>${a}</label>`).join('')}
      <label><input type="checkbox" id="f-g" ${st.gecmis ? 'checked' : ''}>Biten oyunları da göster</label></div>
    <div class="box"><h4>Daha fazla süzgeç</h4><label><input type="checkbox" id="f-a">Erişilebilir gösterim</label><label><input type="checkbox" id="f-c">Çocuklarla</label><label><input type="checkbox" id="f-u">Ücretsiz</label><label style="display:grid;gap:6px">En çok fiyat: <b id="f-fv">Sınırsız</b><input type="range" id="f-f" min="0" max="1500" step="50" value="1500" style="accent-color:var(--accent)"></label></div>
  </aside><section><div class="bar"><div id="sayi"></div><label class="muted">Sırala <select id="f-s" style="height:40px;border-radius:10px;border:1px solid var(--line);background:var(--surface);color:var(--ink);padding:0 10px"><option value="tarih">Yakın tarih</option><option value="fiyat">En düşük fiyat</option><option value="ad">A–Z</option></select></label></div><div id="sonuc"></div></section></div>`;

  const gor = () => {
    const now = new Date(), q = st.q.trim().toLocaleLowerCase('tr');
    const es = (a) => String(a || '').toLocaleLowerCase('tr').includes(q);
    const out = $('#sonuc'), say = $('#sayi');
    $('#b-tur').style.display = $('#b-zaman').style.display = st.tur === 'sahneler' || st.tur === 'topluluklar' || st.tur === 'oyuncular' ? 'none' : '';
    if (st.tur === 'oyuncular') { const l = d.players.filter((p) => !q || es(p.fullName)); say.innerHTML = `<b>${l.length}</b> oyuncu`; out.innerHTML = l.length ? `<div class="people" style="flex-wrap:wrap">${l.map(kisi).join('')}</div>` : '<div class="empty"><h3>Oyuncu bulunamadı</h3></div>'; return; }
    if (st.tur === 'sahneler') { const l = d.stages.filter((s) => (!il || s.il === il) && (!q || es(s.name) || es(s.address))); say.innerHTML = `<b>${l.length}</b> sahne`; out.innerHTML = `<div class="venues">${l.map((s) => `<a class="venue" href="${linkOf('sahne', s)}">${s.imageUrl ? `<img src="${esc(s.imageUrl)}" alt="" loading="lazy">` : ''}<div><h3>${esc(s.name)}</h3><small>${esc(kisalt(s.address, 60))}</small></div></a>`).join('')}</div>`; return; }
    if (st.tur === 'topluluklar') { const l = d.teams.filter((t) => !q || es(t.name)); say.innerHTML = `<b>${l.length}</b> topluluk`; out.innerHTML = `<div class="people" style="flex-wrap:wrap">${l.map((t) => `<a class="person" href="${linkOf('topluluk', t)}"><div class="flower">${t.imageUrl ? `<img src="${esc(t.imageUrl)}" alt="" loading="lazy">` : esc(t.name[0])}</div><b>${esc(t.name)}</b></a>`).join('')}</div>`; return; }
    let l = d.shows.filter((s) => (!il || s.iller.includes(il)) && (st.gecmis || s.state !== 'bitti') && (!q || es(s.name) || es(s.cat) || s.cast.some((p) => es(p.fullName))));
    if (st.tur) l = l.filter((s) => s.cat === st.tur);
    if (st.erisim) l = l.filter((s) => (s.accessKodlari || []).length);
    if (st.cocuk) l = l.filter((s) => /çocuk|masal/i.test(`${s.cat} ${s.type || ''} ${s.name}`) || /^[0-9]\s*\+?$/.test(String(s.ageLimit || '').trim()) && parseInt(s.ageLimit) <= 7);
    if (st.ucretsiz) l = l.filter((s) => s.minPrice === 0 || s.upcoming.some((e) => e.priceNum === 0));
    if (st.fiyat) l = l.filter((s) => s.minPrice == null || s.minPrice <= st.fiyat);
    if (st.zaman === 'yarin' || st.zaman === 'haftasonu') {
      const bas = gunBasi(now);
      const uyar = (e) => { const g = gunBasi(e.when); if (st.zaman === 'yarin') { const y = new Date(bas); y.setDate(y.getDate() + 1); return g.getTime() === y.getTime(); } const wd = e.when.getDay(); return e.when >= now && (wd === 0 || wd === 6 || (wd === 5 && e.when.getHours() >= 17)) && (e.when - bas) < 8 * 864e5; };
      l = l.filter((s) => s.upcoming.some(uyar));
    } else if (st.zaman) {
      const bas = gunBasi(now), bit = new Date(bas); bit.setDate(bit.getDate() + (st.zaman === 'bugun' ? 1 : st.zaman === 'hafta' ? 7 : 31));
      l = l.filter((s) => s.upcoming.some((e) => e.when >= (st.zaman === 'bugun' ? now : bas) && e.when < bit));
    }
    l.sort((a, b) => st.siralama === 'ad' ? a.name.localeCompare(b.name, 'tr')
      : st.siralama === 'fiyat' ? (a.minPrice ?? 1e9) - (b.minPrice ?? 1e9)
      : (a.next?.when ?? 8.64e15) - (b.next?.when ?? 8.64e15));
    say.innerHTML = `<b>${l.length}</b> oyun${il ? ` · ${esc(il)}` : ''}`;
    out.innerHTML = l.length ? `<div class="grid">${l.map((s) => oyunKarti(s)).join('')}</div>` : '<div class="empty"><h3>Sonuç yok</h3><p>Süzgeçleri gevşetmeyi dene.</p></div>';
  };
  const yaz = () => history.replaceState(null, '', `/kesfet?${new URLSearchParams(Object.entries({ q: st.q, tur: st.tur, zaman: st.zaman }).filter(([, v]) => v))}`);
  $('#f-q').addEventListener('input', (e) => { st.q = e.target.value; gor(); yaz(); });
  $$('[name=f-t]').forEach((r) => r.addEventListener('change', () => { st.tur = r.value; $$('[name=f-c]')[0].checked = true; gor(); yaz(); }));
  $$('[name=f-c]').forEach((r) => r.addEventListener('change', () => { st.tur = r.value; $$('[name=f-t]')[0].checked = true; gor(); yaz(); }));
  $$('[name=f-z]').forEach((r) => r.addEventListener('change', () => { st.zaman = r.value; gor(); yaz(); }));
  $('#f-g').addEventListener('change', (e) => { st.gecmis = e.target.checked; gor(); });
  $('#f-a').addEventListener('change', (e) => { st.erisim = e.target.checked; gor(); });
  $('#f-c').addEventListener('change', (e) => { st.cocuk = e.target.checked; gor(); });
  $('#f-u').addEventListener('change', (e) => { st.ucretsiz = e.target.checked; gor(); });
  $('#f-f').addEventListener('input', (e) => { const v = +e.target.value; st.fiyat = v >= 1500 ? 0 : v; $('#f-fv').textContent = v >= 1500 ? 'Sınırsız' : `${v} ₺`; gor(); });
  $('#f-s').addEventListener('change', (e) => { st.siralama = e.target.value; gor(); });
  gor();
}
