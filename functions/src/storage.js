'use strict';
/**
 * Kullanıcı profil görselleri. İstemci yolu: ppics/{uid}.jpg (lib/.../storage_service.dart). Uzantı/biçim değişebilir (png, webp...) ya da
 * alt klasör kullanılabilir -> ÖN EK silinir. Dosya yoksa hata YOK (idempotent); yetki/ağ hatası fırlar (çağıran yeniden dener).
 * `ppics/{uid}.` ön eki başka uid'in dosyasını eşleştiremez (Firebase uid'leri '.' içermez).
 */
async function deleteProfileImages(bucket, uid) {
  if (typeof uid !== 'string' || !uid || /[./]/.test(uid)) throw new Error('geçersiz uid');
  for (const prefix of [`ppics/${uid}.`, `ppics/${uid}/`]) await bucket.deleteFiles({ prefix, force: true });
}
module.exports = { deleteProfileImages };
