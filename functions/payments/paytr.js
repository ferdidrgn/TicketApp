/**
 * PayTR entegrasyonu (iFrame API — barındırılan ödeme sayfası).
 *
 * ⚠️ DOĞRULAMA GEREKİYOR: docs.paytr.com bu ortamdan erişilemediği için
 * alan adları/hash formülü bilinen (yaygın kullanılan) PayTR iFrame API
 * sözleşmesine göre yazıldı. Deploy öncesi mutlaka
 * https://dev.paytr.com/iframe-api adresinden teyit edin ve PayTR mağaza
 * panelinden "Bildirim URL"ini bu fonksiyonların dağıtılan HTTPS adresine
 * (paytrWebhook) ayarlayın — PayTR bildirim URL'sini panelden okur, bu
 * istekte parametre olarak GÖNDERİLMEZ.
 *
 * Akış:
 *   1) createSession(): get-token uç noktasından bir iframe token'ı alır,
 *      barındırılan ödeme sayfası URL'i bu token'dan türetilir.
 *   2) Ödeme tamamlandığında PayTR, panelde tanımlı Bildirim URL'ine
 *      (merchant_oid, status, total_amount, hash) POST eder — imza
 *      `merchant_key`/`merchant_salt` ile HMAC-SHA256 doğrulanır.
 */

const crypto = require('crypto');
const axios = require('axios');

const GET_TOKEN_URL = 'https://www.paytr.com/odeme/api/get-token';

function requireSecrets(secrets) {
  if (!secrets.merchantId || !secrets.merchantKey || !secrets.merchantSalt) {
    const err = new Error('PayTR secrets yapılandırılmamış (PAYTR_MERCHANT_ID / KEY / SALT).');
    err.code = 'not-configured';
    throw err;
  }
}

/**
 * @param {{paymentId:string, amount:number, customerId:string, customerEmail:string,
 *          userIp:string, basketDescription:string, okUrl:string, failUrl:string}} session
 * @param {{merchantId:string, merchantKey:string, merchantSalt:string}} secrets
 * @returns {Promise<{checkoutUrl:string, providerRef:string}>}
 */
async function createSession(session, secrets) {
  requireSecrets(secrets);
  const { merchantId, merchantKey, merchantSalt } = secrets;

  const merchantOid = session.paymentId.replace(/[^a-zA-Z0-9]/g, '');
  const paymentAmountKurus = Math.round(session.amount * 100); // PayTR tutarı kuruş cinsinden bekler.
  const userBasket = Buffer.from(
    JSON.stringify([[session.basketDescription || 'TiyatRol Bileti', session.amount.toFixed(2), 1]]),
  ).toString('base64');
  const noInstallment = 0;
  const maxInstallment = 0;
  const currency = 'TL';
  const testMode = secrets.testMode ? 1 : 0;
  const userIp = session.userIp || '0.0.0.0';

  const hashStr =
    merchantId + userIp + merchantOid + session.customerEmail + paymentAmountKurus +
    userBasket + noInstallment + maxInstallment + currency + testMode;
  const paytrToken = crypto
    .createHmac('sha256', merchantKey)
    .update(hashStr + merchantSalt)
    .digest('base64');

  const form = new URLSearchParams({
    merchant_id: merchantId,
    user_ip: userIp,
    merchant_oid: merchantOid,
    email: session.customerEmail,
    payment_amount: String(paymentAmountKurus),
    payment_type: 'card',
    installment_count: '0',
    currency,
    test_mode: String(testMode),
    non_3d: '0',
    user_name: session.customerName || 'Misafir',
    user_address: 'Belirtilmedi',
    user_phone: '05000000000',
    merchant_ok_url: session.okUrl,
    merchant_fail_url: session.failUrl,
    user_basket: userBasket,
    debug_on: '0',
    client_lang: 'tr',
    paytr_token: paytrToken,
  });

  const { data } = await axios.post(GET_TOKEN_URL, form.toString(), {
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  });

  if (data.status !== 'success') {
    throw new Error(`PayTR get-token başarısız: ${data.reason || data.status}`);
  }

  return {
    checkoutUrl: `https://www.paytr.com/odeme/guvenli/${data.token}`,
    providerRef: merchantOid,
  };
}

/**
 * PayTR bildirim (webhook) gövdesini doğrular.
 * @param {{merchant_oid:string, status:string, total_amount:string, hash:string}} body
 * @param {{merchantKey:string, merchantSalt:string}} secrets
 * @returns {{success:boolean, paymentRef:string}}
 */
function verifyNotification(body, secrets) {
  const { merchant_oid, status, total_amount, hash } = body;
  const expected = crypto
    .createHmac('sha256', secrets.merchantKey)
    .update(merchant_oid + secrets.merchantSalt + status + total_amount)
    .digest('base64');

  if (expected !== hash) {
    const err = new Error('PayTR bildirim imzası geçersiz.');
    err.code = 'invalid-signature';
    throw err;
  }

  return { success: status === 'success', paymentRef: merchant_oid };
}

module.exports = { createSession, verifyNotification };
