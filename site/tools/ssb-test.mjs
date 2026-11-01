// SSS botu test vektörleri (docs/ssb-vectors.json). Çalıştır: node site/tools/ssb-test.mjs  (Dart karşılığı: test/faq_bot_test.dart)
import { readFileSync } from 'node:fs';
import { sor, norm } from '../js/ssb.js';

const v = JSON.parse(readFileSync(new URL('../../docs/ssb-vectors.json', import.meta.url), 'utf8'));
let kotu = 0;
for (const c of v.cases) {
  const r = sor(c.q, v.facts[c.f]);
  if (r.intent !== c.intent || r.answer !== c.answer) { kotu += 1; console.error('HATA:', JSON.stringify(c.q), '\n  beklenen:', c.intent, JSON.stringify(c.answer), '\n  gelen   :', r.intent, JSON.stringify(r.answer)); }
}
const n = { 'İSTANBUL ŞEHİR ÇOCUK ĞÜÖ ıI': 'istanbul sehir cocuk guo ii' };
for (const [a, b] of Object.entries(n)) if (norm(a) !== b) { kotu += 1; console.error('norm HATA:', norm(a)); }
console.log(kotu ? `${kotu} hata` : `ssb: ${v.cases.length} vektör geçti`);
process.exit(kotu ? 1 : 0);
