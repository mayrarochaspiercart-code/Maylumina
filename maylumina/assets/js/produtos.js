/* ═══════════════════════════════════════════════════════════════════
   MAYLUMINA — VITRINE EDITORIAL
   A peça mostra tudo de uma vez: foto, nome, notas, a descrição inteira
   da cliente e o link direto para conversar no WhatsApp. Nada fica atrás
   de um clique.
   Todo conteúdo externo entra por textContent: nada de innerHTML.
   ═══════════════════════════════════════════════════════════════════ */

const SUPABASE_URL = 'https://rkwlumnrlzmusdccwvxd.supabase.co';
// Chave anônima: pública por design, limitada pelas policies da tabela.
const SUPABASE_ANON =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJrd2x1bW5ybHptdXNkY2N3dnhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMxMzEyMDMsImV4cCI6MjA5ODcwNzIwM30.k4n-WiEwXCENCX0ItiZoH-Z1BwYy1429AM8GYOv6_MM';

const WHATSAPP = '5547988412612';

/* Vocabulário sensorial da marca. Serve para transformar uma descrição
   longa nas poucas notas que ajudam a decidir. */
const NOTAS = [
  'amadeirado', 'gourmet', 'relaxante', 'hidratante', 'aveludado', 'floral',
  'cítrico', 'adocicado', 'calmante', 'energizante', 'revigorante', 'nutritivo',
  'alecrim', 'lavanda', 'sândalo', 'chocolate', 'café', 'cereja', 'avelã',
  'aloevera', 'cúrcuma', 'argila', 'morango', 'goiaba', 'erva-doce', 'baunilha',
  'coco', 'rosa', 'jasmim', 'menta', 'esfoliante', 'brilho', 'perolado'
];

const cap = (s) => s.charAt(0).toUpperCase() + s.slice(1);

/** Até três notas curtas, na ordem em que aparecem no texto da cliente. */
function extrairNotas(descricao, categoria) {
  const texto = (descricao || '').toLowerCase();
  const achadas = NOTAS
    .map((n) => ({ n, i: texto.indexOf(n) }))
    .filter((o) => o.i >= 0)
    .sort((a, b) => a.i - b.i)
    .slice(0, 3)
    .map((o) => cap(o.n));

  if (achadas.length) return achadas;

  // Sem vocabulário reconhecido: a primeira oração, enxuta.
  const primeira = (descricao || '').split(/[.!?]/)[0]?.trim();
  if (primeira && primeira.length <= 74) return [primeira];
  if (primeira) return [primeira.slice(0, 70).trimEnd() + '…'];
  return categoria ? [cap(categoria.replace(/-/g, ' '))] : [];
}

const emReais = (v) =>
  Number(v).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });

/* ── Esqueleto: reserva o espaço exato, para nada saltar ─────────── */
function esqueleto(alvo, quantos = 3) {
  alvo.replaceChildren();
  for (let i = 0; i < quantos; i++) {
    const card = document.createElement('div');
    card.className = 'produto esqueleto';
    card.setAttribute('aria-hidden', 'true');
    const midia = document.createElement('div');
    midia.className = 'produto__midia esqueleto__bloco';
    const ficha = document.createElement('div');
    ficha.className = 'produto__ficha';
    ['62%', '84%', '38%'].forEach((w, k) => {
      const l = document.createElement('div');
      l.className = 'esqueleto__bloco';
      l.style.cssText = `height:${k === 0 ? 26 : 14}px;width:${w};margin-bottom:10px`;
      ficha.appendChild(l);
    });
    card.append(midia, ficha);
    alvo.appendChild(card);
  }
}

function estado(alvo, titulo, texto, acao) {
  alvo.replaceChildren();
  const box = document.createElement('div');
  box.className = 'estado';
  const h = document.createElement('p');
  h.className = 'estado__titulo';
  h.textContent = titulo;
  const p = document.createElement('p');
  p.textContent = texto;
  box.append(h, p);
  if (acao) {
    const b = document.createElement('button');
    b.type = 'button';
    b.className = 'botao';
    b.style.marginTop = '1.6rem';
    b.textContent = acao.rotulo;
    b.addEventListener('click', acao.aoClicar);
    box.appendChild(b);
  }
  alvo.appendChild(box);
}

/* ── Descrição ───────────────────────────────────────────────────
   A descrição vem do Supabase como texto puro escrito pela May, e no
   texto real aparecem três formas:

     • parágrafo corrido — a abertura do produto;
     • título de bloco, curto e sem ponto final — "Fragâncias";
     • item "Nome – explicação" — que é, de fato, termo e definição.

   Reconhecer as três transforma um bloco longo numa ficha que se lê de
   relance, sem reescrever uma palavra. Se o texto não tiver nenhuma
   dessas marcas, ele sai como parágrafos e pronto — nada se perde.
   Tudo entra por textContent: descrição de produto nunca vira HTML. */
function montarDescricao(texto) {
  const raiz = document.createElement('div');
  raiz.className = 'produto__descricao';

  const blocos = String(texto || '')
    .split(/\n{2,}/)
    .map((t) => t.trim())
    .filter(Boolean);

  let lista = null;

  for (const bloco of blocos) {
    const item = bloco.match(/^([^.!?\n]{2,36}?)\s+[–—]\s+([\s\S]+)$/);

    if (item) {
      if (!lista) {
        lista = document.createElement('dl');
        lista.className = 'produto__tecnica';
        raiz.appendChild(lista);
      }
      const grupo = document.createElement('div');
      const termo = document.createElement('dt');
      termo.textContent = item[1].trim();
      const texto2 = document.createElement('dd');
      texto2.textContent = item[2].replace(/\s+/g, ' ').trim();
      grupo.append(termo, texto2);
      lista.appendChild(grupo);
      continue;
    }

    lista = null; // qualquer outro bloco encerra a lista corrente

    const ehTitulo = bloco.length <= 36 && !/[.!?;:]$/.test(bloco) && !bloco.includes('\n');
    if (ehTitulo) {
      const titulo = document.createElement('p');
      titulo.className = 'produto__bloco';
      titulo.textContent = bloco;
      raiz.appendChild(titulo);
      continue;
    }

    bloco.split('\n').map((l) => l.trim()).filter(Boolean).forEach((linha) => {
      const par = document.createElement('p');
      par.className = 'produto__par';
      par.textContent = linha;
      raiz.appendChild(par);
    });
  }

  return raiz.childElementCount ? raiz : null;
}

/* ── Peça ────────────────────────────────────────────────────────
   Deixou de ser botão: não há mais nada para abrir. É um artigo, e o
   único elemento clicável dentro dele é o link do WhatsApp. */
function montarCard(p) {
  const artigo = document.createElement('article');
  artigo.className = 'produto entra';

  const midia = document.createElement('div');
  midia.className = 'produto__midia';

  const imagem = (p.imagem_url || '').trim();
  const anima = (p.video_url || '').trim();

  if (imagem) {
    const img = document.createElement('img');
    img.src = imagem;
    img.alt = `${p.nome} — produto MayLumina`;
    img.loading = 'lazy';
    img.decoding = 'async';
    img.width = 800; img.height = 800;
    midia.appendChild(img);
  } else {
    const vazio = document.createElement('div');
    vazio.className = 'produto__vazio';
    vazio.setAttribute('aria-hidden', 'true');
    vazio.textContent = '✦';
    midia.appendChild(vazio);
  }

  // A animação (GIF ou vídeo) só é buscada quando o card chega perto da tela
  if (anima) {
    const ehGif = anima.toLowerCase().includes('.gif');
    const el = ehGif ? document.createElement('img') : document.createElement('video');
    el.className = 'produto__anima';
    el.dataset.fonte = anima;
    if (ehGif) {
      el.alt = '';
      el.decoding = 'async';
    } else {
      el.muted = true; el.loop = true; el.playsInline = true;
      el.preload = 'none';
      el.setAttribute('aria-hidden', 'true');
    }
    midia.appendChild(el);
  }

  const ficha = document.createElement('div');
  ficha.className = 'produto__ficha';

  const nome = document.createElement('h3');
  nome.className = 'produto__nome';
  nome.textContent = p.nome;

  const notas = document.createElement('p');
  notas.className = 'produto__notas';
  const listaNotas = extrairNotas(p.descricao, p.categoria);
  listaNotas.forEach((n, k) => {
    notas.appendChild(Object.assign(document.createElement('span'), { textContent: n }));
    if (k < listaNotas.length - 1) {
      const sep = document.createElement('span');
      sep.className = 'produto__sep';
      sep.setAttribute('aria-hidden', 'true');
      sep.textContent = '·';
      notas.appendChild(sep);
    }
  });

  const descricao = montarDescricao(p.descricao);

  const base = document.createElement('div');
  base.className = 'produto__base';
  if (p.preco != null) {
    const preco = document.createElement('p');
    preco.className = 'produto__preco';
    preco.textContent = emReais(p.preco);
    base.appendChild(preco);
  }

  const msg = `Olá! Tenho interesse no produto ${p.nome}` +
    (p.preco != null ? ` (${emReais(p.preco)})` : '') + '.';
  const falar = document.createElement('a');
  falar.className = 'botao produto__falar';
  falar.href = `https://wa.me/${WHATSAPP}?text=${encodeURIComponent(msg)}`;
  falar.target = '_blank';
  falar.rel = 'noopener';
  falar.append(
    `Falar sobre ${p.nome}`,
    Object.assign(document.createElement('span'), {
      className: 'botao__seta', textContent: '→'
    })
  );
  base.appendChild(falar);

  ficha.append(nome, notas);
  if (descricao) ficha.appendChild(descricao);
  ficha.appendChild(base);

  artigo.append(midia, ficha);
  return artigo;
}

/* ── Animação sob demanda: um único download serve para exibir ───── */
function animarQuandoVisivel(raiz) {
  const alvos = raiz.querySelectorAll('.produto__anima[data-fonte]');
  if (!alvos.length || !('IntersectionObserver' in window)) return;

  const lento = () => {
    const c = navigator.connection;
    return !!c && (c.saveData || ['slow-2g', '2g'].includes(c.effectiveType));
  };

  const obs = new IntersectionObserver(
    (entradas) => {
      entradas.forEach((e) => {
        if (!e.isIntersecting) return;
        const el = e.target;
        obs.unobserve(el);
        if (lento()) return; // em conexão fraca, fica só a foto

        const fonte = el.dataset.fonte;
        delete el.dataset.fonte;

        if (el.tagName === 'IMG') {
          el.addEventListener('load', () => { el.style.opacity = '1'; }, { once: true });
          el.src = fonte;
        } else {
          el.src = fonte;
          el.addEventListener('playing', () => { el.style.opacity = '1'; }, { once: true });
          el.play().catch(() => {});
        }
      });
    },
    { threshold: 0.1, rootMargin: '260px 0px' }
  );
  alvos.forEach((el) => obs.observe(el));
}

/* ── Carga ───────────────────────────────────────────────────────── */
/*
 * `secao` é opcional e resolve o caso da edição que ainda não tem produto:
 * em vez de anunciar "em breve", a seção inteira sai da página e do leitor
 * de tela. A edição fica completa com zero produto — o que ela promete é o
 * que ela entrega. Se a seção vier com o atributo `hidden` no HTML, ela só
 * aparece quando houver produto de verdade, e não pisca no caminho.
 */
export async function carregarProdutos({ alvo, categoria, secao }) {
  const grade = typeof alvo === 'string' ? document.querySelector(alvo) : alvo;
  if (!grade) return;

  const bloco = typeof secao === 'string' ? document.querySelector(secao) : secao;
  const mostrarSecao = () => { if (bloco) bloco.hidden = false; };

  esqueleto(grade);

  const filtro = categoria ? `&categoria=eq.${encodeURIComponent(categoria)}` : '';
  const url =
    `${SUPABASE_URL}/rest/v1/produtos?ativo=eq.true${filtro}` +
    `&select=id,nome,descricao,preco,categoria,imagem_url,video_url` +
    `&order=ordem.asc,created_at.desc`;

  let produtos;
  try {
    const resposta = await fetch(url, {
      headers: { apikey: SUPABASE_ANON, Authorization: `Bearer ${SUPABASE_ANON}` }
    });
    if (!resposta.ok) throw new Error(`Supabase respondeu ${resposta.status}`);
    produtos = await resposta.json();
  } catch (erro) {
    // Falha de rede não é ausência de produto: a seção aparece com o convite
    // a tentar de novo.
    mostrarSecao();
    estado(
      grade,
      'Não foi possível carregar',
      'Os produtos não vieram agora. Pode ser a conexão.',
      { rotulo: 'Tentar de novo', aoClicar: () => carregarProdutos({ alvo: grade, categoria, secao: bloco }) }
    );
    return;
  }

  if (!Array.isArray(produtos) || !produtos.length) {
    if (bloco) {
      bloco.hidden = true;
      grade.replaceChildren();
      // Um link de navegação que aponta para uma seção que não existe é um
      // beco sem saída. Ele sai junto.
      if (bloco.id) {
        document
          .querySelectorAll(`a[href="#${bloco.id}"]`)
          .forEach((link) => { link.hidden = true; });
      }
      return;
    }
    estado(grade, 'Em breve', 'Esta edição ainda está sendo preparada.');
    return;
  }

  mostrarSecao();
  grade.replaceChildren();
  produtos.forEach((p, i) => {
    const card = montarCard(p);
    card.classList.add(`entra-${Math.min(i, 3)}`);
    grade.appendChild(card);
  });

  // Deixa os cards visíveis mesmo se o observador global já tiver rodado
  requestAnimationFrame(() =>
    grade.querySelectorAll('.entra').forEach((el) => el.classList.add('visivel'))
  );
  animarQuandoVisivel(grade);
}
