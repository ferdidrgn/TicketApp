/**
 * SES-1885 → Firestore Stage (ticketappflutter)
 * Kaynak: https://www.ortaoyuncular.com/ses-1885
 *
 * node scripts/add_ses_1885_stage.mjs
 */
const PROJECT = 'ticketappflutter';
// Web API key — lib/core/config/firebase_options.dart ile aynı
const API_KEY = 'AIzaSyDTszWHMEMHY1Ed2ZftOcNUlvXl03S7g-k';

const STAGE = {
  name: 'SES-1885',
  address: 'İstiklal Cd. Halep İşhanı 62/90, 34435 Beyoğlu/İstanbul',
  capacity: '502',
  description:
    'Beyoğlu’nun kalbinde, İstiklal Caddesi’nde tarihi Ses-1885 sahnesi. 1885’te Campanaki tarafından inşa edilen yapı; 1989’dan beri Ortaoyuncular’ın evi. Salon 316, alt localar 102, balkon 84 — toplam 502 kişi. Kaynak: ortaoyuncular.com/ses-1885',
  communication: '0212 251 18 65',
  imageUrl: '',
  lat: '41.0347',
  long: '28.9790',
  showsId: [],
};

function str(v) {
  return { stringValue: String(v ?? '') };
}
function arr(strings) {
  return { arrayValue: { values: strings.map((s) => ({ stringValue: s })) } };
}
function tsNow() {
  return { timestampValue: new Date().toISOString() };
}

async function findExisting() {
  const url =
    `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents:runQuery?key=${API_KEY}`;
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      structuredQuery: {
        from: [{ collectionId: 'Stage' }],
        where: {
          fieldFilter: {
            field: { fieldPath: 'name' },
            op: 'EQUAL',
            value: { stringValue: STAGE.name },
          },
        },
        limit: 1,
      },
    }),
  });
  if (!res.ok) return null;
  const rows = await res.json();
  for (const row of rows) {
    if (row.document?.name) return row.document.name.split('/').pop();
  }
  return null;
}

async function create() {
  const url =
    `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/Stage?key=${API_KEY}`;
  const fields = {
    name: str(STAGE.name),
    address: str(STAGE.address),
    capacity: str(STAGE.capacity),
    description: str(STAGE.description),
    communication: str(STAGE.communication),
    imageUrl: str(STAGE.imageUrl),
    lat: str(STAGE.lat),
    long: str(STAGE.long),
    showsId: arr(STAGE.showsId),
    _createdAt: tsNow(),
    _updatedAt: tsNow(),
  };
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields }),
  });
  if (!res.ok) {
    throw new Error(`create ${res.status}: ${(await res.text()).slice(0, 300)}`);
  }
  const doc = await res.json();
  const id = doc.name.split('/').pop();
  const mask = ['_id']
    .map((f) => `updateMask.fieldPaths=${encodeURIComponent(f)}`)
    .join('&');
  const patch = await fetch(`${doc.name}?key=${API_KEY}&${mask}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields: { _id: str(id) } }),
  });
  if (!patch.ok) throw new Error(`_id patch ${patch.status}`);
  return id;
}

const existing = await findExisting();
if (existing) {
  console.log(`Zaten var: Stage/${existing}`);
} else {
  const id = await create();
  console.log(`Eklendi: Stage/${id}`);
}
console.log(JSON.stringify(STAGE, null, 2));
