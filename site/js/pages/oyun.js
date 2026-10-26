import { yukle } from '../store.js';
import { kabukCiz, oyunKarti, ray, resim, kelimeKelime, DIS_IKON, alanAdi } from '../ui.js';
import { baslikYaz, bulunamadi, hata, etkilesimler, harita, takvimMenusu, dakikaOku, geriSayim, galeri } from '../detay.js';
import { kalpDugme, favMi } from '../fav.js';
import { paylasMenusu } from '../ozellik.js';
import { $, $$, esc, idFromPath, linkOf, tl, tarihUzun, saat, gunKisa, AYLAR, kisalt, baslangic } from '../util.js';

kabukCiz('kesfet');
const biletUrl = (e) => `/koltuk/${encodeURIComponent(e.docId || e.id)}`;
yukle().then(ciz).catch(hata);

const kalpB = (id) => `<button type="button" class="kalp-b ${favMi(id) ? 'on' : ''}" data-fav="${id}" aria-pressed="${favMi(id)}"><svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M12 20s-7.5-4.6-9.3-9.2C1.6 7.6 3.4 4.5 6.5 4.5c2 0 3.5 1.1 4.5 2.7h2c1-1.6 2.5-2.7 4.5-2.7 3.1 0 4.9 3.1 3.8 6.3C19.5 15.4 12 20 12 20Z"/></svg>Favori</button>`;

function ciz(d) {
  const s = d.showById.get(idFromPath());
  if (!s) return bulunamadi('Oyun');
  baslikYaz(s.name, s.description, s.imageUrl);
  try { const son = JSON.parse(localStorage.getItem('tiyatrol.son') || '[]').filter((x) => x !== s.id); localStorage.setItem('tiyatrol.son', JSON.stringify([s.id, ...son].slice(0, 12))); } catch {}
  const seanslar = s.upcoming;
  const st = { i: 0, ay: 'hepsi' };
  const alan = s.external ? alanAdi(s.externalTicketUrl) : '';
  const yer = s.next ? s.next.stage : d.stageById.get(s.sessions.at(-1)?.stageId) || null;

  // ---------- sağ panel: bilet ----------
  const panel = () => {
    const e = seanslar[st.i];
    const al = s.external
      ? `<div class="dis-banner"><b>${DIS_IKON}Biletler başka platformda</b><p>Bu oyunun biletleri <strong>${esc(alan || 'organizatörün sitesinde')}</strong> üzerinden satılır. TiyatRol seni doğru sayfaya götürür.</p><a class="btn btn-primary" target="_blank" rel="noopener sponsored" href="${esc(s.externalTicketUrl)}">Bileti ${esc(alan || 'organizatörden')} sitesinden al</a></div>`
      : (s.state === 'bitti' || !e ? '' : `<a class="btn btn-primary" href="${biletUrl(e)}">Bilet al${e.priceNum === 0 ? ' · Ücretsiz' : ''}</a>`);
    return `<div class="ticket"><div class="head"><span>TiyatRol</span><span>${s.state === 'bitti' ? 'Sezon bitti' : 'Seans bileti'}</span></div>
      <div class="body">
        ${e ? `<div class="fields"><div class="fld"><small>Tarih</small><b>${tarihUzun(e.when)}</b></div><div class="fld"><small>Saat</small><b>${saat(e.when)}</b></div>
          <div class="fld" style="grid-column:1/-1"><small>Sahne</small><b>${esc(e.stage?.name || e.stageId || '—')}</b></div>
          <div class="fld"><small>Fiyat</small><b>${e.priceNum ? tl(e.priceNum) : (e.priceNum === 0 ? 'Ücretsiz' : '—')}</b></div><div class="fld"><small>Süre</small><b>${esc(s.duration || '—')}</b></div></div>`
        : `<div class="fld"><small>Durum</small><b>${s.state === 'bitti' ? 'Sezon sona erdi' : (s.external ? 'Seans bilgisi organizatörde' : 'Seans açıklanmadı')}</b></div>`}
        <div class="perf"></div>
        ${s.external ? '' : al}
        ${e ? '<button class="btn btn-ghost" id="takvim" style="border-color:rgba(29,20,16,.3);color:var(--paper-ink)">Takvime ekle</button>' : ''}
        <div class="bars" aria-hidden="true"></div></div></div>${s.external ? al : ''}`;
  };

  // ---------- seanslar ----------
  const aylar = [...new Set(seanslar.map((e) => `${e.when.getFullYear()}-${e.when.getMonth()}`))];
  const seansHtml = () => {
    const liste = seanslar.map((e, i) => ({ e, i })).filter(({ e }) => st.ay === 'hepsi' || `${e.when.getFullYear()}-${e.when.getMonth()}` === st.ay);
    const satir = ({ e, i }) => `<div class="sess ${i === st.i ? 'on' : ''}" data-i="${i}" tabindex="0" role="button" aria-label="${tarihUzun(e.when)} ${saat(e.when)} seansını seç"><div class="d"><b>${e.when.getDate()}</b><small>${AYLAR[e.when.getMonth()].slice(0, 3)}</small></div>
      <div><b>${esc(e.stage?.name || e.stageId || 'Sahne belirtilmedi')}</b><br><span class="muted">${gunKisa(e.when)} · ${saat(e.when)}</span></div>
      <div class="pr"><b>${e.priceNum ? tl(e.priceNum) : e.priceNum === 0 ? 'Ücretsiz' : ''}</b></div>
      ${s.external ? `<span class="btn btn-sm ${i === st.i ? 'btn-primary' : 'btn-ghost'}">${i === st.i ? 'Seçili' : 'Seç'}</span>` : `<a class="btn btn-sm btn-primary" href="${biletUrl(e)}" aria-label="${tarihUzun(e.when)} ${saat(e.when)} seansı için bilet al">Bilet al</a>`}</div>`;
    const gecmis = s.sessions.filter((e) => e.when < new Date());
    return `${aylar.length > 1 ? `<div class="months"><button class="chip ${st.ay === 'hepsi' ? 'on' : ''}" data-ay="hepsi">Tümü</button>${aylar.map((a) => { const [y, m] = a.split('-'); return `<button class="chip ${st.ay === a ? 'on' : ''}" data-ay="${a}">${AYLAR[+m]} ${y}</button>`; }).join('')}</div>` : ''}
      <div class="sessions">${liste.map(satir).join('') || '<div class="empty">Yaklaşan seans yok.</div>'}</div>
      ${gecmis.length ? `<details style="margin-top:18px"><summary style="font-size:15px">Geçmiş seanslar (${gecmis.length})</summary><div class="sessions" style="margin-top:12px">${gecmis.map((e) => `<div class="sess past" style="cursor:default"><div class="d"><b>${e.when.getDate()}</b><small>${AYLAR[e.when.getMonth()].slice(0, 3)}</small></div><div><b>${esc(e.stage?.name || '')}</b><br><span class="muted">${saat(e.when)}</span></div><span class="tiny">Geçti</span></div>`).join('')}</div></details>` : ''}`;
  };

  // ---------- gövde bölümleri ----------
  const kadro = (l) => `<div class="cast">${l.map((p) => `<a href="${linkOf('oyuncu', p)}"><div class="arch">${p.imageUrl ? `<img src="${esc(p.imageUrl)}" alt="${esc(p.fullName)}" loading="lazy">` : esc(baslangic(p.fullName))}</div><b>${esc(p.fullName)}</b>${p.quote ? `<small>“${esc(kisalt(p.quote, 40))}”</small>` : ''}</a>`).join('')}</div>`;
  const skor = (x) => (x.cat === s.cat ? 3 : 0) + (s.teamId && x.teamId === s.teamId ? 3 : 0) + (x.iller.some((i) => s.iller.includes(i)) ? 2 : 0) + (x.ageLimit && x.ageLimit === s.ageLimit ? 1 : 0) + (x.cast.some((p) => s.cast.includes(p)) ? 2 : 0) + (x.state === 'aktif' ? 1 : 0);
  const benzer = d.shows.filter((x) => x.id !== s.id && x.state !== 'bitti' && skor(x) >= 3).sort((a, b) => skor(b) - skor(a)).slice(0, 10);
  const yil = (n) => '★'.repeat(n) + '☆'.repeat(5 - n);
  const yorumHtml = s.ratingCount ? `<div class="yorum-ozet"><div><div class="buyuk">${s.ratingAvg.toFixed(1)}</div><div class="yil">${yil(Math.round(s.ratingAvg))}</div><div class="tiny">${s.ratingCount} yorum</div></div>
      <div class="dag">${s.ratingDist.map((n, i) => `<div><span>${5 - i}</span><i><b style="width:${(n / s.ratingCount) * 100}%"></b></i><span>${n}</span></div>`).join('')}</div></div>
      ${s.reviews.slice(0, 8).map((r) => `<div class="yorum"><div><b>${esc(r.userName || 'Seyirci')}</b> <span class="yil">${yil(r.rating)}</span>${r.tarih ? ` <span class="tiny">· ${tarihUzun(r.tarih)}</span>` : ''}</div>${r.text ? `<p>${esc(r.text)}</p>` : ''}</div>`).join('')}
      <p class="tiny" style="margin-top:14px">Yorum yazmak için TiyatRol uygulamasını kullan.</p>` : `<div class="empty"><h3>Henüz yorum yok</h3><p>İlk yorumu TiyatRol uygulamasından yazabilirsin.</p></div>`;
  const bolumler = [
    { id: 'hikaye', ad: 'Hikâye', html: s.description ? `<p class="story">${esc(s.description)}</p>` : '' },
    { id: 'bilgi', ad: 'Bilmeniz gerekenler', html: (() => {
      const satir = [['Süre', s.duration], ['Ara', s.interval], ['Yaş önerisi', s.ageLimit && `${s.ageLimit}`], ['İçerik uyarısı', s.contentNotes], ['Tür', s.cat], ['Mekân', (yer && yer.name) || s.externalVenueName], ['Ulaşım', yer && yer.transit], ['Erişim', yer && yer.accessNotes], ['Bilet', s.external ? `${alan} üzerinden` : 'TiyatRol (site ve uygulama)']].filter(([, v]) => v);
      const ERIS = { AD: 'Sesli betimleme', CAP: 'Altyazılı', BSL: 'İşaret dili', R: 'Rahat gösterim', TS: 'İşaret dili' };
      const er = (s.accessKodlari || []).filter((k) => ERIS[k]);
      return satir.length > 2 ? `<div class="bilgi-kutu">${satir.map(([a, b]) => `<div><small>${a}</small><b>${esc(b)}</b></div>`).join('')}</div>${er.length ? `<p class="tiny" style="margin-top:12px">Erişilebilir performans: ${er.map((k) => `<span class="er-yan">${k} · ${ERIS[k]}</span>`).join(' ')}</p>` : ''}` : '';
    })() },
    { id: 'sss', ad: 'Sık sorulanlar', html: (() => {
      const q = [];
      if (s.duration) q.push([`${s.name} kaç dakika sürüyor?`, `Oyunun süresi ${s.duration}${s.interval ? `; ${s.interval}` : ''}.`]);
      if (s.ageLimit) q.push([`${s.name} için yaş sınırı var mı?`, `Önerilen yaş: ${s.ageLimit}.${s.contentNotes ? ` İçerik uyarısı: ${s.contentNotes}.` : ''}`]);
      if (yer && yer.name) q.push([`${s.name} nerede oynanıyor?`, `${yer.name}${yer.address ? `, ${yer.address}` : ''}.`]);
      if (s.next) q.push([`${s.name} bir sonraki seansı ne zaman?`, `${tarihUzun(s.next.when)} saat ${saat(s.next.when)}${s.next.stage ? `, ${s.next.stage.name}` : ''}.`]);
      q.push([`${s.name} biletini nereden alırım?`, s.external ? `Biletler ${alan || 'organizatörün sitesi'} üzerinden satılıyor; TiyatRol seni doğru sayfaya yönlendirir.` : 'Bu sayfada bir seans seçip Bilet al diyerek koltuğunu seçebilirsin; biletlerin hesabındaki Biletlerim sayfasında ve uygulamada görünür.']);
      window.__sss = q;
      return `<div>${q.map(([a, b]) => `<details><summary>${esc(a)}</summary><p>${esc(b)}</p></details>`).join('')}</div>`;
    })() },
    { id: 'seanslar', ad: 'Seanslar', html: seanslar.length || s.sessions.length ? `<div id="seans-kutu"></div>` : '' },
    { id: 'kadro', ad: 'Kadro', html: s.cast.length ? kadro(s.cast) : '' },
    { id: 'mekan', ad: 'Mekân', html: yer ? `<p style="margin-bottom:14px"><a href="${linkOf('sahne', yer)}"><b>${esc(yer.name)}</b></a><br><span class="muted">${esc(yer.address || '')}</span></p>${harita(yer.lat, yer.lng)}` : (s.externalVenueName ? `<p><b>${esc(s.externalVenueName)}</b><br><span class="muted">${esc(s.externalVenueAddress || '')}</span></p>${harita(s.externalLat, s.externalLng)}` : '') },
    { id: 'galeri', ad: 'Galeri', html: galeri(s.photos, s.name) },
    { id: 'yorumlar', ad: s.ratingCount ? `Yorumlar (${s.ratingCount})` : 'Yorumlar', html: yorumHtml },
    { id: 'eski', ad: 'Eski kadro', html: s.pastCast.length ? kadro(s.pastCast) : '' },
    { id: 'benzer', ad: 'Benzer oyunlar', html: benzer.length ? ray(benzer.map((x) => oyunKarti(x)).join('')) : '' },
  ].filter((b) => b.html);

  const chips = [s.cat, s.duration, s.ageLimit && `Yaş sınırı ${s.ageLimit}`, s.type].filter(Boolean).map((x) => `<span class="chip">${esc(x)}</span>`).join('');
  const n = s.next;
  const kirinti = `<a href="/">Vitrin</a> / <a href="/kesfet?tur=${encodeURIComponent(s.cat)}">${esc(s.cat)}</a>${s.team ? ` / <a href="${linkOf('topluluk', s.team)}">${esc(s.team.name)}</a>` : ''}`;

  $('#icerik').innerHTML = `
  <section class="op-hero" id="ust"><div class="op-bg">${s.imageUrl ? `<img src="${esc(s.imageUrl)}" alt="">` : ''}</div>
    <div class="wrap op-grid">
      <div class="op-poster">${resim(s.imageUrl, s.name)}${s.external ? `<span class="dis">${DIS_IKON}<span>Biletler ${esc(alan || 'başka platformda')}</span></span>` : ''}</div>
      <div class="op-info"><div class="crumbs">${kirinti}</div><h1>${kelimeKelime(s.name)}</h1>
        <div class="facts" style="margin-bottom:18px">${chips}${s.ratingCount ? `<a class="chip" href="#yorumlar"><span class="yildiz" style="margin:0">★ ${s.ratingAvg.toFixed(1)}</span> ${s.ratingCount} yorum</a>` : ''}</div>
        ${s.description ? `<p class="op-lead">${esc(kisalt(s.description, 210))}</p>` : ''}
        ${n ? `<div class="op-next"><div class="f"><small>Sıradaki seans</small><b>${tarihUzun(n.when)} · ${saat(n.when)}</b></div><div class="f"><small>Perdeye kalan</small><b class="sayac" id="sayac"></b></div>${(() => { const dk = dakikaOku(s.duration); if (!s.duration) return ''; const bt = new Date(n.when.getTime() + dk * 60000); return `<div class="f"><small>Tahmini bitiş</small><b>${saat(bt)}</b></div>`; })()}${n.stage ? `<div class="f"><small>Sahne</small><b>${esc(n.stage.name)}</b></div>` : ''}</div>` : ''}
        <div class="op-act">
          ${s.external ? `<a class="btn btn-primary" target="_blank" rel="noopener sponsored" href="${esc(s.externalTicketUrl)}">Bileti ${esc(alan || 'organizatörden')} al ${DIS_IKON.replace('<svg', '<svg width="16" height="16"')}</a>` : (n ? `<a class="btn btn-primary" href="${biletUrl(n)}">Bilet al</a>` : `<a class="btn btn-primary" href="#seanslar">Seansları gör</a>`)}
          ${n ? '<button class="btn btn-ghost" id="takvim2">Takvime ekle</button>' : ''}${kalpB(s.id)}<button class="btn btn-ghost" id="paylas">Paylaş</button><button class="btn btn-ghost" id="yazdir">Yazdır</button></div>
      </div></div></section>
  <div class="mini-bar" id="mini"><div class="wrap">${s.imageUrl ? `<img src="${esc(s.imageUrl)}" alt="">` : ''}<b>${esc(s.name)}</b>${s.external ? `<a class="btn btn-primary btn-sm" target="_blank" rel="noopener sponsored" href="${esc(s.externalTicketUrl)}">Bileti al</a>` : (n ? `<a class="btn btn-primary btn-sm" href="${biletUrl(n)}">Bilet al</a>` : `<a class="btn btn-primary btn-sm" href="#seanslar">Seanslar</a>`)}</div></div>
  <div class="wrap"><nav class="bar-nav" id="bnav" aria-label="Sayfa bölümleri">${bolumler.map((b) => `<a href="#${b.id}">${esc(b.ad)}</a>`).join('')}</nav>
  <div class="op-body"><div class="op-main">${bolumler.map((b) => `<section class="block" id="${b.id}"><h2>${esc(b.ad)}</h2>${b.html}</section>`).join('')}</div>
  <aside class="op-side" id="panel">${panel()}<a class="tiny" style="text-align:center" href="mailto:info@tiyatrol.com?subject=${encodeURIComponent('Hata bildir: ' + s.name)}&body=${encodeURIComponent(location.href)}">Bilgi hatalı mı? Bize bildir</a></aside></div></div>`;

  // ---------- canlı davranışlar ----------
  etkilesimler();
  if (n) geriSayim($('#sayac'), n.when.getTime());
  const takvimAc = (btn) => { const e = seanslar[st.i]; takvimMenusu(btn, { baslik: s.name, bas: e.when, dakika: dakikaOku(s.duration), yer: [e.stage?.name, e.stage?.address].filter(Boolean).join(', '), aciklama: kisalt(s.description, 300), url: location.href }); };
  const baglan = () => {
    $('#takvim')?.addEventListener('click', (ev) => takvimAc(ev.currentTarget));
  };
  const seansCiz = () => {
    const k = $('#seans-kutu'); if (!k) return;
    k.innerHTML = seansHtml();
    $$('[data-ay]', k).forEach((b) => b.addEventListener('click', () => { st.ay = b.dataset.ay; seansCiz(); }));
    $$('.sess[data-i]', k).forEach((r) => {
      const sec = () => { st.i = +r.dataset.i; seansCiz(); $('#panel').innerHTML = panel(); baglan(); };
      r.addEventListener('click', sec);
      r.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); sec(); } });
    });
  };
  seansCiz(); baglan();
  $('#takvim2')?.addEventListener('click', (ev) => takvimAc(ev.currentTarget));
  $('#paylas')?.addEventListener('click', (ev) => paylasMenusu(ev.currentTarget, s.name, kisalt(s.description, 120)));
  $('#yazdir')?.addEventListener('click', () => print());
  // üst çubuk: hero görünmezken
  const mini = $('#mini'), ust = $('#ust');
  new IntersectionObserver(([e]) => mini.classList.toggle('on', !e.isIntersecting), { rootMargin: '-80px 0px 0px 0px' }).observe(ust);
  // arka plan paralaksı
  const bg = $('.op-bg img');
  if (bg && !matchMedia('(prefers-reduced-motion: reduce)').matches) addEventListener('scroll', () => { if (scrollY < 900) bg.style.transform = `translateY(${scrollY * 0.18}px) scale(1.2)`; }, { passive: true });

  if (window.__sss && window.__sss.length) { const fq = document.createElement('script'); fq.type = 'application/ld+json';
    fq.textContent = JSON.stringify({ '@context': 'https://schema.org', '@type': 'FAQPage', mainEntity: window.__sss.map(([a, b]) => ({ '@type': 'Question', name: a, acceptedAnswer: { '@type': 'Answer', text: b } })) });
    document.head.append(fq); }
  { const bc = document.createElement('script'); bc.type = 'application/ld+json';
    bc.textContent = JSON.stringify({ '@context': 'https://schema.org', '@type': 'BreadcrumbList', itemListElement: [{ '@type': 'ListItem', position: 1, name: 'Vitrin', item: location.origin + '/' }, { '@type': 'ListItem', position: 2, name: s.cat, item: location.origin + '/kesfet?tur=' + encodeURIComponent(s.cat) }, { '@type': 'ListItem', position: 3, name: s.name }] });
    document.head.append(bc); }
  if (n) {
    const ld = document.createElement('script'); ld.type = 'application/ld+json';
    ld.textContent = JSON.stringify({ '@context': 'https://schema.org', '@type': 'TheaterEvent', name: s.name, description: kisalt(s.description, 300), image: s.imageUrl, startDate: n.when.toISOString(), location: { '@type': 'Place', name: n.stage?.name || '', address: n.stage?.address || '' }, offers: s.minPrice != null ? { '@type': 'Offer', price: s.minPrice, priceCurrency: 'TRY', url: s.externalTicketUrl || location.href } : undefined });
    document.head.append(ld);
  }
}
