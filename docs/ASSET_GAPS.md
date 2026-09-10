# Lacunas de material

O site está apresentável e completo com o que existe hoje. Este documento
lista o que **falta de fato** e o que **elevaria** o resultado.

---

## 0. BLOQUEADOR — vídeo do hero sem a marca d'água (ação externa)

O `hero-bg.mp4` que existia carrega a marca **"KlingAI 3.0"** gravada na
imagem. Não há versão limpa no acervo nem no histórico do repositório.

O que foi feito: o vídeo **saiu do site**. Não foi borrado, não recebeu
retângulo por cima, não foi recortado para fingir que a marca não está lá —
essas são todas formas de publicar a marca de outra pessoa e torcer para
ninguém reparar. O hero da Edição 01 passou a usar `foto2.jpeg`, que é o
**quadro-fonte da mesma composição**, sem marca. O arquivo antigo foi movido
para `fora-de-producao/hero-bg-com-marca-klingai.mp4`, na raiz do
repositório: continua versionado, mas deixou de ser servido na internet.

O que é preciso para o movimento voltar:

- exportar o vídeo de novo a partir da conta que gerou a peça, **sem marca**
  (planos pagos do Kling removem a marca na exportação); ou
- gravar uma cena real equivalente — água leitosa tingida, luz lateral,
  movimento lento.

Formato: **MP4 H.264, 720×1280, faststart ativado**, até ~3 MB. Colocar em
`maylumina/assets/videos/hero-bg.mp4` e devolver o `<video>` no lugar do
`<img>` em `edicao/art-body-care/index.html` — o comentário no HTML tem a
marcação exata.

## 1. Fotografia de maquiagem — Edição 02 (maior impacto)

Não existe **nenhuma** fotografia de maquiagem no acervo. A Edição 02 se
sustenta hoje em direção tipográfica e cor, o que foi uma decisão intencional
— nada de banco de imagens, nada de foto genérica.

O que a transformaria:

| Foto | Por que |
|---|---|
| **Macro de olhos** com sombra em cor forte | é a prova visual de "cor que revela" |
| **Macro de boca** com acabamento perolado | mostra a textura que o texto promete |
| **Antes/depois** de um trabalho real | dá corpo à seção de agendamento |
| **May maquiando alguém** | mostra o ritual, não só o resultado |
| **Detalhe de produto de maquiagem** na mão | conecta a edição à vitrine |

Formato ideal: **3:4 vertical**, fundo claro ou neutro, sem texto gráfico
embutido — a tipografia da página já cumpre esse papel.

**O lugar já está preparado.** A abertura da Edição 02 usava a `foto6.jpeg`,
que é uma foto de estúdio da Edição 01 — bonita, mas não é maquiagem, e
usá-la ali era emprestar material de outra edição para tapar um buraco. Ela
saiu. No lugar entrou uma **placa de pigmento** (`.placa`), que não imita
fotografia: é cor sobreposta em multiply, que é do que a edição fala.

Quando a fotografia existir, o comentário `SLOT DE FOTOGRAFIA · EDIÇÃO 02`
em `edicao/makeup/index.html` traz a marcação pronta. A grade não muda.

## 2. Substituir as duas fotos pretas

`foto4.jpeg` e `foto8.jpeg` são o **mesmo arquivo**, e são 100% pretos
(800×1000, brilho médio RGB 0,0,0). Nenhuma das duas é usada hoje.

Se as versões reais aparecerem, entram direto na esteira da Edição 01.

## 3. Vídeo em formato moderno

Quando o vídeo limpo do item 0 existir: além do MP4, uma versão **WebM/VP9**
e uma variante menor para celular cortam boa parte do peso. Comando exato em
`MAYLUMINA_AWWWARDS_AUDIT.md`, seção 6.1.

Exportar sempre **com faststart ativado** (no Premiere/CapCut costuma
aparecer como "otimizar para web"), senão o vídeo volta a demorar para
começar no celular.

## 4. Fotografia de produto

Os produtos usam imagens hospedadas no ibb.co. Um ensaio dos produtos no
mesmo padrão editorial das fotos da May — fundo creme, luz difusa, foco na
textura vítrea — deixaria a vitrine à altura do resto da publicação.

## 5. Retrato da fundadora em corpo editorial

Existe material da May, mas nenhum retrato pensado como **abertura de
matéria**: plano fechado, olhar na câmera, espaço negativo à esquerda ou à
direita para a manchete entrar. Seria a foto de abertura da seção "A origem".

---

## 6. Tipografia — resolvido, hospedado aqui

Cormorant Garamond e Quicksand **não vêm mais do Google**. Os arquivos
`.woff2` moram em `maylumina/assets/fonts/`, e o `@font-face` está em
`assets/css/fontes.css`.

- São as mesmas fontes, nos mesmos pesos. Nada mudou de aparência.
- Só os subconjuntos **latin** e **latin-ext** — cyrillic e vietnamese
  saíram, o português não usa.
- Os arquivos são variáveis, então 6 arquivos (≈195 KB no total) cobrem
  toda a faixa de peso das duas famílias.
- Ambas são **SIL Open Font License 1.1**, que permite hospedagem própria.

Um detalhe conhecido: `.capa__marca` pede `font-weight: 700` e o Cormorant
aqui vai até 600, então o navegador engorda a letra artificialmente — era
assim antes também, com o Google. Se algum dia isso incomodar, a correção é
uma linha: trocar o 700 por 600 no CSS.

## 7. Domínio próprio (ação externa, recomendada)

O site vive em `maylumina.vercel.app`. Funciona, mas:

- um endereço de subdomínio de plataforma enfraquece a marca em cartão,
  bio do Instagram e no boca a boca;
- todo link já compartilhado aponta para lá, então quanto antes for
  trocado, menos link velho fica para trás;
- Awwwards e similares olham para isso.

Sugestão: **maylumina.com.br** (ou `.com`). Registrar no registro.br,
apontar na Vercel em *Settings → Domains*, e depois atualizar:
`<link rel="canonical">`, as URLs `og:*`/`twitter:*`, `sitemap.xml` e
`robots.txt` — hoje todos escritos com o endereço da Vercel.
