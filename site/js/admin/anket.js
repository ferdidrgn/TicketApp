// Yönetim paneli — "Anket": oluştur (soru + 2-6 seçenek, opsiyonel oyun bağlantısı, tarih aralığı), kapat/yeniden aç, sonuçları gör.
// Yazma YALNIZ adminCreatePoll / adminClosePoll callable'larıyla (Poll istemci yazımına kapalı); okuma Poll (herkese açık). docs/ANKET-PLAN.md
import { db, fonksiyon, collection, getDocs, query, limit } from '../firebase.js';
import { $, $$, esc } from '../util.js';

const cagir = async (ad, veri) => (await (await fonksiyon(ad))(veri)).data;
const ms = (t) => (t && t.toMillis ? t.toMillis() : null);
const tarih = (t) => (ms(t) ? new Date(ms(t)).toLocaleString('tr-TR', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : '—');
const yerel = (d) => new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 16);

export function anket(m, { veri, bildir, hataMesaji }) {
  const oyunlar = (veri.Show || []).slice().sort((a, b) => String(a.name).localeCompare(String(b.name), 'tr'));
  const secenekSatiri = (i) => `<div class="acts" style="margin-bottom:6px"><input data-l maxlength="60" placeholder="Seçenek ${i + 1}${i < 2 ? '' : ' (isteğe bağlı)'}" aria-label="Seçenek ${i + 1}" style="flex:1;min-width:140px">
    <select data-s aria-label="Seçenek ${i + 1} oyun bağlantısı"><option value="">Oyun bağlama</option>${oyunlar.map((s) => `<option value="${esc(s.docId || s.id)}">${esc(s.name)}</option>`).join('')}</select></div>`;
  const simdi = new Date(), bitis = new Date(simdi.getTime() + 7 * 864e5);
  m.innerHTML = `<div class="adm-top"><h1>📊 Anket</h1></div>
    <section class="bk-card"><h2 style="margin-top:0">Yeni anket</h2>
      <p class="muted">Anket "TiyatRol anketi" olarak yayınlanır; oy vermek giriş + doğrulanmış telefon gerektirir (hesap/telefon başına tek oy). Oluşturduktan sonra metin değiştirilemez; kapatabilirsin.</p>
      <label>Soru <input id="an-soru" maxlength="140" style="width:100%" placeholder="Örn. Sonraki sezon hangisi?"></label>
      <div style="margin:10px 0">${[0, 1, 2, 3, 4, 5].map(secenekSatiri).join('')}</div>
      <div class="acts"><label>Başlangıç <input type="datetime-local" id="an-bas" value="${yerel(simdi)}"></label><label>Bitiş <input type="datetime-local" id="an-bit" value="${yerel(bitis)}"></label></div>
      <p class="tiny" id="an-d" role="status"></p><button class="btn btn-primary" id="an-kaydet">Anketi yayınla</button></section>
    <section class="bk-card" id="an-liste" aria-live="polite"></section>`;
  const kap = $('#an-liste', m);

  async function yukle() {
    kap.innerHTML = '<div class="skel" style="height:80px"></div>';
    try {
      const l = (await getDocs(query(collection(db, 'Poll'), limit(100)))).docs.map((d) => ({ id: d.id, ...d.data() })).sort((a, b) => (ms(b.createdAt) || 0) - (ms(a.createdAt) || 0));
      const now = Date.now();
      kap.innerHTML = `<h2 style="margin-top:0">Anketler</h2>` + (l.length ? l.map((p) => {
        const acik = p.status === 'active' && (ms(p.endsAt) || 0) > now, top = p.totalVotes || 0;
        return `<div class="yorum" data-id="${esc(p.id)}"><div><b>${esc(p.question)}</b> · <span class="tag ${acik ? 'ok' : 'warn'}">${acik ? 'Açık' : p.status === 'closed' ? 'Kapalı' : 'Bitti'}</span> · ${esc(tarih(p.startsAt))} → ${esc(tarih(p.endsAt))} · ${top} oy</div>
          <ul>${p.options.map((o) => { const n = (p.counts || {})[o.id] || 0; return `<li>${esc(o.label)} — ${n} (%${top ? Math.round((n / top) * 100) : 0})</li>`; }).join('')}</ul>
          <div class="acts">${acik ? '<button class="btn btn-sm btn-ghost" data-a="kapat">Kapat</button>' : (p.status === 'closed' && (ms(p.endsAt) || 0) > now ? '<button class="btn btn-sm btn-ghost" data-a="ac">Yeniden aç</button>' : '')}</div></div>`;
      }).join('') : '<div class="empty">Henüz anket yok.</div>');
      $$('[data-a]', kap).forEach((b) => b.addEventListener('click', async () => {
        b.disabled = true;
        try { await cagir('adminClosePoll', { pollId: b.closest('[data-id]').dataset.id, reopen: b.dataset.a === 'ac' }); bildir('Kaydedildi'); yukle(); } catch (e) { b.disabled = false; bildir(hataMesaji(e), true); }
      }));
    } catch (e) { kap.innerHTML = `<div class="bk-alert" role="alert">${esc(hataMesaji(e))}</div>`; }
  }

  $('#an-kaydet', m).addEventListener('click', async (ev) => {
    const b = ev.currentTarget, d = $('#an-d', m);
    const secenekler = $$('[data-l]', m).map((i, k) => ({ label: i.value.trim(), showId: $$('[data-s]', m)[k].value })).filter((o) => o.label);
    b.disabled = true; d.textContent = 'Kaydediliyor…';
    try {
      await cagir('adminCreatePoll', {
        question: $('#an-soru', m).value, options: secenekler.map((o) => (o.showId ? o : { label: o.label })),
        startsAt: new Date($('#an-bas', m).value).toISOString(), endsAt: new Date($('#an-bit', m).value).toISOString(),
      });
      d.textContent = 'Anket yayınlandı.'; bildir('Anket yayınlandı'); $('#an-soru', m).value = ''; $$('[data-l]', m).forEach((i) => { i.value = ''; }); yukle();
    } catch (e) { d.textContent = hataMesaji(e); }
    b.disabled = false;
  });
  yukle();
}
