// Ana sayfa "Anket" kartı (F-5). Oy YALNIZ sunucu callable'ı votePoll ile (giriş + doğrulanmış telefon); istemci Poll'a yazamaz.
// Sonuç yüzdeleri oy verdikten SONRA ya da anket bitince gösterilir (arayüz kuralı; sayaçlar Poll belgesinde herkese okunur).
import { db, fonksiyon, collection, getDocs, getDoc, doc, query, where, limit } from './firebase.js';
import { telefonGerekli, oturumDinle } from './auth.js';
import { apiHata } from './bilet-api.js';
import { $, $$, esc, linkOf, tarihUzun } from './util.js';

const ms = (t) => (t && t.toMillis ? t.toMillis() : null);
export const anketAcikMi = (p, t = Date.now()) => p.status === 'active' && (ms(p.startsAt) ?? 0) <= t && t < (ms(p.endsAt) ?? Infinity);

async function aktifAnket() {
  const s = await getDocs(query(collection(db, 'Poll'), where('status', '==', 'active'), limit(10)));
  const l = s.docs.map((d) => ({ id: d.id, ...d.data() })).filter((p) => anketAcikMi(p));
  l.sort((a, b) => (ms(b.startsAt) || 0) - (ms(a.startsAt) || 0));
  return l[0] || null;
}
async function benimOyum(pollId, uid) {
  if (!uid) return null;
  try { const s = await getDoc(doc(db, 'Poll', pollId, 'votes', uid)); return s.exists() ? s.data().optionId : null; } catch { return null; }
}

export async function anketKur(kok) {
  let poll;
  try { poll = await aktifAnket(); } catch { return; }
  if (!poll) return;
  const sec = document.createElement('section');
  sec.className = 'sec anket-sec'; sec.id = 'anket-sec'; sec.setAttribute('aria-label', 'Anket');
  kok.prepend(sec);
  let oy = null, degistir = false;

  const ciz = () => {
    const toplam = poll.totalVotes || 0;
    const sonuc = (oy && !degistir) || !anketAcikMi(poll);
    sec.innerHTML = `<div class="anket-kart"><p class="anket-etiket">Anket</p><h2>${esc(poll.question)}</h2>
      <div class="anket-liste" role="${sonuc ? 'list' : 'radiogroup'}" aria-label="${esc(poll.question)}">${poll.options.map((o) => {
        const n = (poll.counts || {})[o.id] || 0, y = toplam ? Math.round((n / toplam) * 100) : 0;
        const link = o.showId ? ` <a class="anket-oyun" href="${esc(linkOf('oyun', { name: o.label, id: o.showId }))}">Oyunu gör</a>` : '';
        return sonuc
          ? `<div class="anket-satir sonuc ${oy === o.id ? 'benim' : ''}" role="listitem"><i style="width:${y}%"></i><span>${esc(o.label)}${oy === o.id ? ' <em>(oyun)</em>' : ''}${link}</span><b>%${y}</b></div>`
          : `<button type="button" class="anket-satir" role="radio" aria-checked="${oy === o.id}" data-o="${esc(o.id)}"><span>${esc(o.label)}</span></button>`;
      }).join('')}</div>
      <p class="tiny anket-alt" id="anket-d" role="status">${sonuc ? `${toplam} oy` : 'Oy vermek için giriş yap ve telefonunu doğrula; hesap başına tek oy.'}</p>
      <p class="tiny anket-alt">TiyatRol anketi · ${anketAcikMi(poll) ? `${esc(tarihUzun(new Date(ms(poll.endsAt))))} tarihine kadar` : 'sona erdi'}${sonuc && oy && anketAcikMi(poll) ? ' · <button type="button" class="anket-link" id="anket-degis">Oyumu değiştir</button>' : ''}</p></div>`;
    $$('[data-o]', sec).forEach((b) => b.addEventListener('click', () => ver(b.dataset.o)));
    $('#anket-degis', sec)?.addEventListener('click', () => { degistir = true; ciz(); });
  };
  async function ver(optionId) {
    const d = $('#anket-d', sec);
    if (!(await telefonGerekli('Oy vermek için giriş yap ve telefonunu doğrula.'))) return;
    $$('[data-o]', sec).forEach((b) => { b.disabled = true; });
    d.textContent = 'Oyun kaydediliyor…';
    try {
      await (await fonksiyon('votePoll'))({ pollId: poll.id, optionId });
      poll = { id: poll.id, ...(await getDoc(doc(db, 'Poll', poll.id))).data() };
      oy = optionId; degistir = false; ciz();
    } catch (e) { d.textContent = apiHata(e).message; $$('[data-o]', sec).forEach((b) => { b.disabled = false; }); }
  }
  ciz();
  oturumDinle(async (u) => { oy = await benimOyum(poll.id, u?.uid); degistir = false; ciz(); });
}
