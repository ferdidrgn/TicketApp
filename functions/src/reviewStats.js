'use strict';
/** Show.ratingAvg / ratingCount önbelleği: görünür (hidden=false) yorumlardan transaction içinde yeniden hesaplanır. */
async function recomputeShowRating(db, showId) {
  if (typeof showId !== 'string' || !showId) return null;
  const showRef = db.collection('Show').doc(showId);
  return db.runTransaction(async (tx) => {
    const show = await tx.get(showRef);
    if (!show.exists) return null;
    const snap = await tx.get(db.collection('Review').where('showId', '==', showId).where('hidden', '==', false).limit(5000));
    let n = 0, sum = 0;
    snap.docs.forEach((d) => { const r = d.data().rating; if (Number.isInteger(r) && r >= 1 && r <= 5) { n += 1; sum += r; } });
    const out = { ratingAvg: n ? Math.round((sum / n) * 100) / 100 : 0, ratingCount: n };
    tx.set(showRef, out, { merge: true });
    return out;
  });
}
module.exports = { recomputeShowRating };
