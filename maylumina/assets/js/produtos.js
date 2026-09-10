/* ═══════════════════════════════════════════════════════════════════
   MAYLUMINA — VITRINE EDITORIAL
   O card carrega só o que decide. O texto longo abre numa gaveta.
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

/* ── Card ────────────────────────────────────────────────────────── */
function montarCard(p, aoAbrir) {
  const botao = document.createElement('button');
  botao.type = 'button';
  botao.className = 'produto entra';
  botao.setAttribute('aria-haspopup', 'dialog');

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

  const nome = document.createElement('span');
  nome.className = 'produto__nome';
  nome.textContent = p.nome;

  const notas = document.createElement('span');
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

  const base = document.createElement('span');
  base.className = 'produto__base';
  if (p.preco != null) {
    const preco = document.createElement('span');
    preco.className = 'produto__preco';
    preco.textContent = emReais(p.preco);
    base.appendChild(preco);
  }
  const acao = document.createElement('span');
  acao.className = 'produto__acao';
  acao.append('Descobrir', Object.assign(document.createElement('span'), { textContent: '→' }));
  base.appendChild(acao);

  ficha.append(nome, notas, base);
  botao.append(midia, ficha);

  botao.addEventListener('click', () => aoAbrir(p, botao));
  return botao;
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

/* ── Gaveta de detalhe ───────────────────────────────────────────── */
function criarGaveta() {
  const raiz = document.createElement('div');
  raiz.className = 'gaveta';
  raiz.setAttribute('role', 'dialog');
  raiz.setAttribute('aria-modal', 'true');
  raiz.setAttribute('aria-labelledby', 'gaveta-nome');
  raiz.hidden = true;

  const fundo = document.createElement('button');
  fundo.className = 'gaveta__fundo';
  fundo.type = 'button';
  fundo.setAttribute('aria-label', 'Fechar detalhes do produto');

  const painel = document.createElement('div');
  painel.className = 'gaveta__painel';

  const fechar = document.createElement('button');
  fechar.type = 'button';
  fechar.className = 'gaveta__fechar';
  fechar.innerHTML = '<span aria-hidden="true">✕</span> Fechar';

  const foto = document.createElement('img');
  foto.className = 'gaveta__foto';
  foto.alt = '';
  foto.loading = 'lazy';

  const nome = document.createElement('h2');
  nome.className = 'gaveta__nome';
  nome.id = 'gaveta-nome';

  const preco = document.createElement('p');
  preco.className = 'gaveta__preco';

  const descricao = document.createElement('div');
  descricao.className = 'gaveta__descricao';

  const comprar = document.createElement('a');
  comprar.className = 'botao';
  comprar.target = '_blank';
  comprar.rel = 'noopener';
  comprar.append(
    'Falar sobre este produto',
    Object.assign(document.createElement('span'), {
      className: 'botao__seta', textContent: '→'
    })
  );

  painel.append(fechar, foto, nome, preco, descricao, comprar);
  raiz.append(fundo, painel);
  document.body.appendChild(raiz);

  let devolverFocoPara = null;

  function abrir(p, origem) {
    devolverFocoPara = origem;
    nome.textContent = p.nome;
    preco.textContent = p.preco != null ? emReais(p.preco) : '';
    preco.hidden = p.preco == null;

    foto.hidden = !p.imagem_url;
    if (p.imagem_url) {
      foto.src = p.imagem_url;
      foto.alt = `${p.nome} — produto MayLumina`;
    }

    // Parágrafos por textContent: conteúdo externo nunca vira HTML
    descricao.replaceChildren();
    String(p.descricao || '')
      .split(/\n{2,}|(?<=\.)\s{2,}/)
      .map((t) => t.trim())
      .filter(Boolean)
      .forEach((t) => {
        const par = document.createElement('p');
        par.textContent = t;
        descricao.appendChild(par);
      });

    const msg = `Olá! Tenho interesse no produto ${p.nome}` +
      (p.preco != null ? ` (${emReais(p.preco)})` : '') + '.';
    comprar.href = `https://wa.me/${WHATSAPP}?text=${encodeURIComponent(msg)}`;

    raiz.hidden = false;
    document.body.classList.add('travado');
    // O foco só entra depois de a gaveta ficar visível: elemento com
    // visibility:hidden não aceita foco, e a chamada se perderia.
    requestAnimationFrame(() => {
      raiz.classList.add('aberta');
      fechar.focus();
    });
  }

  function fecharGaveta() {
    raiz.classList.remove('aberta');
    document.body.classList.remove('travado');
    const fim = () => { raiz.hidden = true; };
    setTimeout(fim, 600);
    devolverFocoPara?.focus();
  }

  fundo.addEventListener('click', fecharGaveta);
  fechar.addEventListener('click', fecharGaveta);
  document.addEventListener('keydown', (e) => {
    if (raiz.hidden) return;
    if (e.key === 'Escape') { fecharGaveta(); return; }
    if (e.key === 'Tab') {
      const itens = [...painel.querySelectorAll('button, a[href]')].filter(
        (el) => !el.hidden
      );
      if (!itens.length) return;
      const primeiro = itens[0], ultimo = itens[itens.length - 1];
      if (e.shiftKey && document.activeElement === primeiro) {
        e.preventDefault(); ultimo.focus();
      } else if (!e.shiftKey && document.activeElement === ultimo) {
        e.preventDefault(); primeiro.focus();
      }
    }
  });

  return abrir;
}

/* ── Carga ───────────────────────────────────────────────────────── */
export async function carregarProdutos({ alvo, categoria }) {
  const grade = typeof alvo === 'string' ? document.querySelector(alvo) : alvo;
  if (!grade) return;

  const abrirGaveta = criarGaveta();
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
    estado(
      grade,
      'Não foi possível carregar',
      'Os produtos não vieram agora. Pode ser a conexão.',
      { rotulo: 'Tentar de novo', aoClicar: () => carregarProdutos({ alvo: grade, categoria }) }
    );
    return;
  }

  if (!Array.isArray(produtos) || !produtos.length) {
    estado(grade, 'Em breve', 'Esta edição ainda está sendo preparada.');
    return;
  }

  grade.replaceChildren();
  produtos.forEach((p, i) => {
    const card = montarCard(p, abrirGaveta);
    card.classList.add(`entra-${Math.min(i, 3)}`);
    grade.appendChild(card);
  });

  // Deixa os cards visíveis mesmo se o observador global já tiver rodado
  requestAnimationFrame(() =>
    grade.querySelectorAll('.entra').forEach((el) => el.classList.add('visivel'))
  );
  animarQuandoVisivel(grade);
}
