// SADECE TEST: Firestore EMÜLATÖRÜNE REST ile (Bearer owner = kuralları atlar) okuma/yazma yardımcıları.
// Üretim Firestore'una asla bağlanmaz; adres 127.0.0.1:8080'e sabittir.
const HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
export const PROJE = 'ticketappflutter';
const KOK = `http://${HOST}/v1/projects/${PROJE}/databases/(default)/documents`;
const BASLIK = { authorization: 'Bearer owner', 'content-type': 'application/json' };

export const tipli = (v) => {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(tipli) } };
  return { mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, tipli(x)])) } };
};
export const duz = (v) => {
  if (!v) return null;
  if ('stringValue' in v) return v.stringValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('doubleValue' in v) return v.doubleValue;
  if ('booleanValue' in v) return v.booleanValue;
  if ('timestampValue' in v) return v.timestampValue;
  if ('arrayValue' in v) return (v.arrayValue.values || []).map(duz);
  if ('mapValue' in v) return Object.fromEntries(Object.entries(v.mapValue.fields || {}).map(([k, x]) => [k, duz(x)]));
  return null;
};
const belge = (o) => ({ fields: Object.fromEntries(Object.entries(o).map(([k, x]) => [k, tipli(x)])) });

export async function oku(yol) {
  const r = await fetch(`${KOK}/${yol}`, { headers: BASLIK });
  if (r.status === 404) return null;
  if (!r.ok) throw new Error(`GET ${yol}: ${r.status}`);
  const j = await r.json();
  return Object.fromEntries(Object.entries(j.fields || {}).map(([k, v]) => [k, duz(v)]));
}
export async function listele(koleksiyon) {
  const out = []; let token = '';
  do {
    const r = await fetch(`${KOK}/${koleksiyon}?pageSize=300${token ? `&pageToken=${token}` : ''}`, { headers: BASLIK });
    if (!r.ok) throw new Error(`LIST ${koleksiyon}: ${r.status}`);
    const j = await r.json();
    for (const d of j.documents || []) out.push({ id: d.name.split('/').pop(), ...Object.fromEntries(Object.entries(d.fields || {}).map(([k, v]) => [k, duz(v)])) });
    token = j.nextPageToken || '';
  } while (token);
  return out;
}
/** Belgeyi tümden yazar (yoksa oluşturur). */
export async function yaz(yol, o) {
  const r = await fetch(`${KOK}/${yol}`, { method: 'PATCH', headers: BASLIK, body: JSON.stringify(belge(o)) });
  if (!r.ok) throw new Error(`PATCH ${yol}: ${r.status} ${await r.text()}`);
}
/** Yalnızca verilen üst düzey alanları günceller. Alt yol için "seats.A1" gibi noktalı alan yolları kullanılabilir. */
export async function guncelle(yol, alanlar) {
  const maske = Object.keys(alanlar).map((k) => `updateMask.fieldPaths=${encodeURIComponent(k.split('.').map((p) => (/^[A-Za-z_][A-Za-z0-9_]*$/.test(p) ? p : `\`${p}\``)).join('.'))}`).join('&');
  // iç içe yol -> iç içe harita
  const govde = {};
  for (const [k, v] of Object.entries(alanlar)) {
    const p = k.split('.'); let h = govde;
    p.slice(0, -1).forEach((a) => { h[a] = h[a] || {}; h = h[a]; });
    h[p.at(-1)] = v;
  }
  const r = await fetch(`${KOK}/${yol}?${maske}`, { method: 'PATCH', headers: BASLIK, body: JSON.stringify(belge(govde)) });
  if (!r.ok) throw new Error(`UPDATE ${yol}: ${r.status} ${await r.text()}`);
}
export async function sil(yol) { await fetch(`${KOK}/${yol}`, { method: 'DELETE', headers: BASLIK }); }
export const yeniId = () => [...crypto.getRandomValues(new Uint8Array(15))].map((b) => 'abcdefghijklmnopqrstuvwxyz0123456789'[b % 36]).join('') + 'Zx';
