/**
 * Stripe entegrasyonu (Checkout Session — barındırılan ödeme sayfası).
 * Stripe API'si çok stabil/iyi dokümante; aşağıdaki alanlar yüksek
 * güvenle doğru, yine de canlıya çıkmadan önce sandbox'ta (test mode
 * anahtarlarla) uçtan uca bir test işlemi yapılması önerilir.
 */

const Stripe = require('stripe');

function client(secrets) {
  if (!secrets.secretKey) {
    const err = new Error('Stripe secret key yapılandırılmamış (STRIPE_SECRET_KEY).');
    err.code = 'not-configured';
    throw err;
  }
  return new Stripe(secrets.secretKey);
}

/**
 * @param {{paymentId:string, amount:number, currency:string, customerEmail:string,
 *          basketDescription:string, successUrl:string, cancelUrl:string}} session
 * @param {{secretKey:string}} secrets
 * @returns {Promise<{checkoutUrl:string, providerRef:string}>}
 */
async function createSession(session, secrets) {
  const stripe = client(secrets);
  const currency = (session.currency || 'try').toLowerCase();

  const checkoutSession = await stripe.checkout.sessions.create({
    mode: 'payment',
    payment_method_types: ['card'],
    customer_email: session.customerEmail || undefined,
    client_reference_id: session.paymentId,
    line_items: [
      {
        price_data: {
          currency,
          unit_amount: Math.round(session.amount * 100), // Stripe tutarı en küçük birim (kuruş/cent) cinsinden bekler.
          product_data: { name: session.basketDescription || 'TiyatRol Bileti' },
        },
        quantity: 1,
      },
    ],
    success_url: session.successUrl,
    cancel_url: session.cancelUrl,
    metadata: { paymentId: session.paymentId },
  });

  return { checkoutUrl: checkoutSession.url, providerRef: checkoutSession.id };
}

/**
 * Stripe webhook imzasını doğrular (stripe-signature header'ı ile).
 * `rawBody` MUTLAKA ham (parse edilmemiş) request body olmalı — Stripe
 * imza doğrulaması JSON.parse sonrası yeniden serialize edilmiş body ile
 * ÇALIŞMAZ.
 * @returns {{success:boolean, paymentId:string|null, raw:any}}
 */
function verifyWebhook(rawBody, signatureHeader, secrets) {
  const stripe = client(secrets);
  if (!secrets.webhookSecret) {
    const err = new Error('Stripe webhook secret yapılandırılmamış (STRIPE_WEBHOOK_SECRET).');
    err.code = 'not-configured';
    throw err;
  }
  const event = stripe.webhooks.constructEvent(rawBody, signatureHeader, secrets.webhookSecret);

  if (event.type === 'checkout.session.completed' || event.type === 'checkout.session.async_payment_succeeded') {
    const cs = event.data.object;
    return { success: true, paymentId: cs.metadata?.paymentId || cs.client_reference_id || null, raw: event };
  }
  if (event.type === 'checkout.session.async_payment_failed' || event.type === 'checkout.session.expired') {
    const cs = event.data.object;
    return { success: false, paymentId: cs.metadata?.paymentId || cs.client_reference_id || null, raw: event };
  }
  // İlgilenmediğimiz event tipleri — no-op sayılır.
  return { success: null, paymentId: null, raw: event };
}

module.exports = { createSession, verifyWebhook };
