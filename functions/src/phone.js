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

const MIN_SALT_LEN = 16;
/**
 * Üretimde tuz ZORUNLU (PHONE_HASH_SALT param, en az 16 karakter). Tanımsız/kısaysa null döner -> telefon gerektiren her
 * işlem FAIL-CLOSED reddedilir (zayıf/tahmin edilebilir tuzla sessizce çalışmaz). Yalnızca EMÜLATÖRDE sabit geliştirme tuzu kullanılır.
 */
function resolvePhoneSalt({ value, emulator, project }) {
  const v = typeof value === 'string' ? value.trim() : '';
  if (v) return emulator || v.length >= MIN_SALT_LEN ? v : null;
  return emulator ? `tiyatrol-phone-v1:${project || 'ticketappflutter'}` : null;
}

function saltMissing() {
  return new HttpsError('unavailable', 'Bilet satışı şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.', { code: 'SALT_MISSING' });
}

function phoneRequired() {
  return new HttpsError('failed-precondition', 'PHONE_REQUIRED', { code: 'PHONE_REQUIRED' });
}

/** Satış callable'ları için: telefon yoksa/bozuksa PHONE_REQUIRED. -> { phone, key } */
function requirePhone(ctx, salt) {
  const phone = normalizeE164(ctx && ctx.phone);
  if (!phone) throw phoneRequired();
  if (salt == null) throw saltMissing(); // fail-closed: tuz yapılandırılmamış
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
    if (salt == null) throw saltMissing();
    const key = phoneKeyOf(phone, salt);
    const fields = { phoneNumber: phone, isPhoneActive: true, phoneKey: key, phoneVerifiedAt: FieldValue.serverTimestamp() };
    const snap = await ref.get();
    if (!snap.exists) {
      // Belge henüz yok (istemci kaydı sonra gelebilir): istemcilerin beklediği TAM varsayılan User oluşturulur. Eksik `role`/`_id`
      // olursa mobil güncellemesi (role karşılaştırması / boş id) ve rules KIRILIR. role daima 'user' (yetki yükseltilmez).
      const iso = new Date().toISOString();
      try {
        await ref.create({
          _id: uid, _createdAt: iso, _updatedAt: iso, firstName: '', lastName: '', imageUrl: '', eMail: '', city: '', fcmToken: '',
          role: 'user', favoriteShows: [], favoriteStages: [], favoritePlayers: [], ticketsId: [], ...fields,
        });
      } catch (e) {
        if (!(e && (e.code === 6 || e.code === 'already-exists'))) throw e;
        await ref.set(fields, { merge: true }); // yarış: istemci aynı anda oluşturdu
      }
    } else {
      await ref.set(fields, { merge: true });
    }
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

module.exports = { normalizeE164, phoneKeyOf, requirePhone, phoneRequired, createPhoneSync, resolvePhoneSalt, MIN_SALT_LEN };
