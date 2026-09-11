# Onde colocar os originais

Coloque aqui os quatro arquivos, com estes nomes (a extensão pode ser
qualquer uma: .jpg, .png, .webp, .tif):

    makeup-olhos       macro/close dos olhos      ≥1600px no lado maior
    makeup-boca        macro da boca              ≥1400px, quadrada
    makeup-gesto       May com o pincel           ≥1600px
    bodycare-kit       o kit na caixa             ≥1600px

Depois rode, na raiz do repositório:

    python3 tools/preparar-fotos.py

O script valida, converte para sRGB, reamostra e grava os quatro finais em
`maylumina/assets/images/`. Os originais desta pasta não são publicados —
ela fica fora da raiz servida pela Vercel.
