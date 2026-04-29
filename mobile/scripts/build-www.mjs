// Minimaler www-Build: Splash-HTML, das auf Production-URL weiterleitet
// (oder im Dev-Build wird capacitor.config.server.url verwendet).
import fs from 'node:fs';
import path from 'node:path';

const root = path.dirname(new URL(import.meta.url).pathname.replace(/^\/(\w:)/, '$1'));
const wwwDir = path.join(root, '..', 'www');
fs.mkdirSync(wwwDir, { recursive: true });

const url = process.env.SHEETSTORM_PROD_URL ?? 'https://sheetstorm.app';
const html = `<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Sheetstorm</title>
  <style>
    body { margin: 0; font-family: system-ui, sans-serif; background: #0d6efd; color: #fff;
      display: flex; align-items: center; justify-content: center; height: 100vh; }
    .center { text-align: center; }
    .spinner { width: 32px; height: 32px; border-radius: 50%; border: 3px solid rgba(255,255,255,.3);
      border-top-color: #fff; animation: spin 1s linear infinite; margin: 1rem auto; }
    @keyframes spin { to { transform: rotate(360deg) } }
  </style>
</head>
<body>
  <div class="center">
    <h1>🎵 Sheetstorm</h1>
    <div class="spinner"></div>
    <p>Lade …</p>
  </div>
  <script>setTimeout(() => location.href = ${JSON.stringify(url)}, 200);</script>
</body>
</html>
`;

fs.writeFileSync(path.join(wwwDir, 'index.html'), html);
console.log('www/index.html erzeugt; Ziel:', url);
