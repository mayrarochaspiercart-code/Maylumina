# MayLumina — Briefing fotográfico

Quatro fotografias faltam. Enquanto não chegarem, os lugares delas ficam
**tipográficos** — nenhum placeholder, nenhum banco de imagem, nenhuma foto
emprestada de outra edição para tapar buraco.

Este documento tem tudo o que a produção precisa: onde cada arquivo entra,
com que nome, em que proporção e o que não pode aparecer no quadro.

**Medidas de renderização reais**, colhidas no navegador em 1440×900 e
390×844 — é delas que saem as resoluções mínimas (2× para telas retina).

---

## A regra que vale para as quatro

| | |
|---|---|
| Fundo | branco ou neutro de estúdio, sem cenário |
| Luz | difusa, de estúdio; sem flash duro e sem sombra dura no fundo |
| Pele | **real** — textura, poro e brilho natural preservados. Sem pele plastificada |
| Proibido | texto gráfico, marca d'água, logotipo, CGI, aparência de IA, moldura, borda, filtro pesado |
| Proibido | objeto que não faça parte do assunto entrando no quadro |
| Cor | a paleta da marca aparece no **pigmento**, não num filtro por cima |
| Entrega | JPEG qualidade 85–90, progressivo, sRGB, sem metadado de GPS |
| Nome | exatamente o indicado. Tudo minúsculo, sem acento, sem espaço |
| Onde salvar | `maylumina/assets/images/` |

Paleta da marca, para orientar sombra e pigmento:

`#F0944E` laranja · `#E91E8C` pink · `#8B4F9F` roxo · `#00CCA8` turquesa

A Edição 02 puxa **roxo e turquesa**. A Edição 01 puxa **pink e laranja**.

---

## Prioridade 1 — MACRO DE OLHOS

**Conceito: pigmento como refração de luz.** É a prova visual de "cor que
revela" e hoje é a maior lacuna do projeto — a edição se chama Makeup e não
tem nenhum plano fechado de maquiagem aplicada.

| | |
|---|---|
| Arquivo | `makeup-olhos.jpg` |
| Rota | `/edicao/makeup/` |
| Seção | `<section class="tipo-spread">` — "Pigmento é linguagem." |
| Slot | hoje é 100% tipográfico; a fotografia entra como fundo da seção, atrás da palavra |
| Proporção | **4:5** vertical |
| Render desktop | 1440×720 (sangria de largura total) |
| Render mobile | 390×620 |
| Mínimo | **1600px** no lado maior |
| Ideal | 2400×3000 |
| Orientação | vertical |
| Enquadramento | macro: os dois olhos e a ponte do nariz. Sobrancelha inteira no quadro, testa cortada |
| Posição do rosto | olhos no **terço superior**; olhar levemente fora de eixo, não direto na lente |
| Espaço negativo | **40% inferior livre** — é onde a palavra "PIGMENTO É LINGUAGEM" vai deitar. Deixar essa faixa com pele lisa ou fundo, sem detalhe concorrente |
| Luz | lateral suave a 45°, uma fonte só, para o pigmento ganhar relevo e brilho |
| Fundo | branco ou cinza-claro liso |
| Maquiagem | sombra em **degradê camaleão**: turquesa no canto interno → lilás no meio → laranja no externo. Acabamento metálico ou perolado, que muda com o ângulo. Cílios definidos, sem cílios postiços exagerados |
| Paleta | turquesa `#00CCA8` · roxo `#8B4F9F` · laranja `#F0944E` |
| Não pode aparecer | testa inteira, boca, cabelo cobrindo o olho, mão, pincel, reflexo de softbox na íris em formato retangular |
| Crop desktop | centro do quadro, cobrindo 1440×720 (`object-position: center 35%`) |
| Crop mobile | fecha no olho direito, `object-position: 60% 30%` |
| Formato | JPEG (o site não usa AVIF/WebP hoje — manter um formato só evita `<picture>` desnecessário) |
| Peso alvo | **≤ 180 KB** depois de reamostrar para 1600px |

---

## Prioridade 2 — MACRO DE BOCA

**Conceito: brilho como assinatura.** Fecha o par com o macro de olhos e dá
matéria ao terceiro item do trio, hoje um bloco de cor com texto.

| | |
|---|---|
| Arquivo | `makeup-boca.jpg` |
| Rota | `/edicao/makeup/` |
| Seção | `<section aria-labelledby="titulo-presencas">` — "A mesma mulher, em três luzes" |
| Slot | terceiro `<article class="trio__item">`, rótulo **"Assinatura"**. Substitui a `div.trio__midia` com gradiente por `<img>` |
| Proporção | **1:1** (o slot renderiza 3/4; o quadrado tolera o corte nas duas pontas) |
| Render desktop | 413×550 |
| Render mobile | 266×355 |
| Mínimo | **1100px** no lado maior |
| Ideal | 1600×1600 |
| Orientação | quadrada |
| Enquadramento | boca fechada ou levemente entreaberta, do sulco nasolabial ao queixo |
| Posição do corpo | boca **centralizada**, ligeiramente acima do centro geométrico |
| Espaço negativo | margem de pele em volta, ~15% de cada lado — o slot corta as bordas |
| Luz | frontal-alta com preenchimento, para o brilho aparecer como **faixa**, não como ponto estourado |
| Fundo | irrelevante (só pele no quadro); se aparecer, branco |
| Maquiagem | acabamento **perolado camaleão** — reflexo que muda de rosa para turquesa conforme o ângulo. Contorno natural, sem linha dura de lápis |
| Paleta | pink `#E91E8C` com refração turquesa |
| Não pode aparecer | dente, língua, piercing, gloss escorrido, aplicador, dedo |
| Crop desktop | `object-fit: cover; object-position: center center` |
| Crop mobile | idêntico |
| Formato | JPEG |
| Peso alvo | **≤ 120 KB** |

---

## Prioridade 3 — MAY / GESTO DE MAQUIAGEM

**Conceito: autocuidado como expressão.** É a única das quatro em que a May
aparece inteira, e a que conecta "cor, expressão, presença e identidade" a
uma pessoa real.

| | |
|---|---|
| Arquivo | `makeup-gesto.jpg` |
| Rota | `/edicao/makeup/` |
| Seção | `<section aria-labelledby="titulo-presencas">` |
| Slot | segundo `<article class="trio__item">`, rótulo **"Expressão"** |
| Proporção | **3:4** vertical |
| Render desktop | 413×550 |
| Render mobile | 266×355 |
| Mínimo | **1200px** no lado maior |
| Ideal | 1800×2400 |
| Orientação | vertical |
| Enquadramento | meio-corpo, da cintura para cima |
| Posição do rosto | rosto no **terço superior**, levemente fora do eixo central — assimetria, não retrato 3×4 |
| Gesto | **real, em curso**: aplicando sombra, segurando o pincel junto à têmpora, ou fechando o olho no meio do traço. Não pode ser pose de e-commerce com o produto apresentado à câmera |
| Espaço negativo | lado oposto ao gesto livre, para a composição respirar |
| Luz | difusa frontal com leve lateral; sem sombra dura no fundo |
| Fundo | branco de estúdio |
| Maquiagem | a da própria May, coerente com a paleta da edição — sombra em verde-turquesa ou lilás |
| Paleta | roxo `#8B4F9F` · turquesa `#00CCA8` |
| Não pode aparecer | embalagem com marca de terceiro legível, espelho refletindo o fotógrafo, tripé, cabo, fundo infinito enrugado |
| Crop desktop | `object-position: center top` |
| Crop mobile | idem |
| Formato | JPEG |
| Peso alvo | **≤ 150 KB** |

---

## Prioridade 4 — KIT / MATÉRIA / OBJETO

**Conceito: o personalizado como objeto.** Esta é da **Edição 01**, não da
02: o item "Personalizados" do processo ficou tipográfico porque a foto que
estava lá trazia texto gráfico gravado e não falava de produto.

| | |
|---|---|
| Arquivo | `bodycare-kit.jpg` |
| Rota | `/edicao/art-body-care/` |
| Seção | `<section id="processo">` — "Como cada peça nasce." |
| Slot | terceiro `<article class="trio__item">`, rótulo **"Personalizados"**. Substitui a `div.trio__midia` com gradiente por `<img>` |
| Proporção | **3:4** vertical |
| Render desktop | 413×550 |
| Render mobile | 266×355 |
| Mínimo | **1200px** no lado maior |
| Ideal | 1800×2400 |
| Composição | um kit montado: 3 a 5 peças MayLumina em alturas diferentes, agrupadas fora de simetria. Uma peça aberta mostrando a textura do produto |
| Superfície | lisa e mate — papel, tecido liso ou acrílico fosco. Nada de mármore, madeira rústica ou folhagem |
| Fundo | contínuo com a superfície; creme `#F2EAE0` ou branco |
| Luz | lateral suave, sombra longa e macia **para um lado só** — é a sombra que dá matéria ao objeto |
| Espaço para texto | **terço superior livre**, sem peça e sem sombra: o rótulo do card entra por baixo, mas a folga no topo evita o objeto brigar com o título da seção |
| Paleta | pink `#E91E8C` e laranja `#F0944E` nos produtos, sobre creme |
| Não pode aparecer | mão, rótulo de terceiro, etiqueta de preço, reflexo do estúdio no vidro, plástico amassado |
| Crop desktop | `object-position: center center` |
| Crop mobile | idem |
| Formato | JPEG |
| Peso alvo | **≤ 150 KB** |

---

## Como instalar quando as fotos chegarem

1. Salvar em `maylumina/assets/images/` com o nome exato da tabela.
2. Reamostrar para a resolução mínima indicada (`Pillow`, qualidade 85–90,
   `optimize=True`, `progressive=True`).
3. Trocar o bloco marcado no HTML — cada slot tem um comentário dizendo o
   que sai e o que entra.
4. Escrever o `alt` descrevendo a cena, não o conceito: quem não enxerga
   precisa saber o que está na foto.
5. `width` e `height` no `<img>` são obrigatórios — é o que segura o CLS,
   hoje em 0,0006.
6. Rodar `node tools/gerar-og.mjs` se a capa de alguma edição mudar.

## O que NÃO fazer enquanto elas não chegam

Não gerar mockup, não comprar banco de imagem, não reaproveitar foto de
uma edição na outra, não publicar imagem com texto gravado. Os quatro
lugares funcionam tipograficamente e ficam íntegros vazios — é melhor uma
página honestamente tipográfica do que uma fotografia que não é daquilo.
