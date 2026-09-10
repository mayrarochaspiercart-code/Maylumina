/* ═══════════════════════════════════════════════════════════════════
   MAYLUMINA — MODELO DE EDIÇÕES
   Uma edição é um mundo dentro do universo. Adicionar a próxima é
   acrescentar um objeto aqui e uma pasta em /edicao/<slug>/.
   Nenhum layout precisa ser duplicado para isso.
   ═══════════════════════════════════════════════════════════════════ */

export const EDICOES = [
  {
    slug: 'art-body-care',
    numero: '01',
    status: 'publicada',
    titulo: 'Autocuidado também é arte.',
    // Quebras da manchete na capa — compostas à mão, como numa revista
    manchete: ['Autocuidado', 'também é', 'arte.'],
    identificacao: 'Art Body Care',
    deck: 'Cor, aroma, textura e luz.',
    descricao:
      'A edição de estreia da MayLumina: body care artesanal onde cor, ' +
      'aroma e textura viram um ritual de cuidado com a pele.',
    chamadas: ['Ritual', 'Aroma', 'Textura', 'Arte na pele'],
    // Predominância cromática desta edição
    cor: 'var(--pink)',
    corLuz: 'rgba(233, 30, 140, 0.20)',
    capa: {
      src: '/assets/images/foto3.jpeg',
      alt: 'May imersa em uma banheira de água leitosa tingida de rosa, ' +
           'laranja e azul, segurando uma rosa de pétalas multicoloridas.',
      largura: 974,
      altura: 1280
    },
    url: '/edicao/art-body-care/',
    // Como os produtos desta edição são encontrados no Supabase
    categoriaProduto: 'body-care',
    cta: 'Abrir edição'
  },
  {
    slug: 'makeup',
    numero: '02',
    status: 'publicada',
    titulo: 'Makeup também é autocuidado.',
    manchete: ['Makeup', 'também é', 'autocuidado.'],
    identificacao: 'Cor & Expressão',
    deck: 'Cor, expressão, presença e identidade.',
    descricao:
      'A segunda edição da MayLumina: maquiagem como ritual de presença — ' +
      'cor que expressa identidade, não que esconde.',
    chamadas: ['Cor', 'Expressão', 'Identidade', 'Presença'],
    cor: 'var(--roxo)',
    corLuz: 'rgba(139, 79, 159, 0.22)',
    capa: {
      // Foto sem texto gráfico embutido: a tipografia da capa fica sozinha
      src: '/assets/images/foto1.jpeg',
      alt: 'May deitada sobre fundo claro, cabelo ruivo espalhado ao redor do ' +
           'rosto, maquiagem em tons quentes, vestindo jeans.',
      largura: 1122,
      altura: 1402
    },
    url: '/edicao/makeup/',
    categoriaProduto: 'makeup',
    cta: 'Abrir edição'
  }
];

/** A edição seguinte, em ciclo — nenhuma edição termina em beco sem saída. */
export function proximaEdicao(slugAtual) {
  const publicadas = EDICOES.filter((e) => e.status === 'publicada');
  if (publicadas.length < 2) return null;
  const i = publicadas.findIndex((e) => e.slug === slugAtual);
  return publicadas[(i + 1) % publicadas.length];
}

export function edicaoPorSlug(slug) {
  return EDICOES.find((e) => e.slug === slug) || null;
}
