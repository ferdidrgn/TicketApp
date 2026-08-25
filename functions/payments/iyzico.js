/**
 * iyzico entegrasyonu (Checkout Form — barındırılan ödeme sayfası).
 *
 * ⚠️ DOĞRULAMA GEREKİYOR: Bu dosya iyzico'nun resmi `iyzipay` Node SDK'sının
 * bilinen API yüzeyine göre yazıldı, ancak bu ortamda docs.iyzico.com'a
 * canlı erişim engellendiği için alan adları deploy öncesi mutlaka
 * https://docs.iyzico.com/en/products/checkout-form adresinden teyit
 * edilmeli ve SANDBOX'ta gerçek bir test işlemiyle doğrulanmalıdır.
 *
 * Akış:
 *   1) createSession(): checkoutFormInitialize.create çağrısı yapar,
 *      kullanıcının yönlendirileceği barındırılan ödeme sayfası linkini
 *      (paymentPageUrl) döner.
 *   2) iyzico ödeme tamamlandığında kullanıcıyı `callbackUrl`'e (bizim
 *      webhook endpoint'imiz) bir `token` ile POST eder.
 *   3) verifyAndGetStatus(): o token ile checkoutForm.retrieve çağrısı
 *      yapılır — bu çağrının KENDİSİ doğrulamadır (secretKey ile
 *      imzalanmış bir API isteği olduğu için sahtesi üretilemez), ayrıca
 *      dönen paymentStatus alanı gerçek sonucu verir.
 */

const Iyzipay = require('iyzipay');

function client(secrets) {
  const apiKey = secrets.apiKey;
  const secretKey = secrets.secretKey;
  const uri = secrets.baseUrl || 'https://sandbox-api.iyzipay.com';
  if (!apiKey || !secretKey) {
    const err = new Error('iyzico secrets yapılandırılmamış (IYZICO_API_KEY / IYZICO_SECRET_KEY).');
    err.code = 'not-configured';
    throw err;
  }
  return new Iyzipay({ apiKey, secretKey, uri });
}

/**
 * @param {{paymentId:string, amount:number, currency:string, customerId:string,
 *          customerEmail:string, customerName:string, callbackUrl:string,
 *          basketDescription:string}} session
 * @param {{apiKey:string, secretKey:string, baseUrl:string}} secrets
 * @returns {Promise<{checkoutUrl:string, providerRef:string}>}
 */
function createSession(session, secrets) {
  const iyzipay = client(secrets);
  const price = session.amount.toFixed(2);

  // ⚠️ iyzico "buyer" alanı için identityNumber/adres gibi KYC bilgileri
  // ZORUNLUDUR. TicketApp'ın User modelinde şu an TC Kimlik No / açık adres
  // toplanmıyor — production'a çıkmadan önce bu alanların kullanıcıdan
  // (ör. ilk kart ödemesinde tek seferlik bir form ile) toplanması gerekir.
  // Aşağıdaki değerler SADECE SANDBOX testlerinde çalışacak yer tutuculardır.
  const buyer = {
    id: session.customerId,
    name: session.customerName || 'Misafir',
    surname: '-',
    gsmNumber: '+905000000000',
    email: session.customerEmail || 'no-reply@tiyatrol.app',
    identityNumber: '11111111111', // SANDBOX placeholder — gerçek TC Kimlik No gerekir.
    registrationAddress: 'Belirtilmedi',
    ip: '85.34.78.112',
    city: 'Istanbul',
    country: 'Turkey',
  };
  const address = {
    contactName: buyer.name,
    city: buyer.city,
    country: buyer.country,
    address: buyer.registrationAddress,
  };

  const request = {
    locale: Iyzipay.LOCALE.TR,
    conversationId: session.paymentId,
    price,
    paidPrice: price,
    currency: session.currency === 'USD' ? Iyzipay.CURRENCY.USD : Iyzipay.CURRENCY.TRY,
    basketId: session.paymentId,
    paymentGroup: Iyzipay.PAYMENT_GROUP.PRODUCT,
    callbackUrl: session.callbackUrl,
    buyer,
    shippingAddress: address,
    billingAddress: address,
    basketItems: [
      {
        id: session.paymentId,
        name: session.basketDescription || 'TiyatRol Bileti',
        category1: 'Bilet',
        itemType: Iyzipay.BASKET_ITEM_TYPE.VIRTUAL,
        price,
      },
    ],
  };

  return new Promise((resolve, reject) => {
    iyzipay.checkoutFormInitialize.create(request, (err, result) => {
      if (err) return reject(err);
      if (result.status !== 'success') {
        return reject(new Error(`iyzico initialize başarısız: ${result.errorMessage || result.status}`));
      }
      // ⚠️ `paymentPageUrl` alanı doğrulanmalı — yoksa `checkoutFormContent`
      // (embed HTML/JS) bir WebView içinde render edilmelidir.
      const checkoutUrl = result.paymentPageUrl;
      if (!checkoutUrl) {
        return reject(new Error(
          'iyzico yanıtında paymentPageUrl yok — checkoutFormContent tabanlı ' +
          'WebView entegrasyonuna geçilmesi gerekebilir (bkz. iyzico dokümantasyonu).',
        ));
      }
      resolve({ checkoutUrl, providerRef: result.token });
    });
  });
}

/**
 * Webhook/callback handler'ından çağrılır. `token`'ı iyzico'ya karşı
 * doğrular ve gerçek ödeme durumunu döner.
 * @returns {Promise<{success:boolean, paymentId:string, raw:any}>}
 */
function verifyAndGetStatus(token, secrets) {
  const iyzipay = client(secrets);
  return new Promise((resolve, reject) => {
    iyzipay.checkoutForm.retrieve({ locale: Iyzipay.LOCALE.TR, token }, (err, result) => {
      if (err) return reject(err);
      resolve({
        success: result.status === 'success' && result.paymentStatus === 'SUCCESS',
        paymentId: result.conversationId,
        raw: result,
      });
    });
  });
}

module.exports = { createSession, verifyAndGetStatus };
