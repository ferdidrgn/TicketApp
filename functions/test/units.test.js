'use strict';
// Emülatör gerektirmeyen birim testleri (util + iyzico imzası).
const { test } = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('crypto');
const { parsePriceKurus, parseEventDateMs } = require('../src/util');
const { createIyzico, INIT_PATH, DETAIL_PATH } = require('../providers/iyzico');

test('parsePriceKurus', () => {
  assert.equal(parsePriceKurus('0'), 0);
  assert.equal(parsePriceKurus(''), 0);
  assert.equal(parsePriceKurus(null), 0);
  assert.equal(parsePriceKurus('150'), 15000);
  assert.equal(parsePriceKurus('150,5'), 15050);
  assert.equal(parsePriceKurus('1.250,50'), 125050);
  assert.equal(parsePriceKurus('99.99'), 9999);
  assert.equal(parsePriceKurus('250 TL'), 25000);
  assert.equal(parsePriceKurus('abc'), null);
  assert.equal(parsePriceKurus('-5'), null);
  assert.equal(parsePriceKurus('1e9'), null);
});

test('parseEventDateMs: yerel (UTC+3) saat', () => {
  assert.equal(parseEventDateMs('15.11.2026,22:00'), Date.UTC(2026, 10, 15, 19, 0));
  assert.equal(parseEventDateMs('2026-11-15T22:00:00.000'), Date.UTC(2026, 10, 15, 19, 0));
  assert.equal(parseEventDateMs('2026-11-15T19:00:00.000Z'), Date.UTC(2026, 10, 15, 19, 0));
  assert.equal(parseEventDateMs('saçma'), null);
  assert.equal(parseEventDateMs(''), null);
});

test('iyzico: IYZWSv2 imzası doğru, gövde sunucu tutarını taşır, yanıt normalize edilir', async () => {
  const calls = [];
  const fetchImpl = async (url, opts) => {
    calls.push({ url, opts });
    const body = JSON.parse(opts.body);
    if (url.endsWith(INIT_PATH)) return { status: 200, json: async () => ({ status: 'success', token: 'T1', paymentPageUrl: 'https://p/T1', checkoutFormContent: '<s/>' }) };
    return { status: 200, json: async () => ({ status: 'success', paymentStatus: 'SUCCESS', price: '400.0', paidPrice: 400, currency: 'TRY', conversationId: body.conversationId, basketId: 'o1', paymentId: '77' }) };
  };
  const iy = createIyzico({ apiKey: 'AK', secretKey: 'SK', baseUrl: 'https://sandbox-api.iyzipay.com/', fetchImpl, randomKey: () => 'RND' });
  const s = await iy.initialize({
    order: { id: 'o1', totalStr: '400.00', itemName: 'Bilet' }, buyer: { id: 'u' }, address: { city: 'X' }, callbackUrl: 'https://cb',
  });
  assert.equal(s.token, 'T1');
  const c = calls[0];
  assert.equal(c.url, 'https://sandbox-api.iyzipay.com' + INIT_PATH);
  const body = JSON.parse(c.opts.body);
  assert.equal(body.price, '400.00'); assert.equal(body.paidPrice, '400.00'); assert.equal(body.conversationId, 'o1');
  assert.equal(body.basketItems[0].price, '400.00'); assert.equal(body.callbackUrl, 'https://cb');
  const auth = c.opts.headers.Authorization;
  assert.ok(auth.startsWith('IYZWSv2 '));
  const decoded = Buffer.from(auth.slice(8), 'base64').toString();
  const sig = crypto.createHmac('sha256', 'SK').update('RND' + INIT_PATH + c.opts.body).digest('hex');
  assert.equal(decoded, `apiKey:AK&randomKey:RND&signature:${sig}`);
  assert.equal(c.opts.headers['x-iyzi-rnd'], 'RND');

  const d = await iy.retrieve({ token: 'T1', conversationId: 'o1' });
  assert.equal(calls[1].url, 'https://sandbox-api.iyzipay.com' + DETAIL_PATH);
  assert.deepEqual({ paid: d.paid, paidPrice: d.paidPrice, price: d.price, basketId: d.basketId }, { paid: true, paidPrice: 400, price: 400, basketId: 'o1' });
});

test('iyzico: hata yanıtı initialize\'ı reddeder; FAILURE paid=false', async () => {
  const iy = createIyzico({
    apiKey: 'a', secretKey: 'b',
    fetchImpl: async (url) => ({ status: 200, json: async () => (url.endsWith(INIT_PATH) ? { status: 'failure', errorCode: '1000' } : { status: 'success', paymentStatus: 'FAILURE' }) }),
  });
  await assert.rejects(iy.initialize({ order: { id: 'o', totalStr: '1.00', itemName: 'x' }, buyer: {}, address: {}, callbackUrl: 'c' }), /1000/);
  assert.equal((await iy.retrieve({ token: 't', conversationId: 'o' })).paid, false);
});
