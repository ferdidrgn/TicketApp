'use strict';
/**
 * Eski Event.seats kayıtlarındaki `customerId` alanını siler ve eski yönetici bloğunu
 * ({status:'sold', customerId:'__ADMIN_BLOCKED__'}) `{status:'blocked'}`'a çevirir.
 *
 *   node functions/tools/scrub-seat-owners.js                       -> yalnızca EMÜLATÖR (FIRESTORE_EMULATOR_HOST gerekir), kuru çalıştırma
 *   node functions/tools/scrub-seat-owners.js --apply               -> emülatörde uygular
 *   node functions/tools/scrub-seat-owners.js --project <id> --i-know-this-is-production --apply
 *                                                                   -> GERÇEK proje (Application Default Credentials). Sahibi çalıştırır.
 * Satılmış koltuğun sahibi Ticket/Order'dan bilinir; koltukta kimlik tutulmaz.
 */
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldPath, FieldValue } = require('firebase-admin/firestore');

const arg = (n) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : null; };
const has = (n) => process.argv.includes(n);
const apply = has('--apply');
const prod = has('--i-know-this-is-production') && arg('--project');
if (!process.env.FIRESTORE_EMULATOR_HOST && !prod) {
  console.error('Emülatör yok. Gerçek proje için: --project <id> --i-know-this-is-production'); process.exit(1);
}
initializeApp({ projectId: arg('--project') || process.env.GCLOUD_PROJECT || 'ticketappflutter' });
const db = getFirestore();

(async () => {
  let events = 0, seats = 0;
  const snap = await db.collection('Event').get();
  for (const d of snap.docs) {
    const map = d.data().seats || {};
    const args = [];
    for (const [sid, s] of Object.entries(map)) {
      if (!s || typeof s !== 'object' || !('customerId' in s)) continue;
      const blocked = s.status === 'sold' && s.customerId === '__ADMIN_BLOCKED__';
      if (blocked) args.push(new FieldPath('seats', sid), { status: 'blocked' });
      else {
        args.push(new FieldPath('seats', sid, 'customerId'), FieldValue.delete());
        if (s.status === 'sold') args.push(new FieldPath('seats', sid, 'soldAt'), FieldValue.delete());
      }
      seats += 1;
    }
    if (args.length) { events += 1; if (apply) await d.ref.update(...args); }
  }
  console.log(`${apply ? 'Temizlendi' : 'Kuru çalıştırma'}: ${events} etkinlik, ${seats} koltuk.`);
})();
