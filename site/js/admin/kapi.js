// Yönetim paneli — "Biletler & Kapı": satış modu, bilet listesi, kapı kontrolü, sistem sağlığı.
// Güvenlik: durum değişimi ve kapı okuması SUNUCU callable'larıyla yapılır (adminSetTicketStatus / adminCheckIn /
// adminHealth; yetki sunucuda User/{uid}.role ile denetlenir). Bu dosya yalnızca arayüzdür.
import { db, doc, getDoc, setDoc, collection, getDocs, query, limit, serverTimestamp, fonksiyon } from '../firebase.js';
import { $, $$, esc } from '../util.js';

const MODLAR = [
  ['kapali', 'Kapalı', 'Satış durur; yeni koltuk tutulamaz.'],
  ['rezervasyon', 'Rezervasyon', 'Bilet onaylanır, ödeme sahnede alınır.'],
  ['online', 'Online', 'iyzico ile kartla ödeme.'],
];
const DURUM = {
  pay_at_venue: ['Rezervasyon', 'warn'], paid: ['Ödendi', 'ok'], no_show: ['Gelmedi', 'bad'],
  cancelled: ['İptal', 'bad'], free: ['Ücretsiz', ''],
};
const durumOf = (t) => t.paymentStatus || (t.orderMethod === 'venue' ? 'pay_at_venue' : t.orderMethod === 'free' ? 'free' : 'paid');
const sure = (ms) => (ms == null ? '—' : ms < 1 ? 'şimdi' : ms < 120 ? `${ms} dk önce` : ms < 2880 ? `${Math.round(ms / 60)} sa önce` : `${Math.round(ms / 1440)} gün önce`);
const kodAyikla = (v) => { const m = String(v || '').trim().match(/[A-Za-z0-9_-]{6,}/g); return m ? m[m.length - 1] : ''; };

async function cagir(ad, veri) { return (await (await fonksiyon(ad))(veri)).data; }

export function biletKapi(m, { veri, bildir, hataMesaji }) {
  let biletler = [];
  let satis = { mode: 'rezervasyon', rezervasyonLimit: 3, iptalSaat: 24 };
  const f = { etkinlik: '', durum: 'aktif', ara: '' };
  let iptalAcik = false;

  m.innerHTML = `<div class="adm-top"><h1>🎟️ Biletler &amp; Kapı</h1><button class="btn btn-ghost btn-sm" id="bk-yenile">Yenile</button></div>
    <section class="bk-card" id="bk-sagl" aria-label="Sistem sağlığı"></section>
    <section class="bk-card" id="bk-satis" aria-label="Satış modu"></section>
    <section class="bk-card" id="bk-kapi" aria-label="Kapı kontrolü"></section>
    <section class="bk-card" id="bk-iptalliste" aria-label="İptal edilenler"></section>
    <section id="bk-liste" aria-label="Bilet listesi"></section>`;
  $('#bk-yenile', m).addEventListener('click', () => { saglik(); biletleriYukle(); iptalCiz(true); });

  // ---------------- sistem sağlığı
  async function saglik() {
    const k = $('#bk-sagl', m);
    k.innerHTML = '<h2>Sistem sağlığı</h2><div class="skel" style="height:64px"></div>';
    try {
      const h = await cagir('adminHealth', {});
      const takili = h.stuck.held + h.stuck.paying;
      const hb = h.heartbeat;
      const ad = h.accountDeletion || null; // hesap silme işleyicisi (docs/HESAP-SILME.md); eski backend'de/hatada yok
      k.classList.toggle('bad', hb.stale || takili > 0 || h.refundRequired.count > 0 || h.reminders.stale || !!(ad && (ad.stale || ad.failing > 0)));
      k.innerHTML = `<h2>Sistem sağlığı</h2>
        ${hb.stale ? `<div class="bk-alert" role="alert">⚠ Süre dolumu görevi ${hb.lastRunAt ? `${esc(sure(hb.ageMinutes))} çalışmış — 15 dakikadan eski` : 'hiç çalışmamış'}. Tutulan koltuklar serbest kalmayabilir.</div>` : ''}
        ${takili > 0 ? `<div class="bk-alert" role="alert">⚠ ${takili} sipariş süresi geçtiği hâlde kapanmadı (tutulan: ${h.stuck.held}, ödemede: ${h.stuck.paying}).</div>` : ''}
        ${h.refundRequired.count > 0 ? `<div class="bk-alert" role="alert">⚠ İade gereken ${h.refundRequired.count} sipariş var: ${h.refundRequired.orders.map((o) => `<code>${esc(o.orderId)}</code>${o.total != null ? ` (${esc(o.total)} ₺)` : ''}`).join(', ')}</div>` : ''}
        <div class="bk-stats">
          <div><b>${esc(sure(hb.ageMinutes))}</b><span>Son süre dolumu (${hb.expiredOrders} sipariş, ${hb.releasedSeats} koltuk)</span></div>
          <div><b>${takili}</b><span>Takılı sipariş</span></div>
          <div><b>${h.reservations.today} / ${h.reservations.total}</b><span>Rezervasyon (bugün / toplam) — iptaller hariç</span></div>
          <div><b>${h.freeTickets.today} / ${h.freeTickets.total}</b><span>Ücretsiz bilet (bugün / toplam) — iptaller hariç</span></div>
          <div><button type="button" class="bk-link" id="bk-iptal-git" aria-label="İptal edilenleri göster"><b>${h.cancelled.today} / ${h.cancelled.total}</b><span>İptal edilen (bugün / toplam) ›</span></button></div>
          <div><b>${h.refundRequired.count}</b><span>İade gereken</span></div>
        </div>
        ${ad ? `<div class="bk-sub" id="bk-ad" aria-label="Hesap silme">
          <h3>Hesap silme (30 gün bekleme)</h3>
          ${ad.stale ? `<div class="bk-alert" role="alert">⚠ Hesap silme görevi ${ad.lastRunAt ? `${esc(sure(ad.ageMinutes))} çalışmış` : 'hiç çalışmamış'} ve vadesi geçmiş ${ad.overdue} kayıt var. Aşağıdan elle çalıştırın; sürerse Cloud Scheduler'ı kontrol edin.</div>` : ''}
          ${ad.failing > 0 ? `<div class="bk-alert" role="alert">⚠ ${ad.failing} silme kaydı tekrar tekrar hata veriyor (Firestore: AccountDeletion, lastError alanı). Kayıt silinmeden kalır; elle çalıştırmak aynı hatayı verirse müdahale gerekir.</div>` : ''}
          ${!(ad.pending || ad.deleting || ad.overdue || ad.failing) ? '<p class="bk-note">Şu an bekleyen hesap silme talebi yok.</p>' : ''}
          <div class="bk-stats">
            <div><b>${ad.pending}</b><span>Bekleyen (30 gün dolmadı / henüz alınmadı)</span></div>
            <div><b>${ad.deleting}</b><span>Siliniyor / yarım kaldı</span></div>
            <div><b>${ad.overdue}</b><span>Vadesi geçmiş, işlenmemiş</span></div>
            <div><b>${ad.failing}</b><span>Hatalı (3+ deneme)</span></div>
            <div><b>${esc(sure(ad.ageMinutes))}</b><span>Son çalışma (silinen ${ad.deleted}, ertelenen ${ad.postponed}, hata ${ad.failed})</span></div>
          </div>
          <div class="bk-row"><button type="button" class="btn btn-ghost btn-sm" id="bk-ad-calistir">Silme işlerini şimdi çalıştır</button><span class="muted" id="bk-ad-sonuc" role="status" aria-live="polite"></span></div>
        </div>` : ''}
        ${h.reminders.stale ? '<div class="bk-alert" role="alert" style="margin-top:12px">⚠ Otomatik hatırlatma görevi çalışmıyor (son çalışma: ' + (h.reminders.lastRunAt ? esc(sure(h.reminders.ageMinutes)) : 'hiç') + '). Sahne kumandası sekmesinden kontrol et.</div>' : ''}`;
      const adBtn = $('#bk-ad-calistir', k);
      if (adBtn) adBtn.addEventListener('click', async () => {
        if (!confirm('Vadesi gelen hesap silme talepleri şimdi İŞLENECEK: bu hesaplar ve kişisel verileri KALICI olarak silinir (geri alınamaz). Devam edilsin mi?')) return;
        adBtn.disabled = true; const so = $('#bk-ad-sonuc', k); so.textContent = 'Çalışıyor…';
        try {
          const r = await cagir('adminProcessAccountDeletions', {});
          const ozet = `Silinen ${r.deleted}, ertelenen ${r.postponed}, hatalı ${r.failed} (taranan ${r.scanned}${r.remainingDue ? `, kalan vadesi gelmiş ${r.remainingDue}` : ''})`;
          bildir(ozet, r.failed > 0); saglik();
        } catch (e) { adBtn.disabled = false; so.textContent = ''; bildir(hataMesaji(e), true); }
      });
      $('#bk-iptal-git', k).addEventListener('click', () => { iptalAcik = true; iptalCiz(true); $('#bk-iptalliste', m).scrollIntoView({ behavior: 'smooth', block: 'start' }); });
    } catch (e) { k.classList.add('bad'); k.innerHTML = `<h2>Sistem sağlığı</h2><div class="bk-alert" role="alert">Sağlık bilgisi alınamadı: ${esc(hataMesaji(e))}</div>`; }
  }

  // ---------------- satış modu
  async function satisYukle() {
    try { const s = await getDoc(doc(db, 'Config', 'satis')); if (s.exists()) satis = { ...satis, ...s.data() }; } catch (e) { bildir(hataMesaji(e), true); }
    satisCiz();
  }
  function satisCiz() {
    const k = $('#bk-satis', m);
    k.innerHTML = `<h2>Satış modu</h2>
      <div class="bk-seg" role="radiogroup" aria-label="Satış modu">${MODLAR.map(([id, ad, ac]) => `<button type="button" role="radio" aria-checked="${satis.mode === id}" class="${satis.mode === id ? 'on' : ''}" data-mod="${id}"><b>${ad}</b><small>${ac}</small></button>`).join('')}</div>
      ${satis.mode === 'online' ? '<div class="bk-alert" role="alert">⚠ iyzico henüz canlı değil. Online modda kartla ödeme denenir; canlı anahtarlar tanımlanmadan açmayın.</div>' : ''}
      <div class="bk-row">
        <label class="fld-in">Rezervasyon limiti (kişi başı, toplam koltuk)<input id="bk-lim" type="number" min="0" max="50" step="1" value="${esc(satis.rezervasyonLimit)}"></label>
        <label class="fld-in">İptal süresi (seanstan en az kaç saat önce)<input id="bk-iptal" type="number" min="0" max="2160" step="1" value="${esc(satis.iptalSaat)}"></label>
        <button class="btn btn-primary" id="bk-kaydet">Kaydet</button>
      </div>`;
    $$('[data-mod]', k).forEach((b) => b.addEventListener('click', () => { satis.mode = b.dataset.mod; satis.rezervasyonLimit = Number($('#bk-lim', k).value); satis.iptalSaat = Number($('#bk-iptal', k).value); satisCiz(); }));
    $('#bk-kaydet', k).addEventListener('click', async () => {
      const lim = Number($('#bk-lim', k).value), iptal = Number($('#bk-iptal', k).value);
      if (!Number.isInteger(lim) || lim < 0 || lim > 50) return bildir('Limit 0–50 arasında tam sayı olmalı.', true);
      if (!(iptal >= 0 && iptal <= 2160)) return bildir('İptal süresi 0–2160 saat olmalı.', true);
      if (satis.mode === 'online' && !confirm('iyzico henüz canlı değil. Online modu yine de açmak istiyor musun?')) return;
      try {
        await setDoc(doc(db, 'Config', 'satis'), { mode: satis.mode, rezervasyonLimit: lim, iptalSaat: iptal, updatedAt: serverTimestamp() });
        satis.rezervasyonLimit = lim; satis.iptalSaat = iptal;
        bildir('Satış modu kaydedildi ✓'); saglik();
      } catch (e) { bildir(hataMesaji(e), true); }
    });
  }

  // ---------------- kapı kontrolü
  function kapiCiz() {
    const k = $('#bk-kapi', m);
    k.innerHTML = `<h2>Kapı kontrolü</h2>
      <form class="bk-row" id="bk-kf"><label class="fld-in" style="flex:1">Bilet kodu (QR okuyucu buraya yazar)<input id="bk-kod" type="text" autocomplete="off" autocapitalize="off" spellcheck="false" autofocus></label>
      <button class="btn btn-primary" type="submit">Kontrol et</button></form><div id="bk-sonuc" aria-live="assertive"></div>`;
    const inp = $('#bk-kod', k);
    $('#bk-kf', k).addEventListener('submit', async (e) => {
      e.preventDefault();
      const kod = kodAyikla(inp.value);
      if (!kod) return sonuc('bad', 'KOD YOK', 'Bilet kodunu gir ya da QR okut.');
      sonuc('', 'Kontrol ediliyor…', '');
      try {
        const r = await cagir('adminCheckIn', { ticketId: kod });
        const t = r.ticket || {}, ozet = bilgi(t);
        if (r.ok) {
          const ode = t.paymentStatus === 'pay_at_venue';
          sonuc('ok', 'GEÇERLİ', ozet + (ode ? '<div class="bk-pay">ÖDEME ALINACAK — rezervasyon sahnede ödenir</div>' : ''));
        } else if (r.already) sonuc('bad', 'ZATEN KULLANILDI', `${ozet}<div>İlk giriş: ${esc(t.usedAt ? new Date(t.usedAt).toLocaleString('tr-TR') : '—')}</div>`);
        else if (t.paymentStatus === 'cancelled') sonuc('bad', 'İPTAL EDİLMİŞ', ozet);
        else sonuc('bad', 'GEÇERSİZ', `${ozet}<div>Durum: ${esc((DURUM[t.paymentStatus] || [t.paymentStatus])[0])}</div>`);
        biletleriYukle(true);
      } catch (er) {
        if ((er.code || '').includes('not-found')) sonuc('bad', 'BULUNAMADI', `“${esc(kod)}” koduyla bilet yok.`);
        else sonuc('bad', 'HATA', esc(hataMesaji(er)));
      }
      inp.value = ''; inp.focus();
    });
    function bilgi(t) {
      return `<div><b>${esc(t.showName || '—')}</b> · ${esc(t.eventDate || '')}</div><div>${esc(t.stageName || '')}</div>
        <div>Koltuk: <b>${esc([].concat(t.buySeats || []).join(', '))}</b>${t.customerName ? ` · ${esc(t.customerName)}` : ''}</div>`;
    }
    function sonuc(tur, baslik, govde) { $('#bk-sonuc', k).innerHTML = `<div class="bk-res ${tur}"><div class="bk-res-t">${esc(baslik)}</div>${govde}</div>`; }
  }

  // ---------------- iptal edilenler (kim, ne zaman, kim iptal etti)
  const iptalEden = { customer: 'Müşteri', admin: 'Yönetici' };
  async function iptalCiz(yukle) {
    const k = $('#bk-iptalliste', m);
    if (!iptalAcik) {
      k.innerHTML = `<div class="bk-row" style="justify-content:space-between;align-items:center"><h2 style="margin:0">İptal edilenler</h2><button class="btn btn-ghost btn-sm" id="bk-iptal-ac" aria-expanded="false">Göster</button></div>`;
      $('#bk-iptal-ac', k).addEventListener('click', () => { iptalAcik = true; iptalCiz(true); });
      return;
    }
    if (yukle) k.innerHTML = '<h2>İptal edilenler</h2><div class="skel" style="height:80px"></div>';
    try {
      const r = (await cagir('adminCancelled', { limit: 100 }));
      k.innerHTML = `<div class="bk-row" style="justify-content:space-between;align-items:center"><h2 style="margin:0">İptal edilenler <span class="muted" style="font-size:.6em">${r.shown}/${r.total}</span></h2><button class="btn btn-ghost btn-sm" id="bk-iptal-kapat" aria-expanded="true">Gizle</button></div>
        <p class="muted" style="margin:8px 0 12px">Bu biletler Rezervasyon / Ücretsiz sayaçlarına dahil değildir; koltukları serbest bırakılmıştır. En yeni ${r.shown} iptal gösteriliyor.</p>
        <div class="tbl-wrap"><table class="tbl"><thead><tr><th>İptal zamanı</th><th>Müşteri</th><th>Oyun / seans</th><th>Koltuk</th><th>Tür</th><th>İptal eden</th></tr></thead><tbody>
        ${r.tickets.map((t) => `<tr><td>${esc(t.cancelledAt ? new Date(t.cancelledAt).toLocaleString('tr-TR', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }) : '—')}</td>
          <td>${esc(t.customerName || 'İsimsiz')}<br><span class="muted"><code title="${esc(t.customerId)}">${esc((t.customerId || '').slice(0, 8))}…</code></span></td>
          <td>${esc(t.showName || '—')}<br><span class="muted">${esc(t.eventDate || '')}</span></td><td>${esc([].concat(t.seats || []).join(', '))}</td>
          <td>${t.orderMethod === 'venue' ? 'Rezervasyon' : t.orderMethod === 'free' ? 'Ücretsiz' : 'Online'}</td>
          <td><span class="tag ${t.cancelledBy === 'admin' ? 'warn' : ''}">${esc(iptalEden[t.cancelledBy] || 'Bilinmiyor')}</span></td></tr>`).join('') || '<tr><td colspan="6"><div class="empty">İptal edilen bilet yok.</div></td></tr>'}</tbody></table></div>`;
      $('#bk-iptal-kapat', k).addEventListener('click', () => { iptalAcik = false; iptalCiz(); });
    } catch (e) { k.innerHTML = `<h2>İptal edilenler</h2><div class="bk-alert" role="alert">${esc(hataMesaji(e))}</div>`; }
  }

  // ---------------- bilet listesi
  async function biletleriYukle(sessiz) {
    const k = $('#bk-liste', m);
    if (!sessiz) k.innerHTML = '<div class="skel" style="height:200px"></div>';
    try {
      const sn = await getDocs(query(collection(db, 'Ticket'), limit(500)));
      biletler = sn.docs.map((d) => ({ ...d.data(), docId: d.id }));
      listeCiz();
    } catch (e) { k.innerHTML = `<div class="err">${esc(hataMesaji(e))}</div>`; }
  }
  const etkinlikAdi = (id) => {
    const e = (veri.Event || []).find((x) => x.id === id || x.docId === id);
    const s = e && (veri.Show || []).find((y) => y.id === e.showId || y.docId === e.showId);
    return e ? `${s ? s.name : 'Oyun'} — ${e.date}` : id;
  };
  function listeCiz() {
    const k = $('#bk-liste', m);
    const q = f.ara.trim().toLocaleLowerCase('tr');
    const satirlar = biletler.filter((t) => (!f.etkinlik || t.eventId === f.etkinlik) && (!f.durum || (f.durum === 'aktif' ? durumOf(t) !== 'cancelled' : durumOf(t) === f.durum)) &&
      (!q || t.docId.toLocaleLowerCase('tr').includes(q))).slice(0, 300);
    const etkIds = [...new Set(biletler.map((t) => t.eventId).filter(Boolean))];
    k.innerHTML = `<h2 style="margin:26px 0 12px">Biletler <span class="muted" style="font-size:.6em">${satirlar.length}/${biletler.length}${biletler.length >= 500 ? '+' : ''}</span></h2>
      <div class="tools"><select class="in" id="bk-fe" aria-label="Etkinlik"><option value="">Tüm etkinlikler</option>${etkIds.map((id) => `<option value="${esc(id)}" ${f.etkinlik === id ? 'selected' : ''}>${esc(etkinlikAdi(id))}</option>`).join('')}</select>
        <select class="in" id="bk-fd" aria-label="Durum"><option value="aktif" ${f.durum === 'aktif' ? 'selected' : ''}>Aktif (iptaller hariç)</option><option value="">Tüm durumlar</option>${Object.entries(DURUM).map(([id, [ad]]) => `<option value="${id}" ${f.durum === id ? 'selected' : ''}>${ad}</option>`).join('')}</select>
        <input class="in" id="bk-fa" type="search" placeholder="Bilet kodu ara…" value="${esc(f.ara)}"></div>
      <div class="tbl-wrap"><table class="tbl"><thead><tr><th>Kod</th><th>Oyun / seans</th><th>Koltuk</th><th>Tutar</th><th>Durum</th><th></th></tr></thead><tbody>
      ${satirlar.map((t) => {
    const d = durumOf(t), [ad, sinif] = DURUM[d] || [d, ''], aktif = d !== 'cancelled';
    return `<tr><td><code title="${esc(t.docId)}">${esc(t.docId.slice(0, 8))}…</code></td><td>${esc(t.showName || '—')}<br><span class="muted">${esc(t.eventDate || '')}</span></td>
          <td>${esc([].concat(t.buySeats || []).join(', '))}</td><td>${esc(t.orderPrice ?? '')}</td>
          <td><span class="tag ${sinif}">${esc(ad)}</span>${t.usedAt ? ' <span class="tag ok">Girdi</span>' : ''}</td>
          <td><div class="acts">${aktif ? `${t.orderMethod === 'venue' && d !== 'paid' ? `<button class="btn btn-ghost btn-sm" data-t="${esc(t.docId)}" data-s="paid">Ödendi</button>` : ''}
            ${d !== 'no_show' ? `<button class="btn btn-ghost btn-sm" data-t="${esc(t.docId)}" data-s="no_show">Gelmedi</button>` : ''}
            ${t.orderMethod !== 'card' ? `<button class="btn btn-ghost btn-sm" data-t="${esc(t.docId)}" data-s="cancelled">İptal</button>` : ''}` : ''}</div></td></tr>`;
  }).join('') || '<tr><td colspan="6"><div class="empty">Bilet yok.</div></td></tr>'}</tbody></table></div>`;
    $('#bk-fe', k).addEventListener('change', (e) => { f.etkinlik = e.target.value; listeCiz(); });
    $('#bk-fd', k).addEventListener('change', (e) => { f.durum = e.target.value; listeCiz(); });
    $('#bk-fa', k).addEventListener('input', (e) => { f.ara = e.target.value; const p = e.target.selectionStart; listeCiz(); const n = $('#bk-fa', k); n.focus(); n.setSelectionRange(p, p); });
    $$('[data-t]', k).forEach((b) => b.addEventListener('click', async () => {
      const hedef = b.dataset.s, id = b.dataset.t;
      if (hedef === 'cancelled' && !confirm('Bilet iptal edilsin mi? Koltuklar başkasına açılır, geri alınamaz.')) return;
      b.disabled = true;
      try {
        const r = await cagir('adminSetTicketStatus', { ticketId: id, paymentStatus: hedef });
        const t = biletler.find((x) => x.docId === id); if (t) t.paymentStatus = r.paymentStatus;
        bildir('Güncellendi ✓'); listeCiz(); saglik(); if (iptalAcik) iptalCiz(true);
      } catch (e) { bildir(hataMesaji(e), true); b.disabled = false; }
    }));
  }

  kapiCiz(); satisYukle(); saglik(); biletleriYukle(); iptalCiz();
}
