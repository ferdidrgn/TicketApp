// "Birlikte gidelim" (F-6): seans için paylaşılabilir plan bağlantısı üretir (sunucu: createPlan) ve paylaşım menüsünü açar.
// Plan sayfası oluşturanın adını/telefonunu göstermez; yanıt girişsizdir. docs/ANKET-PLAN.md
import { fonksiyon } from './firebase.js';
import { girisGerekli } from './auth.js';
import { apiHata } from './bilet-api.js';
import { paylasMenusu } from './ozellik.js';
import { bildir } from './fav.js';

export async function birlikteGidelim(btn, show, seans) {
  if (!seans) { bildir('Önce bir seans seç.'); return; }
  if (!(await girisGerekli('Birlikte gidelim planı için giriş yap.'))) return;
  btn.disabled = true;
  try {
    const r = (await (await fonksiyon('createPlan'))({ showId: show.docId || show.id, eventId: seans.docId || seans.id })).data;
    paylasMenusu(btn, `${show.name} — birlikte gidelim mi?`, 'Gelip gelemeyeceğini tek dokunuşla bildir.', location.origin + r.path);
  } catch (e) { bildir(apiHata(e).message); } finally { btn.disabled = false; }
}
