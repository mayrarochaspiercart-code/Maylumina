#!/usr/bin/env python3
"""
MayLumina — preparação dos assets fotográficos finais.

Lê os originais de fotos-entrada/, valida contra o briefing, reamostra e
grava em maylumina/assets/images/ com o nome definitivo.

    python3 tools/preparar-fotos.py

Não decide enquadramento: crop é decisão de arte e é feita no CSS, com
object-position, olhando o resultado renderizado. Aqui só entra o que é
determinístico — dimensão, perfil de cor, compressão e peso.

Sobre o formato: o site serve JPEG em todas as imagens e não usa <picture>.
Trocar para AVIF/WebP exigiria adicionar <picture> com fallback em cada
slot, o que é mexer na arquitetura — e a direção está congelada. O script
mede os três formatos e relata a economia, mas grava JPEG. Se um dia
valer a pena migrar, a decisão fica documentada com número em mãos.
"""
from PIL import Image, ImageCms
from pathlib import Path
import io, sys

RAIZ = Path(__file__).resolve().parent.parent
ENTRADA = RAIZ / 'fotos-entrada'
SAIDA = RAIZ / 'maylumina' / 'assets' / 'images'

# nome final -> (nome de entrada aceito, lado maior alvo, peso alvo em KB, proporção esperada)
# O lado maior de saida vem do tamanho REAL do slot, medido no navegador,
# com folga para tela 2x — nao de um numero redondo. Pedir 1600px para um
# card que renderiza 413px de largura e peso jogado fora, e foi isso que
# fez a primeira passada estourar todos os alvos.
#
# CROP: fracoes (esq, topo, dir, base) do original, aplicadas ANTES de
# reamostrar. So entra aqui o recorte que foi escolhido comparando opcoes
# lado a lado — nao e ajuste fino de layout, que continua sendo
# object-position no CSS.
CROP = {
    # A boca ocupava pouco do card 3:4: o arquivo 1:1 mostra 100% da altura,
    # entao o nariz comia o topo e o assunto ficava pequeno. Comparei tres
    # recortes; este deixa a boca dominante, o nariz parcial, o queixo
    # respirando e os cantos dos labios longe da borda.
    'makeup-boca.jpg': (0.13, 0.18, 0.87, 0.88),
}
# Proporcao final forcada, quando o slot exige (corta do centro).
PROPORCAO = {'makeup-boca.jpg': 0.75}   # 3:4, igual ao card do trio

#   nome final: (prefixo de entrada, lado maior, peso alvo KB, proporcao, por que)
ASSETS = {
    # Fundo de secao inteira, renderizado a 1440x720 no desktop sob um veu de
    # 30-80%. Medido: nenhuma combinacao bate os 180KB do briefing sem upscale
    # visivel — a foto tem cabelo fino, glitter e sarda, que comprimem mal.
    # 1150px a q80 da 249KB com upscale de 1.25x, invisivel sob o veu; 1024px
    # daria 203KB mas 1.41x ja aparece em tela grande. O alvo do briefing foi
    # estimado sem conhecer a textura do material.
    'makeup-olhos.jpg':  ('makeup-olhos',  1438, 250, (0.70, 0.85)),
    # cards do trio: 413x550 no desktop, 266x355 no celular -> 2x de 413 = 826
    # depois do recorte a boca sai 658x878 (1,6x o card de 413x550): o
    # original nao tem pixel para 2x nesse enquadramento, e apertar menos
    # custaria o enquadramento, que e o que importa aqui
    'makeup-boca.jpg':   ('makeup-boca',   1140, 120, (0.95, 1.05)),
    'makeup-gesto.jpg':  ('makeup-gesto',  1140, 150, (0.70, 0.85)),
    'bodycare-kit.jpg':  ('bodycare-kit',  1140, 150, (0.70, 0.85)),
}
EXTS = ('.jpg', '.jpeg', '.png', '.webp', '.avif', '.tif', '.tiff')


def achar(prefixo):
    for p in sorted(ENTRADA.iterdir()) if ENTRADA.exists() else []:
        if p.is_file() and p.stem.lower().startswith(prefixo) and p.suffix.lower() in EXTS:
            return p
    return None


def para_srgb(im):
    """Converte para sRGB quando o arquivo traz outro perfil embutido."""
    icc = im.info.get('icc_profile')
    if icc:
        try:
            origem = ImageCms.ImageCmsProfile(io.BytesIO(icc))
            return ImageCms.profileToProfile(im, origem, ImageCms.createProfile('sRGB'),
                                             outputMode='RGB'), True
        except Exception:
            pass
    return im.convert('RGB'), False


def grava_no_peso(im, destino, alvo_kb):
    """Desce a qualidade só até bater o peso, e nunca abaixo de 78:
    o briefing diz para não sacrificar qualidade perceptível."""
    for q in (90, 88, 86, 84, 82, 80, 78):
        buf = io.BytesIO()
        im.save(buf, 'JPEG', quality=q, optimize=True, progressive=True, subsampling=1)
        if buf.tell() <= alvo_kb * 1024 or q == 78:
            destino.write_bytes(buf.getvalue())
            return q, buf.tell()


def comparar_formatos(im, alvo_kb):
    tam = {}
    for fmt, kw in (('WEBP', dict(quality=82, method=6)), ('AVIF', dict(quality=62))):
        try:
            buf = io.BytesIO(); im.save(buf, fmt, **kw); tam[fmt] = buf.tell()
        except Exception:
            pass
    return tam


def main():
    if not ENTRADA.exists() or not any(ENTRADA.iterdir()):
        print(f'Coloque os originais em {ENTRADA.relative_to(RAIZ)}/ e rode de novo.')
        print('Nomes aceitos (qualquer extensão): ' + ', '.join(v[0] for v in ASSETS.values()))
        return 1

    faltando, erros = [], []
    for final, (prefixo, lado, kb, ar) in ASSETS.items():
        origem = achar(prefixo)
        if not origem:
            faltando.append(prefixo); continue

        im = Image.open(origem)
        w0, h0 = im.size
        im, converteu = para_srgb(im)

        if final in CROP:
            l, t, r, b = CROP[final]
            im = im.crop((int(l*w0), int(t*h0), int(r*w0), int(b*h0)))
        if final in PROPORCAO:
            alvo_w = round(im.size[1] * PROPORCAO[final])
            if alvo_w < im.size[0]:
                dx = (im.size[0] - alvo_w) // 2
                im = im.crop((dx, 0, dx + alvo_w, im.size[1]))
            else:
                alvo_h = round(im.size[0] / PROPORCAO[final])
                dy = (im.size[1] - alvo_h) // 2
                im = im.crop((0, dy, im.size[0], dy + alvo_h))
        w0, h0 = im.size

        if max(w0, h0) < lado:
            print(f'  ⚠ {final}: original {w0}x{h0} é menor que o alvo de {lado}px — '
                  f'não faço upscale, vai no tamanho que veio')

        razao = w0 / h0
        if final in PROPORCAO:
            ar = (PROPORCAO[final] - 0.02, PROPORCAO[final] + 0.02)
        if not (ar[0] <= razao <= ar[1]):
            print(f'  ⚠ {final}: proporção {razao:.2f} fora do previsto {ar[0]}–{ar[1]} — '
                  f'confira o enquadramento antes de publicar')

        if max(w0, h0) > lado:
            escala = lado / max(w0, h0)
            im = im.resize((round(w0 * escala), round(h0 * escala)), Image.LANCZOS)

        q, tam = grava_no_peso(im, SAIDA / final, kb)
        outros = comparar_formatos(im, kb)
        extra = '  '.join(f'{k} seria {v/1024:.0f}KB' for k, v in outros.items())
        marca = 'ok' if tam <= kb * 1024 else f'ACIMA do alvo de {kb}KB'
        print(f'  {final:22s} {im.size[0]}x{im.size[1]}  q{q}  {tam/1024:5.0f} KB  {marca}'
              + (f'   [{extra}]' if extra else '')
              + ('   (perfil convertido para sRGB)' if converteu else ''))

    if faltando:
        print('\n  faltando em fotos-entrada/: ' + ', '.join(faltando))
    for e in erros:
        print(f'  ✗ {e}')
    return 1 if (faltando or erros) else 0


if __name__ == '__main__':
    sys.exit(main())
