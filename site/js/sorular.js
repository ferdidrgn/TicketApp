// Oyun sayfası "Ekibe sor" bölümü (Q-2): ön onaylı soru-cevap + kural tabanlı SSS botu önerisi. docs/SSS-BOTU.md
// Soru YALNIZ sunucu callable'larıyla yazılır (askQuestion / reportContent / blockUser / myQuestions); istemci Question'a yazamaz.
// Yalnız ekip yanıtlayıp yayınlayınca herkese görünür. Bot cevabı oyunun gerçek alanlarından üretilir (site/js/ssb.js), uydurma yok.
import { auth, db, fonksiyon, collection, getDocs, query, where } from './firebase.js';
import { girisGerekli, telefonGerekli, oturumDinle } from './auth.js';
import { apiHata } from './bilet-api.js';
import { sor, factsOf, YOK } from './ssb.js';
import { $, $$, esc, tarihUzun } from './util.js';

const SAYFA = 5;
const NEDENLER = [['spam', 'Spam / reklam'], ['hakaret', 'Hakaret / küfür'], ['nefret', 'Nefret söylemi'], ['uygunsuz', 'Uygunsuz içerik'], ['kisisel_bilgi', 'Kişisel bilgi paylaşımı'], ['diger', 'Diğer']];
const DURUM = { pending: 'Onay bekliyor', rejected: 'Yayınlanmadı', hidden: 'Gizlendi', answered: 'Yanıtlandı' };

async function cagir(ad, veri) {
  try { return (await (await fonksiyon(ad))(veri)).data; } catch (e) { const h = apiHata(e); h.detay = e?.details?.code || ''; throw h; }
}

export function sorularHtml() {
  return `<p class="tiny" style="margin:0 0 12px">Merak ettiğin bir şeyi ekibe sor. Soruların ekip yanıtladıktan sonra herkese görünür olur.</p>
    <div id="soru-liste"></div><div id="soru-daha"></div><div id="soru-benim" aria-live="polite"></div><div id="soru-form" class="yorum-form" aria-live="polite"></div>
    <p class="tiny" style="margin-top:14px">Bağlantı, telefon ve e-posta yazılamaz. <a href="/topluluk-kurallari">Topluluk kuralları</a></p>`;
}

async function engelAnahtarlari(uid) {
  if (!uid) return new Set();
  try { return new Set((await getDocs(collection(db, 'User', uid, 'blocks'))).docs.map((d) => d.data().askerKey).filter(Boolean)); } catch { return new Set(); }
}

export async function sorularBaglan(s, yer, alan, mod) {
  const liste = $('#soru-liste'), daha = $('#soru-daha'), form = $('#soru-form'), benim = $('#soru-benim');
  if (!liste) return;
  const showId = s.docId || s.id;
  const facts = factsOf(s, yer, { alan, mod });
  let tum = [], engelli = new Set(), gorunen = SAYFA, kullanici = auth.currentUser;

  async function yukle() {
    try {
      const sn = await getDocs(query(collection(db, 'Question'), where('showId', '==', showId), where('status', '==', 'answered'), where('hidden', '==', false)));
      tum = sn.docs.map((d) => ({ id: d.id, ...d.data() })).sort((a, b) => (b.answeredAt?.toMillis?.() || 0) - (a.answeredAt?.toMillis?.() || 0));
    } catch { tum = []; }
    cizListe();
  }
  const satir = (q) => `<div class="yorum" data-qid="${esc(q.id)}"><div class="yorum-ust"><div><b>${esc(q.askerName || 'Seyirci')}</b> <span class="tiny">sordu${q.createdAt?.toMillis ? ` · ${tarihUzun(new Date(q.createdAt.toMillis()))}` : ''}</span></div>
      <button type="button" class="yorum-menu-d" aria-haspopup="true" aria-expanded="false" aria-label="Soru seçenekleri">⋯</button></div>
    <p>${esc(q.text)}</p><p class="soru-cevap"><b>${esc(q.answeredBy || 'Ekip')}:</b> ${esc(q.answer || '')}</p><div class="yorum-menu" hidden></div></div>`;
  function cizListe() {
    const l = tum.filter((q) => !engelli.has(q.askerKey));
    liste.innerHTML = l.length ? l.slice(0, gorunen).map(satir).join('') : '<div class="empty"><h3>Henüz yanıtlanmış soru yok</h3><p>İlk soruyu sen sorabilirsin.</p></div>';
    daha.innerHTML = l.length > gorunen ? `<button type="button" class="btn btn-ghost btn-sm" id="soru-daha-b">Daha fazla soru (${l.length - gorunen})</button>` : '';
    $('#soru-daha-b')?.addEventListener('click', () => { gorunen += SAYFA; cizListe(); });
    $$('.yorum-menu-d', liste).forEach((b) => b.addEventListener('click', () => menuAc(b.closest('.yorum'), b)));
  }

  function menuAc(sat, dugme) {
    const m = $('.yorum-menu', sat);
    if (!m.hidden) { m.hidden = true; dugme.setAttribute('aria-expanded', 'false'); return; }
    dugme.setAttribute('aria-expanded', 'true'); m.hidden = false;
    m.innerHTML = '<button type="button" class="btn btn-ghost btn-sm" data-sik>Şikâyet et</button> <button type="button" class="btn btn-ghost btn-sm" data-engel>Soran kişiyi engelle</button>';
    $('[data-sik]', m).addEventListener('click', () => sikayetFormu(sat, m));
    $('[data-engel]', m).addEventListener('click', () => engelle(sat, m));
  }
  async function giris(neden) { const u = await girisGerekli(neden); kullanici = u || auth.currentUser; return u; }
  async function sikayetFormu(sat, m) {
    if (!(await giris('Şikâyet etmek için giriş yap.'))) return;
    m.innerHTML = `<form class="yorum-sikayet" novalidate><label>Şikâyet nedeni <select name="neden">${NEDENLER.map(([k, v]) => `<option value="${k}">${v}</option>`).join('')}</select></label>
      <label>Açıklama (isteğe bağlı) <input name="detay" maxlength="200"></label><div class="yorum-eylem"><button class="btn btn-primary btn-sm" type="submit">Şikâyeti gönder</button> <button class="btn btn-ghost btn-sm" type="button" data-iptal>Vazgeç</button></div><p class="tiny" data-m role="status"></p></form>`;
    $('[data-iptal]', m).addEventListener('click', () => { m.hidden = true; });
    $('form', m).addEventListener('submit', async (ev) => {
      ev.preventDefault();
      const f = ev.currentTarget, d = $('[data-m]', m), b = $('button[type=submit]', f);
      b.disabled = true; d.textContent = 'Gönderiliyor…';
      try {
        const r = await cagir('reportContent', { type: 'question', id: sat.dataset.qid, reason: f.neden.value, detail: f.detay.value.trim() });
        d.textContent = r.hidden ? 'Teşekkürler. Soru incelenmek üzere gizlendi.' : r.already ? 'Bunu zaten şikâyet etmiştin.' : 'Teşekkürler. Şikâyetin moderatörlere iletildi.';
      } catch (e) { d.textContent = e.message; b.disabled = false; }
    });
  }
  async function engelle(sat, m) {
    if (!(await giris('Kullanıcı engellemek için giriş yap.'))) return;
    if (!confirm('Bu soruyu soran kişi engellensin mi? Sorularını artık görmeyeceksin. (Ayarlar\'dan geri alınabilir.)')) return;
    try { const r = await cagir('blockUser', { questionId: sat.dataset.qid }); engelli.add(r.askerKey); cizListe(); } catch (e) { m.insertAdjacentHTML('beforeend', `<p class="tiny" role="alert">${esc(e.message)}</p>`); }
  }

  async function benimSorular() {
    benim.innerHTML = '';
    if (!kullanici) return;
    try {
      const r = await cagir('myQuestions', { showId });
      const l = r.items.filter((x) => x.status !== 'answered' || !tum.some((t) => t.id === x.id));
      benim.innerHTML = l.length ? `<div class="yorum-hak"><b>Sorularım</b>${l.map((x) => `<div class="yorum"><p>${esc(x.text)}</p><span class="tag ${x.status === 'pending' ? 'warn' : ''}">${esc(DURUM[x.status] || x.status)}</span></div>`).join('')}</div>` : '';
    } catch { /* ek bilgi */ }
  }

  function cizForm() {
    form.innerHTML = `<form class="yorum-yaz" novalidate><h3>Ekibe soru sor</h3>
      <label class="sr-only" for="soru-metin">Sorun</label><textarea id="soru-metin" maxlength="300" rows="3" placeholder="Örn. Çocuğa uygun mu? (en fazla 300 karakter)"></textarea>
      <div id="soru-oneri" aria-live="polite"></div>
      <div class="yorum-alt"><span class="tiny" id="soru-say">0/300</span><span class="tiny">Giriş ve doğrulanmış telefon gerekir.</span></div>
      <div class="yorum-eylem"><button class="btn btn-primary" type="submit">Ekibe sor</button></div><p class="tiny" id="soru-durum" role="status"></p></form>`;
    const f = $('form', form), ta = $('#soru-metin'), onr = $('#soru-oneri'), dur = $('#soru-durum');
    let zam = 0;
    ta.addEventListener('input', () => {
      $('#soru-say').textContent = `${ta.value.length}/300`;
      clearTimeout(zam);
      zam = setTimeout(() => {
        const r = ta.value.trim().length >= 5 ? sor(ta.value, facts) : { intent: '', answer: null };
        onr.innerHTML = r.answer ? `<div class="soru-bot" role="status"><b>Cevap burada olabilir</b><p>${esc(r.answer)}</p><p class="tiny">Bu otomatik bir yanıttır; yetmezse aşağıdan ekibe sorabilirsin.</p></div>` : '';
      }, 250);
    });
    f.addEventListener('submit', async (ev) => {
      ev.preventDefault();
      const metin = ta.value.trim();
      if (metin.length < 5) { dur.textContent = 'Sorun en az 5 karakter olmalı.'; return; }
      if (!(await giris('Soru sormak için giriş yap.'))) return;
      const b = $('button[type=submit]', f); b.disabled = true; dur.textContent = 'Gönderiliyor…';
      try {
        await cagir('askQuestion', { showId, text: metin });
        ta.value = ''; onr.innerHTML = ''; $('#soru-say').textContent = '0/300';
        dur.textContent = 'Teşekkürler! Sorun ekibe iletildi; yanıtlanınca burada yayınlanır.';
        benimSorular();
      } catch (e) {
        if (e.detay === 'PHONE_REQUIRED') { dur.textContent = 'Soru sormak için telefon numaranı doğrulaman gerekir.'; if (await telefonGerekli('Soru için telefonunu doğrula.')) dur.textContent = 'Telefonun doğrulandı, şimdi tekrar gönderebilirsin.'; }
        else dur.textContent = e.message;
      }
      b.disabled = false;
    });
  }

  cizListe(); cizForm(); await yukle();
  oturumDinle(async (u) => { kullanici = u; engelli = await engelAnahtarlari(u?.uid); cizListe(); benimSorular(); });
}
export { YOK };
