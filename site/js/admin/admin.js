// TiyatRol yönetim paneli. Giriş: Firebase Authentication (e-posta/şifre veya Google).
// Yetki: User/{uid}.role == 'admin'. NOT: Bu kontrol yalnızca arayüzü gizler; asıl güvenlik
// Firestore kurallarındadır (firestore.rules → yazma = isAdmin()). Kurallar yayınlanmadan panel güvenli SAYILMAZ.
import '../theme.js';
import {
  auth, db, storage, onAuthStateChanged, signInWithEmailAndPassword, signInWithPopup, GoogleAuthProvider, signOut,
  sendPasswordResetEmail, collection, getDocs, getDoc, doc, setDoc, updateDoc, deleteDoc, serverTimestamp, query, where, limit,
  arrayUnion, arrayRemove, getCountFromServer, sRef, uploadBytes, getDownloadURL,
} from '../firebase.js';
import { KOLEKSIYONLAR, SUTUN_ADI } from './schema.js';
import { temaOku, temaYaz, temaSecenekleri } from '../theme.js';
import { $, $$, esc, tarihAyristir, debounce } from '../util.js';
import { biletKapi } from './kapi.js';
import { dashboard } from './dashboard.js';
import { sahneKumandasi } from './sahne.js';
import { ekipYoneticileri } from './ekipyonetici.js';

const app = $('#app');
let kullanici = null;
let veri = {};          // { Show: [..], ... } her biri {docId, ...alanlar}
let gorunum = 'ozet';
let arama = '';

// ---------- yardımcılar ----------
export function bildir(m, hata = false) {
  const t = $('#toast'); t.textContent = m; t.className = 'on' + (hata ? ' err' : '');
  clearTimeout(bildir.t); bildir.t = setTimeout(() => { t.className = ''; }, 3200);
}
const hataMesaji = (e) => {
  const k = e?.code || '';
  if (k.includes('permission-denied')) return 'Yetki reddedildi. Firestore kuralları yayınlı mı ve hesabın admin mi? (Yardım sekmesine bak)';
  if (k.includes('invalid-credential') || k.includes('wrong-password') || k.includes('user-not-found')) return 'E-posta veya şifre hatalı.';
  if (k.includes('too-many-requests')) return 'Çok fazla deneme. Biraz bekle.';
  if (k.includes('popup-closed')) return 'Giriş penceresi kapatıldı.';
  if (k.includes('unauthorized-domain')) return 'Bu alan adı Firebase > Authentication > Ayarlar > Yetkili alanlar listesinde değil.';
  return e?.message || 'Beklenmeyen hata.';
};
const adlari = (c) => (veri[c] || []).map((x) => ({ id: x.id, docId: x.docId, ad: KOLEKSIYONLAR[c].baslik(x) || x.id }));
const adBul = (c, id) => adlari(c).find((x) => x.id === id || x.docId === id)?.ad || id || '';
const dtLokalden = (v) => { // "15.11.2026,22:00" → "2026-11-15T22:00"
  const d = tarihAyristir(v); if (!d) return '';
  const p = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}T${p(d.getHours())}:${p(d.getMinutes())}`;
};
const dtUygulamaya = (v) => { // "2026-11-15T22:00" → "15.11.2026,22:00"
  const m = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})/.exec(v); return m ? `${m[3]}.${m[2]}.${m[1]},${m[4]}:${m[5]}` : '';
};
const gunYaz = (v) => { const d = tarihAyristir(v); if (!d) return ''; const p = (n) => String(n).padStart(2, '0'); return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`; };

async function hepsiniYukle() {
  const adlar = Object.keys(KOLEKSIYONLAR);
  const sonuc = await Promise.all(adlar.map((a) => getDocs(collection(db, a)).then((s) => s.docs.map((d) => ({ ...d.data(), docId: d.id, id: d.data()._id || d.id })))));
  adlar.forEach((a, i) => { veri[a] = sonuc[i]; });
}

// ---------- giriş ----------
function girisCiz(mesaj = '') {
  app.innerHTML = `<div class="login-wrap"><form class="login" id="gf">
    <div class="brand"><img src="/img/logo.png" alt=""><span>TİYATROL</span></div>
    <h1>Yönetim paneli</h1><p class="muted">Yalnızca yetkili hesaplar girebilir.</p>
    ${mesaj ? `<div class="err">${esc(mesaj)}</div>` : ''}
    <div class="fld-in"><label for="em">E-posta</label><input id="em" type="email" autocomplete="username" required></div>
    <div class="fld-in"><label for="pw">Şifre</label><input id="pw" type="password" autocomplete="current-password" required></div>
    <button class="btn btn-primary" type="submit">Giriş yap</button>
    <button class="btn btn-ghost" type="button" id="gg">Google ile giriş</button>
    <button class="btn btn-ghost btn-sm" type="button" id="fp">Şifremi unuttum</button>
    <p class="tiny"><a href="/">← Siteye dön</a></p></form></div>`;
  $('#gf').addEventListener('submit', async (e) => {
    e.preventDefault();
    try { await signInWithEmailAndPassword(auth, $('#em').value.trim(), $('#pw').value); } catch (x) { girisCiz(hataMesaji(x)); }
  });
  $('#gg').addEventListener('click', async () => { try { await signInWithPopup(auth, new GoogleAuthProvider()); } catch (x) { girisCiz(hataMesaji(x)); } });
  $('#fp').addEventListener('click', async () => {
    const em = $('#em').value.trim(); if (!em) return bildir('Önce e-posta yaz.', true);
    try { await sendPasswordResetEmail(auth, em); bildir('Sıfırlama bağlantısı gönderildi.'); } catch (x) { bildir(hataMesaji(x), true); }
  });
}
function yetkisizCiz(u) {
  app.innerHTML = `<div class="login-wrap"><div class="login"><h1>Yetkin yok</h1>
    <p class="muted"><b>${esc(u.email || u.uid)}</b> hesabı yönetici değil. Hesabın <code>User/${esc(u.uid)}</code> belgesindeki <code>role</code> alanı <code>admin</code> olmalı.</p>
    <p class="tiny">Kendi kendine yönetici yapma yolu bilerek kapalıdır; Firebase Console'dan elle verilir (Yardım sekmesine bak).</p>
    <div class="help-box"><b>Hesap kimliğin (uid):</b><br><code style="user-select:all">${esc(u.uid)}</code></div>
    <button class="btn btn-primary" id="co">Çıkış yap</button></div></div>`;
  $('#co').addEventListener('click', () => signOut(auth));
}

onAuthStateChanged(auth, async (u) => {
  kullanici = u;
  if (!u) return girisCiz();
  try {
    const d = await getDoc(doc(db, 'User', u.uid));
    if (!d.exists() || d.data().role !== 'admin') return yetkisizCiz(u);
    await hepsiniYukle();
    iskeletCiz();
  } catch (e) { girisCiz(hataMesaji(e)); }
});

// ---------- iskelet ----------
function iskeletCiz() {
  app.innerHTML = `<div class="adm"><aside class="adm-side"><a class="brand" href="/yonetim"><img src="/img/logo.png" alt=""><span>YÖNETİM</span></a>
    <button class="nv" data-g="ozet">📊 Genel bakış</button>
    ${Object.entries(KOLEKSIYONLAR).map(([k, c]) => `<button class="nv" data-g="${k}">${c.ikon} ${c.ad}</button>`).join('')}
    <button class="nv" data-g="biletler">🎟️ Biletler &amp; Kapı</button>
    <button class="nv" data-g="sahne">🎭 Sahne kumandası</button>
    <button class="nv" data-g="ekipyon">🧑‍🤝‍🧑 Ekip yöneticileri</button>
    <span class="sp"></span>
    <button class="nv" data-g="gorunum">🎨 Görünüm</button><button class="nv" data-g="yardim">❓ Yardım</button>
    <a class="nv btn" href="/" style="justify-content:flex-start;color:var(--ink-2)">↗ Siteyi aç</a>
    <button class="nv" id="cikis">⎋ Çıkış (${esc((kullanici.email || '').split('@')[0])})</button></aside>
    <main class="adm-main" id="ana"></main></div>`;
  $$('.nv[data-g]').forEach((b) => b.addEventListener('click', () => { gorunum = b.dataset.g; arama = ''; goster(); }));
  $('#cikis').addEventListener('click', () => signOut(auth));
  goster();
}
function goster() {
  $$('.nv[data-g]').forEach((b) => b.classList.toggle('on', b.dataset.g === gorunum));
  const m = $('#ana');
  if (gorunum === 'ozet') return ozet(m);
  if (gorunum === 'biletler') return biletKapi(m, { veri, bildir, hataMesaji });
  if (gorunum === 'sahne') return sahneKumandasi(m, { veri, bildir, hataMesaji });
  if (gorunum === 'ekipyon') return ekipYoneticileri(m, { veri, bildir, hataMesaji });
  if (gorunum === 'gorunum') return gorunumAyari(m);
  if (gorunum === 'yardim') return yardim(m);
  return liste(m, gorunum);
}

// ---------- genel bakış ----------
// Üstte DASHBOARD (istatistik, dashboard.js); altta içerik sayıları + hızlı işlemler.
async function ozet(m) {
  const now = new Date();
  const yaklasan = veri.Event.filter((e) => { const d = tarihAyristir(e.date); return d && d >= now; }).length;
  const eksik = veri.Show.filter((s) => !s.imageUrl || !s.description).length;
  m.innerHTML = `<div id="dash"></div>
    <div class="adm-top" style="margin-top:34px"><h2 style="font-size:24px;margin:0">İçerik</h2><button class="btn btn-ghost btn-sm" id="yenile">İçeriği yenile</button></div>
    <div class="stats">${Object.entries(KOLEKSIYONLAR).map(([k, c]) => `<button class="stat" data-g="${k}"><b>${veri[k].length}</b><span>${c.ikon} ${c.ad}</span></button>`).join('')}
    <button class="stat" data-g="Event"><b>${yaklasan}</b><span>⏳ Yaklaşan seans</span></button>
    <button class="stat" data-g="Show"><b>${eksik}</b><span>⚠️ Afişi/açıklaması eksik oyun</span></button></div>
    <h2 style="margin:34px 0 14px;font-size:24px">Hızlı işlemler</h2>
    <div class="tools"><button class="btn btn-primary" data-yeni="Show">+ Oyun ekle</button><button class="btn btn-ghost" data-yeni="Event">+ Seans ekle</button><button class="btn btn-ghost" data-yeni="Stage">+ Sahne ekle</button><button class="btn btn-ghost" data-yeni="Campaign">+ Kampanya ekle</button></div>`;
  dashboard($('#dash', m), { veri, bildir, hataMesaji });
  $$('.stat', m).forEach((b) => b.addEventListener('click', () => { gorunum = b.dataset.g; goster(); }));
  $$('[data-yeni]', m).forEach((b) => b.addEventListener('click', () => form(b.dataset.yeni)));
  $('#yenile').addEventListener('click', async () => { await hepsiniYukle(); goster(); bildir('Güncellendi'); });
}

// ---------- liste ----------
function hucre(c, k, x) {
  const v = x[k];
  if (k === 'imageUrl') return v ? `<img src="${esc(v)}" alt="" loading="lazy">` : '—';
  if (k === 'showId') return esc(adBul('Show', v));
  if (k === 'stageId') return esc(adBul('Stage', v));
  if (k === 'date') { const d = tarihAyristir(v); return `${esc(v)} ${d && d < new Date() ? '<span class="tag warn">Geçti</span>' : '<span class="tag ok">Yaklaşan</span>'}`; }
  if (k === 'price') return v === '0' ? 'Ücretsiz' : v ? `${esc(v)} ₺` : '—';
  return esc(v ?? '—');
}
function liste(m, c) {
  const S = KOLEKSIYONLAR[c];
  let satirlar = veri[c].slice();
  const q = arama.toLocaleLowerCase('tr');
  if (q) satirlar = satirlar.filter((x) => JSON.stringify([S.baslik(x), x.category, x.address, adBul('Show', x.showId), adBul('Stage', x.stageId)]).toLocaleLowerCase('tr').includes(q));
  if (c === 'Event') satirlar.sort((a, b) => (tarihAyristir(b.date) || 0) - (tarihAyristir(a.date) || 0));
  m.innerHTML = `<div class="adm-top"><h1>${S.ikon} ${S.ad} <span class="muted" style="font-size:.5em">${veri[c].length}</span></h1><button class="btn btn-primary" id="yeni">+ ${S.tek} ekle</button></div>
    <div class="tools"><input class="in" id="ara" type="search" placeholder="Ara…" value="${esc(arama)}"></div>
    <div class="tbl-wrap"><table class="tbl"><thead><tr>${S.sutunlar.map((k) => `<th>${SUTUN_ADI[k] ?? k}</th>`).join('')}<th></th></tr></thead>
    <tbody>${satirlar.map((x) => `<tr>${S.sutunlar.map((k) => `<td>${hucre(c, k, x)}</td>`).join('')}<td><div class="acts"><button class="btn btn-ghost btn-sm" data-d="${esc(x.docId)}">Düzenle</button><button class="btn btn-ghost btn-sm" data-s="${esc(x.docId)}" aria-label="Sil">Sil</button></div></td></tr>`).join('') || `<tr><td colspan="9"><div class="empty">Kayıt yok.</div></td></tr>`}</tbody></table></div>`;
  $('#yeni').addEventListener('click', () => form(c));
  $('#ara').addEventListener('input', debounce((e) => { arama = e.target.value; liste(m, c); $('#ara').focus(); $('#ara').setSelectionRange(arama.length, arama.length); }, 180));
  $$('[data-d]', m).forEach((b) => b.addEventListener('click', () => form(c, veri[c].find((x) => x.docId === b.dataset.d))));
  $$('[data-s]', m).forEach((b) => b.addEventListener('click', () => sil(c, veri[c].find((x) => x.docId === b.dataset.s))));
}

// ---------- form ----------
/** Harici bağlantı alanları: yalnız https:// (http, javascript:, data: vb. reddedilir). */
export const httpsGecerli = (v) => { try { return new URL(v).protocol === 'https:'; } catch { return false; } };
const ONAY_ACIK = /^(evet|true|1|e)$/i;
function alanHtml(c, a, x) {
  const h = alanHtml0(c, a, x);
  if (!a.ipucu || a.t === 'img') return h;
  if (a.t === 'secenekler') return h.replace('</legend>', `</legend><span class="hint" id="f_${a.k}_h" style="display:block;margin-bottom:8px">${esc(a.ipucu)}</span>`);
  const i = h.lastIndexOf('</div>');
  return h.slice(0, i) + `<span class="hint" id="f_${a.k}_h">${esc(a.ipucu)}</span>` + h.slice(i);
}
function alanHtml0(c, a, x) {
  const v = x?.[a.k];
  const id = `f_${a.k}`;
  const tam = a.tam ? ' full' : '';
  const L = `<label for="${id}">${a.e}${a.zorunlu ? ' *' : ''}</label>`;
  switch (a.t) {
    case 'area': return `<div class="fld-in${tam}">${L}<textarea id="${id}">${esc(v ?? '')}</textarea></div>`;
    case 'img': return `<div class="fld-in${tam}">${L}<div class="img-row">${v ? `<img src="${esc(v)}" alt="" id="${id}_p">` : `<img id="${id}_p" style="display:none" alt="">`}<div style="flex:1;display:grid;gap:8px"><input id="${id}" type="url" placeholder="https://…" value="${esc(v ?? '')}"><input type="file" accept="image/*" data-up="${id}"></div></div><span class="hint">Adres yapıştır ya da dosya yükle (Firebase Storage).</span></div>`;
    case 'sel': return `<div class="fld-in${tam}">${L}<select id="${id}"><option value="">— Seç —</option>${adlari(a.kaynak).sort((p, q) => p.ad.localeCompare(q.ad, 'tr')).map((o) => `<option value="${esc(o.id)}" ${(v === o.id || v === o.docId) ? 'selected' : ''}>${esc(o.ad)}</option>`).join('')}</select></div>`;
    case 'multi': { const secili = new Set(Array.isArray(v) ? v : []); return `<div class="fld-in${tam}">${L}<div class="multi" id="${id}">${adlari(a.kaynak).sort((p, q) => p.ad.localeCompare(q.ad, 'tr')).map((o) => `<label><input type="checkbox" value="${esc(o.id)}" ${secili.has(o.id) ? 'checked' : ''}>${esc(o.ad)}</label>`).join('') || '<span class="hint">Henüz kayıt yok.</span>'}</div></div>`; }
    case 'secenekler': {
      const bilinen = new Set(a.secenekler.map((o) => o.kod));
      const liste = (Array.isArray(v) ? v : []).map((k) => String(k).trim());
      const secili = new Set(liste.map((k) => k.toUpperCase()));
      const diger = liste.filter((k) => k && !bilinen.has(k.toUpperCase()));
      return `<fieldset class="fld-in${tam} opts" id="${id}"><legend>${a.e}</legend>${a.secenekler.map((o) => `<label class="opt"><input type="checkbox" value="${esc(o.kod)}" ${secili.has(o.kod) ? 'checked' : ''}><span><b>${esc(o.ad)}</b><small>${esc(o.acik)}</small></span></label>`).join('')}
        <div class="opt-other"><label for="${id}_diger">Diğer kodlar</label><input id="${id}_diger" type="text" value="${esc(diger.join(', '))}" placeholder="Boş bırakabilirsin"><small>Eski kayıtlardan kalan kodlar burada korunur; virgülle ayır.</small></div></fieldset>`;
    }
    case 'onay': return `<div class="fld-in${tam}"><label for="${id}">${a.e}</label><label class="opt single"><input id="${id}" type="checkbox" ${ONAY_ACIK.test(String(v ?? '').trim()) ? 'checked' : ''}><span><b>${esc(a.onayMetin)}</b></span></label></div>`;
    case 'lines': return `<div class="fld-in${tam}">${L}<textarea id="${id}">${esc((Array.isArray(v) ? v : []).join('\n'))}</textarea></div>`;
    case 'odul': return `<div class="fld-in${tam}">${L}<textarea id="${id}" placeholder="2013 | Yılın En Başarılı Erkek Oyuncusu | Pippa oyunundaki performansı">${esc((Array.isArray(v) ? v : []).map((x) => (x && typeof x === 'object') ? [x.year || '', x.title || '', x.detail || ''].join(' | ') : String(x)).join('\n'))}</textarea><span class="hint">Mobil uygulamayla aynı biçimde (yıl, başlık, detay) kaydedilir.</span></div>`;
    case 'dt': return `<div class="fld-in${tam}">${L}<input id="${id}" type="datetime-local" value="${dtLokalden(v)}"></div>`;
    case 'day': return `<div class="fld-in${tam}">${L}<input id="${id}" type="date" value="${gunYaz(v)}"></div>`;
    case 'num': return `<div class="fld-in${tam}">${L}<input id="${id}" type="number" step="any" value="${v ?? ''}"></div>`;
    case 'https': return `<div class="fld-in${tam}">${L}<input id="${id}" type="url" inputmode="url" placeholder="https://…" value="${esc(v ?? '')}"></div>`;
    default: return `<div class="fld-in${tam}">${L}<input id="${id}" type="text" value="${esc(v ?? '')}" ${a.liste ? `list="dl_${a.liste}"` : ''}>${a.liste === 'turler' ? `<datalist id="dl_turler">${[...new Set(veri.Show.map((s) => s.category).filter(Boolean))].map((t) => `<option value="${esc(t)}">`).join('')}</datalist>` : ''}</div>`;
  }
}
function form(c, x = null) {
  const S = KOLEKSIYONLAR[c];
  const bg = document.createElement('div'); bg.className = 'modal-bg';
  bg.innerHTML = `<form class="modal"><h2>${x ? `${S.tek} düzenle` : `Yeni ${S.tek.toLowerCase()}`}</h2><div class="form-grid">${S.alanlar.map((a) => alanHtml(c, a, x)).join('')}</div>
    <div class="modal-act"><button type="button" class="btn btn-ghost" data-i>Vazgeç</button><button class="btn btn-primary" type="submit">Kaydet</button></div></form>`;
  document.body.append(bg);
  const kapat = () => bg.remove();
  bg.querySelector('[data-i]').addEventListener('click', kapat);
  bg.addEventListener('mousedown', (e) => { if (e.target === bg) kapat(); });
  bg.querySelectorAll('[data-up]').forEach((inp) => inp.addEventListener('change', async () => {
    const f = inp.files[0]; if (!f) return;
    try {
      bildir('Yükleniyor…');
      const yol = `images/${c}/${Date.now()}-${f.name.replace(/[^\w.\-]+/g, '_')}`;
      const r = sRef(storage, yol); await uploadBytes(r, f);
      const url = await getDownloadURL(r);
      bg.querySelector('#' + inp.dataset.up).value = url;
      const p = bg.querySelector('#' + inp.dataset.up + '_p'); p.src = url; p.style.display = '';
      bildir('Görsel yüklendi');
    } catch (e) { bildir('Yükleme başarısız: ' + hataMesaji(e), true); }
  }));
  bg.querySelector('form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const veriObj = {};
    for (const a of S.alanlar) {
      const el = bg.querySelector('#f_' + a.k);
      let v;
      if (a.t === 'secenekler') {
        const sec = [...el.querySelectorAll('input[type=checkbox]:checked')].map((i) => i.value);
        const diger = bg.querySelector('#f_' + a.k + '_diger').value.split(/[,;]/).map((t) => t.trim()).filter(Boolean);
        v = [...new Set([...sec, ...diger])];
      } else if (a.t === 'onay') v = el.checked ? a.onayDeger : '';
      else if (a.t === 'multi') v = [...el.querySelectorAll('input:checked')].map((i) => i.value);
      else if (a.t === 'lines') v = el.value.split('\n').map((s) => s.trim()).filter(Boolean);
      else if (a.t === 'odul') v = el.value.split('\n').map((s) => s.trim()).filter(Boolean).map((s) => { const [y, t, ...r] = s.split('|').map((x) => x.trim()); return t === undefined ? { year: '', title: y, detail: '' } : { year: y, title: t, detail: r.join(' | ') }; });
      else if (a.t === 'dt') v = dtUygulamaya(el.value);
      else if (a.t === 'num') v = el.value === '' ? null : Number(el.value);
      else if (a.t === 'https') {
        v = el.value.trim();
        if (v && !httpsGecerli(v)) { bildir(`${a.e}: yalnızca https:// ile başlayan geçerli bir adres girilebilir.`, true); el.focus(); return; }
      }
      else v = el.value.trim();
      if (a.zorunlu && (v === '' || v == null)) { bildir(`${a.e} zorunlu.`, true); el.focus(); return; }
      veriObj[a.k] = v;
    }
    const btn = bg.querySelector('[type=submit]'); btn.disabled = true; btn.textContent = 'Kaydediliyor…';
    try { await kaydet(c, x, veriObj); kapat(); await hepsiniYukle(); goster(); bildir('Kaydedildi ✓'); }
    catch (er) { console.error(er); bildir(hataMesaji(er), true); btn.disabled = false; btn.textContent = 'Kaydet'; }
  });
}

async function kaydet(c, x, d) {
  const eski = x ? { ...x } : null;
  if (x) {
    await updateDoc(doc(db, c, x.docId), { ...d, _updatedAt: serverTimestamp() });
  } else {
    const ref = doc(collection(db, c));
    const ek = c === 'Event' ? { seats: {} } : {};
    await setDoc(ref, { ...d, ...ek, _id: ref.id, _createdAt: serverTimestamp(), _updatedAt: serverTimestamp() });
    x = { docId: ref.id, id: ref.id };
  }
  // Çift yönlü ilişkiler (uygulama Show.eventsId / Stage.showsId'i yedek olarak okur).
  if (c === 'Event') {
    const sh = (id) => veri.Show.find((s) => s.id === id || s.docId === id), sg = (id) => veri.Stage.find((s) => s.id === id || s.docId === id);
    if (eski && eski.showId && eski.showId !== d.showId && sh(eski.showId)) await updateDoc(doc(db, 'Show', sh(eski.showId).docId), { eventsId: arrayRemove(x.id) });
    if (sh(d.showId)) await updateDoc(doc(db, 'Show', sh(d.showId).docId), { eventsId: arrayUnion(x.id) });
    if (sg(d.stageId) && sh(d.showId)) await updateDoc(doc(db, 'Stage', sg(d.stageId).docId), { showsId: arrayUnion(sh(d.showId).id) });
  }
  // Oyuncu <-> oyun ilişkisi: oyuncu formundan seçilen oyunlara oyuncu eklenir/çıkarılır.
  if (c === 'Player') {
    const pid = x.id;
    for (const s of veri.Show) {
      const simdi = new Set(s.nowPlayersId || []), eskiS = new Set(s.oldPlayersId || []);
      const nowOlsun = d.nowShowsId.includes(s.id), oldOlsun = d.oldShowsId.includes(s.id);
      const degisti = simdi.has(pid) !== nowOlsun || eskiS.has(pid) !== oldOlsun;
      if (!degisti) continue;
      nowOlsun ? simdi.add(pid) : simdi.delete(pid); oldOlsun ? eskiS.add(pid) : eskiS.delete(pid);
      await updateDoc(doc(db, 'Show', s.docId), { nowPlayersId: [...simdi], oldPlayersId: [...eskiS] });
    }
  }
}

async function sil(c, x) {
  const S = KOLEKSIYONLAR[c];
  const alan = { Show: 'showId', Stage: 'stageId', Event: 'eventId' }[c];
  try {
    if (alan) {
      const n = (await getCountFromServer(query(collection(db, 'Ticket'), where(alan, '==', x.id)))).data().count;
      if (n > 0) return bildir(`Bu ${S.tek.toLowerCase()} için ${n} bilet var; silinemez (biletler geçmişte buradan okunur).`, true);
    }
  } catch (e) { return bildir(hataMesaji(e), true); }
  if (!confirm(`“${S.baslik(x)}” kalıcı olarak silinsin mi? Bu işlem geri alınamaz.`)) return;
  try {
    await deleteDoc(doc(db, c, x.docId));
    if (c === 'Event' && x.showId) { const s = veri.Show.find((y) => y.id === x.showId); if (s) await updateDoc(doc(db, 'Show', s.docId), { eventsId: arrayRemove(x.id) }); }
    await hepsiniYukle(); goster(); bildir('Silindi');
  } catch (e) { bildir(hataMesaji(e), true); }
}

// ---------- görünüm ----------
function gorunumAyari(m) {
  const ciz = () => {
    const s = temaOku();
    m.innerHTML = `<div class="adm-top"><h1>🎨 Görünüm</h1></div><div class="help-box" style="max-width:520px">
      <p class="muted">Panel ve site aynı tema ayarını kullanır; seçim bu tarayıcıda saklanır.</p>
      <div class="drawer" style="position:static;transform:none;width:auto;padding:0;border:0;background:none">
      <div class="grp"><b>Mod</b><div class="seg">${[['sistem', 'Sistem'], ['gunduz', 'Gündüz'], ['gece', 'Gece']].map(([k, a]) => `<button data-mod="${k}" class="${s.mod === k ? 'on' : ''}">${a}</button>`).join('')}</div></div>
      <div class="grp"><b>Renk paleti</b><div class="swatches">${temaSecenekleri.map((p) => `<button class="sw ${s.palet === p.id ? 'on' : ''}" data-pal="${p.id}"><i style="background:${p.renk}"></i>${p.ad}</button>`).join('')}
      <button class="sw ${s.palet === 'ozel' ? 'on' : ''}" data-pal="ozel"><i style="background:${s.ozel}"></i>Özel renk</button></div>
      ${s.palet === 'ozel' ? `<input type="color" id="ozel" value="${s.ozel}" style="margin-top:10px">` : ''}</div></div></div>`;
    $$('[data-mod]', m).forEach((b) => b.addEventListener('click', () => { temaYaz({ mod: b.dataset.mod }); ciz(); }));
    $$('[data-pal]', m).forEach((b) => b.addEventListener('click', () => { temaYaz({ palet: b.dataset.pal }); ciz(); }));
    $('#ozel', m)?.addEventListener('input', (e) => temaYaz({ palet: 'ozel', ozel: e.target.value }));
  };
  ciz();
}

// ---------- yardım ----------
function yardim(m) {
  m.innerHTML = `<div class="adm-top"><h1>❓ Yardım</h1></div>
  <div class="help-box" style="max-width:820px">
    <h3>Bu panele nasıl girilir?</h3>
    <p>Adres: <code>${esc(location.origin)}/yonetim</code>. Site yayınlandığında alan adının sonuna <code>/yonetim</code> yazman yeterli. Panel arama motorlarına kapalıdır (<code>noindex</code>) ve sitede görünür bir bağlantısı yoktur (altbilgideki küçük "Yönetim" bağlantısı hariç).</p>
    <h3 style="margin-top:22px">Kendini yönetici yapma (bir kez)</h3>
    <ol><li>Mobil uygulamada ya da bu panelde Google ile bir kez giriş yap; <code>User</code> koleksiyonunda hesabın belgesi oluşur.</li>
    <li>Firebase Console → Firestore → <code>User</code> → kendi belgen (belge kimliği = uid).</li><li><code>role</code> alanını <code>admin</code> yap.</li></ol>
    <p class="muted">Güvenlik gereği kimse kendi rolünü uygulamadan değiştiremez (<code>firestore.rules</code>).</p>
    <h3 style="margin-top:22px">Güvenlik kontrol listesi</h3>
    <ul><li><b>Kuralları yayınla:</b> <code>firebase deploy --only firestore:rules</code> — yayınlanmazsa veritabanı herkese açık kalabilir.</li>
    <li>Firebase Console → Authentication → Ayarlar → Yetkili alan adları: sitenin alan adını ekle.</li>
    <li>Authentication → Oturum açma yöntemi: E-posta/Şifre ve Google etkin olmalı.</li>
    <li>Storage kuralları: <code>images/**</code> yoluna yalnızca admin yazabilmeli.</li></ul>
    <h3 style="margin-top:22px">Veri nasıl çalışır?</h3>
    <p>Panel, mobil uygulamayla aynı Firestore koleksiyonlarını düzenler. Seans eklediğinde oyunun <code>eventsId</code> ve sahnenin <code>showsId</code> listeleri de güncellenir. Tarihi geçen seanslar silinmez; oyun "bitti" sayılır. Bileti olan oyun/sahne/seans silinemez.</p>
  </div>`;
}
