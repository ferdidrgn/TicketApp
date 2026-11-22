function baslikKimligi(metin, sira) {
  const kok = metin
    .toLocaleLowerCase('tr-TR')
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9çğıöşü]+/gi, '-')
    .replace(/^-|-$/g, '')
    .slice(0, 56);
  return kok || `bolum-${sira + 1}`;
}

export function metinSayfasiniHazirla() {
  const makale = document.querySelector('.metin');
  if (!makale) return;

  makale.querySelectorAll('table').forEach((tablo) => {
    if (tablo.parentElement?.classList.contains('metin-tabla-kaydir')) return;
    const kaydir = document.createElement('div');
    kaydir.className = 'metin-tabla-kaydir';
    kaydir.tabIndex = 0;
    kaydir.setAttribute('role', 'region');
    kaydir.setAttribute('aria-label', 'Tablo, yatay kaydırılabilir');
    tablo.before(kaydir);
    kaydir.append(tablo);
  });

  makale.querySelector('.metin-icindekiler')?.remove();
  const basliklar = [...makale.querySelectorAll('h2')];
  if (basliklar.length < 4) return;

  const kullanilan = new Set();
  basliklar.forEach((baslik, sira) => {
    let kimlik = baslik.id || baslikKimligi(baslik.textContent || '', sira);
    const temel = kimlik;
    let tekrar = 2;
    while (kullanilan.has(kimlik) || (document.getElementById(kimlik) && document.getElementById(kimlik) !== baslik)) {
      kimlik = `${temel}-${tekrar++}`;
    }
    baslik.id = kimlik;
    kullanilan.add(kimlik);
  });

  const nav = document.createElement('nav');
  nav.className = 'metin-icindekiler';
  nav.setAttribute('aria-label', 'Bu sayfadaki bölümler');
  const ayrinti = document.createElement('details');
  ayrinti.open = matchMedia('(min-width: 768px)').matches;
  const ozet = document.createElement('summary');
  ozet.textContent = 'Bu sayfada';
  const liste = document.createElement('ol');
  basliklar.forEach((baslik) => {
    const oge = document.createElement('li');
    const bag = document.createElement('a');
    bag.href = `#${baslik.id}`;
    bag.textContent = baslik.textContent || 'Bölüm';
    oge.append(bag);
    liste.append(oge);
  });
  ayrinti.append(ozet, liste);
  nav.append(ayrinti);
  makale.querySelector('h1')?.insertAdjacentElement('afterend', nav);
}
