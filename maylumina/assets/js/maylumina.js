/* ═══════════════════════════════════════════════════════════════════
   MAYLUMINA — RUNTIME COMPARTILHADO
   Navegação, sistema de luz, entrada de conteúdo e fundo em vídeo.
   Tudo degrada com elegância: sem JS, a página continua legível.
   ═══════════════════════════════════════════════════════════════════ */

const semMovimento = () =>
  window.matchMedia('(prefers-reduced-motion: reduce)').matches;

/* ── NAVEGAÇÃO ───────────────────────────────────────────────────── */
function navegacao() {
  const nav = document.querySelector('[data-nav]');
  const botao = document.querySelector('[data-menu-botao]');
  const menu = document.querySelector('[data-menu]');
  if (!nav) return;

  // Fundo da barra só aparece depois que a página sai do topo
  const aoRolar = () => nav.classList.toggle('pousada', window.scrollY > 40);
  aoRolar();
  window.addEventListener('scroll', aoRolar, { passive: true });

  if (!botao || !menu) return;

  const focaveis = () =>
    menu.querySelectorAll('a[href], button:not([disabled])');
  let devolverFocoPara = null;

  function abrir() {
    devolverFocoPara = document.activeElement;
    menu.classList.add('aberto');
    menu.removeAttribute('inert');
    botao.setAttribute('aria-expanded', 'true');
    document.body.classList.add('travado');
    // O foco entra só depois de o painel ficar visível: enquanto o CSS
    // mantiver visibility:hidden, a chamada de foco se perde.
    requestAnimationFrame(() => focaveis()[0]?.focus());
  }

  function fechar() {
    menu.classList.remove('aberto');
    menu.setAttribute('inert', '');
    botao.setAttribute('aria-expanded', 'false');
    document.body.classList.remove('travado');
    devolverFocoPara?.focus();
  }

  const aberto = () => botao.getAttribute('aria-expanded') === 'true';

  botao.addEventListener('click', () => (aberto() ? fechar() : abrir()));
  menu.querySelectorAll('a').forEach((a) => a.addEventListener('click', fechar));

  document.addEventListener('keydown', (e) => {
    if (!aberto()) return;
    if (e.key === 'Escape') { fechar(); return; }
    // Prende o foco dentro do painel enquanto ele estiver aberto
    if (e.key === 'Tab') {
      const itens = [...focaveis()];
      if (!itens.length) return;
      const primeiro = itens[0];
      const ultimo = itens[itens.length - 1];
      if (e.shiftKey && document.activeElement === primeiro) {
        e.preventDefault(); ultimo.focus();
      } else if (!e.shiftKey && document.activeElement === ultimo) {
        e.preventDefault(); primeiro.focus();
      }
    }
  });

  // Voltar ao desktop com o menu aberto não pode deixar o body travado
  window.matchMedia('(min-width: 861px)').addEventListener('change', (ev) => {
    if (ev.matches && aberto()) fechar();
  });

  menu.setAttribute('inert', '');
}

/* ── ENTRADA DE CONTEÚDO E LUZ ───────────────────────────────────── */
function entradaEluz() {
  const alvos = document.querySelectorAll(
    '.entra, .linha-mascara, .fio-luz, [data-luz]'
  );
  if (!alvos.length) return;

  // Sem IntersectionObserver ou sem movimento: tudo já nasce visível
  if (!('IntersectionObserver' in window) || semMovimento()) {
    alvos.forEach((el) => el.classList.add('visivel'));
    return;
  }

  const revelar = (el) => {
    el.classList.add('visivel');

    // A luz varre a peça uma única vez, quando ela entra em cena
    if (el.hasAttribute('data-luz')) {
      el.classList.add('acesa');
      el.addEventListener('animationend', () => el.classList.remove('acesa'), {
        once: true
      });
    }
  };

  const observador = new IntersectionObserver(
    (entradas) => {
      entradas.forEach((entrada) => {
        if (!entrada.isIntersecting) return;
        revelar(entrada.target);
        observador.unobserve(entrada.target);
      });
    },
    { threshold: 0.16, rootMargin: '0px 0px -8% 0px' }
  );

  alvos.forEach((el) => observador.observe(el));

  /* A margem negativa de 8% existe para o conteúdo de baixo não acender
     antes da hora. Só que ela também corta a faixa final do hero — as
     chamadas e o "Ler a edição" caem justamente nesses últimos pixels e
     ficavam invisíveis para sempre em telas curtas, que é o contrário do
     que a peça serve para fazer. Então: o que já está na primeira tela
     acende agora, sem esperar rolagem que talvez nunca venha. */
  requestAnimationFrame(() => {
    alvos.forEach((el) => {
      if (el.classList.contains('visivel')) return;
      const r = el.getBoundingClientRect();
      if (r.bottom > 0 && r.top < window.innerHeight && r.height > 0) {
        revelar(el);
        observador.unobserve(el);
      }
    });
  });
}

/* ── REFRAÇÃO DA MANCHETE ────────────────────────────────────────────
   A luz chega una e se separa em cor ao tocar a matéria: a manchete
   entra com as cores da marca deslocadas e elas se recompõem.        */
function refracao() {
  const alvos = document.querySelectorAll('[data-refrata]');
  if (!alvos.length || semMovimento()) {
    alvos.forEach((el) => (el.style.textShadow = 'none'));
    return;
  }

  alvos.forEach((el, i) => {
    el.classList.add('refrata');
    el.style.setProperty('--refra', '1');
    setTimeout(() => {
      el.classList.add('assentou');
      el.style.setProperty('--refra', '0');
    }, 260 + i * 130);
  });
}

/* ── FUNDO EM VÍDEO ──────────────────────────────────────────────────
   É um fundo, não um player. Nunca deve pedir play ao visitante.     */
function fundoEmVideo() {
  const video = document.querySelector('[data-fundo-video]');
  const cortina = document.querySelector('[data-cortina]');

  // Hero com fotografia em vez de vídeo: a cortina de luz é só a entrada,
  // então ela se dissolve assim que a imagem estiver pronta. Sem isto a
  // luz cobriria a fotografia para sempre.
  if (!video) {
    if (!cortina) return;
    const foto = cortina.parentElement?.querySelector('img');
    const abrir = () => cortina.classList.add('dissolvida');
    if (!foto) { abrir(); return; }
    if (foto.complete) requestAnimationFrame(abrir);
    else foto.addEventListener('load', abrir, { once: true });
    foto.addEventListener('error', abrir, { once: true });
    return;
  }

  // A propriedade — não só o atributo — é o que libera o autoplay
  video.muted = true;
  video.defaultMuted = true;

  let revelado = false;
  let heroVisivel = true;

  function revelar() {
    if (revelado) return;
    revelado = true;
    cortina?.classList.add('dissolvida');
  }

  function tentarTocar() {
    if (!heroVisivel || !video.paused) return;
    video.play().catch(() => {
      /* Bloqueado (economia de bateria/dados): a cortina de luz fica,
         o visitante vê a marca e nunca um botão de play. */
    });
  }

  video.addEventListener('playing', revelar);

  // Rede de segurança: se os eventos falharem mas o tempo estiver
  // correndo, revela mesmo assim. O vídeo nunca fica preso atrás da luz.
  let ultimo = -1;
  const vigia = setInterval(() => {
    if (revelado) { clearInterval(vigia); return; }
    if (!video.paused && video.currentTime > 0 && video.currentTime !== ultimo) revelar();
    ultimo = video.currentTime;
  }, 400);
  setTimeout(() => {
    if (!revelado && video.readyState >= 2 && !video.paused) revelar();
  }, 6000);

  tentarTocar();
  video.addEventListener('loadeddata', tentarTocar);
  video.addEventListener('canplay', tentarTocar);

  ['touchstart', 'pointerdown', 'keydown'].forEach((ev) =>
    window.addEventListener(ev, tentarTocar, { passive: true })
  );
  document.addEventListener('visibilitychange', () => {
    if (!document.hidden) tentarTocar();
  });

  // Fora do topo o fundo não precisa rodar: poupa bateria e evita
  // travar a rolagem nas seções seguintes.
  const hero = video.closest('[data-hero]') || video.parentElement;
  if (hero && 'IntersectionObserver' in window) {
    new IntersectionObserver(
      (entradas) => {
        entradas.forEach((e) => {
          heroVisivel = e.isIntersecting;
          if (heroVisivel) tentarTocar();
          else if (!video.paused) video.pause();
        });
      },
      { threshold: 0.01 }
    ).observe(hero);
  }
}

/* ── ABERTURA DE EDIÇÃO ──────────────────────────────────────────────
   A capa não vira página: ela se expande e vira o hero da edição.

   A continuidade é feita por VIEW TRANSITIONS CROSS-DOCUMENT, declaradas
   no CSS (@view-transition { navigation: auto }). Aqui o JS faz uma coisa
   só: marcar QUAL capa foi clicada, para o navegador ligá-la ao hero de
   destino. A navegação segue sendo um link comum — nada é interceptado.

   document.startViewTransition() NÃO serve aqui: ela é same-document, e
   envolvê-la em window.location.href apenas anima a saída e descarta o
   resultado ao trocar de documento.                                     */
function aberturaDeEdicao() {
  const capas = document.querySelectorAll('[data-capa]');
  if (!capas.length) return;

  const temCrossDoc =
    'CSSViewTransitionRule' in window ||
    (document.startViewTransition && 'onpagereveal' in window);

  function marcar(capa) {
    // Só uma capa por vez pode ter o nome, senão a transição é descartada
    capas.forEach((c) => (c.style.viewTransitionName = ''));
    capa.style.viewTransitionName = 'capa-ativa';
  }

  capas.forEach((capa) => {
    // Ao apenas apontar já preparamos: o nome precisa estar aplicado
    // antes de a navegação começar.
    capa.addEventListener('pointerenter', () => marcar(capa));
    capa.addEventListener('focus', () => marcar(capa));
    capa.addEventListener('click', () => marcar(capa));
  });

  // Voltando pelo histórico, o nome não pode ficar preso numa capa antiga
  window.addEventListener('pageshow', () => {
    capas.forEach((c) => (c.style.viewTransitionName = ''));
  });

  // Alternativa para quem não tem cross-document: a capa cresce até a
  // viewport e só então navega. Sem isso, o link continua funcionando.
  if (temCrossDoc || semMovimento()) return;

  capas.forEach((capa) => {
    capa.addEventListener('click', (e) => {
      const destino = capa.getAttribute('href');
      if (!destino || e.metaKey || e.ctrlKey || e.shiftKey || e.button !== 0) return;
      e.preventDefault();

      const caixa = capa.getBoundingClientRect();
      const clone = capa.cloneNode(true);
      Object.assign(clone.style, {
        position: 'fixed',
        left: caixa.left + 'px', top: caixa.top + 'px',
        width: caixa.width + 'px', height: caixa.height + 'px',
        margin: '0', zIndex: '300', pointerEvents: 'none',
        transition: 'all 0.62s cubic-bezier(0.16, 1, 0.3, 1)'
      });
      document.body.appendChild(clone);
      requestAnimationFrame(() => {
        Object.assign(clone.style, {
          left: '0px', top: '0px', width: '100vw', height: '100svh'
        });
      });
      setTimeout(() => { window.location.href = destino; }, 560);
    });
  });
}

/* ── ARRANQUE ────────────────────────────────────────────────────── */
function iniciar() {
  navegacao();
  entradaEluz();
  refracao();
  fundoEmVideo();
  // Na Home as capas ainda nao existem neste ponto: ela chama
  // aberturaDeEdicao() de novo depois de montar a banca.
  aberturaDeEdicao();
  document.documentElement.classList.add('pronto');
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', iniciar);
} else {
  iniciar();
}

export { semMovimento, aberturaDeEdicao };
