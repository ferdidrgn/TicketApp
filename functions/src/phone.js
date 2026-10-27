'use strict';
/**
 * Telefon doğrulamalı kimlik (docs/TELEFON-DOGRULAMA.md, docs/ODEME-GUVENLIK.md "Telefon doğrulamalı kimlik").
 * KAYNAK DOĞRULUK: ID token'ındaki `phone_number` (E.164) — Firebase SMS doğrulamasının sonucu. İstemci verisi (User belgesi,
 * callable gövdesi) telefon kimliği olarak ASLA kullanılmaz.
 */
const crypto = require('crypto');
const { FieldValue } = require('firebase-admin/firestore');
const { HttpsError } = require('firebase-functions/v2/https');

const E164 = /^\+[1-9]\d{6,14}$/;

/** Geçerli E.164 ise aynen, değilse null. */
function normalizeE164(v) {
  return typeof v === 'string' && E164.test(v) ? v : null;
}

/** Telefon numarasından limit anahtarı: ph_<sha256(e164 + tuz)>. Düz numara hiçbir limit/sipariş belgesine yazılmaz (KVKK). */
function phoneKeyOf(e164, salt) {
  return 'ph_' + crypto.createHash('sha256').update(String(e164) + String(salt || '')).digest('hex');
}

function phoneRequired() {
  return new HttpsError('failed-precondition', 'PHONE_REQUIRED', { code: 'PHONE_REQUIRED' });
}

/** Satış callable'ları için: telefon yoksa/bozuksa PHONE_REQUIRED. -> { phone, key } */
function requirePhone(ctx, salt) {
  const phone = normalizeE164(ctx && ctx.phone);
  if (!phone) throw phoneRequired();
  return { phone, key: phoneKeyOf(phone, salt) };
}

/**
 * syncPhoneVerification: token'da phone_number varsa User/{uid} belgesine doğrulama bilgisini SUNUCU yazar.
 * `role`'e dokunulmaz. Telefon yoksa hata atılmaz; belge daha önce isPhoneActive:true ise false'a çekilir (telefon sonradan kaldırılmış olabilir).
 */
function createPhoneSync({ db, salt, log = console }) {
  async function syncPhoneVerification(uid, ctx) {
    const phone = normalizeE164(ctx && ctx.phone);
    const ref = db.collection('User').doc(uid);
    if (!phone) {
      const snap = await ref.get();
      if (snap.exists && snap.data().isPhoneActive === true) {
        await ref.set({ isPhoneActive: false }, { merge: true });
      }
      return { isPhoneActive: false };
    }
    const key = phoneKeyOf(phone, salt);
    await ref.set({
      phoneNumber: phone, isPhoneActive: true, phoneKey: key, phoneVerifiedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    // Savunma: Firebase bir numarayı iki canlı hesaba bağlamaz; ama numarayı bırakmış (updatePhoneNumber/silinip yeniden açılmış)
    // eski bir uid'in User belgesi hâlâ "aktif" görünebilir -> pasifleştir. Limitler uid'e değil numaraya bağlı olduğundan etkilenmez.
    try {
      const others = await db.collection('User').where('phoneKey', '==', key).get();
      for (const d of others.docs) {
        if (d.id !== uid && d.data().isPhoneActive === true) await d.ref.set({ isPhoneActive: false }, { merge: true });
      }
    } catch (e) { log.error('syncPhoneVerification eski sahip temizliği hatası', { code: e && e.code }); }
    return { isPhoneActive: true, phoneNumber: phone };
  }
  return { syncPhoneVerification };
}

module.exports = { normalizeE164, phoneKeyOf, requirePhone, phoneRequired, createPhoneSync };
