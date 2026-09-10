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
    focaveis()[0]?.focus();
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

  const observador = new IntersectionObserver(
    (entradas) => {
      entradas.forEach((entrada) => {
        if (!entrada.isIntersecting) return;
        const el = entrada.target;
        el.classList.add('visivel');

        // A luz varre a peça uma única vez, quando ela entra em cena
        if (el.hasAttribute('data-luz')) {
          el.classList.add('acesa');
          el.addEventListener('animationend', () => el.classList.remove('acesa'), {
            once: true
          });
        }
        observador.unobserve(el);
      });
    },
    { threshold: 0.16, rootMargin: '0px 0px -8% 0px' }
  );

  alvos.forEach((el) => observador.observe(el));
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
  if (!video) return;

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
   Com View Transitions quando houver; com uma expansão própria quando
   não houver. Nunca depende só da API.                                */
function aberturaDeEdicao() {
  const capas = document.querySelectorAll('[data-capa]');
  if (!capas.length) return;

  capas.forEach((capa) => {
    capa.addEventListener('click', (e) => {
      const destino = capa.getAttribute('href');
      if (!destino || e.metaKey || e.ctrlKey || e.shiftKey || e.button !== 0) return;
      if (semMovimento()) return; // navegação direta, sem teatro

      // Caminho nativo: o navegador faz a continuidade entre as páginas
      if (document.startViewTransition) {
        e.preventDefault();
        capa.style.viewTransitionName = 'capa-aberta';
        document.startViewTransition(() => { window.location.href = destino; });
        return;
      }

      // Alternativa: a capa cresce até a viewport antes de navegar
      e.preventDefault();
      const caixa = capa.getBoundingClientRect();
      const clone = capa.cloneNode(true);
      Object.assign(clone.style, {
        position: 'fixed',
        left: caixa.left + 'px',
        top: caixa.top + 'px',
        width: caixa.width + 'px',
        height: caixa.height + 'px',
        margin: '0',
        zIndex: '300',
        transition: 'all 0.62s cubic-bezier(0.16, 1, 0.3, 1)',
        pointerEvents: 'none'
      });
      document.body.appendChild(clone);
      requestAnimationFrame(() => {
        Object.assign(clone.style, {
          left: '0px', top: '0px',
          width: '100vw', height: '100svh'
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
  aberturaDeEdicao();
  document.documentElement.classList.add('pronto');
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', iniciar);
} else {
  iniciar();
}

export { semMovimento };
