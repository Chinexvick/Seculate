// Build step: writes a fully rendered HTML file for every page, plus 404.html and sitemap.xml.
// Run after `vite build` (client) and `vite build --ssr src/entry-server.tsx` (server bundle).
import { readFileSync, writeFileSync, mkdirSync, rmSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const root = resolve(import.meta.dirname, '..');
const dist = resolve(root, 'dist');
const ssr = await import(pathToFileURL(resolve(root, 'dist-ssr/entry-server.js')).href);
const template = readFileSync(resolve(dist, 'index.html'), 'utf8');

const esc = (s) => s.replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

function page(url, { status404 = false } = {}) {
  const meta = status404 ? { title: 'Page not found', noindex: true } : ssr.metaFor(url);
  const title = ssr.fullTitle(meta.title);
  const description = meta.description ?? ssr.DEFAULT_DESCRIPTION;
  const canonical = ssr.canonicalFor(url);
  const image = meta.image ?? ssr.DEFAULT_IMAGE;
  const jsonLd = status404 ? [] : ssr.jsonLdFor(url);

  // Replace one tag in the template; fail the build loudly if index.html stops matching.
  const set = (html, pattern, value) => {
    const found = typeof pattern === 'string' ? html.includes(pattern) : pattern.test(html);
    if (!found) throw new Error(`prerender: pattern not found in index.html: ${pattern}`);
    // A function replacement keeps "$" in descriptions from being read as a group reference.
    return html.replace(pattern, (_m, a = '', b = '') =>
      typeof pattern === 'string' ? value : value.replace('$1', () => a).replace('$2', () => b),
    );
  };

  let html = template;
  html = set(html, /<title>.*?<\/title>/s, `<title>${esc(title)}</title>`);
  html = set(html, /(<meta name="description" content=")[^"]*(")/, `$1${esc(description)}$2`);
  html = set(html, /(<meta name="robots" content=")[^"]*(")/, `$1${meta.noindex ? 'noindex, follow' : 'index, follow'}$2`);
  html = set(html, /(<link rel="canonical" href=")[^"]*(")/, `$1${canonical}$2`);
  html = set(html, /(<meta property="og:type" content=")[^"]*(")/, `$1${meta.type ?? 'website'}$2`);
  html = set(html, /(<meta property="og:url" content=")[^"]*(")/, `$1${canonical}$2`);
  html = set(html, /(<meta property="og:title" content=")[^"]*(")/, `$1${esc(title)}$2`);
  html = set(html, /(<meta property="og:description" content=")[^"]*(")/, `$1${esc(description)}$2`);
  html = set(html, /(<meta property="og:image" content=")[^"]*(")/, `$1${esc(image)}$2`);
  html = set(html, /(<meta name="twitter:title" content=")[^"]*(")/, `$1${esc(title)}$2`);
  html = set(html, /(<meta name="twitter:description" content=")[^"]*(")/, `$1${esc(description)}$2`);
  html = set(html, /(<meta name="twitter:image" content=")[^"]*(")/, `$1${esc(image)}$2`);
  if (meta.image) {
    // Article images are not 1200x630, so drop the fixed size hints of the default preview.
    html = html.replace(/\s*<meta property="og:image:(width|height)" content="\d+" \/>/g, '');
  }
  const ld = jsonLd.map((o) => `<script type="application/ld+json">${JSON.stringify(o).replace(/</g, '\\u003c')}</script>`).join('\n    ');
  if (ld) html = html.replace('</head>', `    ${ld}\n  </head>`);
  html = set(html, '<div id="root"></div>', `<div id="root">${ssr.render(url)}</div>`);
  return html;
}

const fileFor = (url) => (url === '/' ? 'index.html' : `${url.slice(1)}.html`);
for (const url of ssr.routes) {
  const out = resolve(dist, fileFor(url));
  mkdirSync(dirname(out), { recursive: true });
  writeFileSync(out, page(url));
}
writeFileSync(resolve(dist, '404.html'), page('/404', { status404: true }));

const today = new Date().toISOString().slice(0, 10);
const lastmod = (url) => ssr.posts.find((p) => `/blog/${p.slug}` === url)?.date ?? today;
const sitemap = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${ssr.routes.map((u) => `  <url>\n    <loc>${ssr.canonicalFor(u)}</loc>\n    <lastmod>${lastmod(u)}</lastmod>\n  </url>`).join('\n')}
</urlset>
`;
writeFileSync(resolve(dist, 'sitemap.xml'), sitemap);
rmSync(resolve(root, 'dist-ssr'), { recursive: true, force: true });
console.log(`prerendered ${ssr.routes.length} pages + 404.html + sitemap.xml`);
