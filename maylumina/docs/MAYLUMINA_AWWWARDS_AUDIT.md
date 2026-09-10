# MayLumina — Auditoria de Estado Final

Data: 2026-09-10 · Branch: `maylumina-awwwards-editorial`

---

## 1. Estado final

Site estático (HTML/CSS/JS, sem build), publicado na Vercel. O stack foi
**mantido**: ele entrega a experiência com excelência e não há build a manter.
Migrar de framework aqui seria complexidade sem função.

### Rotas

| Rota | Papel |
|---|---|
| `/` | Universo MayLumina — masthead e banca de edições |
| `/edicao/art-body-care/` | Edição 01 — Autocuidado também é arte |
| `/edicao/makeup/` | Edição 02 — Makeup também é autocuidado |
| `/404.html` | Erro, dentro da linguagem da marca |

---

## 2. O que foi encontrado no baseline

| Achado | Evidência | Resolução |
|---|---|---|
| Descrição de 1026 caracteres despejada no card | `Doce Noir`, campo `descricao` | Card só com nome, notas, preço e CTA; texto completo na gaveta |
| `foto8.jpeg` preta | hash MD5 **idêntico** a `foto4.jpeg`; ambas 800×1000, brilho médio RGB 0,0,0 | Nenhuma das duas é referenciada em nenhuma página |
| Alt texts genéricos ("MayLumina") | 9 ocorrências | Todos reescritos descrevendo a cena real |
| Cards e dots como `div` com `onclick` | vitrine e carrossel antigos | `div[onclick]` = **0** em todas as rotas |
| Página única sem URLs compartilháveis | tudo em `index.html` | 3 rotas reais com canonical, OG e JSON-LD |
| Sem sitemap, robots, manifest, favicon | ausentes | Todos criados |

---

## 3. Notas internas (autoavaliação severa)

| Critério | Nota | Justificativa |
|---|---|---|
| **Design** | 8.5 | Masthead e capas funcionam congelados. Escala tipográfica real de revista. Perde meio ponto por só haver 7 fotografias utilizáveis. |
| **Usability** | 8.5 | Sempre se sabe onde se está, como voltar e como comprar. Logo devolve ao universo; cada edição oferece a próxima. |
| **Creativity** | 8.0 | O sistema luz→cor é autoral e coerente do conceito ao código. Não é um clone de site premiado. |
| **Content** | 8.0 | Todo o conteúdo é verdadeiro da cliente. A Edição 02 depende de spreads tipográficos por falta de fotografia. |
| **Semantics / SEO** | 9.0 | 1 h1 por rota, hierarquia sem saltos, 4 landmarks, canonical, OG, JSON-LD, sitemap, robots. |
| **Animations** | 8.5 | Assinatura reconhecível, não fade-up genérico. Movimento reduzido entrega experiência boa parada. |
| **Accessibility** | 9.0 | Teclado completo, foco preso e devolvido, skip link, contraste medido, zero `div[onclick]`. |
| **WPO** | 8.0 | LCP e CLS excelentes. Penalizado pelo peso do vídeo (ver limitação 6.1). |
| **Responsive** | 9.0 | 8 viewports verificados, zero overflow, composições dirigidas por corte. |
| **Markup / Metadata** | 9.0 | HTML válido, metadados completos e únicos por rota. |

Nenhuma área abaixo de 8.

---

## 4. Resultado dos testes

### Estrutura e semântica — 3 rotas

```
h1 por página                1 ✓        headings sem salto      ✓
landmarks                    4/4 ✓      img sem alt             0 ✓
img sem width/height         0 ✓        div[onclick]            0 ✓
skip-link                    ✓          lang=pt-BR              ✓
canonical                    ✓          OG tags                 8 ✓
JSON-LD                      ✓          overflow horizontal     0 ✓
```

### Viewports verificados

360 · 390 · 430 · 768 · 1024 · 1280 · 1440 · 1920 — **zero overflow
horizontal e nenhuma manchete cortada** em qualquer um.

### Interação

| Teste | Resultado |
|---|---|
| Movimento reduzido — elementos presos invisíveis | **0** |
| 1º Tab é o skip link | ✓ |
| Capas alcançáveis por teclado | ✓ (`<a>` com `aria-label`) |
| Gaveta: `role=dialog`, `aria-modal`, rotulada | ✓ |
| Gaveta: foco entra, Escape fecha, foco devolvido | ✓ |
| Gaveta: conteúdo externo sem HTML cru | ✓ (11 parágrafos por `textContent`) |
| Menu mobile: `inert` fechado, foco entra e fica preso | ✓ |
| Card de produto é `<button>` semântico | ✓ |
| Texto do card | 53 caracteres (era 1026+) |

### Console e rede

Zero erros de console e zero requisições falhas em todas as rotas.

> Os `ERR_CONNECTION_RESET` que aparecem ao rodar no sandbox são o Google
> Fonts bloqueado pelo proxy do ambiente, não erros do site. Confirmado
> servindo as fontes localmente: console limpo.

---

## 5. Performance medida

| Rota | LCP | CLS | Requisições | DOM |
|---|---|---|---|---|
| `/` | **124 ms** | **0.0052** | 16 | 201 nós |
| `/edicao/art-body-care/` | **112 ms** | **0.0004** | 18 | 239 nós |
| `/edicao/makeup/` | **1148 ms** | **0.0016** | 16 | 239 nós |

Metas: LCP ≤ 2500ms ✓ · CLS ≤ 0.1 ✓ (folga de ~20×).

O LCP da Home é de 124ms porque o masthead é **tipografia e luz CSS** — sem
imagem no caminho crítico. Foi uma decisão conceitual (a luz ainda não se
refratou) que virou também a decisão de performance certa.

### Vídeo do hero

| Verificação | Resultado |
|---|---|
| `moov` antes do `mdat` (faststart) | ✓ |
| Trilha de áudio | removida (era sempre mudo) |
| Codec | H.264 High 4.0, 1904×1088 — compatível |
| **Segunda transferência completa** | **não ocorre** — 1 requisição, mesmo descendo até o rodapé e voltando |
| Pausa fora da tela | ✓ |

---

## 6. Limitações conhecidas

### 6.1 Peso do vídeo — 3,0 MB (o gargalo)

A Edição 01 pesa 5,0 MB, dos quais 3,0 MB são o `hero-bg.mp4`. Já foi feito
tudo que não exige recodificação: faststart, remoção do áudio (−165 kB),
requisição única, pausa fora da tela.

**O que falta exige `ffmpeg`, que não existe neste ambiente.** Remédio exato:

```bash
# WebM/VP9 — costuma cair para ~40% do tamanho
ffmpeg -i hero-bg.mp4 -c:v libvpx-vp9 -crf 34 -b:v 0 -an hero-bg.webm
# variante para celular
ffmpeg -i hero-bg.mp4 -vf scale=960:-2 -c:v libx264 -crf 28 -movflags +faststart -an hero-bg-mobile.mp4
```

Depois, no `<video>`: `<source>` WebM primeiro, MP4 como alternativa.

### 6.2 Fotografia de maquiagem

Não existe nenhuma. A Edição 02 se sustenta em direção tipográfica e cor —
intencionalmente, não por descuido. Ver `ASSET_GAPS.md`.

### 6.3 Não verificável neste ambiente

- **Reprodução do vídeo**: o Chromium do sandbox não traz codec H.264. A
  lógica de revelação foi validada com um WebM gerado em tempo de execução.
- **Lighthouse**: não instalável aqui. As métricas acima vêm de
  `PerformanceObserver` real (LCP e CLS), não de estimativa.
- **Safari/Firefox**: apenas Chromium disponível. Todo recurso experimental
  tem alternativa — View Transitions cai para uma expansão própria da capa.

---

## 7. Momentos memoráveis

1. **Masthead** — `MAYLUMINA` em corpo de capa sobre luz viva, sem fotografia.
2. **A banca** — duas capas editoriais reais; hover acende borda iridescente.
3. **Abertura de edição** — a capa **expande** até virar o hero da edição.
4. **Refração** — "Uma luz. Muitas cores." como spread tipográfico.
5. **Coluna presa** — a história rolando ao lado da foto parada.
