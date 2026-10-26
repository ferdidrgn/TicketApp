'use strict';
/**
 * SAHTE iyzico Checkout Form sunucusu (yalnızca test). Resmî dokümana (docs.iyzico.com, CF-Initialize /
 * CF-Retrieve / hmacsha256-auth) göre şekilleri taklit eder:
 *   - Authorization: IYZWSv2 base64("apiKey:..&randomKey:..&signature:..") ; signature = HMAC-SHA256(secret, randomKey + path + body) hex.
 *     İmza YENİDEN HESAPLANIR; yanlışsa 400/1000 döner (gerçek iyzico gibi).
 *   - initialize: zorunlu alanlar doğrulanır (price, paidPrice, currency, callbackUrl, buyer.*, billingAddress.*, basketItems[].*),
 *     sepet toplamı == price olmalı. -> {status, token, checkoutFormContent, paymentPageUrl, conversationId}
 *   - detail: token ile ödeme sonucu. Sonucu test belirler (mock.pay).
 * GERÇEK iyzico sandbox'ı DEĞİLDİR; gerçek davranış için sandbox denemesi şart (docs/ODEME-GUVENLIK.md).
 */
const http = require('http');
const crypto = require('crypto');

const INIT = '/payment/iyzipos/checkoutform/initialize/auth/ecom';
const DETAIL = '/payment/iyzipos/checkoutform/auth/ecom/detail';

const need = (o, keys, prefix, errs) => { for (const k of keys) if (o?.[k] == null || o[k] === '') errs.push(`${prefix}.${k}`); };

function validateInit(b) {
  const errs = [];
  need(b, ['price', 'paidPrice', 'currency', 'callbackUrl', 'buyer', 'billingAddress', 'basketItems'], 'req', errs);
  need(b.buyer, ['id', 'name', 'surname', 'identityNumber', 'email', 'gsmNumber', 'registrationAddress', 'city', 'country'], 'buyer', errs);
  need(b.billingAddress, ['address', 'contactName', 'city', 'country'], 'billingAddress', errs);
  if (!Array.isArray(b.basketItems) || !b.basketItems.length) errs.push('basketItems[]');
  else b.basketItems.forEach((it, i) => need(it, ['id', 'price', 'name', 'category1', 'itemType'], `basketItems[${i}]`, errs));
  if (b.basketItems?.some((it) => it.itemType === 'PHYSICAL')) need(b.shippingAddress, ['address', 'contactName', 'city', 'country'], 'shippingAddress', errs);
  if (!errs.length) {
    const sum = b.basketItems.reduce((n, it) => n + Math.round(Number(it.price) * 100), 0);
    if (sum !== Math.round(Number(b.price) * 100)) errs.push('basket_total_mismatch');
    if (Math.round(Number(b.paidPrice) * 100) !== Math.round(Number(b.price) * 100)) errs.push('paidPrice_ne_price');
    if (!/^https:\/\//.test(b.callbackUrl) && !/^http:\/\/(127\.0\.0\.1|localhost)/.test(b.callbackUrl)) errs.push('callbackUrl');
    if (!['TRY', 'USD', 'EUR', 'GBP', 'NOK', 'CHF'].includes(b.currency)) errs.push('currency');
  }
  return errs;
}

function startMock({ port = 8787, apiKey = 'sandbox-fake-api-key', secretKey = 'sandbox-fake-secret-key' } = {}) {
  const sessions = new Map(); // token -> {body, outcome, paidPrice, ...}
  const log = []; // {path, ok}
  let n = 0;

  function authOk(req, path, bodyStr) {
    const h = req.headers.authorization || '';
    if (!h.startsWith('IYZWSv2 ')) return false;
    const dec = Buffer.from(h.slice(8), 'base64').toString('utf8');
    const m = /^apiKey:(.+)&randomKey:(.+)&signature:([0-9a-f]{64})$/.exec(dec);
    if (!m || m[1] !== apiKey) return false;
    const sig = crypto.createHmac('sha256', secretKey).update(m[2] + path + bodyStr).digest('hex');
    return sig === m[3];
  }

  const server = http.createServer((req, res) => {
    const chunks = [];
    req.on('data', (c) => chunks.push(c));
    req.on('end', () => {
      const bodyStr = Buffer.concat(chunks).toString('utf8');
      const send = (code, obj) => { res.writeHead(code, { 'Content-Type': 'application/json' }); res.end(JSON.stringify(obj)); };
      const fail = (code, errorCode, errorMessage, conversationId) =>
        send(400, { status: 'failure', errorCode, errorMessage, locale: 'tr', systemTime: Date.now(), conversationId });
      const path = req.url.split('?')[0];
      let b = {};
      try { b = bodyStr ? JSON.parse(bodyStr) : {}; } catch { return fail(400, '1', 'invalid json'); }
      if (req.method !== 'POST' || ![INIT, DETAIL].includes(path)) return send(404, { status: 'failure' });
      if (!authOk(req, path, bodyStr)) { log.push({ path, ok: false, why: 'auth' }); return fail(400, '1000', 'Geçersiz imza', b.conversationId); }

      if (path === INIT) {
        const errs = validateInit(b);
        if (errs.length) { log.push({ path, ok: false, why: errs }); return fail(400, '11', `Eksik/hatalı alan: ${errs.join(',')}`, b.conversationId); }
        const token = `mocktok_${++n}_${crypto.randomBytes(8).toString('hex')}`;
        sessions.set(token, { body: b, outcome: null });
        log.push({ path, ok: true });
        return send(200, {
          status: 'success', locale: 'tr', systemTime: Date.now(), conversationId: b.conversationId, token,
          checkoutFormContent: '<script>/* mock iyzico form */</script><div id="iyzipay-checkout-form"></div>',
          paymentPageUrl: `http://127.0.0.1:${port}/pay/${token}`, signature: 'mock',
        });
      }
      // DETAIL
      const s = sessions.get(b.token);
      log.push({ path, ok: !!s });
      if (!s || !s.outcome) return fail(400, '5', 'Ödeme bulunamadı', b.conversationId);
      const base = {
        status: 'success', locale: 'tr', systemTime: Date.now(), conversationId: s.body.conversationId, token: b.token,
        currency: s.body.currency, basketId: s.body.basketId, price: Number(s.body.price), signature: 'mock',
      };
      if (s.outcome === 'fail') return send(200, { ...base, paymentStatus: 'FAILURE', paidPrice: 0, errorCode: '10051', errorMessage: 'Yetersiz bakiye' });
      const paidPrice = s.paidPrice != null ? s.paidPrice : Number(s.body.paidPrice);
      return send(200, {
        ...base, paymentStatus: 'SUCCESS', paidPrice, paymentId: s.paymentId || `pay_${b.token}`, fraudStatus: s.outcome === 'review' ? 0 : 1,
        installment: 1, itemTransactions: [], ...s.override,
      });
    });
  });

  return new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(port, '127.0.0.1', () => resolve({
      port, sessions, log,
      /** Test "kart sahibi" ödemesi: sonucu belirler. outcome: 'success'|'fail'|'review'. */
      pay(token, outcome, opts = {}) {
        const s = sessions.get(token);
        if (!s) throw new Error('mock: bilinmeyen token');
        Object.assign(s, { outcome }, opts);
      },
      close: () => new Promise((r) => server.close(r)),
    }));
  });
}

module.exports = { startMock, INIT, DETAIL };

if (require.main === module) {
  startMock({ port: Number(process.env.MOCK_IYZICO_PORT) || 8787 }).then((m) => console.log(`mock iyzico :${m.port}`));
}
