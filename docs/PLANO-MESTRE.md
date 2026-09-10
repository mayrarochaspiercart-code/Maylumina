# PLANO MESTRE — Site Maylumina

## Estrutura de pastas

```
maylumina/
├── index.html              ← site principal
├── admin/
│   └── index.html          ← painel restrito da cliente
├── css/
│   └── style.css
├── js/
│   ├── main.js             ← animações, scroll, vídeos
│   ├── checkout.js          ← Mercado Pago + Melhor Envio
│   └── admin.js             ← lógica do painel
├── assets/
│   ├── videos/              ← vídeos dos produtos (depois)
│   ├── images/              ← imagens geradas por IA
│   ├── icons/               ← ícones da marca
│   └── fonts/               ← fontes custom
└── docs/
    └── PLANO-MESTRE.md      ← este arquivo
```

---

## FASE 1 — Geração de assets visuais (IAs externas)

### Passo 1.1 — Imagem de referência → Nano Banana

**O que fazer:**
Pegar a imagem de referência (banheira com flores, mão, água, espuma)
e gerar uma versão nova no Nano Banana usando as cores da Maylumina.

**Prompt sugerido (adaptar ao estilo do Nano Banana):**
```
A dreamy overhead view of a luxurious bath filled with 
flower petals floating on milky water with soft foam. 
No hand visible. No bathtub edges visible — only water, 
foam, and petals. Color palette: warm cream (#F2EAE0), 
vivid hot pink/magenta (#E91E8C) petals, warm orange 
(#F0944E) petals and foam tones, turquoise/cyan (#00CCA8) 
accents in some petals, touches of purple (#8B4F9F). 
The gradient of colors should flow from cream to orange 
to magenta pink naturally. Soft diffused lighting from 
above. Ethereal, artistic, sensorial, vibrant. 
Shot from directly above. Ultra high resolution.
```

**Gerar pelo menos 3 variações** e escolher a melhor.

**Esforço:** 1-2 horas de iteração de prompts.

---

### Passo 1.2 — Imagem estática → Vídeo com Higgsfield

**O que fazer:**
Pegar a melhor imagem do passo anterior e enviar pro Higgsfield
para criar um vídeo com movimento sutil de água.

**Instruções pro Higgsfield:**
- Movimento: ondulação suave da água, pétalas flutuando lentamente
- Duração: 6-10 segundos em loop perfeito (seamless loop)
- Sem zoom, sem pan — câmera estática
- Movimento lento e hipnótico
- Exportar em MP4 e WebM (máxima qualidade)

**Importante:** o loop precisa ser perfeito (o frame final
conecta suavemente com o primeiro). Se o Higgsfield não
fizer loop perfeito, use o CapCut ou Runway pra ajustar.

**Esforço:** 2-3 horas (incluindo testes de loop).

---

### Passo 1.3 — Hospedar o vídeo

**Opções gratuitas para streaming sem player visível:**

1. **Bunny.net Stream** (recomendado)
   - Free tier generoso
   - Entrega em HLS (carrega por pedaço, sem buffering)
   - Sem branding/player — você controla o <video> via HTML
   - CDN global = carrega rápido em qualquer lugar

2. **Cloudinary** (alternativa)
   - Free tier: 25GB de banda/mês
   - Transformações automáticas (redimensionar, comprimir)
   - Suporta .webm e .mp4 adaptativo

**O que subir:**
- Versão desktop: 1920x1080, ~30fps, bitrate moderado
- Versão mobile: 720x1280 (vertical) ou 720x720, bitrate baixo
- Formato: .webm (Chrome/Firefox) + .mp4 (Safari/iOS)

**Esforço:** 30 minutos.

---

## FASE 2 — Estrutura do site (HTML + CSS)

### Passo 2.1 — Montar o index.html base

**Estrutura das seções (de cima pra baixo):**

```
[VÍDEO FIXO DE FUNDO — sempre visível, position:fixed]

  Seção 1: HERO
  → Título: "Autocuidado que ilumina."
  → Subtítulo: frase sobre produtos sensoriais
  → Botão CTA: "Conhecer produtos"
  → Fundo: transparente (vídeo aparece por trás)

  Seção 2: SOBRE A MAYLUMINA
  → Texto do manifesto/sobre (versão curta)
  → Fundo: crème semi-transparente com glassmorphism leve
  → A seção cobre parcialmente o vídeo

  Seção 3: SIGNIFICADO DAS CORES
  → Cards coloridos com cada cor da paleta
  → Animação de entrada ao rolar (Fable 5 / CSS)

  Seção 4: PRODUTOS
  → Grid de produtos com micro-vídeo artístico
  → Vídeo autoplay muted loop dentro do card
  → Ao clicar → abre página/modal de compra

  Seção 5: EXPERIÊNCIA / RITUAL
  → Texto sensorial sobre os rituais
  → Pode ter parallax com imagem IA

  Seção 6: RODAPÉ
  → Instagram, WhatsApp, frase da marca
  → Links legais (depois)
```

**Comportamento do vídeo fixo:**
```css
.video-bg {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  object-fit: cover;
  z-index: -1;
}
```

As seções rolam por cima com `position: relative; z-index: 1;`

**Esforço:** 3-5 horas para o HTML/CSS completo.

---

### Passo 2.2 — Paleta de cores CSS (baseada na logo real)

```css
:root {
  --creme:       #F2EAE0;
  --laranja:     #F0944E;
  --pink:        #E91E8C;
  --turquesa:    #00CCA8;
  --roxo:        #8B4F9F;
  --branco:      #FFFFFF;
  --texto:       #3A2F2F;
  --texto-light: #6B5E5E;
  --glass-bg:    rgba(242, 234, 224, 0.85);
  --glass-blur:  blur(12px);
}
```

**Nota:** a paleta real da logo é mais vibrante e saturada
do que o documento de identidade sugeria. O rosa virou
pink/magenta (#E91E8C), o turquesa é mais ciano (#00CCA8),
o laranja é mais quente (#F0944E), e o verde limão não
aparece na logo (removido como cor primária). O gradiente
principal da marca vai de crème → laranja → pink/magenta.

**Fontes sugeridas (Google Fonts, gratuitas):**
- Títulos: "Cormorant Garamond" (elegante, luxo, leve)
- Corpo: "Quicksand" (suave, moderna, feminina)
- Script/logo: a logo já tem tipografia script própria ("My")

---

### Passo 2.3 — Animações de scroll

**Onde usar Fable 5:**
- Entrada do título do hero (fade-up com delay entre linhas)
- Transição entre seções (reveal suave)
- Entrada dos cards de produto (stagger animation)
- Entrada dos cards de cores (cada cor entra com delay)

**Se não usar Fable 5**, replicar com:
- CSS `@keyframes` + `IntersectionObserver` no JS
- Ou GSAP (ScrollTrigger) — gratuito, poderoso

**Esforço com Fable 5:** 2-3 horas
**Esforço sem (CSS/GSAP):** 4-6 horas

---

## FASE 3 — Sistema de produtos

### Passo 3.1 — Banco de dados (Supabase — gratuito)

**Criar conta em supabase.com** (free tier: 500MB, 2 projetos)

**Tabelas necessárias:**

```sql
-- Produtos
CREATE TABLE produtos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome TEXT NOT NULL,
  descricao TEXT,
  preco DECIMAL(10,2) NOT NULL,
  categoria TEXT,
  imagens TEXT[],          -- URLs das imagens
  video_url TEXT,           -- URL do micro-vídeo
  video_curto_url TEXT,     -- vídeo da tela inicial
  ativo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Pedidos
CREATE TABLE pedidos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_nome TEXT NOT NULL,
  cliente_email TEXT,
  cliente_telefone TEXT NOT NULL,
  endereco_rua TEXT NOT NULL,
  endereco_numero TEXT NOT NULL,
  endereco_complemento TEXT,
  endereco_bairro TEXT NOT NULL,
  endereco_cidade TEXT NOT NULL,
  endereco_estado TEXT NOT NULL,
  endereco_cep TEXT NOT NULL,
  frete_valor DECIMAL(10,2),
  frete_prazo TEXT,
  subtotal DECIMAL(10,2) NOT NULL,
  total DECIMAL(10,2) NOT NULL,
  status TEXT DEFAULT 'pendente',
  payment_id TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Itens do pedido
CREATE TABLE pedido_itens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pedido_id UUID REFERENCES pedidos(id),
  produto_id UUID REFERENCES produtos(id),
  quantidade INTEGER NOT NULL,
  preco_unitario DECIMAL(10,2) NOT NULL
);
```

**Esforço:** 1 hora.

---

### Passo 3.2 — Painel administrativo (admin/index.html)

**Acesso:** link secreto + senha simples (Supabase Auth com email/senha)

**Funcionalidades:**
- [ ] Login com email/senha
- [ ] Listar produtos
- [ ] Adicionar produto (nome, descrição, preço, categoria)
- [ ] Upload de imagens (via Cloudinary — link direto)
- [ ] Colar URL do vídeo curto (hospedado no Bunny/Cloudinary)
- [ ] Colar URL do vídeo longo (se quiser)
- [ ] Ativar/desativar produto
- [ ] Ver pedidos (lista com status, dados do cliente, endereço)
- [ ] Atualizar status do pedido (pendente → pago → enviado → entregue)

**Interface:** simples, funcional, sem firula.

**Esforço:** 6-10 horas (é a parte mais trabalhosa).

---

## FASE 4 — Checkout e pagamento

### Passo 4.1 — Mercado Pago (gratuito, cobra só por venda)

**Criar conta no mercadopago.com.br**

**Usar:** Checkout Transparente (o cliente paga sem sair do site)

**Métodos:** Pix, cartão de crédito, boleto

**Taxa:** ~4.99% no cartão, 0.99% no Pix

**Integração:**
- SDK JavaScript do Mercado Pago (client-side)
- Webhook pra confirmar pagamento → atualiza status no Supabase

**Esforço:** 4-6 horas.

---

### Passo 4.2 — Cálculo de frete

**Opção 1: Melhor Envio API (recomendado)**
- Free tier disponível
- Calcula Correios + transportadoras
- Retorna prazo e preço
- Cliente digita o CEP → mostra opções

**Opção 2: API dos Correios direto**
- Gratuita, mas instável e sem suporte
- Só Correios, sem transportadoras

**Fluxo:**
1. Cliente adiciona produto ao carrinho
2. Digita CEP
3. Sistema consulta Melhor Envio
4. Mostra opções (PAC, SEDEX, transportadora)
5. Cliente escolhe
6. Valor do frete soma ao total
7. Segue pro pagamento

**Esforço:** 3-4 horas.

---

## FASE 5 — Vídeos dos produtos (IAs externas)

### Passo 5.1 — Gerar micro-vídeos artísticos

**Para cada produto, gerar um vídeo de 1-3 segundos.**

**Ferramentas (em ordem de qualidade pra produto):**
1. **Kling 2.0** — melhor pra objetos com movimento controlado
2. **Runway Gen-3** — bom pra cenas artísticas
3. **Higgsfield** — bom pra movimento orgânico (água, brilho)

**Estilo dos vídeos:**
- Produto em cena artística (pétalas, brilho, água, luz)
- Cores da paleta real: crème, laranja quente, pink/magenta, turquesa, roxo
- Movimento sutil: brilho cintilando, pétalas caindo, óleo escorrendo
- Sem texto, sem logo
- Loop perfeito (crucial)
- Fundo que combine com o card do site (crème ou transparente)

**Exportar:** .webm (leve, boa qualidade) + .mp4 (fallback)

**Esforço:** 1-2 horas por produto.

---

## FASE 6 — Testes e ajustes finais

### Passo 6.1 — Mobile
- [ ] Vídeo de fundo: testar se roda no iOS (Safari bloqueia autoplay
      em alguns casos — precisa de muted + playsinline)
- [ ] Seções responsivas
- [ ] Cards de produto adaptados
- [ ] Checkout funcional no mobile
- [ ] Formulário de endereço usável em tela pequena

### Passo 6.2 — Performance
- [ ] Lighthouse score > 80
- [ ] Vídeo em HLS/streaming (não download direto)
- [ ] Imagens em .webp
- [ ] Lazy loading nos vídeos de produto
- [ ] Font-display: swap nas fontes

### Passo 6.3 — SEO e meta tags (FASE POSTERIOR)
- [ ] Open Graph (título, descrição, imagem)
- [ ] Favicon
- [ ] Meta description
- [ ] Sitemap básico

**Esforço total da fase 6:** 3-5 horas.

---

## FASE 7 — Hospedagem

**Opções gratuitas:**
1. **Vercel** (recomendado) — deploy por Git, HTTPS automático, rápido
2. **Netlify** — similar ao Vercel
3. **GitHub Pages** — mais limitado, mas funciona

**Domínio:** a cliente precisa registrar maylumina.com.br
(Registro.br ~ R$40/ano)

**Esforço:** 30 minutos.

---

## RESUMO DE ESFORÇO TOTAL

| Fase | Descrição | Estimativa |
|------|-----------|------------|
| 1 | Assets visuais (IA) | 4-6h |
| 2 | HTML + CSS + animações | 8-14h |
| 3 | Supabase + painel admin | 7-11h |
| 4 | Checkout + frete | 7-10h |
| 5 | Vídeos de produto | 1-2h por produto |
| 6 | Testes e ajustes | 3-5h |
| 7 | Hospedagem | 0.5h |
| **TOTAL** | **Sem contar vídeos de produto** | **~30-47h** |

---

## ORDEM DE EXECUÇÃO

```
1. Fase 1 (assets) — pode rodar em paralelo com Fase 2
2. Fase 2 (site HTML/CSS) — base precisa estar de pé
3. Fase 3 (Supabase + admin) — precisa antes do checkout
4. Fase 4 (checkout + frete) — depende do Supabase
5. Fase 5 (vídeos produto) — pode ser a qualquer momento
6. Fase 6 (testes) — depois de tudo montado
7. Fase 7 (hospedagem) — último passo
```

## PRÓXIMO PASSO IMEDIATO

→ Começar pela Fase 2.1: montar o index.html com o vídeo
  fixo de fundo (usando um placeholder) e as seções
  sobrepostas com a identidade visual da Maylumina.
