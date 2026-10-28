// Yönetim paneli — "Ekip yöneticileri": topluluk başına yönetici ata / geri al. Yazma yalnız adminSetTeamManager callable'ıyla
// (istemci TeamManager'a yazamaz; firestore.rules). Okuma: TeamManager koleksiyonu (yalnız admin). Atanan kişi /ekip sayfasından
// yalnız kendi topluluğunun oyun/seanslarını yönetir; admin DEĞİLDİR. Ayrıntı: docs/EKIP-YONETICISI.md
import { db, fonksiyon, collection, getDocs, query, where } from '../firebase.js';
import { $, $$, esc } from '../util.js';

const cagir = async (ad, veri) => (await (await fonksiyon(ad))(veri)).data;
const tarih = (ts) => (ts && ts.toMillis ? new Date(ts.toMillis()).toLocaleString('tr-TR', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : '—');

export function ekipYoneticileri(m, { veri, bildir, hataMesaji, secili = '' }) {
  const toplulukler = (veri.Team || []).map((t) => ({ id: t.id, ad: t.name || t.id })).sort((a, b) => a.ad.localeCompare(b.ad, 'tr'));
  let teamId = secili && toplulukler.some((t) => t.id === secili) ? secili : (toplulukler[0] || {}).id || '';
  m.innerHTML = `<div class="adm-top"><h1>🧑‍🤝‍🧑 Ekip yöneticileri</h1></div>
    <section class="bk-card"><p class="muted" style="margin:0">Ekip yöneticisi <b>admin değildir</b>: yalnızca atandığı topluluğun oyunlarının seanslarına bildirim gönderebilir, kapı kontrolü yapabilir ve doluluk özetini görür. Yetkiyi geri almak belgeyi silmez (denetim izi kalır).</p></section>
    <section class="bk-card" aria-label="Yönetici ekle">
      ${toplulukler.length ? `<div class="form-grid">
        <div class="fld-in"><label for="ey-ekip">Topluluk</label><select id="ey-ekip">${toplulukler.map((t) => `<option value="${esc(t.id)}" ${t.id === teamId ? 'selected' : ''}>${esc(t.ad)}</option>`).join('')}</select></div>
        <div class="fld-in"><label for="ey-mail">Yöneticinin e-postası</label><input id="ey-mail" type="email" autocomplete="off" placeholder="kisi@ornek.com"><span class="hint">Kişi daha önce siteye/uygulamaya bu e-postayla giriş yapmış olmalı.</span></div>
      </div><div class="modal-act"><button class="btn btn-primary" id="ey-ekle">Yönetici olarak ekle</button></div>` : '<div class="empty">Önce bir topluluk ekle.</div>'}
      <div id="ey-sonuc" aria-live="polite"></div>
    </section>
    <section class="bk-card" id="ey-liste" aria-label="Yöneticiler"></section>`;

  async function listele() {
    const k = $('#ey-liste', m);
    if (!teamId) { k.innerHTML = ''; return; }
    k.innerHTML = '<div class="skel" style="height:80px"></div>';
    try {
      const sn = await getDocs(query(collection(db, 'TeamManager'), where('teamId', '==', teamId)));
      const satir = sn.docs.map((d) => d.data()).sort((a, b) => (a.status === b.status ? 0 : a.status === 'active' ? -1 : 1));
      k.innerHTML = `<h2>Yöneticiler</h2>${satir.length ? `<div class="tbl-wrap"><table class="tbl"><thead><tr><th>Kişi</th><th>Durum</th><th>Telefon</th><th>Eklenme</th><th></th></tr></thead><tbody>
        ${satir.map((x) => `<tr><td>${esc(x.displayName || '—')}<br><span class="muted">${esc(x.emailHint || '')}</span></td>
          <td>${x.status === 'active' ? '<span class="tag ok">Aktif</span>' : '<span class="tag warn">Geri alındı</span>'}</td>
          <td>${x.phoneActive ? 'Doğrulanmış' : '<span class="tag warn">Doğrulanmamış</span>'}</td><td>${esc(tarih(x.addedAt))}</td>
          <td><div class="acts">${x.status === 'active' ? `<button class="btn btn-ghost btn-sm" data-geri="${esc(x.uid)}">Yetkiyi geri al</button>` : ''}</div></td></tr>`).join('')}</tbody></table></div>` : '<div class="empty">Bu toplulukta ekip yöneticisi yok.</div>'}`;
      $$('[data-geri]', k).forEach((b) => b.addEventListener('click', async () => {
        if (!confirm('Bu kişinin ekip yöneticisi yetkisi geri alınsın mı?')) return;
        b.disabled = true;
        try { await cagir('adminSetTeamManager', { teamId, uid: b.dataset.geri, action: 'revoke' }); bildir('Yetki geri alındı'); listele(); } catch (e) { b.disabled = false; bildir(hataMesaji(e), true); }
      }));
    } catch (e) { k.innerHTML = `<h2>Yöneticiler</h2><div class="bk-alert" role="alert">${esc(hataMesaji(e))}</div>`; }
  }

  $('#ey-ekip', m)?.addEventListener('change', (e) => { teamId = e.target.value; listele(); });
  $('#ey-ekle', m)?.addEventListener('click', async (ev) => {
    const mail = $('#ey-mail', m).value.trim(), btn = ev.currentTarget, so = $('#ey-sonuc', m);
    if (!mail) return bildir('E-posta yaz.', true);
    btn.disabled = true; so.textContent = '';
    try {
      const r = await cagir('adminSetTeamManager', { teamId, email: mail, action: 'add' });
      bildir(r.already ? 'Bu kişi zaten yönetici' : 'Yönetici eklendi ✓');
      if (r.phoneActive === false) so.innerHTML = '<div class="bk-alert" role="status">Bu hesabın telefonu doğrulanmamış. Atama geçerli; ancak güvenlik için kişiden telefonunu doğrulamasını isteyin.</div>';
      $('#ey-mail', m).value = ''; listele();
    } catch (e) { bildir(hataMesaji(e), true); } finally { btn.disabled = false; }
  });
  listele();
}
