# MayLumina — Sistema de Design

> **MayLumina é uma publicação viva sobre as diferentes cores do autocuidado.**
> A marca é o universo. Cada área é uma edição desse universo.

---

## 1. Conceito

A identidade não é "revista". A identidade é:

```
LUZ → COR → ARTE → CUIDADO → EXPRESSÃO
```

A revista é o **meio** pelo qual essa identidade é apresentada. Nunca inverter.

A metáfora que governa o sistema visual e o motion:

```
LUZ UNA → REFRAÇÃO → CORES → MATÉRIA → EXPRESSÃO → CUIDADO
```

Consequência estrutural direta: **a Home não tem fotografia no masthead.**
Ali a luz ainda é una — ela só se refrata ao entrar numa edição. A cena da
banheira, que antes abria o site inteiro, passou a ser a capa da Edição 01,
onde a luz já virou água, pigmento e matéria.

---

## 2. Cores

Paleta oficial, usada como **pigmento** — com intenção, nunca como papel de parede.

| Token | Hex | Significado |
|---|---|---|
| `--creme` | `#F2EAE0` | leveza, pureza, acolhimento — é o papel |
| `--laranja` | `#F0944E` | May, energia, calor, identidade ruiva |
| `--pink` | `#E91E8C` | intensidade, paixão, feminilidade vibrante |
| `--roxo` | `#8B4F9F` | criatividade, mistério, transformação |
| `--turquesa` | `#00CCA8` | frescor, equilíbrio, calma, brilho |

**Refração** — o pigmento diluído em luz. Superfícies, lavagens e faixas:

| Token | Hex |
|---|---|
| `--laranja-luz` | `#F9D5B4` |
| `--pink-luz` | `#F4C2DA` |
| `--roxo-luz` | `#D3BCE3` |
| `--turquesa-luz` | `#B3E4D8` |

**Tinta** — texto. Pigmento puro não tem contraste para ler:

| Token | Hex | Uso |
|---|---|---|
| `--tinta` | `#3B2F35` | corpo e manchetes sobre creme |
| `--tinta-suave` | `#5E4E56` | texto de apoio |
| `--tinta-pink` | `#8E3560` | olhos, rótulos, preço, acentos |

### Regras de cor

1. **Crème domina.** A cor tem impacto porque é rara, não porque é constante.
2. **Cada edição tem predominância própria** — 01 puxa para o pink/laranja,
   02 para o roxo/turquesa — permanecendo inconfundivelmente MayLumina.
3. **Nunca texto claro sobre pastel.** Branco sobre pastel dá ~1,5:1.
   Sobre superfície pastel, o texto é `--tinta`.
4. A cor deve parecer **luz refratada, pigmento, líquido ou matéria** —
   nunca gradiente decorativo.

---

## 3. Tipografia

Duas famílias, preservadas do projeto original:

- **Cormorant Garamond** — display/editorial. É o instrumento de composição.
- **Quicksand** — corpo, navegação, metadados, UI.

Nenhuma terceira fonte. Não havia justificativa conceitual superior à identidade
existente.

As duas famílias são **hospedadas no próprio projeto**
(`assets/fonts/*.woff2`, `@font-face` em `assets/css/fontes.css`), apenas nos
subconjuntos latin e latin-ext. Nenhuma requisição sai para terceiros: o
caminho crítico não depende do Google e o IP do visitante não vai junto.

### Escala fluida

| Token | clamp | Onde |
|---|---|---|
| `--t-masthead` | `3.2rem → 15rem` | nome da publicação |
| `--t-capa` | `2.8rem → 8rem` | manchete de capa |
| `--t-manchete` | `2.6rem → 5.5rem` | manchetes de seção |
| `--t-titulo` | `2rem → 3.2rem` | títulos internos |
| `--t-sub` | `1.15rem → 1.6rem` | decks |
| `--t-corpo` | `1.02rem → 1.18rem` | texto corrido |
| `--t-meta` | `0.68rem` | ficha editorial, rótulos |

### O que faz parecer revista

- **Entrelinha abaixo de 1** nas manchetes (`0.88`–`0.97`).
- **Tracking negativo** (`-0.025em` a `-0.04em`) em corpo grande.
- **Salto de escala brutal** entre o rótulo (11px, tracking `0.4em`) e a
  manchete (até 120px). Esse contraste é o efeito, não o tamanho isolado.
- **Quebras de linha compostas à mão**, via `linha-mascara`, nunca deixadas
  ao acaso do navegador.
- `text-wrap: balance` nas manchetes, `pretty` no corpo.
- `hyphens: none` — manchete não parte palavra.

---

## 4. Ritmo e espaço

| Token | Valor |
|---|---|
| `--margem` | `clamp(1.25rem, 5vw, 5rem)` |
| `--respiro` | `clamp(4.5rem, 11vh, 10rem)` |
| `--gap` | `clamp(1rem, 2.5vw, 2rem)` |
| `--medida` | `62ch` (medida de leitura) |

---

## 5. Motion — a assinatura

Uma curva só, para a marca ter um "andar" reconhecível:

```css
--passo:     cubic-bezier(0.22, 0.61, 0.36, 1);
--passo-luz: cubic-bezier(0.16, 1, 0.3, 1);
```

### Princípios

1. **Fade-up é apoio, não linguagem.** A linguagem é a luz.
2. A luz **não pisca nem brilha** — ela *passa*, como reflexo raso deslizando
   sobre superfície molhada.
3. Nada se move sem relação com o conteúdo.
4. Motion eleva design; **não esconde design fraco**. Todo hero, capa e spread
   precisa funcionar congelado.

### Componentes de luz

| Classe | Comportamento |
|---|---|
| `.luz-varre` + `data-luz` | varredura única quando a peça entra em cena |
| `.refrata` + `data-refrata` | cores da marca deslocadas que se recompõem |
| `.fio-luz` | filete que cresce da esquerda, separando capítulos |
| `.iridescente` | borda que acende no hover/focus das capas |
| `.linha-mascara` | manchete que sobe linha a linha, como página composta |

### Sem JavaScript

Tudo que esconde conteúdo à espera de animação (`.entra`, `.linha-mascara`,
`.fio-luz`) está escopado em **`.js`** — classe que o próprio JavaScript
escreve no `<html>` antes da primeira pintura. Sem JavaScript nada fica
escondido: a página não se move, mas está inteira, com links reais e texto
legível.

Consequência prática: **nunca** escrever uma regra que esconde conteúdo sem
prefixá-la com `.js`.

### Movimento reduzido

`prefers-reduced-motion` **não remove tudo** — entrega uma experiência boa
parada: conteúdo já visível, luz vira presença estática em vez de sumir,
abertura de edição navega direto sem teatro. Nada pode ficar preso invisível.

---

## 6. Sistema de edições

Uma edição é um mundo dentro do universo. O modelo vive em
`assets/js/edicoes.js`.

```js
{
  slug, numero, status,          // 'publicada' | 'em-breve'
  titulo, manchete: [],          // quebras compostas à mão
  identificacao, deck, descricao,
  chamadas: [],                  // cover lines
  cor, corLuz,                   // predominância cromática
  capa: { src, alt, largura, altura },
  url, categoriaProduto, cta
}
```

**Adicionar a Edição 03:**

1. Acrescentar um objeto em `EDICOES`.
2. Rodar `node tools/gerar-capas.mjs` — reescreve as capas e a ficha da banca
   dentro de `index.html`.
3. Rodar `node tools/gerar-og.mjs` — desenha o cartão de compartilhamento
   1200×630 da edição nova.
4. Criar `edicao/<slug>/index.html` (copiar a estrutura de uma existente).
5. Acrescentar a URL em `sitemap.xml`.

O modelo continua sendo a fonte da verdade — **nenhuma marcação é escrita
duas vezes à mão**. O que mudou é *quando* a marcação nasce: antes ela era
montada pelo JavaScript no navegador, o que deixava a banca inteira invisível
para quem chega sem JS e para um robô de busca que não executa script. Agora
o gerador escreve as capas no HTML, entre `CAPAS:INICIO` e `CAPAS:FIM`, e o
resultado é versionado. Não há build no deploy.

`proximaEdicao()` fecha o ciclo: nenhuma edição termina em beco sem saída.

**Edição sem produto.** `carregarProdutos({ alvo, categoria, secao })`: se a
categoria não devolver nenhum produto, a seção inteira sai da página e do
leitor de tela, junto com qualquer link de navegação que apontasse para ela.
A edição fica **completa com zero produto** — ela não promete "em breve" o
que não tem. A seção da Edição 02 nasce com `hidden` no HTML justamente para
não piscar antes de sumir; assim que o primeiro produto de maquiagem for
cadastrado no Supabase, ela aparece sozinha.

Produtos são roteados por `categoriaProduto`, que casa com a coluna
`categoria` da tabela `produtos` no Supabase.

---

## 7. Componentes

| Componente | Regra |
|---|---|
| `.capa` | `<a>` real com `aria-label`; nunca div clicável |
| `.produto` | `<button aria-haspopup="dialog">`; só o que decide |
| `.gaveta` | `role="dialog"`, `aria-modal`, foco preso, Escape, foco devolvido |
| `.menu` | `inert` quando fechado; foco entra e fica preso |
| `.trio` | grade de 3 no desktop, esteira deslizável no celular |
| `.presa` | mídia fixa, texto rolando ao lado |
| `.tipo-spread` | spread dirigido por tipografia, quando não há fotografia |
| `.placa` | pigmento no lugar da fotografia que ainda não existe |

### Cards de produto

O card carrega **só informação de decisão**: nome, até três notas sensoriais,
preço e CTA. As notas são extraídas do vocabulário da marca presente na própria
descrição da cliente — `Doce Noir` vira `Amadeirado · Gourmet · Relaxante`.

O texto completo (1026 caracteres, no caso do Doce Noir) abre na gaveta.
Conteúdo externo entra sempre por `textContent` — **nunca `innerHTML`**.

---

## 8. Responsivo

Cada composição é **dirigida**, não comprimida.

| Corte | O que muda |
|---|---|
| `1024px` | spreads passam a colunas mais estreitas |
| `860px` | nav vira menu próprio; trio vira esteira; spreads empilham |
| `480px` | capas mudam de proporção; sangrias encurtam |

Regras invioláveis:

- A foto vem **sempre depois** do texto quando empilha.
- Zero overflow horizontal — verificado em 360, 390, 430, 768, 1024, 1280,
  1440 e 1920px.
- `svh` no lugar de `vh` nos heroes, para não quebrar na barra do celular.
- Alvos de toque com no mínimo 44–48px.

---

## 9. Acessibilidade — não negociável

- Um `<h1>` por página, hierarquia sem saltos.
- `header`/`nav`/`main`/`footer` presentes em todas as rotas.
- Skip link como primeiro item do teclado.
- `:focus-visible` com contorno pink de 3px e afastamento.
- Toda imagem com `alt` descritivo real; decorativas com `alt=""`.
- Todo `img` com `width`/`height` — zero salto de layout.
- Modais: foco entra, fica preso, Escape fecha, foco volta, body travado.
- Vídeo de fundo com `pointer-events: none` — é fundo, não player.

---

## 10. Segurança do painel

O `/admin` autentica pelo **Supabase Auth** (`signInWithPassword`), e o que
autoriza cada escrita é o *access token* daquele usuário — não um booleano
guardado no navegador. A chave anon continua pública, porque é o que ela é:
identifica o projeto, não autoriza nada.

Quem pode o quê é decidido **no banco**, por Row Level Security. A migration
está em `docs/supabase/001-auth-e-rls.sql` e precisa ser aplicada à mão no
Dashboard do Supabase — o navegador não tem, e não deve ter, permissão para
isso.

Regra que não se negocia: **nenhuma senha, hash ou segredo administrativo
pode ser devolvido por uma consulta anônima.** Se um dia alguém precisar
guardar configuração sensível, ela não mora numa tabela lida pela chave anon.

---

## 11. O que é publicado

A raiz publicada na Vercel é `maylumina/`. Fora dela, e portanto fora da
internet, ficam:

- `docs/` — documentação interna, incluindo a migration de SQL;
- `tools/` — geradores de capa e de cartão de compartilhamento;
- `fora-de-producao/` — material que não pode ser servido, como o vídeo com
  a marca d'água da KlingAI.

Antes de mover um arquivo para dentro de `maylumina/`, vale a pergunta: *eu
publicaria isto numa URL pública?*
