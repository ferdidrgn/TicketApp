// Yönetim paneli — "Sahne kumandası": seans biletlilerine tek dokunuşla bildirim (telefondan, kulisten kullanılır).
// Güvenlik: gönderim SUNUCU callable'larıyla yapılır (adminSendNotification / adminNotifyPreview; yetki sunucuda denetlenir).
// Şablon metinleri sunucuda üretilir; bu dosya yalnızca arayüzdür. Alarm = yüksek öncelikli push (sessiz modda ses GARANTİ DEĞİL).
import { db, fonksiyon, doc, getDoc, setDoc, serverTimestamp, collection, getDocs, query, limit, orderBy } from '../firebase.js';
import { $, $$, esc, tarihAyristir } from '../util.js';

const HOUR = 3600e3;
const IKON = { baslamak_uzere: '⏰', basladi: '🤫', ara: '☕', ara_bitiyor: '🔔', bitti: '👏', ertelendi: '📅', iptal: '⛔', genel: '📣' };
const cagir = async (ad, veri) => (await (await fonksiyon(ad))(veri)).data;
const uuid = () => (crypto.randomUUID ? crypto.randomUUID().replace(/-/g, '') : `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 12)}`);
const gorece = (ms) => {
  const d = Math.round((ms - Date.now()) / 60000), a = Math.abs(d);
  const t = a < 90 ? `${a} dk` : a < 48 * 60 ? `${Math.round(a / 60)} sa` : `${Math.round(a / 1440)} gün`;
  return d >= 0 ? `${t} sonra` : `${t} önce`;
};
const saatYaz = (ms) => new Date(ms).toLocaleString('tr-TR', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' });

export function sahneKumandasi(m, { veri, bildir, hataMesaji }) {
  const st = { ev: '', sablonlar: [], onizleme: null, ara: 15 };
  const ad = (c, id) => { const x = (veri[c] || []).find((y) => y.id === id || y.docId === id); return x ? x.name : ''; };
  const seanslar = () => (veri.Event || []).map((e) => { const d = tarihAyristir(e.date); return { id: e.id, docId: e.docId, ms: d ? d.getTime() : null, showId: e.showId, stageId: e.stageId, oyun: ad('Show', e.showId) || 'Oyun', sahne: ad('Stage', e.stageId) }; })
    .filter((e) => e.ms != null && e.ms >= Date.now() - 24 * HOUR && e.ms <= Date.now() + 7 * 24 * HOUR).sort((a, b) => a.ms - b.ms);
  const secili = () => seanslar().find((e) => e.id === st.ev);

  m.innerHTML = `<div class="adm-top"><h1>🎭 Sahne kumandası</h1></div>
    <section class="bk-card" id="sk-oto" aria-label="Otomatik hatırlatmalar"></section>
    <section class="bk-card" id="sk-seans" aria-label="Seans"></section>
    <section class="bk-card" id="sk-hizli" aria-label="Hızlı bildirimler"></section>
    <section class="bk-card" id="sk-serbest" aria-label="Serbest mesaj"></section>
    <section class="bk-card" id="sk-log" aria-label="Son gönderimler"></section>`;

  // ---------------- otomatik hatırlatmalar
  async function otomatik() {
    const k = $('#sk-oto', m);
    let acik = true, hb = null;
    try {
      const [c, h] = await Promise.all([getDoc(doc(db, 'Config', 'bildirim')), getDoc(doc(db, 'System', 'eventReminders'))]);
      if (c.exists() && c.data().autoReminders === false) acik = false;
      hb = h.exists() ? h.data() : null;
    } catch (e) { k.innerHTML = `<h2>Otomatik hatırlatmalar</h2><div class="bk-alert" role="alert">${esc(hataMesaji(e))}</div>`; return; }
    const son = hb && hb.lastRunAt && hb.lastRunAt.toMillis ? hb.lastRunAt.toMillis() : null;
    const bayat = acik && (son == null || Date.now() - son > 45 * 60000);
    k.classList.toggle('bad', bayat);
    k.innerHTML = `<div class="sk-oto-row"><div><h2 style="margin:0 0 4px">Otomatik hatırlatmalar</h2>
        <p class="muted" style="margin:0">Seansa yaklaşık 24 saat ve 2 saat kala bilet sahiplerine bildirim gider.</p></div>
        <button class="sw-toggle ${acik ? 'on' : ''}" role="switch" aria-checked="${acik}" aria-label="Otomatik hatırlatmalar" id="sk-sw"><i></i><span>${acik ? 'Açık' : 'Kapalı'}</span></button></div>
      ${bayat ? `<div class="bk-alert" role="alert" style="margin-top:12px">⚠ Hatırlatma görevi ${son ? `${esc(gorece(son))} çalışmış` : 'hiç çalışmamış'}. Zamanlanmış görev (Cloud Scheduler) kurulu mu?</div>` : ''}
      <p class="muted" style="margin:10px 0 0">${son ? `Son çalışma: ${esc(gorece(son))} · gönderilen: ${hb.sent24 || 0} (24 sa) + ${hb.sent2 || 0} (2 sa)` : 'Henüz çalışmadı.'}</p>`;
    $('#sk-sw', k).addEventListener('click', async () => {
      try { await setDoc(doc(db, 'Config', 'bildirim'), { autoReminders: !acik, updatedAt: serverTimestamp() }, { merge: true }); bildir(!acik ? 'Otomatik hatırlatmalar açıldı' : 'Otomatik hatırlatmalar kapatıldı'); otomatik(); } catch (e) { bildir(hataMesaji(e), true); }
    });
  }

  // ---------------- seans seçimi + alıcı sayısı
  function seansCiz() {
    const k = $('#sk-seans', m), liste = seanslar();
    if (!st.ev || !liste.some((e) => e.id === st.ev)) {
      const simdi = liste.filter((e) => Math.abs(e.ms - Date.now()) <= 24 * HOUR).sort((a, b) => Math.abs(a.ms - Date.now()) - Math.abs(b.ms - Date.now()));
      st.ev = (simdi[0] || liste[0] || {}).id || '';
    }
    const grup = (b, bas) => `<optgroup label="${bas}">${b.map((e) => `<option value="${esc(e.id)}" ${st.ev === e.id ? 'selected' : ''}>${esc(e.oyun)} · ${esc(e.sahne)} · ${esc(saatYaz(e.ms))}</option>`).join('')}</optgroup>`;
    const yakin = liste.filter((e) => Math.abs(e.ms - Date.now()) <= 24 * HOUR), uzak = liste.filter((e) => Math.abs(e.ms - Date.now()) > 24 * HOUR);
    k.innerHTML = `<h2>Seans</h2>${liste.length ? `<div class="fld-in"><label for="sk-ev">Hangi seans?</label><select id="sk-ev">${yakin.length ? grup(yakin, 'Şimdi (±24 saat)') : ''}${uzak.length ? grup(uzak, 'Yaklaşan (7 gün)') : ''}</select></div>
        <div id="sk-kitle" aria-live="polite"><div class="skel" style="height:56px;margin-top:12px"></div></div>` : '<div class="empty">Önümüzdeki 7 gün içinde seans yok. Aşağıdan genel duyuru gönderebilirsin.</div>'}`;
    if (!liste.length) { hizliCiz(); return; }
    $('#sk-ev', k).addEventListener('change', (e) => { st.ev = e.target.value; kitleYukle(); });
    kitleYukle();
  }
  async function kitleYukle() {
    const e = secili(), k = $('#sk-kitle', m);
    if (!e) return;
    k.innerHTML = '<div class="skel" style="height:56px;margin-top:12px"></div>';
    try {
      const r = await cagir('adminNotifyPreview', { target: { type: 'event', id: e.id } });
      st.sablonlar = r.templates; st.kitle = r;
      const aktif = Math.abs(e.ms - Date.now()) <= 24 * HOUR;
      k.innerHTML = `<div class="sk-kitle"><div class="sk-kim"><b>${esc(e.oyun)}</b><span>${esc(e.sahne)} · ${esc(saatYaz(e.ms))} · ${esc(gorece(e.ms))}</span></div>
        <div class="sk-sayi"><b>${r.recipients}</b><span>bilet sahibi</span></div><div class="sk-sayi"><b>${r.withToken}</b><span>push alabilir</span></div></div>
        ${r.withToken < r.recipients ? `<p class="muted" style="margin:8px 0 0">${r.recipients - r.withToken} kişi bildirimi yalnızca uygulama içi kutuda görür (cihaz kaydı yok / bildirim kapalı). İptal ve "gelmedi" biletler sayılmaz.</p>` : ''}
        ${aktif ? '' : '<p class="muted" style="margin:8px 0 0">Bu seans ±24 saat dışında: sahne şablonları (başladı, ara, bitti…) kapalı; duyuru gönderebilirsin.</p>'}`;
      hizliCiz(); serbestCiz();
    } catch (er) { k.innerHTML = `<div class="bk-alert" role="alert">Alıcılar alınamadı: ${esc(hataMesaji(er))}</div>`; hizliCiz(); serbestCiz(); }
  }

  // ---------------- hızlı şablon düğmeleri
  function hizliCiz() {
    const k = $('#sk-hizli', m), e = secili();
    if (!e) { k.innerHTML = ''; return; }
    const yakin = Math.abs(e.ms - Date.now()) <= 24 * HOUR;
    const tp = (id) => st.sablonlar.find((t) => t.id === id);
    const dugmeler = [];
    const ekle = (id, etiket, params) => { const t = tp(id); if (t) dugmeler.push({ id, etiket, params, kind: t.kind, timed: t.timed, ikon: IKON[id] }); };
    ekle('baslamak_uzere', 'Oyun 10 dk sonra başlıyor', { dk: 10 });
    ekle('baslamak_uzere', 'Oyun 5 dk sonra başlıyor', { dk: 5 });
    ekle('basladi', 'Oyun başladı — telefonları sessize alın');
    ekle('ara', `Birinci perde bitti — ${st.ara} dk ara`, { dk: st.ara });
    ekle('ara_bitiyor', 'Ara bitiyor — 5 dk içinde yerlerimize');
    ekle('bitti', 'Oyun bitti — teşekkürler');
    ekle('ertelendi', 'Seans ertelendi…');
    ekle('iptal', 'Seans iptal edildi…');
    k.innerHTML = `<h2>Hızlı bildirimler</h2>
      <div class="bk-row" style="margin-bottom:12px"><label class="fld-in" style="max-width:190px">Ara süresi (dk)<input id="sk-ara" type="number" min="5" max="30" step="1" value="${st.ara}"></label></div>
      <div class="sk-grid">${dugmeler.map((d, i) => {
    const kapali = d.timed && !yakin;
    return `<button type="button" class="sk-btn ${d.kind === 'alarm' ? 'alarm' : ''}" data-i="${i}" ${kapali ? 'disabled title="Yalnızca seansa ±24 saat kala"' : ''}><span class="sk-ik" aria-hidden="true">${d.ikon || '📣'}</span><span class="sk-et">${esc(d.etiket)}</span>${d.kind === 'alarm' ? '<small>🔔 Alarm</small>' : ''}</button>`;
  }).join('')}</div>`;
    $('#sk-ara', k).addEventListener('change', (ev) => { st.ara = Math.min(30, Math.max(5, Math.round(Number(ev.target.value)) || 15)); hizliCiz(); });
    $$('.sk-btn', k).forEach((b) => b.addEventListener('click', () => {
      const d = dugmeler[+b.dataset.i];
      onayAc({ target: { type: 'event', id: e.id }, template: d.id, params: d.params });
    }));
  }

  // ---------------- serbest mesaj
  function serbestCiz() {
    const k = $('#sk-serbest', m), e = secili();
    k.innerHTML = `<h2>Serbest mesaj</h2>
      <div class="form-grid">
        <div class="fld-in"><label for="sf-hedef">Kime?</label><select id="sf-hedef">
          ${e ? `<option value="event">Bu seansın biletlileri</option><option value="show">Bu oyunun tüm biletlileri</option>` : ''}
          <option value="all">Herkese (tüm kullanıcılar)</option><option value="user">Tek kişi (kullanıcı no)</option></select></div>
        <div class="fld-in" id="sf-uid-w" style="display:none"><label for="sf-uid">Kullanıcı no (uid)</label><input id="sf-uid" type="text" autocomplete="off"></div>
        <div class="fld-in full"><label for="sf-baslik">Başlık <span class="muted" id="sf-bc">0/60</span></label><input id="sf-baslik" type="text" maxlength="60"></div>
        <div class="fld-in full"><label for="sf-govde">Mesaj <span class="muted" id="sf-gc">0/240</span></label><textarea id="sf-govde" maxlength="240" style="min-height:90px"></textarea><span class="hint">{oyun} ve {sahne} yazarsan seansın bilgisiyle dolar.</span></div>
        <div class="fld-in full"><label>Tür</label><div class="bk-seg" role="radiogroup" aria-label="Bildirim türü" style="margin:0">
          <button type="button" role="radio" aria-checked="true" class="on" data-k="normal"><b>Normal</b><small>Standart bildirim.</small></button>
          <button type="button" role="radio" aria-checked="false" data-k="alarm"><b>🔔 Alarm</b><small>Yüksek öncelik, alarm kanalı. Sessiz modda garanti yok.</small></button></div></div>
      </div><div class="modal-act"><button class="btn btn-primary" id="sf-gonder">Önizle ve gönder</button></div>`;
    let tur = 'normal';
    const say = () => { $('#sf-bc', k).textContent = `${$('#sf-baslik', k).value.length}/60`; $('#sf-gc', k).textContent = `${$('#sf-govde', k).value.length}/240`; };
    $('#sf-baslik', k).addEventListener('input', say); $('#sf-govde', k).addEventListener('input', say);
    $('#sf-hedef', k).addEventListener('change', (ev) => { $('#sf-uid-w', k).style.display = ev.target.value === 'user' ? '' : 'none'; });
    $$('[data-k]', k).forEach((b) => b.addEventListener('click', () => { tur = b.dataset.k; $$('[data-k]', k).forEach((x) => { x.classList.toggle('on', x === b); x.setAttribute('aria-checked', x === b); }); }));
    $('#sf-gonder', k).addEventListener('click', () => {
      const h = $('#sf-hedef', k).value, baslik = $('#sf-baslik', k).value.trim(), govde = $('#sf-govde', k).value.trim();
      if (!baslik || !govde) return bildir('Başlık ve mesaj gerekli.', true);
      let target;
      if (h === 'user') { const u = $('#sf-uid', k).value.trim(); if (!u) return bildir('Kullanıcı no gerekli.', true); target = { type: 'user', id: u }; }
      else if (h === 'all') target = { type: 'all' };
      else if (h === 'show') target = { type: 'show', id: e.showId };
      else target = { type: 'event', id: e.id };
      onayAc({ target, template: 'genel', title: baslik, body: govde, kind: tur });
    });
  }

  // ---------------- önizleme + onay penceresi
  async function onayAc(istek) {
    const bg = document.createElement('div'); bg.className = 'modal-bg';
    bg.innerHTML = '<div class="modal" role="dialog" aria-modal="true" aria-label="Bildirim önizleme"><div class="skel" style="height:180px"></div></div>';
    document.body.append(bg);
    const kapat = () => { bg.remove(); };
    bg.addEventListener('mousedown', (ev) => { if (ev.target === bg) kapat(); });
    const requestId = uuid();
    let r;
    try { r = await cagir('adminNotifyPreview', istek); } catch (er) { kapat(); return bildir(hataMesaji(er), true); }
    if (r.blocked) { kapat(); return bildir(r.blocked, true); }
    const sablon = st.sablonlar.find((t) => t.id === istek.template);
    const duzenle = sablon && sablon.custom && istek.template !== 'genel'; // ertelendi / iptal: metin yönetici tarafından yazılır
    const p = r.preview || { title: istek.title, body: istek.body, kind: istek.kind || 'normal' };
    const cok = istek.target.type === 'all' || r.recipients > 1;
    const modal = $('.modal', bg);
    modal.innerHTML = `<h2>Göndermeden önce kontrol et</h2>
      <div class="bildirim-onizle ${p.kind === 'alarm' ? 'alarm' : ''}" aria-label="Bildirim önizlemesi"><small>TiyatRol${p.kind === 'alarm' ? ' · 🔔 ALARM' : ''}</small>
        ${duzenle ? `<input id="o-baslik" type="text" maxlength="60" value="${esc(p.title)}" aria-label="Başlık">` : `<b>${esc(p.title)}</b>`}
        ${duzenle ? `<textarea id="o-govde" maxlength="240" placeholder="Mesajı yaz (en fazla 240 karakter)" aria-label="Mesaj">${esc(istek.body || '')}</textarea>` : `<p>${esc(p.body)}</p>`}</div>
      <p class="sk-hedef-satir"><b>${esc(r.target.label)}</b> · ${istek.target.type === 'all' ? `${r.recipients} kullanıcıya (uygulamayı yüklemiş herkese) gider` : `${r.recipients} kişi · ${r.withToken} push alabilir`}</p>
      ${istek.target.type === 'all' ? '<div class="bk-alert" role="alert">⚠ Bu bildirim TÜM kullanıcılara gider. Emin misin?</div>' : ''}
      ${p.kind === 'alarm' ? '<p class="muted">Alarm bildirimi yüksek öncelikle gider; telefon sessizde veya "Rahatsız Etme"deyse sesi çalmayabilir.</p>' : ''}
      <div id="o-sonuc" aria-live="polite"></div>
      <div class="modal-act"><button class="btn btn-ghost" id="o-iptal">Vazgeç</button><button class="btn btn-primary btn-lg" id="o-gonder">Gönder${cok ? ` (${r.recipients} kişi)` : ''}</button></div>`;
    $('#o-iptal', modal).addEventListener('click', kapat);
    const g = $('#o-gonder', modal);
    g.addEventListener('click', async () => {
      const gonderilecek = { ...istek, confirm: cok, requestId };
      if (duzenle) { gonderilecek.title = $('#o-baslik', modal).value.trim(); gonderilecek.body = $('#o-govde', modal).value.trim(); if (!gonderilecek.title || !gonderilecek.body) return bildir('Başlık ve mesaj gerekli.', true); }
      g.disabled = true; g.textContent = 'Gönderiliyor…';
      try {
        const s = await cagir('adminSendNotification', gonderilecek);
        $('#o-sonuc', modal).innerHTML = `<div class="bk-res ok"><div class="bk-res-t">${s.duplicate ? 'ZATEN GÖNDERİLMİŞ' : 'GÖNDERİLDİ'}</div>
          <div>${s.recipients} alıcı${s.topic ? ' (tüm kullanıcılar, konu üzerinden)' : ` · push: ${s.success} başarılı${s.failure ? `, ${s.failure} başarısız` : ''} · ${s.withToken ?? 0} cihaz kaydı`}</div></div>`;
        g.remove(); $('#o-iptal', modal).textContent = 'Kapat';
        logYukle();
      } catch (er) { g.disabled = false; g.textContent = 'Tekrar dene'; $('#o-sonuc', modal).innerHTML = `<div class="bk-alert" role="alert">${esc(hataMesaji(er))}</div>`; }
    });
    g.focus();
  }

  // ---------------- son gönderimler
  async function logYukle() {
    const k = $('#sk-log', m);
    try {
      const sn = await getDocs(query(collection(db, 'NotificationLog'), orderBy('createdAt', 'desc'), limit(20)));
      const satir = sn.docs.map((d) => d.data());
      k.innerHTML = `<h2>Son gönderimler</h2>${satir.length ? `<div class="tbl-wrap"><table class="tbl"><thead><tr><th>Zaman</th><th>Gönderen</th><th>Hedef</th><th>Mesaj</th><th>Sonuç</th></tr></thead><tbody>
        ${satir.map((x) => `<tr><td>${esc(x.createdAt && x.createdAt.toMillis ? saatYaz(x.createdAt.toMillis()) : '—')}</td><td>${esc(x.sentByName || (x.sentBy || '').slice(0, 6))}</td>
          <td>${esc(x.targetLabel || x.target?.type || '')}${x.template ? `<br><span class="muted">${esc(x.template)}</span>` : ''}</td>
          <td>${x.kind === 'alarm' ? '<span class="tag bad">Alarm</span> ' : ''}<b>${esc(x.title || '')}</b><br><span class="muted">${esc(x.body || '')}</span></td>
          <td>${x.status === 'done' ? `${x.recipients ?? 0} alıcı<br><span class="muted">${x.success ?? 0} ✓ ${x.failure ? `· ${x.failure} ✗` : ''}</span>` : '<span class="tag warn">Tamamlanmadı</span>'}</td></tr>`).join('')}</tbody></table></div>` : '<div class="empty">Henüz gönderim yok.</div>'}`;
    } catch (e) { k.innerHTML = `<h2>Son gönderimler</h2><div class="bk-alert" role="alert">${esc(hataMesaji(e))}</div>`; }
  }

  otomatik(); seansCiz(); serbestCiz(); logYukle();
}
