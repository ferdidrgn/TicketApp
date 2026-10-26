'use strict';
/**
 * iyzico Checkout Form sağlayıcısı.
 *   - initialize : POST /payment/iyzipos/checkoutform/initialize/auth/ecom
 *   - retrieve   : POST /payment/iyzipos/checkoutform/auth/ecom/detail
 *   - Kimlik doğrulama: IYZWSv2 = base64("apiKey:<key>&randomKey:<rnd>&signature:<hmac>"),
 *     hmac = HMAC-SHA256(secretKey, randomKey + uriPath + body) (hex). Bkz. docs.iyzico.com.
 *
 * Sağlayıcı arayüzü (başka sağlayıcı eklemek için aynısını uygulayın):
 *   name: string
 *   initialize({order, buyer, address, callbackUrl}) -> {token, paymentPageUrl?, checkoutFormContent?}
 *   retrieve({token, conversationId})       -> {ok, paid, paidPrice, price, currency,
 *                                              conversationId, basketId, paymentId, rawStatus}
 * `retrieve` ham yanıtı normalize eder; tutar/kimlik KARŞILAŞTIRMASI sağlayıcıdan bağımsız olarak
 * src/orders.js içinde yapılır. İstemci (fetch) enjekte edilebilir (testlerde sahte).
 */
const crypto = require('crypto');

const INIT_PATH = '/payment/iyzipos/checkoutform/initialize/auth/ecom';
const DETAIL_PATH = '/payment/iyzipos/checkoutform/auth/ecom/detail';

function createIyzico({ apiKey, secretKey, baseUrl, fetchImpl, randomKey }) {
  const f = fetchImpl || globalThis.fetch;
  const base = String(baseUrl || 'https://sandbox-api.iyzipay.com').replace(/\/+$/, '');

  function authHeaders(path, bodyStr) {
    const rnd = randomKey ? randomKey() : `${Date.now()}${crypto.randomBytes(6).toString('hex')}`;
    const signature = crypto.createHmac('sha256', secretKey).update(rnd + path + bodyStr).digest('hex');
    const authStr = `apiKey:${apiKey}&randomKey:${rnd}&signature:${signature}`;
    return {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      'x-iyzi-rnd': rnd,
      Authorization: `IYZWSv2 ${Buffer.from(authStr).toString('base64')}`,
    };
  }

  async function post(path, body) {
    const bodyStr = JSON.stringify(body);
    const res = await f(base + path, { method: 'POST', headers: authHeaders(path, bodyStr), body: bodyStr });
    let json;
    try { json = await res.json(); } catch { json = null; }
    if (!json || typeof json !== 'object') throw new Error(`iyzico yanıtı okunamadı (HTTP ${res.status})`);
    return json;
  }

  return {
    name: 'iyzico',

    async initialize({ order, buyer, address, callbackUrl }) {
      const price = order.totalStr; // "100.00"
      const body = {
        locale: 'tr',
        conversationId: order.id,
        price,
        paidPrice: price,
        currency: 'TRY',
        basketId: order.id,
        paymentGroup: 'PRODUCT',
        callbackUrl,
        enabledInstallments: [1],
        buyer,
        shippingAddress: address,
        billingAddress: address,
        basketItems: [{
          id: order.id,
          name: order.itemName,
          category1: 'Bilet',
          itemType: 'VIRTUAL',
          price,
        }],
      };
      const r = await post(INIT_PATH, body);
      if (r.status !== 'success' || !r.token) {
        // errorMessage kullanıcıya gösterilmez/loglanmaz ayrıntısıyla (PII sızıntısı olmasın); kod yeter.
        const e = new Error(`iyzico initialize başarısız: ${r.errorCode || 'bilinmeyen'}`);
        e.providerCode = r.errorCode;
        throw e;
      }
      return {
        token: String(r.token),
        paymentPageUrl: r.paymentPageUrl || null,
        checkoutFormContent: r.checkoutFormContent || null,
      };
    },

    async retrieve({ token, conversationId }) {
      const r = await post(DETAIL_PATH, { locale: 'tr', conversationId, token });
      const num = (x) => (x == null || x === '' ? NaN : Number(x));
      return {
        ok: r.status === 'success',
        paid: r.status === 'success' && r.paymentStatus === 'SUCCESS',
        paidPrice: num(r.paidPrice),
        price: num(r.price),
        currency: r.currency || null,
        conversationId: r.conversationId || null,
        basketId: r.basketId || null,
        paymentId: r.paymentId || null,
        token: r.token || null,
        rawStatus: r.paymentStatus || r.errorCode || null,
      };
    },
  };
}

module.exports = { createIyzico, INIT_PATH, DETAIL_PATH };
