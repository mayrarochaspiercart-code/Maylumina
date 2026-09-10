/* ═══════════════════════════════════════════════════════════════════
   MAYLUMINA — GERADOR DAS IMAGENS DE COMPARTILHAMENTO (Open Graph)

   Antes o og:image era uma fotografia vertical de 974×1280. WhatsApp,
   Instagram e Twitter recortam isso em 1200×630 e cortavam o rosto da
   May. Agora cada rota tem uma imagem desenhada nessa proporção, com a
   tipografia e o pigmento da própria edição.

   As imagens são versionadas — não há build no deploy.

   Uso:
     node tools/gerar-og.mjs
   (requer playwright instalado localmente)
   ═══════════════════════════════════════════════════════════════════ */

import { chromium } from 'playwright';
import { writeFile, readFile } from 'node:fs/promises';
import { createServer } from 'node:http';
import { fileURLToPath } from 'node:url';
import { dirname, join, extname } from 'node:path';

/* tools/ e docs/ vivem FORA de maylumina/, que é a raiz publicada na
   Vercel: ferramenta de build e documentação interna não têm por que
   ficar acessíveis na internet. Daí o caminho abaixo. */
const raiz = join(dirname(fileURLToPath(import.meta.url)), '..', 'maylumina');
const { EDICOES } = await import(join(raiz, 'assets/js/edicoes.js'));

const CARTOES = [
  {
    arquivo: 'og-home.jpg',
    ficha: ['MayLumina', 'Publicação viva'],
    manchete: ['Sua luz', 'também tem <i>cor.</i>'],
    deck: 'Autocuidado, cor e expressão — em edições.',
    a: 'var(--laranja-luz)', b: 'var(--pink-luz)', c: 'var(--turquesa-luz)'
  },
  ...EDICOES.filter((e) => e.status === 'publicada').map((ed) => ({
    arquivo: `og-${ed.slug}.jpg`,
    ficha: ['MayLumina', `Edição ${ed.numero}`, ed.identificacao],
    manchete: ed.manchete.map((l, i) =>
      i === ed.manchete.length - 1 ? `<i>${l}</i>` : l),
    deck: ed.deck,
    a: ed.slug === 'makeup' ? 'var(--roxo-luz)' : 'var(--laranja-luz)',
    b: ed.slug === 'makeup' ? 'var(--turquesa-luz)' : 'var(--pink-luz)',
    c: ed.slug === 'makeup' ? 'var(--pink-luz)' : 'var(--turquesa-luz)'
  }))
];

const pagina = (c) => `<!DOCTYPE html>
<html lang="pt-BR"><head><meta charset="UTF-8">
<link rel="stylesheet" href="/assets/css/fontes.css">
<style>
  :root {
    --papel: #F2EAE0; --papel-claro: #F8F3EC;
    --laranja-luz: #F9D5B4; --pink-luz: #F4C2DA;
    --roxo-luz: #D3BCE3; --turquesa-luz: #B3E4D8;
    --tinta: #3B2F35; --tinta-suave: #5E4E56; --tinta-pink: #8E3560;
  }
  * { margin: 0; box-sizing: border-box; }
  body {
    width: 1200px; height: 630px; overflow: hidden;
    display: grid; align-content: center;
    padding: 74px 88px;
    background:
      radial-gradient(75% 90% at 12% 8%, ${c.a}, transparent 60%),
      radial-gradient(70% 85% at 92% 26%, ${c.b}, transparent 58%),
      radial-gradient(90% 95% at 55% 104%, ${c.c}, transparent 62%),
      var(--papel);
    font-family: 'Quicksand', sans-serif;
    color: var(--tinta);
  }
  .ficha {
    display: flex; align-items: center; gap: 14px;
    font-size: 15px; font-weight: 700; letter-spacing: 0.34em;
    text-transform: uppercase; color: var(--tinta-pink);
    margin-bottom: 30px;
  }
  .risco { width: 26px; height: 1px; background: currentColor; opacity: 0.55; }
  h1 {
    font-family: 'Cormorant Garamond', serif;
    font-weight: 400; font-size: 100px; line-height: 0.97;
    letter-spacing: -0.035em; max-width: 17ch;
  }
  h1 i { font-style: italic; font-weight: 300; }
  p {
    margin-top: 34px; font-size: 25px; letter-spacing: -0.01em;
    color: var(--tinta-suave); max-width: 42ch;
  }
  .fio {
    margin-top: 42px; width: 260px; height: 2px;
    background: linear-gradient(90deg, #F0944E, #E91E8C, #8B4F9F, #00CCA8);
  }
</style></head><body>
  <div class="ficha">${c.ficha.map((f, i) => (i ? '<span class="risco"></span>' : '') + `<span>${f}</span>`).join('')}</div>
  <h1>${c.manchete.join('<br>')}</h1>
  <p>${c.deck}</p>
  <div class="fio"></div>
</body></html>`;

/* Um servidor mínimo, só para o cartão ser carregado da mesma origem dos
   arquivos de fonte — senão o navegador não acha /assets/fonts e o cartão
   sai com a fonte errada, que é o tipo de defeito que ninguém vê até estar
   publicado no WhatsApp de todo mundo. */
const TIPOS = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.woff2': 'font/woff2'
};

let cartaoAtual = '';
const servidor = createServer(async (req, res) => {
  const caminho = decodeURIComponent(req.url.split('?')[0]);
  if (caminho === '/cartao.html') {
    res.writeHead(200, { 'Content-Type': TIPOS['.html'] });
    res.end(cartaoAtual);
    return;
  }
  try {
    const dados = await readFile(join(raiz, caminho.replace(/^\/+/, '')));
    res.writeHead(200, { 'Content-Type': TIPOS[extname(caminho)] || 'application/octet-stream' });
    res.end(dados);
  } catch {
    res.writeHead(404).end();
  }
});
await new Promise((ok) => servidor.listen(0, '127.0.0.1', ok));
const porta = servidor.address().port;

const b = await chromium.launch({ executablePath: process.env.CHROMIUM || undefined });
const pg = await (await b.newContext({ viewport: { width: 1200, height: 630 }, deviceScaleFactor: 1 })).newPage();

for (const c of CARTOES) {
  cartaoAtual = pagina(c);
  await pg.goto(`http://127.0.0.1:${porta}/cartao.html`, { waitUntil: 'load' });
  await pg.evaluate(() => document.fonts.ready);
  const usouAFonte = await pg.evaluate(() =>
    document.fonts.check("400 104px 'Cormorant Garamond'") &&
    document.fonts.check("700 15px 'Quicksand'"));
  if (!usouAFonte) throw new Error(`${c.arquivo}: a tipografia da marca não carregou — cartão descartado.`);

  const img = await pg.screenshot({ type: 'jpeg', quality: 92 });
  await writeFile(join(raiz, 'assets/og', c.arquivo), img);
  console.log(`${c.arquivo} — ${(img.length / 1024).toFixed(0)} KB`);
}
await b.close();
servidor.close();
