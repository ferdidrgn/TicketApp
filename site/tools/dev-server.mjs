// Yerel geliştirme sunucusu: site/ klasörünü firebase.json "web" hedefindeki rewrites + cleanUrls kurallarıyla sunar.
//   node site/tools/dev-server.mjs [port=4173]
import http from 'node:http';
import { readFile } from 'node:fs/promises';
import { join, extname, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const KOK = join(dirname(fileURLToPath(import.meta.url)), '..');
const cfg = JSON.parse(await readFile(join(KOK, '..', 'firebase.json'), 'utf8'));
const web = cfg.hosting.find((h) => h.target === 'web');
const kurallar = web.rewrites.map((r) => ({ re: new RegExp(`^${r.source.replace(/[.+?^${}()|[\]\\]/g, '\\$&').replace('/**', '(?:/.*)?')}$`), hedef: r.destination }));
const TUR = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.png': 'image/png', '.jpg': 'image/jpeg', '.svg': 'image/svg+xml', '.webmanifest': 'application/manifest+json', '.json': 'application/json', '.webp': 'image/webp', '.ico': 'image/x-icon' };

http.createServer(async (req, res) => {
  const yol = decodeURIComponent(req.url.split('?')[0]);
  const adaylar = [];
  const kural = kurallar.find((k) => k.re.test(yol));
  if (kural) adaylar.push(kural.hedef);
  adaylar.push(yol.endsWith('/') ? `${yol}index.html` : yol, `${yol}.html`, `${yol}/index.html`);
  for (const a of adaylar) {
    if (a.includes('..')) continue;
    try {
      const veri = await readFile(join(KOK, a));
      res.writeHead(200, { 'content-type': TUR[extname(a)] || 'application/octet-stream', 'cache-control': 'no-store' });
      return res.end(veri);
    } catch {}
  }
  res.writeHead(404, { 'content-type': 'text/html; charset=utf-8' });
  res.end(await readFile(join(KOK, '404.html')).catch(() => 'Bulunamadı'));
}).listen(+(process.argv[2] || 4173), '127.0.0.1', () => console.log('Geliştirme sunucusu: http://localhost:' + (process.argv[2] || 4173)));
