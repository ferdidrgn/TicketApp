// Yönetim: sahne koltuk planı oluşturucu. Seats/{sahneId} = { seatsId: [...], closedSeatsId?: [...] }.
// Yalnız admin (Firestore rules: Seats yazma = isAdmin). Giriş: Google (admin hesabı). Üretim yazımı kullanıcının kendi oturumuyla yapılır.
import {
  auth, db, onAuthStateChanged, signInWithPopup, GoogleAuthProvider, signOut,
  doc, getDoc, setDoc, updateDoc, collection, getDocs,
} from '../firebase.js';

const app = document.getElementById('app');
const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const bildir = (m) => { const t = document.getElementById('toast'); if (t) { t.textContent = m; t.classList.add('on'); setTimeout(() => t.classList.remove('on'), 3500); } };

/** "A-T:15" (tek harf aralığı), "A:15", "BA:16" biçimlerinden koltuk kimlikleri üretir. Hata varsa { hata }. */
export function koltukUret(metin) {
  const ids = [], satirlar = [];
  const gorulen = new Set();
  const satir = String(metin || '').split(/\r?\n/).map((s) => s.trim()).filter(Boolean);
  for (const ln of satir) {
    const m = /^([A-Z]{1,3})(?:\s*-\s*([A-Z]))?\s*:\s*(\d{1,3})$/.exec(ln.toUpperCase());
    if (!m) return { hata: `Anlaşılamayan satır: "${ln}" (örnek: A-T:15 ya da BA:16)` };
    const [, bas, son, sayi] = m, n = Number(sayi);
    if (n < 1 || n > 80) return { hata: `Satırdaki koltuk sayısı 1–80 olmalı: "${ln}"` };
    let satirAdlari = [bas];
    if (son) {
      if (bas.length !== 1) return { hata: `Aralık yalnız tek harfle olur: "${ln}"` };
      const a = bas.charCodeAt(0), b = son.charCodeAt(0);
      if (b < a) return { hata: `Aralık ters: "${ln}"` };
      satirAdlari = Array.from({ length: b - a + 1 }, (_, i) => String.fromCharCode(a + i));
    }
    for (const ad of satirAdlari) {
      if (gorulen.has(ad)) return { hata: `Satır tekrarlanıyor: ${ad}` };
      gorulen.add(ad);
      satirlar.push([ad, n]);
      for (let i = 1; i <= n; i++) ids.push(`${ad}${i}`);
    }
  }
  return { ids, satirlar };
}

function girisCiz(mesaj = '') {
  app.innerHTML = `<h1>Koltuk planı</h1><p class="muted">Yönetici hesabıyla giriş yap.</p>${mesaj ? `<p class="uyari" role="alert">${esc(mesaj)}</p>` : ''}
    <button class="btn btn-primary" id="gg" type="button">Google ile giriş</button>`;
  document.getElementById('gg').addEventListener('click', async () => {
    try { await signInWithPopup(auth, new GoogleAuthProvider()); } catch (e) { girisCiz(e?.code === 'auth/unauthorized-domain' ? 'Bu alan adı Firebase "Yetkili alanlar" listesinde değil.' : 'Giriş yapılamadı.'); }
  });
}

async function panelCiz(user) {
  const rol = await getDoc(doc(db, 'User', user.uid)).then((d) => (d.exists() ? d.data().role : null)).catch(() => null);
  if (rol !== 'admin') { app.innerHTML = `<h1>Koltuk planı</h1><p class="uyari">Bu hesap yönetici değil.</p><button class="btn btn-ghost" id="cik" type="button">Çıkış</button>`; document.getElementById('cik').onclick = () => signOut(auth); return; }

  const sahneler = (await getDocs(collection(db, 'Stage'))).docs.map((d) => ({ id: d.id, ...d.data() })).sort((a, b) => String(a.name).localeCompare(String(b.name), 'tr'));
  const varsayilan = sahneler.find((s) => /mustafa saffet/i.test(s.name || '')) || sahneler[0];
  app.innerHTML = `<h1>Koltuk planı</h1>
    <p class="muted">Sahnenin koltuk kimliklerini (<code>A1, A2…</code>) üretip <code>Seats</code> koleksiyonuna yazar. Mevcut kapalı koltuk listesi (<code>closedSeatsId</code>) korunur. Daha önce oluşturulmuş seansların koltuk durumu değişmez.</p>
    <div class="kart">
      <label for="sahne">Sahne</label>
      <select id="sahne">${sahneler.map((s) => `<option value="${esc(s.id)}" ${varsayilan && s.id === varsayilan.id ? 'selected' : ''}>${esc(s.name)}${s.capacity ? ` · kapasite ${esc(s.capacity)}` : ''}</option>`).join('')}</select>
      <div id="mevcut" class="muted" style="margin-top:8px"></div>
      <label for="zemin">Zemin katı satırları <span class="muted">(her satır: HARF:KOLTUK ya da A-T:15)</span></label>
      <textarea id="zemin" spellcheck="false">A-T:15</textarea>
      <label for="balkon">Balkon satırları <span class="muted">(kimlik BA, BB… biçiminde)</span></label>
      <textarea id="balkon" spellcheck="false">BA:16
BB:15</textarea>
      <label for="hedef">Hedef toplam koltuk</label>
      <input type="text" id="hedef" value="331" inputmode="numeric">
      <div class="ozet" id="ozet" aria-live="polite"></div>
      <div id="mesaj" aria-live="polite"></div>
      <div class="satirlar" id="satirlar"></div>
    </div>
    <div class="kart">
      <label><input type="checkbox" id="kap" checked> Sahne kapasitesini de toplam koltuk sayısı yap</label>
      <label><input type="checkbox" id="onay"> Satır uzunluklarını gerçek salon düzeniyle karşılaştırdım, yazmak istiyorum</label>
      <button class="btn btn-primary" id="kaydet" type="button" style="margin-top:12px" disabled>Firebase'e yaz</button>
      <button class="btn btn-ghost" id="cik" type="button" style="margin-left:8px">Çıkış</button>
    </div>`;
  const $ = (s) => document.getElementById(s);
  let sonuc = null;

  const hesapla = () => {
    const z = koltukUret($('zemin').value), b = koltukUret($('balkon').value);
    $('mesaj').innerHTML = ''; $('satirlar').innerHTML = ''; sonuc = null;
    if (z.hata || b.hata) { $('ozet').innerHTML = ''; $('mesaj').innerHTML = `<p class="uyari" role="alert">${esc(z.hata || b.hata)}</p>`; $('kaydet').disabled = true; return; }
    const ayniVar = b.satirlar.some(([ad]) => z.satirlar.some(([x]) => x === ad));
    if (ayniVar) { $('mesaj').innerHTML = '<p class="uyari" role="alert">Zemin ve balkon satır adları çakışıyor.</p>'; $('kaydet').disabled = true; return; }
    const ids = [...z.ids, ...b.ids], hedef = Number(String($('hedef').value).replace(/\D/g, '')) || 0;
    sonuc = ids;
    $('ozet').innerHTML = `<span>Zemin: ${z.ids.length}</span><span>Balkon: ${b.ids.length}</span><span>Toplam: ${ids.length}</span>`;
    $('satirlar').innerHTML = [...z.satirlar, ...b.satirlar].map(([a, n]) => `<div><b>${esc(a)}</b> · ${n} koltuk</div>`).join('');
    $('mesaj').innerHTML = hedef && ids.length !== hedef ? `<p class="uyari" role="alert">Toplam ${ids.length}, hedef ${hedef}. Satırları düzelt.</p>` : `<p class="ok">Toplam hedefle uyumlu.</p>`;
    $('kaydet').disabled = !(hedef ? ids.length === hedef : true) || !$('onay').checked;
  };
  const mevcutYaz = async () => {
    const s = $('sahne').value; const d = await getDoc(doc(db, 'Seats', s)).catch(() => null);
    $('mevcut').textContent = d && d.exists() ? `Şu an kayıtlı plan: ${(d.data().seatsId || []).length} koltuk (${(d.data().closedSeatsId || []).length} kapalı).` : 'Bu sahne için kayıtlı koltuk planı yok.';
  };
  ['zemin', 'balkon', 'hedef'].forEach((k) => $(k).addEventListener('input', hesapla));
  $('onay').addEventListener('change', hesapla);
  $('sahne').addEventListener('change', mevcutYaz);
  $('cik').onclick = () => signOut(auth);
  $('kaydet').addEventListener('click', async () => {
    if (!sonuc) return;
    const s = $('sahne').value, ad = (sahneler.find((x) => x.id === s) || {}).name || s;
    if (!confirm(`"${ad}" için ${sonuc.length} koltuk yazılacak. Emin misin?`)) return;
    $('kaydet').disabled = true;
    try {
      await setDoc(doc(db, 'Seats', s), { seatsId: sonuc }, { merge: true });
      if ($('kap').checked) await updateDoc(doc(db, 'Stage', s), { capacity: String(sonuc.length), _updatedAt: new Date().toISOString() });
      bildir('Koltuk planı kaydedildi.'); await mevcutYaz();
    } catch (e) { bildir(e?.code === 'permission-denied' ? 'Yetki reddedildi (Firestore kuralları).' : 'Kaydedilemedi.'); }
    finally { hesapla(); }
  });
  await mevcutYaz(); hesapla();
}

onAuthStateChanged(auth, (u) => { if (u) panelCiz(u).catch((e) => { app.innerHTML = `<p class="uyari">Yüklenemedi: ${esc(e?.code || '')}</p>`; }); else girisCiz(); });
