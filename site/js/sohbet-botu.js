// Oyun sayfasında yüzen "Bu oyun hakkında sor" sohbet balonu (docs/SSS-BOTU.md).
// Eskiden statik "Sık sorulanlar" akordeonuydu (kaldırıldı) — aynı bilgi artık
// soru-cevap biçiminde. Kural tabanlı bot: YAPAY ZEKA / ağ çağrısı YOK, yalnız
// site/js/ssb.js (= mobil ShowFaqMatcher). Botun cevaplayamadığı soru aşağıdaki
// "Ekibe sor" (site/js/sorular.js) formuna taşınır; oradan gerçek bir ekip
// üyesi/moderatör yanıtlar. Geçmiş kalıcı değildir (sayfa yenilenince sıfırlanır).
import { sor, factsOf, YOK } from './ssb.js';
import { $, esc } from './util.js';

const ONERI = ['Kaç dakika sürüyor?', 'Yaş sınırı var mı?', 'Nerede oynanıyor?', 'Biletini nereden alırım?', 'Geç kalırsam ne olur?', 'Biletini iptal edebilir miyim?'];

const balonHtml = (m) => `<div class="sb-balon ${m.ben ? 'ben' : 'bot'}"><p>${esc(m.metin)}</p>${m.yetersiz ? '<button type="button" class="btn btn-primary btn-sm" data-ekibe-sor>Ekibe sor</button>' : ''}</div>`;

export function sohbetBaglan(s, yer, alan, mod) {
  if ($('#sb-dugme')) return; // SPA içi yeniden çizimde iki kez eklenmesin
  const facts = factsOf(s, yer, { alan, mod });
  const mesajlar = [{ ben: false, metin: `Merhaba! "${s.name}" hakkında süre, yaş sınırı, mekân, bilet ya da iptal ile ilgili soru sorabilirsin.` }];
  let panel = null, ilkMesaj = true;

  const dugme = document.createElement('button');
  dugme.id = 'sb-dugme'; dugme.type = 'button'; dugme.className = 'sb-dugme';
  dugme.setAttribute('aria-label', 'Bu oyun hakkında sor'); dugme.title = 'Bu oyun hakkında sor';
  dugme.innerHTML = '<svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 11.5a8.4 8.4 0 0 1-8.4 8.4 8.3 8.3 0 0 1-3.8-.9L3 21l2-5.8a8.3 8.3 0 0 1-.9-3.7A8.4 8.4 0 1 1 21 11.5Z"/></svg>';
  document.body.append(dugme);

  function cizMesajlar() {
    const liste = $('.sb-liste', panel);
    liste.innerHTML = mesajlar.map(balonHtml).join('') + (ilkMesaj ? `<div class="sb-oneri">${ONERI.map((o) => `<button type="button" class="chip" data-oneri>${esc(o)}</button>`).join('')}</div>` : '');
    liste.scrollTop = liste.scrollHeight;
    $('[data-ekibe-sor]', liste)?.addEventListener('click', ekibeYonlendir);
  }

  function gonder(metin) {
    const t = metin.trim();
    if (!t) return;
    ilkMesaj = false;
    mesajlar.push({ ben: true, metin: t });
    const r = sor(t, facts);
    mesajlar.push(r.answer ? { ben: false, metin: r.answer } : { ben: false, metin: YOK, yetersiz: true });
    cizMesajlar();
  }

  function escKapat(e) { if (e.key === 'Escape') kapat(); }
  function kapat() { if (panel) panel.hidden = true; document.removeEventListener('keydown', escKapat); }

  function ekibeYonlendir() {
    kapat();
    const hedef = $('#sorular');
    hedef?.scrollIntoView({ behavior: matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth', block: 'start' });
    const ta = $('#soru-metin');
    if (!ta) return;
    ta.value = [...mesajlar].reverse().find((m) => m.ben)?.metin || '';
    ta.dispatchEvent(new Event('input'));
    ta.focus();
  }

  function ac() {
    if (panel) { panel.hidden = false; $('.sb-girdi', panel)?.focus(); document.addEventListener('keydown', escKapat); return; }
    panel = document.createElement('div');
    panel.className = 'sb-panel'; panel.setAttribute('role', 'dialog'); panel.setAttribute('aria-modal', 'false'); panel.setAttribute('aria-label', `${s.name} hakkında sohbet`);
    panel.innerHTML = `<div class="sb-ust"><div><b>Bu oyun hakkında sor</b><small>${esc(s.name)}</small></div><button type="button" class="sb-kapat" aria-label="Kapat">✕</button></div>
      <div class="sb-liste" aria-live="polite"></div>
      <form class="sb-form"><label class="sr-only" for="sb-girdi">Sorunu yaz</label><textarea id="sb-girdi" class="sb-girdi" rows="1" maxlength="300" placeholder="Sorunu yaz…"></textarea><button type="submit" class="sb-gonder" aria-label="Gönder">➤</button></form>`;
    document.body.append(panel);
    cizMesajlar();
    $('.sb-kapat', panel).addEventListener('click', kapat);
    $('.sb-liste', panel).addEventListener('click', (e) => { const o = e.target.closest('[data-oneri]'); if (o) gonder(o.textContent); });
    const form = $('.sb-form', panel), girdi = $('.sb-girdi', panel);
    form.addEventListener('submit', (e) => { e.preventDefault(); gonder(girdi.value); girdi.value = ''; girdi.style.height = 'auto'; });
    girdi.addEventListener('keydown', (e) => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); form.requestSubmit(); } });
    girdi.addEventListener('input', () => { girdi.style.height = 'auto'; girdi.style.height = `${Math.min(girdi.scrollHeight, 96)}px`; });
    document.addEventListener('keydown', escKapat);
    girdi.focus();
  }

  dugme.addEventListener('click', () => (panel && !panel.hidden ? kapat() : ac()));
}
