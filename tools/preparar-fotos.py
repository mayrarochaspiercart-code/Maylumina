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
ASSETS = {
    'makeup-olhos.jpg':  ('makeup-olhos',  1600, 180, (0.70, 0.85)),
    'makeup-boca.jpg':   ('makeup-boca',   1400, 120, (0.95, 1.05)),
    'makeup-gesto.jpg':  ('makeup-gesto',  1600, 150, (0.70, 0.85)),
    'bodycare-kit.jpg':  ('bodycare-kit',  1600, 150, (0.70, 0.85)),
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

        if max(w0, h0) < lado:
            erros.append(f'{origem.name}: {w0}x{h0} — abaixo do mínimo de {lado}px no lado maior')

        razao = w0 / h0
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
