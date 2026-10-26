// Gizlilik ve Şartlar: mobil uygulamayla TEK KAYNAK — Firestore AppTools belgesindeki metin (HTML) gösterilir.
// Metin güvenli listeden geçirilir (script/stil/olay yok); belge okunamazsa sayfadaki statik kopya kalır.
import '../theme.js';
import { kabukCiz } from '../ui.js';
import { db, doc, getDoc } from '../firebase.js';
import { $ } from '../util.js';

kabukCiz('');
const alan = document.body.dataset.alan; // 'privacyPolicy' | 'termsAndCondition'
const IZIN = new Set(['H1', 'H2', 'H3', 'H4', 'P', 'UL', 'OL', 'LI', 'B', 'STRONG', 'I', 'EM', 'U', 'A', 'BR', 'TABLE', 'THEAD', 'TBODY', 'TR', 'TH', 'TD', 'BLOCKQUOTE', 'SPAN', 'DIV', 'SMALL']);
function temizle(html) {
  const d = new DOMParser().parseFromString(html, 'text/html');
  const gez = (n) => {
    [...n.children].forEach((c) => {
      if (!IZIN.has(c.tagName)) { c.replaceWith(document.createTextNode(c.textContent)); return; }
      [...c.attributes].forEach((a) => {
        const ad = a.name.toLowerCase();
        if (c.tagName === 'A' && ad === 'href' && /^(https?:|mailto:|tel:|\/)/i.test(a.value.trim())) return;
        c.removeAttribute(a.name);
      });
      if (c.tagName === 'A') { c.setAttribute('rel', 'noopener'); if (/^https?:/i.test(c.getAttribute('href') || '')) c.setAttribute('target', '_blank'); }
      gez(c);
    });
  };
  gez(d.body);
  return d.body.innerHTML;
}
(async () => {
  try {
    const s = await getDoc(doc(db, 'AppTools', 'bgVYTTauB9gwd1qOyjix'));
    const t = s.exists() ? s.data()[alan] : '';
    if (typeof t === 'string' && t.trim().length > 200) $('.metin').innerHTML = temizle(t);
  } catch (e) { console.warn('Yasal metin canlı okunamadı, statik kopya gösteriliyor.', e); }
})();
