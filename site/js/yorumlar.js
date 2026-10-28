// Oyun sayfası "Yorumlar" bölümü (Q-1/M-1): doğrulanmış izleyici yorumları + şikâyet/engelle + yazma formu.
// Yazma/şikâyet/engelleme YALNIZ sunucu callable'larıyla (submitReview / reportContent / blockUser / canReview); istemci Review'a yazamaz.
// Yorum hakkı sunucuda denetlenir (telefon + o oyunun geçmiş bileti); buradaki kontroller yalnız açıklama içindir. docs/UGC-KURALLARI.md
import { auth, db, fonksiyon, collection, getDocs } from './firebase.js';
import { girisGerekli, telefonGerekli, oturumDinle } from './auth.js';
import { apiHata } from './bilet-api.js';
import { $, $$, esc, tarihUzun } from './util.js';

const yil = (n) => '★'.repeat(n) + '☆'.repeat(5 - n);
const SAYFA = 10;
const NEDENLER = [['spam', 'Spam / reklam'], ['hakaret', 'Hakaret / küfür'], ['nefret', 'Nefret söylemi'], ['uygunsuz', 'Uygunsuz içerik'], ['kisisel_bilgi', 'Kişisel bilgi paylaşımı'], ['diger', 'Diğer']];
const HAK_METNI = {
  NOT_VERIFIED_ATTENDEE: 'Yorum yazabilmek için bu oyunu izlemiş olman gerekir. Biletin olan ve seansı geçmiş oyunlara yorum yazabilirsin.',
  PHONE_REQUIRED: 'Yorum yazabilmek için telefon numaranı doğrulaman gerekir.',
  ACCOUNT_DELETION_PENDING: 'Hesabın silinme sürecinde olduğu için yorum yazamazsın.',
};

async function cagir(ad, veri) {
  try { return (await (await fonksiyon(ad))(veri)).data; } catch (e) {
    const h = apiHata(e); h.detay = e?.details?.code || ''; throw h;
  }
}

/** Yorum bölümü iskeleti (özet + liste + boş form kabuğu). Bağlama: yorumlarBaglan. */
export function yorumlarHtml(s) {
  const n = s.ratingCount;
  const ozet = n ? `<div class="yorum-ozet"><div><div class="buyuk">${s.ratingAvg.toFixed(1)}</div><div class="yil" aria-label="${s.ratingAvg.toFixed(1)} yıldız">${yil(Math.round(s.ratingAvg))}</div><div class="tiny">${n} yorum</div></div>
      <div class="dag">${s.ratingDist.map((c, i) => `<div><span>${5 - i}</span><i><b style="width:${(c / n) * 100}%"></b></i><span>${c}</span></div>`).join('')}</div></div>` : '';
  return `${ozet}<div id="yorum-form" class="yorum-form" aria-live="polite"></div><div id="yorum-liste"></div><div id="yorum-daha"></div>
    <p class="tiny" style="margin-top:14px">Yorumlar yalnızca oyunu izlemiş (bileti olan) ve telefonu doğrulanmış kişilerce yazılabilir. <a href="/topluluk-kurallari">Topluluk kuralları</a></p>`;
}

async function engelListesi(uid) {
  if (!uid) return new Set();
  try { return new Set((await getDocs(collection(db, 'User', uid, 'blocks'))).docs.map((d) => d.id)); } catch { return new Set(); }
}

function yorumSatiri(r, ben) {
  const benimki = ben && r.userId === ben;
  return `<div class="yorum" data-rid="${esc(r.docId)}" data-uid="${esc(r.userId || '')}">
    <div class="yorum-ust"><div><b>${esc(r.userName || 'Seyirci')}</b>${r.verified ? ' <span class="dogrulandi" title="Bu oyunun bileti olan, telefonu doğrulanmış izleyici">Doğrulanmış izleyici</span>' : ''} <span class="yil" aria-label="${r.rating} yıldız">${yil(r.rating)}</span>${r.tarih ? ` <span class="tiny">· ${tarihUzun(r.tarih)}</span>` : ''}</div>
      ${benimki ? '' : `<button type="button" class="yorum-menu-d" aria-haspopup="true" aria-expanded="false" aria-label="Yorum seçenekleri: ${esc(r.userName || 'Seyirci')}">⋯</button>`}</div>
    ${r.text ? `<p>${esc(r.text)}</p>` : ''}<div class="yorum-menu" hidden></div></div>`;
}

/** Bölümü canlı hale getirir: liste (engellenenler gizli), daha fazla, şikâyet/engelle, yazma formu, ?yorum=1 kaydırması. */
export async function yorumlarBaglan(s) {
  const liste = $('#yorum-liste'), daha = $('#yorum-daha'), form = $('#yorum-form');
  if (!liste) return;
  let engelli = new Set(), gorunen = SAYFA, kullanici = auth.currentUser;
  const hepsi = () => (s.reviews || []).filter((r) => !engelli.has(r.userId));

  const cizListe = () => {
    const l = hepsi();
    liste.innerHTML = l.length ? l.slice(0, gorunen).map((r) => yorumSatiri(r, kullanici?.uid)).join('') : (s.ratingCount ? '' : '<div class="empty"><h3>Henüz yorum yok</h3><p>İlk yorumu bu oyunu izledikten sonra sen yazabilirsin.</p></div>');
    daha.innerHTML = l.length > gorunen ? `<button type="button" class="btn btn-ghost btn-sm" id="yorum-daha-b">Daha fazla yorum (${l.length - gorunen})</button>` : '';
    $('#yorum-daha-b')?.addEventListener('click', () => { gorunen += SAYFA; cizListe(); });
    $$('.yorum-menu-d', liste).forEach((b) => b.addEventListener('click', () => menuAc(b.closest('.yorum'), b)));
  };

  function menuAc(satir, dugme) {
    const m = $('.yorum-menu', satir);
    if (!m.hidden) { m.hidden = true; dugme.setAttribute('aria-expanded', 'false'); return; }
    dugme.setAttribute('aria-expanded', 'true'); m.hidden = false;
    m.innerHTML = '<button type="button" class="btn btn-ghost btn-sm" data-sik>Şikâyet et</button> <button type="button" class="btn btn-ghost btn-sm" data-engel>Bu kullanıcıyı engelle</button>';
    $('[data-sik]', m).addEventListener('click', () => sikayetFormu(satir, m));
    $('[data-engel]', m).addEventListener('click', () => engelle(satir, m));
  }
  async function girisYap(neden) { const u = await girisGerekli(neden); kullanici = u || auth.currentUser; return u; }

  async function sikayetFormu(satir, m) {
    if (!(await girisYap('Şikâyet etmek için giriş yap.'))) return;
    m.innerHTML = `<form class="yorum-sikayet" novalidate><label>Şikâyet nedeni <select name="neden">${NEDENLER.map(([k, v]) => `<option value="${k}">${v}</option>`).join('')}</select></label>
      <label>Açıklama (isteğe bağlı) <input name="detay" maxlength="200"></label><div class="yorum-eylem"><button class="btn btn-primary btn-sm" type="submit">Şikâyeti gönder</button> <button class="btn btn-ghost btn-sm" type="button" data-iptal>Vazgeç</button></div><p class="tiny" data-m role="status"></p></form>`;
    $('[data-iptal]', m).addEventListener('click', () => { m.hidden = true; });
    $('form', m).addEventListener('submit', async (ev) => {
      ev.preventDefault();
      const f = ev.currentTarget, durum = $('[data-m]', m), b = $('button[type=submit]', f);
      b.disabled = true; durum.textContent = 'Gönderiliyor…';
      try {
        const r = await cagir('reportContent', { type: 'review', id: satir.dataset.rid, reason: f.neden.value, detail: f.detay.value.trim() });
        durum.textContent = r.hidden ? 'Teşekkürler. Yorum incelenmek üzere gizlendi.' : r.already ? 'Bu yorumu zaten şikâyet etmiştin.' : 'Teşekkürler. Şikâyetin moderatörlere iletildi.';
      } catch (e) { durum.textContent = e.message; b.disabled = false; }
    });
  }

  async function engelle(satir, m) {
    if (!(await girisYap('Kullanıcı engellemek için giriş yap.'))) return;
    const ad = $('b', satir)?.textContent || 'Bu kullanıcı';
    if (!confirm(`${ad} engellensin mi? Yorumlarını artık görmeyeceksin. (Ayarlar'dan geri alınabilir.)`)) return;
    try {
      await cagir('blockUser', { uid: satir.dataset.uid });
      engelli.add(satir.dataset.uid); cizListe();
    } catch (e) { m.insertAdjacentHTML('beforeend', `<p class="tiny" role="alert">${esc(e.message)}</p>`); }
  }

  // ---- yazma formu ----
  async function cizForm() {
    kullanici = auth.currentUser;
    if (!kullanici) {
      form.innerHTML = `<div class="yorum-hak"><b>Bu oyunu izlediysen yorum yaz.</b><p class="tiny">Yorum yazmak için giriş yapman ve oyunu izlemiş olman gerekir.</p><button type="button" class="btn btn-ghost btn-sm" id="yorum-giris">Giriş yap</button></div>`;
      $('#yorum-giris').addEventListener('click', async () => { if (await girisGerekli('Yorum yazmak için giriş yap.')) cizForm(); });
      return;
    }
    form.innerHTML = '<div class="skel" style="height:56px"></div>';
    let hak;
    try { hak = await cagir('canReview', { showId: s.docId || s.id }); } catch { form.innerHTML = ''; return; }
    if (!hak.canReview) {
      if (hak.existing) { form.innerHTML = ''; return; }
      form.innerHTML = `<div class="yorum-hak"><b>Yorum yazabilmek için bu oyunu izlemiş olman gerekir.</b><p class="tiny">${esc(HAK_METNI[hak.code] || HAK_METNI.NOT_VERIFIED_ATTENDEE)}</p>${hak.code === 'PHONE_REQUIRED' ? '<button type="button" class="btn btn-ghost btn-sm" id="yorum-tel">Telefonunu doğrula</button>' : ''}</div>`;
      $('#yorum-tel')?.addEventListener('click', async () => { if (await telefonGerekli('Yorum için telefonunu doğrula.')) cizForm(); });
      return;
    }
    const var_ = hak.existing || null;
    let puan = var_?.rating || 0;
    form.innerHTML = `<form class="yorum-yaz" novalidate><h3>${var_ ? 'Yorumunu düzenle' : 'Yorumunu yaz'}</h3>
      ${var_?.status === 'pending' ? '<p class="tiny">Yorumun inceleme bekliyor; onaylanınca yayınlanır.</p>' : ''}
      <div class="yildiz-sec" role="radiogroup" aria-label="Puan">${[1, 2, 3, 4, 5].map((n) => `<button type="button" role="radio" aria-checked="${n === puan}" data-p="${n}" aria-label="${n} yıldız">${n <= puan ? '★' : '☆'}</button>`).join('')}</div>
      <label class="sr-only" for="yorum-metin">Yorum metni</label><textarea id="yorum-metin" maxlength="600" rows="4" placeholder="Oyun hakkında ne düşündün? (isteğe bağlı, en fazla 600 karakter)">${esc(var_?.text || '')}</textarea>
      <div class="yorum-alt"><span class="tiny" id="yorum-say"></span><span class="tiny">Bağlantı, telefon ve e-posta yazılamaz. <a href="/topluluk-kurallari">Topluluk kuralları</a></span></div>
      <div class="yorum-eylem"><button class="btn btn-primary" type="submit">${var_ ? 'Güncelle' : 'Yorumu gönder'}</button>${var_ ? ' <button type="button" class="btn btn-ghost" id="yorum-sil">Yorumumu sil</button>' : ''}</div><p class="tiny" id="yorum-durum" role="status"></p></form>`;
    const f = $('form', form), ta = $('#yorum-metin'), say = $('#yorum-say'), durum = $('#yorum-durum');
    const sayGuncelle = () => { say.textContent = `${ta.value.length}/600`; }; sayGuncelle(); ta.addEventListener('input', sayGuncelle);
    $$('[data-p]', f).forEach((b) => b.addEventListener('click', () => { puan = +b.dataset.p; $$('[data-p]', f).forEach((x) => { x.textContent = +x.dataset.p <= puan ? '★' : '☆'; x.setAttribute('aria-checked', String(+x.dataset.p === puan)); }); }));
    f.addEventListener('submit', async (ev) => {
      ev.preventDefault();
      if (!puan) { durum.textContent = 'Önce bir puan seç.'; return; }
      const b = $('button[type=submit]', f); b.disabled = true; durum.textContent = 'Gönderiliyor…';
      try {
        const r = await cagir('submitReview', { showId: s.docId || s.id, rating: puan, text: ta.value });
        durum.textContent = r.pending ? 'Teşekkürler! Yorumun incelendikten sonra yayınlanacak.' : 'Teşekkürler! Yorumun kaydedildi. Sayfayı yenilediğinde listede görünür.';
        b.disabled = false;
      } catch (e) { durum.textContent = e.detay && HAK_METNI[e.detay] ? HAK_METNI[e.detay] : e.message; b.disabled = false; }
    });
    $('#yorum-sil')?.addEventListener('click', async () => {
      if (!confirm('Yorumun silinsin mi?')) return;
      try { await cagir('deleteMyReview', { showId: s.docId || s.id }); durum.textContent = 'Yorumun silindi.'; cizForm(); } catch (e) { durum.textContent = e.message; }
    });
    if (new URLSearchParams(location.search).get('yorum') === '1') { form.scrollIntoView({ behavior: matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth', block: 'center' }); ta.focus({ preventScroll: true }); }
  }

  cizListe();
  oturumDinle(async (u) => { kullanici = u; engelli = await engelListesi(u?.uid); cizListe(); cizForm(); });
}
