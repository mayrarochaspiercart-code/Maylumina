/* ═══════════════════════════════════════════════════════════════════
   MAYLUMINA — GERADOR DAS CAPAS DA HOME

   Por que isto existe: as capas precisam estar no HTML inicial, para
   serem indexáveis e navegáveis sem JavaScript. Mas duplicar a marcação
   à mão faria o modelo de edições deixar de ser a fonte da verdade.

   Então a fonte da verdade continua sendo assets/js/edicoes.js, e este
   script escreve a marcação correspondente dentro de index.html, entre
   os marcadores CAPAS:INICIO e CAPAS:FIM. A saída é versionada — não há
   build no deploy.

   Uso, ao mexer em EDICOES:
     node tools/gerar-capas.mjs

   Ele falha se o arquivo já estiver na forma correta? Não: é idempotente,
   pode rodar quantas vezes quiser.
   ═══════════════════════════════════════════════════════════════════ */

import { readFile, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

/* tools/ e docs/ vivem FORA de maylumina/, que é a raiz publicada na
   Vercel: ferramenta de build e documentação interna não têm por que
   ficar acessíveis na internet. Daí o caminho abaixo. */
const raiz = join(dirname(fileURLToPath(import.meta.url)), '..', 'maylumina');
const { EDICOES } = await import(join(raiz, 'assets/js/edicoes.js'));

const esc = (t) =>
  String(t)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');

function capaHTML(ed, i) {
  const publicada = ed.status === 'publicada';
  const tag = publicada ? 'a' : 'article';
  const p = '        ';

  const atributos = [
    `class="capa iridescente entra entra-${Math.min(i + 1, 3)}${publicada ? '' : ' capa--breve'}"`,
    `style="--capa-cor-a:${esc(ed.corLuz)}"`
  ];
  if (publicada) {
    atributos.push(`href="${esc(ed.url)}"`);
    atributos.push('data-capa');
    atributos.push(`aria-label="Abrir edição ${esc(ed.numero)}: ${esc(ed.titulo)}"`);
  }

  // O espaço vai ANTES do <br>: sem ele o texto acessível cola as palavras
  // ("Autocuidadotambém é arte") para leitor de tela e crawler.
  const manchete = ed.manchete
    .map((linha, k) => esc(linha) + (k === ed.manchete.length - 1 ? '' : ' <br>'))
    .join('');

  const chamadas = ed.chamadas
    .slice(0, 4)
    .map((c) => `<li>${esc(c)}</li>`)
    .join('');

  const abrir = publicada
    ? `\n${p}      <span class="capa__abrir">${esc(ed.cta)}<span>→</span></span>`
    : '';

  const recuo = p + ' '.repeat(tag.length + 2);

  return [
    `${p}<${tag} ${atributos.join('\n' + recuo)}>`,
    `${p}  <div class="capa__foto">`,
    `${p}    <img src="${esc(ed.capa.src)}" alt="${esc(ed.capa.alt)}"`,
    `${p}         width="${ed.capa.largura}" height="${ed.capa.altura}"`,
    `${p}         loading="${i === 0 ? 'eager' : 'lazy'}" decoding="async"${i === 0 ? ' fetchpriority="high"' : ''}>`,
    `${p}  </div>`,
    `${p}  <div class="capa__luz" aria-hidden="true"></div>`,
    `${p}  <div class="capa__grade">`,
    `${p}    <div class="capa__topo">`,
    `${p}      <span class="capa__marca">MayLumina</span>`,
    `${p}      <span>Edição ${esc(ed.numero)}</span>`,
    `${p}    </div>`,
    `${p}    <h3 class="capa__manchete">${manchete}</h3>`,
    `${p}    <div class="capa__base">`,
    `${p}      <p class="capa__deck">${esc(ed.deck)}</p>`,
    `${p}      <ul class="capa__chamadas">${chamadas}</ul>${abrir}`,
    `${p}    </div>`,
    `${p}  </div>`,
    `${p}</${tag}>`
  ].join('\n');
}

/* A ficha da banca é lida como ficha de revista: "Edições · 01 – 02 ·
   Em circulação". O meio é a faixa de números publicados, não uma
   contagem solta. */
const numeros = EDICOES.filter((e) => e.status === 'publicada').map((e) => e.numero);
const contagem =
  numeros.length === 0 ? '—'
  : numeros.length === 1 ? numeros[0]
  : `${numeros[0]} – ${numeros[numeros.length - 1]}`;

const capas = EDICOES.map(capaHTML).join('\n\n');

const alvo = join(raiz, 'index.html');
let html = await readFile(alvo, 'utf8');

const marcadores = /(<!-- CAPAS:INICIO[\s\S]*?-->)[\s\S]*?([ \t]*<!-- CAPAS:FIM -->)/;
if (!marcadores.test(html)) {
  console.error('Marcadores CAPAS:INICIO / CAPAS:FIM não encontrados em index.html');
  process.exit(1);
}
html = html.replace(marcadores, (_, abre, fecha) => `${abre}\n\n${capas}\n\n${fecha}`);

html = html.replace(
  /(<span id="contagem-edicoes">)[^<]*(<\/span>)/,
  (_, a, b) => a + contagem + b
);

await writeFile(alvo, html);
console.log(`index.html atualizado: ${EDICOES.length} capas, ficha "${contagem}".`);
