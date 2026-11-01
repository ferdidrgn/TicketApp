'use strict';
/**
 * Küçük Türkçe küfür/nefret filtresi (yorum metni). AŞIRI AGRESİF DEĞİL: eşleşme yorumu REDDETMEZ, `status:'pending'`
 * ile yönetici kuyruğuna düşürür (insan karar verir). URL/telefon/e-posta ise ayrıca reddedilir (reviews.js).
 * Normalleştirme: küçük harf, aksan/Türkçe harf varyantları (ı->i, ö->o, ü->u, ş->s, ç->c, ğ->g), basit "leet"
 * (0->o, 1->i, 3->e, 4->a, 5->s, 7->t, @->a, $->s), tekrarlanan harfler tekile iner (siiiktir -> siktir),
 * harf dışı ayraçlar atılır (s.i.k.t.i.r). Listeler normalleştirilmiş biçime çevrilerek karşılaştırılır.
 * Bilinçli olarak yok: "sık" (sık sık), "göt" (götürmek), "hayvan", "salak" gibi sık/masum kullanımı olan sözcükler.
 */
const ZERO_WIDTH = /[​-‏‪-‮⁠﻿]/g;
const LEET = { 0: 'o', 1: 'i', 3: 'e', 4: 'a', 5: 's', 7: 't', '@': 'a', $: 's' };
const TR = { ı: 'i', İ: 'i', ö: 'o', Ö: 'o', ü: 'u', Ü: 'u', ş: 's', Ş: 's', ç: 'c', Ç: 'c', ğ: 'g', Ğ: 'g' };

function fold(s) {
  let o = '';
  for (const ch of String(s == null ? '' : s).replace(ZERO_WIDTH, '').normalize('NFKC')) o += TR[ch] || LEET[ch] || ch;
  return o.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '');
}
const collapse = (s) => s.replace(/(.)\1+/g, '$1');
const norm = (w) => collapse(fold(w));

// Tam jeton olarak aranır (yanlış pozitif riski olan kısa sözcükler).
const TOKENS = new Set(['amk', 'aq', 'pic', 'amcik', 'ibne', 'pust', 'gavat', 'yarak', 'tasak', 'siktir', 'sikik', 'orospu', 'orspu', 'pezevenk',
  'kahpe', 'sikerim', 'sikeyim', 'amina', 'aminakoyim', 'gerizekali', 'serefsiz'].map(norm));
// Birleşik (ayraçsız) metinde alt dize olarak aranır: uzun, belirgin ifadeler.
const squash = (w) => norm(w).replace(/[^a-z]/g, '');
const SUBSTR = ['orospu', 'pezevenk', 'siktir', 'yarak', 'amina koy', 'anani sik', 'sikerim', 'ibne', 'gavat', 'kahpe', 'pic kurusu'].map(squash);
// Nefret söylemi / tehdit: küçük liste, yalnız yönetici kuyruğuna düşürür.
const HATE = ['gavur', 'cingene', 'zenci', 'oldurun', 'geberin', 'gebersin', 'defolun memleketimden'].map(squash);

/** -> { flagged:boolean, reasons:string[] } ('kufur' | 'nefret'). */
function checkText(raw) {
  const folded = collapse(fold(raw));
  const tokens = folded.split(/[^a-z0-9]+/).filter(Boolean);
  const squashed = folded.replace(/[^a-z]/g, '');
  const reasons = [];
  if (tokens.some((t) => TOKENS.has(t)) || SUBSTR.some((w) => w && squashed.includes(w))) reasons.push('kufur');
  if (HATE.some((w) => w && squashed.includes(w))) reasons.push('nefret');
  return { flagged: reasons.length > 0, reasons };
}
module.exports = { checkText };
