# MayLumina — Texto pronto para submissão

---

## Project title

**MayLumina — A Living Publication on the Colors of Self-Care**

## Short description (máx. ~150 caracteres)

> A brand universe where every area of self-care is a living editorial issue,
> and light refracts into color.

## Long description

MayLumina is a Brazilian art body care brand founded by May Rocha. The brief
was not "a beauty website" — it was to turn a brand with many arms (body care,
makeup, artisanal rituals, future services) into something whose diversity
reads as strength rather than lack of focus.

The answer was to treat the brand as a **publication**. MayLumina is the
universe; each area is an **issue** of that universe. A woman has many
versions — so does her self-care.

The whole system is governed by one metaphor, drawn from the brand's own
origin: **light comes from God, refracts, and becomes color, matter and
expression.** That is not decoration — it is structure. The homepage masthead
carries **no photograph**, because there the light has not refracted yet. It
only becomes water, pigment and matter once you enter an issue. That single
conceptual decision is also why the homepage reaches LCP in 124 ms: the hero
is typography and CSS light, with no image in the critical path.

Opening an issue is the signature interaction: the cover does not flip like a
PDF — it **expands** until it becomes the issue's own hero, carrying the
masthead and headline across the navigation.

Built as a static site with no framework, because the stack already delivered
the experience and complexity without function was out of scope.

## Concept

```
LIGHT → REFRACTION → COLOR → MATTER → EXPRESSION → CARE
```

One light, many colors. Each issue is the same light crossing a different
material.

## Technologies

- Semantic HTML5, modern CSS (custom properties, fluid `clamp()` scales,
  container-aware layout, `svh`)
- Vanilla JavaScript ES modules — no framework, no bundler, no build step
- View Transitions API with a full custom fallback
- IntersectionObserver for light and content entry
- Supabase (REST, anon key) for the live product catalogue
- Vercel static hosting

## Suggested categories

Sites of the Day · Honorable Mention · Developer Award

**Best fit:** Beauty · Fashion & Beauty · Art & Illustration

## Tags

`editorial` `typography` `beauty` `self-care` `brand` `light` `color`
`magazine` `portuguese` `no-framework` `accessibility` `art-direction`

## Credits (a preencher pela cliente)

| Papel | Nome |
|---|---|
| Brand & Founder | May Rocha (Mayra Rocha) |
| Photography | *(preencher — as fotografias são da própria marca)* |
| Art Direction | *(preencher)* |
| Design | *(preencher)* |
| Development | *(preencher)* |

## Screenshots recomendadas, na ordem de apresentação

1. **Home — masthead**: `MAYLUMINA` / "SUA LUZ TAMBÉM TEM COR."
2. **Home — a banca**: as duas capas lado a lado
3. **Abertura de edição**: a capa a meio caminho da expansão
4. **Edição 01 — capa em movimento**: "AUTOCUIDADO TAMBÉM É ARTE."
5. **Edição 01 — coluna presa**: a história ao lado da foto
6. **Edição 01 — vitrine**: os cards editoriais
7. **Edição 02 — capa**: "MAKEUP TAMBÉM É AUTOCUIDADO."
8. **Refração**: "Uma luz. Muitas cores."
9. **Mobile — masthead**
10. **Mobile — uma edição**

## Descrição da interação principal

On the homepage, the issues are presented as real magazine covers. On hover,
an iridescent border lights up and the photograph breathes. On click, the
cover **expands to fill the viewport and becomes the issue's hero** — the
masthead and headline keep continuity across the navigation, so it reads as
opening a publication, not loading a page. Uses View Transitions where
available, with a custom expansion fallback everywhere else, and navigates
directly under `prefers-reduced-motion`.

## Resumo mobile

Mobile is directed, not compressed. The navigation becomes a full-screen
typographic menu; the three-card rows become swipeable rails with the next
card peeking; photographs always follow text when stacking; headlines keep
magazine scale (43px) instead of shrinking to body size. Zero horizontal
overflow at 360, 390 and 430px.

---

## ⚠️ Ainda depende da cliente

1. **Domínio próprio.** O site está em `maylumina.vercel.app`. Recomendado
   conectar um domínio antes da submissão final — já está preparado para isso
   (basta trocar o host nos `canonical`, `og:url` e no `sitemap.xml`).
2. **Créditos** da tabela acima.
3. **Conta e taxa de submissão** no Awwwards — exige login e pagamento da
   própria cliente. Nenhuma submissão foi feita.
