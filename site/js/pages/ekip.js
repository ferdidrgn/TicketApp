// /ekip — ekip yöneticisi paneli (admin DEĞİL). Yetki ve kapsam SUNUCUDA denetlenir (getMyManagedTeams / team* callable'ları);
// bu dosya yalnız arayüzdür ve admin modüllerini içe aktarmaz. Kişisel veri gösterilmez: yalnız sayılar ve bilet kodu.
import { kabukCiz } from '../ui.js';
import { girisGerekli, oturumDinle } from '../auth.js';
import { db, doc, getDoc, onSnapshot, fonksiyon } from '../firebase.js';
import { $, $$, esc } from '../util.js';

kabukCiz('');
const kok = $('#icerik');
const yaz = (h) => { kok.setAttribute('aria-busy', 'false'); kok.innerHTML = h; };
const cagir = async (ad, veri) => (await (await fonksiyon(ad))(veri)).data;
const uuid = () => (crypto.randomUUID ? crypto.randomUUID().replace(/-/g, '') : `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 12)}`);
const IKON = { baslamak_uzere: '⏰', basladi: '🤫', ara: '☕', ara_bitiyor: '🔔', bitti: '👏', ertelendi: '📅', iptal: '⛔', genel: '📣' };
const SAAT = 3600e3;
const saatYaz = (ms) => new Date(ms).toLocaleString('tr-TR', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' });
const gorece = (ms) => {
  const d = Math.round((ms - Date.now()) / 60000), a = Math.abs(d);
  const t = a < 90 ? `${a} dk` : a < 48 * 60 ? `${Math.round(a / 60)} sa` : `${Math.round(a / 1440)} gün`;
  return d >= 0 ? `${t} sonra` : `${t} önce`;
};
const hata = (e) => {
  if (e?.details?.code === 'ACCOUNT_DELETION_PENDING' || /ACCOUNT_DELETION_PENDING/.test(e?.message || '')) return 'Hesabın silinme sürecinde; bu süreçte ekip paneli kullanılamaz. Ayarlar sayfasından vazgeçebilirsin.';
  const k = String(e?.code || '');
  if (k.includes('permission-denied')) return e.message && !/^permission-denied/.test(e.message) ? e.message : 'Bu işlem için yetkin yok.';
  if (k.includes('unauthenticated')) return 'Oturum süresi doldu. Tekrar giriş yap.';
  if (k.includes('resource-exhausted') || k.includes('failed-precondition') || k.includes('invalid-argument') || k.includes('not-found')) return e.message;
  return 'Bir hata oluştu. Bağlantını kontrol edip tekrar dene.';
};

const st = { veri: null, ti: 0, showId: '', eventId: '', sekme: 'bildirim', kitle: null, ara: 15, stats: null, kapiSon: [], kullanici: null };

// ---------------------------------------------------------------- ekranlar
function giris() {
  yaz(`<section class="ek-sayfa"><h1>Ekip paneli</h1><div class="empty"><h3>Devam etmek için giriş yap</h3>
    <p>Bu sayfa yalnızca ekip yöneticilerine açıktır.</p><p style="margin-top:16px"><button type="button" class="btn btn-primary" id="giris">Giriş yap</button></p></div></section>`);
  $('#giris').addEventListener('click', () => girisGerekli('Ekip paneline girmek için giriş yap.'));
}
function yetkisiz(mesaj) {
  yaz(`<section class="ek-sayfa"><h1>Yetkin yok</h1><div class="ek-kart"><p>${esc(mesaj || 'Bu hesap herhangi bir topluluğun ekip yöneticisi olarak atanmamış.')}</p>
    <p class="ek-muted">Yetki, TiyatRol yönetimi tarafından e-posta adresine göre verilir. Yetki verildiyse çıkış yapıp tekrar giriş yapmayı dene.</p>
    <div><a class="btn btn-ghost" href="/vitrin">Siteye dön</a></div></div></section>`);
}

const ekip = () => st.veri.teams[st.ti];
const oyun = () => ekip().shows.find((s) => s.showId === st.showId);
const seans = () => (oyun()?.events || []).find((e) => e.eventId === st.eventId);

function seansSec() {
  const e = ekip();
  if (!e.shows.some((s) => s.showId === st.showId)) st.showId = (e.shows[0] || {}).showId || '';
  const evs = oyun()?.events || [];
  if (!evs.some((x) => x.eventId === st.eventId)) {
    const yakin = evs.slice().sort((a, b) => Math.abs(a.ms - Date.now()) - Math.abs(b.ms - Date.now()))[0];
    st.eventId = yakin ? yakin.eventId : '';
  }
}

function iskelet() {
  const v = st.veri;
  yaz(`<section class="ek-sayfa"><h1>Ekip paneli</h1>
    <div class="ek-kart"><div class="ek-sec">
      ${v.teams.length > 1 ? `<div class="ek-alan"><label for="ek-ekip">Topluluk</label><select id="ek-ekip">${v.teams.map((t, i) => `<option value="${i}" ${i === st.ti ? 'selected' : ''}>${esc(t.name)}</option>`).join('')}</select></div>` : `<div class="ek-alan"><label>Topluluk</label><b>${esc(ekip().name)}</b></div>`}
      <div class="ek-alan"><label for="ek-oyun">Oyun</label><select id="ek-oyun">${ekip().shows.map((s) => `<option value="${esc(s.showId)}" ${s.showId === st.showId ? 'selected' : ''}>${esc(s.name)}</option>`).join('') || '<option value="">Oyun yok</option>'}</select></div>
      <div class="ek-alan"><label for="ek-seans">Seans</label><select id="ek-seans">${(oyun()?.events || []).map((x) => `<option value="${esc(x.eventId)}" ${x.eventId === st.eventId ? 'selected' : ''}>${esc(saatYaz(x.ms))}${x.stage ? ` · ${esc(x.stage)}` : ''}</option>`).join('') || '<option value="">Yaklaşan seans yok</option>'}</select></div>
    </div><div id="ek-doluluk"></div></div>
    <div class="ek-sekmeler" role="tablist" aria-label="Ekip paneli bölümleri">
      ${[['bildirim', 'Bildirim'], ['kapi', 'Kapı'], ['koltuk', 'Koltuklar'], ['yorum', 'Yorumlar'], ['soru', 'Sorular'], ['ozet', 'Özet']].map(([k, a]) => `<button type="button" role="tab" class="ek-sekme" id="tab-${k}" aria-selected="${st.sekme === k}" data-s="${k}">${a}</button>`).join('')}</div>
    <div id="ek-govde" role="tabpanel" aria-live="polite"></div></section>`);
  $('#ek-ekip')?.addEventListener('change', (ev) => { st.ti = +ev.target.value; st.showId = ''; st.eventId = ''; seansSec(); st.kitle = null; iskelet(); });
  $('#ek-oyun').addEventListener('change', (ev) => { st.showId = ev.target.value; st.eventId = ''; seansSec(); st.kitle = null; iskelet(); });
  $('#ek-seans').addEventListener('change', (ev) => { st.eventId = ev.target.value; st.kitle = null; doluluk(); sekmeCiz(); });
  $$('.ek-sekme').forEach((b) => b.addEventListener('click', () => { st.sekme = b.dataset.s; $$('.ek-sekme').forEach((x) => x.setAttribute('aria-selected', x === b)); sekmeCiz(); }));
  doluluk(); sekmeCiz();
}

function doluluk() {
  const k = $('#ek-doluluk'), e = seans();
  if (!e) { k.innerHTML = '<p class="ek-muted">Bu oyun için yaklaşan seans yok.</p>'; return; }
  const yuzde = e.total ? Math.round((e.sold / e.total) * 100) : 0;
  k.innerHTML = `<div class="ek-ozet"><div><b>${e.sold}</b><span>Satılan koltuk</span></div><div><b>${e.held}</b><span>Tutulan</span></div><div><b>${e.total}</b><span>Toplam</span></div><div><b>%${yuzde}</b><span>Doluluk</span></div></div>
    <div class="ek-bar" role="progressbar" aria-label="Doluluk" aria-valuemin="0" aria-valuemax="100" aria-valuenow="${yuzde}"><i style="width:${yuzde}%"></i></div>
    <p class="ek-muted">${esc(saatYaz(e.ms))} · ${esc(gorece(e.ms))}</p>`;
}

function sekmeCiz() {
  if (st.sekme !== 'koltuk') koltukAboneKapat();
  if (st.sekme === 'kapi') return kapi();
  if (st.sekme === 'ozet') return ozet();
  if (st.sekme === 'yorum') return yorumlar();
  if (st.sekme === 'soru') return sorular();
  if (st.sekme === 'koltuk') return koltuklar();
  return bildirim();
}

// ---------------------------------------------------------------- yorumlar (gizle / geri aç; silme yok; kapsam sunucuda)
async function yorumlar() {
  const g = $('#ek-govde');
  if (!st.showId) { g.innerHTML = '<div class="ek-kart"><p class="ek-muted">Bir oyun seç.</p></div>'; return; }
  g.innerHTML = '<div class="skel" style="height:120px"></div>';
  let r;
  try { r = await cagir('teamReviews', { showId: st.showId }); } catch (er) { g.innerHTML = `<div class="ek-hata" role="alert">${esc(hata(er))}</div>`; return; }
  const dur = { pending: 'Bekliyor', hidden: 'Gizli', published: 'Yayında' };
  g.innerHTML = `<div class="ek-kart"><h2>Yorumlar</h2><p class="ek-muted">Kurallara aykırı yorumları gizleyebilir, yanlışlıkla gizlenenleri geri açabilirsin. Silme yalnız yönetici tarafından yapılır. <a href="/topluluk-kurallari">Topluluk kuralları</a></p>
    ${r.items.length ? r.items.map((x) => `<div class="yorum" data-id="${esc(x.id)}"><div><b>${esc(x.userName)}</b> · ${'★'.repeat(x.rating || 0)} · ${esc(dur[x.status] || (x.hidden ? 'Gizli' : 'Yayında'))} · şikâyet: ${x.reportCount}</div><p>${esc(x.text || '(metin yok)')}</p>
      <button type="button" class="btn btn-ghost btn-sm" data-a="${x.hidden ? 'restore' : 'hide'}">${x.hidden ? 'Geri aç' : 'Gizle'}</button></div>`).join('') : '<p class="ek-muted">Bu oyunda henüz yorum yok.</p>'}</div>`;
  $$('[data-a]', g).forEach((b) => b.addEventListener('click', async () => {
    const sebep = prompt('Sebep (zorunlu, 3-200 karakter):'); if (!sebep) return;
    b.disabled = true;
    try { await cagir('teamModerate', { reviewId: b.closest('[data-id]').dataset.id, action: b.dataset.a, reason: sebep }); yorumlar(); } catch (er) { b.disabled = false; alert(hata(er)); }
  }));
}

// ---------------------------------------------------------------- sorular (Q-2: yanıtla = yayınla / reddet / gizle; kapsam sunucuda)
async function sorular() {
  const g = $('#ek-govde');
  if (!st.showId) { g.innerHTML = '<div class="ek-kart"><p class="ek-muted">Bir oyun seç.</p></div>'; return; }
  g.innerHTML = '<div class="skel" style="height:120px"></div>';
  let r;
  try { r = await cagir('teamQuestions', { showId: st.showId }); } catch (er) { g.innerHTML = `<div class="ek-hata" role="alert">${esc(hata(er))}</div>`; return; }
  const dur = { pending: 'Onay bekliyor', answered: 'Yayında', hidden: 'Gizli', rejected: 'Reddedildi' };
  g.innerHTML = `<div class="ek-kart"><h2>Seyirci soruları</h2><p class="ek-muted">Soru, sen yanıtlayınca herkese görünür olur. Uygunsuz soruyu reddedebilir, yayındakini gizleyebilirsin. Cevapta bağlantı yazılamaz.</p>
    ${r.items.length ? r.items.map((x) => `<div class="yorum" data-id="${esc(x.id)}"><div><b>${esc(x.askerName)}</b> · ${esc(dur[x.status] || x.status)} · şikâyet: ${x.reportCount}</div><p>${esc(x.text)}</p>
      ${x.answer ? `<p class="ek-muted">Cevap: ${esc(x.answer)}</p>` : ''}
      ${x.status === 'pending' || x.status === 'answered' ? `<textarea data-cevap rows="2" maxlength="600" placeholder="Cevabın" aria-label="Cevap">${esc(x.answer || '')}</textarea><button type="button" class="btn btn-primary btn-sm" data-a="answer">${x.status === 'answered' ? 'Cevabı güncelle' : 'Yanıtla ve yayınla'}</button> ` : ''}
      ${x.status === 'pending' ? '<button type="button" class="btn btn-ghost btn-sm" data-a="reject">Reddet</button>' : ''}
      ${x.status === 'answered' ? '<button type="button" class="btn btn-ghost btn-sm" data-a="hide">Gizle</button>' : ''}
      ${x.status === 'hidden' ? '<button type="button" class="btn btn-ghost btn-sm" data-a="restore">Geri aç</button>' : ''}</div>`).join('') : '<p class="ek-muted">Bu oyunda henüz soru yok.</p>'}</div>`;
  $$('[data-a]', g).forEach((b) => b.addEventListener('click', async () => {
    const kutu = b.closest('[data-id]'), id = kutu.dataset.id, a = b.dataset.a;
    let istek, ad;
    if (a === 'answer') { ad = 'answerQuestion'; istek = { id, answer: $('[data-cevap]', kutu).value }; }
    else {
      const sebep = prompt('Sebep (zorunlu, 3-200 karakter):'); if (!sebep) return;
      ad = a === 'reject' ? 'rejectQuestion' : 'hideQuestion'; istek = a === 'restore' ? { id, reason: sebep, restore: true } : { id, reason: sebep };
    }
    b.disabled = true;
    try { await cagir(ad, istek); sorular(); } catch (er) { b.disabled = false; alert(hata(er)); }
  }));
}

// ---------------------------------------------------------------- bildirim
async function bildirim() {
  const g = $('#ek-govde'), e = seans();
  if (!e) { g.innerHTML = '<div class="ek-kart"><p class="ek-muted">Bildirim göndermek için bir seans seç.</p></div>'; return; }
  g.innerHTML = '<div class="skel" style="height:140px"></div>';
  try { st.kitle = await cagir('teamNotifyPreview', { target: { type: 'event', id: e.eventId } }); } catch (er) { g.innerHTML = `<div class="ek-hata" role="alert">${esc(hata(er))}</div>`; return; }
  if (st.eventId !== e.eventId) return; // seans arada değişti
  const k = st.kitle, q = k.quota || {};
  const yakin = Math.abs(e.ms - Date.now()) <= 24 * SAAT;
  const tp = (id) => k.templates.find((t) => t.id === id);
  const d = [];
  const ekle = (id, etiket, params) => { const t = tp(id); if (t) d.push({ id, etiket, params, kind: t.kind, timed: t.timed, custom: t.custom }); };
  ekle('baslamak_uzere', 'Oyun 10 dk sonra başlıyor', { dk: 10 });
  ekle('baslamak_uzere', 'Oyun 5 dk sonra başlıyor', { dk: 5 });
  ekle('basladi', 'Oyun başladı — telefonları sessize alın');
  ekle('ara', `Birinci perde bitti — ${st.ara} dk ara`, { dk: st.ara });
  ekle('ara_bitiyor', 'Ara bitiyor — 5 dk içinde yerlerimize');
  ekle('bitti', 'Oyun bitti — teşekkürler');
  ekle('ertelendi', 'Seans ertelendi…');
  ekle('iptal', 'Seans iptal edildi…');
  const kalan = Math.min(q.hourLeft ?? 99, q.dayLeft ?? 99, q.targetLeft ?? 99);
  g.innerHTML = `<div class="ek-kart"><h2>Sahne kumandası</h2>
      <p class="ek-muted"><b>${k.recipients}</b> bilet sahibine ulaşılır (${k.withToken} kişi push alabilir; diğerleri uygulama içi kutuda görür). Kişi bilgileri gösterilmez.</p>
      ${k.recipients === 0 ? '<div class="ek-uyari" role="status">Bu seansta bildirim alacak aktif bilet sahibi yok.</div>' : ''}
      ${kalan <= 2 ? `<div class="ek-uyari" role="status">Gönderim hakkın azalıyor: bu seansa ${q.targetLeft} / saatlik ${q.hourLeft} / günlük ${q.dayLeft} hakkın kaldı.</div>` : `<p class="ek-muted">Kalan hak: bu seansa ${q.targetLeft}, saatte ${q.hourLeft}, günde ${q.dayLeft}.</p>`}
      ${yakin ? '' : '<div class="ek-uyari" role="status">Bu seans ±24 saat dışında: sahne şablonları (başladı, ara, bitti…) kapalı; duyuru gönderebilirsin.</div>'}
      <div class="ek-alan" style="max-width:200px"><label for="ek-ara">Ara süresi (dk)</label><input id="ek-ara" type="number" min="5" max="30" step="1" value="${st.ara}" inputmode="numeric"></div>
      <div class="ek-grid">${d.map((x, i) => `<button type="button" class="ek-btn ${x.kind === 'alarm' ? 'alarm' : ''}" data-i="${i}" ${(x.timed && !yakin) || k.recipients === 0 ? 'disabled' : ''}><span aria-hidden="true">${IKON[x.id] || '📣'}</span><span>${esc(x.etiket)}${x.kind === 'alarm' ? '<small>Alarm bildirimi</small>' : ''}</span></button>`).join('')}</div></div>
    <div class="ek-kart"><h2>Kısa mesaj</h2>
      <div class="ek-alan"><label for="ek-baslik">Başlık <span class="ek-muted" id="ek-bc">0/60</span></label><input id="ek-baslik" type="text" maxlength="60" autocomplete="off"></div>
      <div class="ek-alan"><label for="ek-govde-m">Mesaj <span class="ek-muted" id="ek-gc">0/240</span></label><textarea id="ek-govde-m" maxlength="240"></textarea>
        <span class="ek-muted">{oyun} ve {sahne} yazarsan seansın bilgisiyle dolar. Bağlantı, telefon numarası ve e-posta yazılamaz; serbest mesaj alarm olarak gitmez.</span></div>
      <div class="ek-act"><button type="button" class="btn btn-primary" id="ek-gonder" ${k.recipients === 0 ? 'disabled' : ''}>Önizle ve gönder</button></div></div>`;
  $('#ek-ara').addEventListener('change', (ev) => { st.ara = Math.min(30, Math.max(5, Math.round(Number(ev.target.value)) || 15)); bildirim(); });
  $$('.ek-btn', g).forEach((b) => b.addEventListener('click', () => {
    const x = d[+b.dataset.i];
    onay({ target: { type: 'event', id: e.eventId }, template: x.id, params: x.params }, x.custom);
  }));
  const say = () => { $('#ek-bc').textContent = `${$('#ek-baslik').value.length}/60`; $('#ek-gc').textContent = `${$('#ek-govde-m').value.length}/240`; };
  $('#ek-baslik').addEventListener('input', say); $('#ek-govde-m').addEventListener('input', say);
  $('#ek-gonder').addEventListener('click', () => {
    const t = $('#ek-baslik').value.trim(), m = $('#ek-govde-m').value.trim();
    if (!t || !m) return uyar('Başlık ve mesaj gerekli.');
    onay({ target: { type: 'event', id: e.eventId }, template: 'genel', title: t, body: m }, false);
  });
}
function uyar(m) { const g = $('#ek-govde'); let u = $('#ek-uy'); if (!u) { u = document.createElement('div'); u.id = 'ek-uy'; u.className = 'ek-hata'; u.setAttribute('role', 'alert'); g.prepend(u); } u.textContent = m; }

async function onay(istek, duzenle) {
  const onceki = document.activeElement;
  const bg = document.createElement('div'); bg.className = 'ek-modal-bg';
  bg.innerHTML = '<div class="ek-modal" role="dialog" aria-modal="true" aria-labelledby="ek-mb"><h2 id="ek-mb">Önizleme hazırlanıyor…</h2><div class="skel" style="height:120px"></div></div>';
  document.body.append(bg);
  const modal = bg.firstElementChild;
  const tus = (ev) => { if (ev.key === 'Escape') kapat(); };
  const kapat = () => { document.removeEventListener('keydown', tus, true); bg.remove(); onceki?.focus?.(); };
  document.addEventListener('keydown', tus, true);
  bg.addEventListener('mousedown', (ev) => { if (ev.target === bg) kapat(); });
  const requestId = uuid();
  let r;
  if (duzenle) { // ertelendi / iptal: metni yönetici yazar; önce yazım penceresi
    modal.innerHTML = `<h2 id="ek-mb">${esc(istek.template === 'iptal' ? 'Seans iptal mesajı' : 'Seans erteleme mesajı')}</h2>
      <div class="ek-alan"><label for="ek-mm">Mesaj (en fazla 240 karakter)</label><textarea id="ek-mm" maxlength="240" placeholder="Örn. Yeni tarih 12 Kasım 20:00"></textarea></div>
      <div class="ek-act"><button type="button" class="btn btn-ghost" id="ek-v">Vazgeç</button><button type="button" class="btn btn-primary" id="ek-d">Devam</button></div>`;
    $('#ek-v', modal).addEventListener('click', kapat);
    await new Promise((coz) => $('#ek-d', modal).addEventListener('click', () => { const m = $('#ek-mm', modal).value.trim(); if (m) { istek = { ...istek, body: m }; coz(); } }));
  }
  try { r = await cagir('teamNotifyPreview', istek); } catch (er) { modal.innerHTML = `<h2>Gönderilemez</h2><div class="ek-hata" role="alert">${esc(hata(er))}</div><div class="ek-act"><button type="button" class="btn btn-ghost" id="ek-k">Kapat</button></div>`; $('#ek-k', modal).addEventListener('click', kapat); return; }
  if (r.blocked) { modal.innerHTML = `<h2>Gönderilemez</h2><div class="ek-hata" role="alert">${esc(r.blocked)}</div><div class="ek-act"><button type="button" class="btn btn-ghost" id="ek-k">Kapat</button></div>`; $('#ek-k', modal).addEventListener('click', kapat); return; }
  const p = r.preview;
  modal.innerHTML = `<h2 id="ek-mb">Göndermeden önce kontrol et</h2>
    <div class="ek-onizle ${p.kind === 'alarm' ? 'alarm' : ''}" aria-label="Bildirim önizlemesi"><small>TiyatRol${p.kind === 'alarm' ? ' · ALARM' : ''}</small><b>${esc(p.title)}</b><span>${esc(p.body)}</span></div>
    <p class="ek-muted"><b>${esc(r.target.label)}</b> · ${r.recipients} kişi · ${r.withToken} push alabilir</p>
    ${p.kind === 'alarm' ? '<p class="ek-muted">Alarm bildirimi yüksek öncelikle gider; telefon sessizdeyse sesli olması alıcının iznine bağlıdır.</p>' : ''}
    <div id="ek-s" aria-live="polite"></div>
    <div class="ek-act"><button type="button" class="btn btn-ghost" id="ek-v">Vazgeç</button><button type="button" class="btn btn-primary btn-lg" id="ek-g">Gönder (${r.recipients} kişi)</button></div>`;
  $('#ek-v', modal).addEventListener('click', kapat);
  const g = $('#ek-g', modal); g.focus();
  g.addEventListener('click', async () => {
    g.disabled = true; g.textContent = 'Gönderiliyor…';
    try {
      const s = await cagir('teamSendNotification', { ...istek, confirm: true, requestId });
      $('#ek-s', modal).innerHTML = `<div class="ek-sonuc ok"><b>${s.duplicate ? 'ZATEN GÖNDERİLMİŞ' : 'GÖNDERİLDİ'}</b><span>${s.recipients} alıcı · push: ${s.success} başarılı${s.failure ? `, ${s.failure} başarısız` : ''}</span></div>`;
      g.remove(); $('#ek-v', modal).textContent = 'Kapat';
      if (st.sekme === 'bildirim') bildirim();
    } catch (er) { g.disabled = false; g.textContent = 'Tekrar dene'; $('#ek-s', modal).innerHTML = `<div class="ek-hata" role="alert">${esc(hata(er))}</div>`; }
  });
}

// ---------------------------------------------------------------- kapı
function kapi() {
  const g = $('#ek-govde'), e = seans();
  g.innerHTML = `<div class="ek-kart"><h2>Kapı kontrolü</h2>
    ${e ? '' : '<div class="ek-uyari">Önce bir seans seç.</div>'}
    <form id="ek-kf" class="ek-alan"><label for="ek-kod">Bilet kodu (QR okuyucu buraya yazar)</label>
      <input id="ek-kod" type="text" autocomplete="off" autocapitalize="off" spellcheck="false" inputmode="text" ${e ? '' : 'disabled'}>
      <button class="btn btn-primary" type="submit" ${e ? '' : 'disabled'}>Kontrol et</button></form>
    <div id="ek-ks" aria-live="assertive"></div>
    ${st.kapiSon.length ? `<h2 style="margin-top:8px">Son okutulanlar</h2><div class="ek-tablo"><table><thead><tr><th>Saat</th><th>Kod</th><th>Sonuç</th></tr></thead><tbody>${st.kapiSon.map((x) => `<tr><td>${esc(x.saat)}</td><td>${esc(x.kod)}</td><td>${esc(x.sonuc)}</td></tr>`).join('')}</tbody></table></div>` : ''}</div>`;
  const inp = $('#ek-kod'); inp.focus();
  const ayikla = (v) => { const m = String(v || '').trim().match(/[A-Za-z0-9_-]{6,}/g); return m ? m[m.length - 1] : ''; };
  $('#ek-kf').addEventListener('submit', async (ev) => {
    ev.preventDefault();
    const kod = ayikla(inp.value), s = $('#ek-ks');
    const goster = (tur, baslik, alt) => { s.innerHTML = `<div class="ek-sonuc ${tur}" role="status"><b>${esc(baslik)}</b>${alt}</div>`; };
    if (!kod) return goster('bad', 'KOD YOK', '<span>Bilet kodunu yaz ya da QR okut.</span>');
    goster('', 'Kontrol ediliyor…', '');
    let sonuc = '';
    try {
      const r = await cagir('teamCheckIn', { ticketId: kod, eventId: st.eventId });
      const t = r.ticket || {};
      const ozet = `<span>${esc(t.showName || '')} · ${(t.buySeats || []).map(esc).join(', ')}</span>`;
      if (r.wrongEvent) { sonuc = 'Başka seans'; goster('bad', 'BAŞKA SEANSA AİT', `${ozet}<span>${esc(t.eventDate || '')}</span>`); }
      else if (r.ok) { sonuc = 'Geçerli'; goster('ok', 'GEÇERLİ', ozet + (t.payAtVenue ? '<span><b>ÖDEME ALINACAK</b> — rezervasyon sahnede ödenir</span>' : '')); }
      else if (r.already) { sonuc = 'Zaten kullanıldı'; goster('bad', 'ZATEN KULLANILDI', `${ozet}<span>İlk giriş: ${esc(t.usedAt ? new Date(t.usedAt).toLocaleString('tr-TR') : '—')}</span>`); }
      else if (t.paymentStatus === 'cancelled') { sonuc = 'İptal'; goster('bad', 'İPTAL EDİLMİŞ', ozet); }
      else { sonuc = 'Geçersiz'; goster('bad', 'GEÇERSİZ', `${ozet}<span>Durum: ${esc(t.paymentStatus || '')}</span>`); }
    } catch (er) {
      sonuc = 'Hata';
      goster('bad', String(er?.code || '').includes('not-found') ? 'BULUNAMADI' : 'HATA', `<span>${esc(hata(er))}</span>`);
    }
    st.kapiSon.unshift({ saat: new Date().toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' }), kod: kod.slice(0, 8), sonuc });
    st.kapiSon = st.kapiSon.slice(0, 10);
    inp.value = ''; inp.focus();
  });
}

// ---------------------------------------------------------------- koltuklar (İş T-2: satışa kapatma / protokol bileti)
// Yetki ve sınır tamamen sunucuda (team.js: assertCanManageEvent) — bu dosya yalnız arayüzdür. Canlı durum (kim şu an
// alıyor/tutuyor) Event.seats'in herkese açık onSnapshot akışından gelir; aynı akış `/koltuk` satın alma sayfasında da kullanılır.
const ADMIN_BLOK = '__ADMIN_BLOCKED__'; // eski yönetici bloğu işareti; yeni biçim status:'blocked'
let koltukAbone = null;
const koltukAboneKapat = () => { try { koltukAbone?.(); } catch { /* yoktu */ } koltukAbone = null; };
const koltukAyir = (id) => { const m = /^(.*?)(\d+)$/.exec(id); return m ? [m[1].trim().replace(/[\s\-_.:]+$/, ''), +m[2]] : ['', NaN]; };

/** `Seats/{stageId}` + canlı `Event.seats`'ten sıra/koltuk düzeni (biletal.css'teki satın alma sayfasıyla aynı algoritma). */
function koltukDuzenKur(sd, esMap) {
  const META = new Set(['closedSeatsId', '_id', '_createdAt', '_updatedAt']);
  const grup = new Map();
  const ekle = (etiket, id) => { if (!grup.has(etiket)) grup.set(etiket, []); grup.get(etiket).push(id); };
  if (sd && Array.isArray(sd.seatsId)) sd.seatsId.filter((x) => typeof x === 'string' && x).forEach((id) => ekle(koltukAyir(id)[0], id));
  else if (sd) for (const [k, v] of Object.entries(sd)) { if (!META.has(k) && Array.isArray(v)) v.filter((x) => typeof x === 'string' && x).forEach((id) => ekle(k, id)); }
  if (!grup.size) Object.keys(esMap || {}).forEach((id) => ekle(koltukAyir(id)[0], id));
  const anahtarlar = [...grup.keys()].sort((a, b) => a.length - b.length || a.localeCompare(b, 'tr', { numeric: true }));
  let satirlar = anahtarlar.map((k) => ({ ad: k, koltuklar: grup.get(k).map((id) => ({ id, num: koltukAyir(id)[1] })).sort((a, b) => (isNaN(a.num) || isNaN(b.num) ? 0 : a.num - b.num)) }));
  if (satirlar.length === 1 && satirlar[0].ad === '' && satirlar[0].koltuklar.length > 14) {
    const hepsi = satirlar[0].koltuklar; satirlar = [];
    for (let i = 0; i < hepsi.length; i += 12) satirlar.push({ ad: String(i / 12 + 1), koltuklar: hepsi.slice(i, i + 12) });
  }
  return satirlar;
}
const koltukKapaliMi = (info) => !!info && (info.status === 'blocked' || (info.status === 'sold' && info.customerId === ADMIN_BLOK));
function koltukDurum(info) {
  if (!info) return 'bos';
  switch (info.status) {
    case 'available': return 'bos';
    case 'reserved': return 'rezerve';
    case 'sold': return info.customerId === ADMIN_BLOK ? 'kapali' : 'dolu';
    case 'blocked': return 'kapali';
    default: return 'kapali';
  }
}
const KOLTUK_METNI = { bos: 'boş', dolu: 'satıldı', rezerve: 'tutuluyor', kapali: 'satışa kapalı' };

function koltukGrid(satirlar, seats) {
  if (!satirlar.length) return '<p class="ek-muted">Bu sahne için koltuk düzeni tanımlı değil.</p>';
  const html = satirlar.map((s) => {
    let onceki = null;
    const hucre = s.koltuklar.map((k) => {
      const bosluk = onceki != null && !isNaN(k.num) && k.num - onceki > 1 ? '<span class="bosluk" aria-hidden="true"></span>' : '';
      onceki = isNaN(k.num) ? onceki : k.num;
      const d = koltukDurum(seats[k.id]);
      return `${bosluk}<button type="button" class="koltuk ${d}" data-id="${esc(k.id)}" aria-label="${esc(k.id)}, ${KOLTUK_METNI[d]}">${esc(isNaN(k.num) ? k.id : k.num)}</button>`;
    }).join('');
    return `<div class="satir" role="group" aria-label="${s.ad ? `Sıra ${esc(s.ad)}` : 'Koltuklar'}"><span class="satir-ad" aria-hidden="true">${esc(s.ad)}</span>${hucre}<span class="satir-ad" aria-hidden="true">${esc(s.ad)}</span></div>`;
  }).join('');
  return `<div class="ek-plan"><div class="ek-plan-gorus"><div class="ek-plan-ic"><div class="satirlar">${html}</div></div></div>
    <div class="lejant"><span><button type="button" class="koltuk bos" tabindex="-1" aria-hidden="true"></button>Boş</span><span><button type="button" class="koltuk dolu" tabindex="-1" aria-hidden="true"></button>Satıldı (protokol bileti de buraya düşer)</span><span><button type="button" class="koltuk rezerve" tabindex="-1" aria-hidden="true"></button>Tutuluyor</span><span><button type="button" class="koltuk kapali" tabindex="-1" aria-hidden="true"></button>Satışa kapalı</span></div></div>`;
}

function koltukTikla(root, eventId, seats) {
  $$('.koltuk[data-id]', root).forEach((b) => b.addEventListener('click', () => {
    const id = b.dataset.id, info = seats[id], d = koltukDurum(info);
    if (d === 'bos') return koltukEylemSec(eventId, id);
    if (d === 'kapali' && koltukKapaliMi(info)) return koltukBlogKaldir(eventId, id);
  }));
}

async function koltuklar() {
  koltukAboneKapat();
  const g = $('#ek-govde'), e = seans();
  if (!e) { g.innerHTML = '<div class="ek-kart"><p class="ek-muted">Önce bir seans seç.</p></div>'; return; }
  g.innerHTML = '<div class="ek-kart"><h2>Koltuklar</h2><p class="ek-muted">Boş bir koltuğa dokunarak satışa kapatabilir ya da doğrudan ücretsiz protokol bileti verebilirsin. Durum canlıdır.</p><div id="ek-koltuk-govde"><div class="skel" style="height:220px"></div></div></div>';
  const eid = e.eventId;
  let satirlar = null, seats = {};
  const cizGovde = () => {
    if (st.eventId !== eid || st.sekme !== 'koltuk') return;
    const h = $('#ek-koltuk-govde');
    if (h) { h.innerHTML = koltukGrid(satirlar || [], seats); koltukTikla(h, eid, seats); }
  };
  koltukAbone = onSnapshot(doc(db, 'Event', eid), async (snap) => {
    if (st.eventId !== eid || st.sekme !== 'koltuk' || !snap.exists()) return;
    const veri = snap.data();
    seats = veri.seats && typeof veri.seats === 'object' ? veri.seats : {};
    if (!satirlar) {
      const sid = String(veri.stageId || '');
      const ss = sid ? await getDoc(doc(db, 'Seats', sid)) : null;
      satirlar = koltukDuzenKur(ss && ss.exists() ? ss.data() : null, seats);
    }
    cizGovde();
  }, (er) => { const h = $('#ek-koltuk-govde'); if (h) h.innerHTML = `<div class="ek-hata" role="alert">Koltuklar yüklenemedi: ${esc(er?.message || '')}</div>`; });
}

function koltukModalAc(html) {
  const onceki = document.activeElement;
  const bg = document.createElement('div'); bg.className = 'ek-modal-bg';
  bg.innerHTML = `<div class="ek-modal" role="dialog" aria-modal="true">${html}</div>`;
  document.body.append(bg);
  const modal = bg.firstElementChild;
  const tus = (ev) => { if (ev.key === 'Escape') kapat(); };
  const kapat = () => { document.removeEventListener('keydown', tus, true); bg.remove(); onceki?.focus?.(); };
  document.addEventListener('keydown', tus, true);
  bg.addEventListener('mousedown', (ev) => { if (ev.target === bg) kapat(); });
  return { modal, kapat };
}

function koltukEylemSec(eventId, seatId) {
  const { modal, kapat } = koltukModalAc(`<h2>Koltuk ${esc(seatId)}</h2>
    <p class="ek-muted">Bu koltuk şu an boş. Satışa kapatabilir ya da doğrudan ücretsiz protokol bileti verebilirsin.</p>
    <div id="ek-ke-s"></div>
    <div class="ek-act"><button type="button" class="btn btn-ghost" id="ek-ke-v">Vazgeç</button>
      <button type="button" class="btn btn-ghost" id="ek-ke-bloke">Satışa kapat</button>
      <button type="button" class="btn btn-primary" id="ek-ke-prot">Protokol bileti ver</button></div>`);
  $('#ek-ke-v', modal).addEventListener('click', kapat);
  $('#ek-ke-bloke', modal).addEventListener('click', async (ev) => {
    const btn = ev.currentTarget; btn.disabled = true;
    try { await cagir('teamSetSeatBlocked', { eventId, seatId, blocked: true }); kapat(); }
    catch (er) { btn.disabled = false; $('#ek-ke-s', modal).innerHTML = `<div class="ek-hata" role="alert">${esc(hata(er))}</div>`; }
  });
  $('#ek-ke-prot', modal).addEventListener('click', () => { kapat(); koltukProtokolModal(eventId, seatId); });
}

function koltukProtokolModal(eventId, seatId) {
  const { modal, kapat } = koltukModalAc(`<h2>Koltuk ${esc(seatId)} — protokol bileti</h2>
    <p class="ek-muted">Bu koltuk ücretsiz olarak ayrılır; ödeme/kota denetimine girmez. Kapıda giriş bilet koduyla yapılır.</p>
    <div class="ek-alan"><label for="ek-prot-not">Not (kime/ne için — opsiyonel)</label><textarea id="ek-prot-not" maxlength="140" placeholder="Örn. Ahmet Yılmaz — arkadaş davetiyesi"></textarea></div>
    <div id="ek-prot-s"></div>
    <div class="ek-act"><button type="button" class="btn btn-ghost" id="ek-p-v">Vazgeç</button><button type="button" class="btn btn-primary" id="ek-p-g">Protokol bileti ver</button></div>`);
  $('#ek-p-v', modal).addEventListener('click', kapat);
  $('#ek-p-g', modal).addEventListener('click', async (ev) => {
    const btn = ev.currentTarget; btn.disabled = true; btn.textContent = 'Veriliyor…';
    try {
      await cagir('teamGrantFreeSeat', { eventId, seatIds: [seatId], note: $('#ek-prot-not', modal).value.trim() });
      kapat();
    } catch (er) { btn.disabled = false; btn.textContent = 'Protokol bileti ver'; $('#ek-prot-s', modal).innerHTML = `<div class="ek-hata" role="alert">${esc(hata(er))}</div>`; }
  });
}

function koltukBlogKaldir(eventId, seatId) {
  const { modal, kapat } = koltukModalAc(`<h2>Koltuk ${esc(seatId)}</h2>
    <p class="ek-muted">Bu koltuk satışa kapalı. Bloğu kaldırıp yeniden satışa açmak istiyor musun?</p>
    <div id="ek-bk-s"></div>
    <div class="ek-act"><button type="button" class="btn btn-ghost" id="ek-bk-v">Vazgeç</button><button type="button" class="btn btn-primary" id="ek-bk-g">Bloğu kaldır</button></div>`);
  $('#ek-bk-v', modal).addEventListener('click', kapat);
  $('#ek-bk-g', modal).addEventListener('click', async (ev) => {
    const btn = ev.currentTarget; btn.disabled = true;
    try { await cagir('teamSetSeatBlocked', { eventId, seatId, blocked: false }); kapat(); }
    catch (er) { btn.disabled = false; $('#ek-bk-s', modal).innerHTML = `<div class="ek-hata" role="alert">${esc(hata(er))}</div>`; }
  });
}

// ---------------------------------------------------------------- özet
async function ozet() {
  const g = $('#ek-govde');
  g.innerHTML = '<div class="skel" style="height:160px"></div>';
  try { st.stats = await cagir('teamStats', { teamId: ekip().teamId }); } catch (er) { g.innerHTML = `<div class="ek-hata" role="alert">${esc(hata(er))}</div>`; return; }
  const s = st.stats.shows;
  g.innerHTML = s.length ? s.map((o) => `<div class="ek-kart"><h2>${esc(o.name)}</h2>
    <div class="ek-ozet"><div><b>${o.totals.sold}</b><span>Satılan</span></div><div><b>${o.totals.held}</b><span>Tutulan</span></div><div><b>${o.totals.checkedIn}</b><span>Girişi yapılan bilet</span></div></div>
    <div class="ek-tablo"><table><thead><tr><th>Seans</th><th>Satılan</th><th>Doluluk</th><th>Giriş</th></tr></thead><tbody>${o.events.map((x) => `<tr><td>${esc(saatYaz(x.ms))}</td><td>${x.sold}/${x.total}</td><td>%${x.occupancy}</td><td>${x.checkedIn}/${x.activeTickets}</td></tr>`).join('') || '<tr><td colspan="4">Seans yok</td></tr>'}</tbody></table></div></div>`).join('')
    : '<div class="ek-kart"><p class="ek-muted">Gösterilecek oyun yok.</p></div>';
}

// ---------------------------------------------------------------- başlangıç
let sira = 0;
async function yukle(u) {
  const benim = ++sira;
  st.kullanici = u;
  if (!u) { st.veri = null; return giris(); }
  yaz('<section class="ek-sayfa"><h1>Ekip paneli</h1><div class="skel" style="height:240px"></div></section>');
  try {
    const v = await cagir('getMyManagedTeams', {});
    if (benim !== sira) return;
    if (!v.teams.length) return yetkisiz();
    st.veri = v; seansSec(); iskelet();
  } catch (e) {
    if (benim !== sira) return;
    yetkisiz(hata(e));
  }
}
let sonUid = '__yok__';
oturumDinle((u) => { const id = u ? u.uid : ''; if (id === sonUid) return; sonUid = id; yukle(u); });
