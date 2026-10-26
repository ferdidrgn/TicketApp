'use strict';
// Sağlayıcı kayıt defteri. Yeni sağlayıcı: providers/<ad>.js yazıp buraya `factories` içine ekleyin
// (arayüz için bkz. iyzico.js üst yorumu). BKM Express'in güncel durumu belirsiz olduğundan EKLENMEDİ.
const { createIyzico } = require('./iyzico');

const factories = {
  iyzico: (creds) => createIyzico(creds),
};

function createProvider(name, creds) {
  const f = factories[name];
  return f ? f(creds) : null;
}

const SUPPORTED = Object.keys(factories);

module.exports = { createProvider, SUPPORTED };
