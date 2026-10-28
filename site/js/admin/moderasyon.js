// Yönetim paneli — "Moderasyon": bekleyen / şikâyetli / gizli yorumlar. İşlemler yalnız adminModerate callable'ıyla (sebep zorunlu,
// ModerationLog'a yazılır; silme yalnız admin). Okuma: Review (admin) ve ModerationLog (yalnız admin). docs/UGC-KURALLARI.md
import { db, fonksiyon, collection, getDocs, query, where, limit } from '../firebase.js';
import { $, $$, esc } from '../util.js';

const cagir = async (ad, veri) => (await (await fonksiyon(ad))(veri)).data;
const tarih = (ts) => (ts && ts.toMillis ? new Date(ts.toMillis()).toLocaleString('tr-TR', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }) : '—');
const DURUM = { pending: 'Bekliyor', hidden: 'Gizli', published: 'Yayında' };
const SEBEP = { pending: 'Süzgeç', reports: 'Şikâyetler', moderator: 'Moderatör' };

export function moderasyon(m, { veri, bildir, hataMesaji }) {
  let sekme = 'kuyruk';
  const oyunAdi = (id) => (veri.Show || []).find((s) => s.docId === id || s.id === id)?.name || id;
  m.innerHTML = `<div class="adm-top"><h1>🛡️ Moderasyon</h1></div>
    <section class="bk-card"><p class="muted" style="margin:0">Bekleyen (süzgece takılan), şikâyetli ve gizli yorumlar. Her işlem için sebep zorunludur ve kayda geçer. Silme geri alınamaz.</p>
    <div class="acts" style="margin-top:10px"><button class="btn btn-sm btn-primary" data-s="kuyruk">Kuyruk</button><button class="btn btn-sm btn-ghost" data-s="gizli">Gizli yorumlar</button><button class="btn btn-sm btn-ghost" data-s="kayit">İşlem kayıtları</button></div></section>
    <section class="bk-card" id="mod-liste" aria-live="polite"></section>`;
  const kap = $('#mod-liste', m);

  async function yukle() {
    kap.innerHTML = '<div class="skel" style="height:80px"></div>';
    try {
      if (sekme === 'kayit') {
        const sn = await getDocs(query(collection(db, 'ModerationLog'), limit(200)));
        const l = sn.docs.map((d) => d.data()).sort((a, b) => (b.at?.toMillis?.() || 0) - (a.at?.toMillis?.() || 0));
        kap.innerHTML = l.length ? `<div class="tbl-wrap"><table class="tbl"><thead><tr><th>Zaman</th><th>Rol</th><th>İşlem</th><th>Oyun</th><th>Sebep</th></tr></thead><tbody>${l.map((x) => `<tr><td>${esc(tarih(x.at))}</td><td>${esc(x.byRole)}</td><td>${esc(x.action)}</td><td>${esc(oyunAdi(x.showId))}</td><td>${esc(x.reason)}</td></tr>`).join('')}</tbody></table></div>` : '<div class="empty">Kayıt yok.</div>';
        return;
      }
      const q = sekme === 'kuyruk' ? query(collection(db, 'Review'), where('queue', '==', true), limit(200)) : query(collection(db, 'Review'), where('hidden', '==', true), limit(200));
      const l = (await getDocs(q)).docs.map((d) => ({ id: d.id, ...d.data() }));
      kap.innerHTML = l.length ? l.map((r) => `<div class="yorum" data-id="${esc(r.id)}"><div><b>${esc(r.userName || 'Seyirci')}</b> · ${esc(oyunAdi(r.showId))} · ${'★'.repeat(r.rating || 0)} · <span class="tag ${r.hidden ? 'warn' : 'ok'}">${esc(DURUM[r.status] || (r.hidden ? 'Gizli' : 'Yayında'))}</span>${r.hiddenReason ? ` <span class="muted">(${esc(SEBEP[r.hiddenReason] || r.hiddenReason)})</span>` : ''} · şikâyet: ${r.reportCount || 0} · ${esc(tarih(r.createdAt))}</div>
        <p>${esc(r.text || '(metin yok)')}</p><div class="acts">${r.hidden ? '<button class="btn btn-sm btn-primary" data-a="restore">Yayınla / geri aç</button>' : '<button class="btn btn-sm btn-ghost" data-a="hide">Gizle</button>'}<button class="btn btn-sm btn-ghost" data-a="delete">Sil</button></div></div>`).join('') : '<div class="empty">Bu listede yorum yok.</div>';
      $$('[data-a]', kap).forEach((b) => b.addEventListener('click', async () => {
        const id = b.closest('[data-id]').dataset.id, a = b.dataset.a;
        const sebep = prompt(`Sebep (zorunlu, 3-200 karakter) — ${a === 'delete' ? 'KALICI SİL' : a === 'hide' ? 'gizle' : 'yayınla'}:`);
        if (!sebep) return;
        if (a === 'delete' && !confirm('Yorum kalıcı olarak silinsin mi?')) return;
        b.disabled = true;
        try { await cagir('adminModerate', { reviewId: id, action: a, reason: sebep }); bildir('İşlem kaydedildi'); yukle(); } catch (e) { b.disabled = false; bildir(hataMesaji(e), true); }
      }));
    } catch (e) { kap.innerHTML = `<div class="bk-alert" role="alert">${esc(hataMesaji(e))}</div>`; }
  }
  $$('[data-s]', m).forEach((b) => b.addEventListener('click', () => { sekme = b.dataset.s; $$('[data-s]', m).forEach((x) => { x.className = `btn btn-sm ${x === b ? 'btn-primary' : 'btn-ghost'}`; }); yukle(); }));
  yukle();
}
