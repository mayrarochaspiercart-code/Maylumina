# O que só a May pode fazer

Cinco coisas ficaram fora do alcance do código. Estão em ordem de urgência.
As duas primeiras são de segurança e valem para **hoje**.

---

## 1. 🔴 URGENTE — trocar a senha "maylumina2026"

Essa senha esteve **publicamente legível na internet**. Qualquer pessoa
conseguia buscá-la com uma única requisição, sem login, sem nada:

```
GET /rest/v1/admin_config?select=senha_hash   →   200 {"senha_hash":"maylumina2026"}
```

Se ela for usada em qualquer outro lugar — e-mail, Instagram, banco,
qualquer coisa — **trocar lá também, agora**. Não é "provavelmente ninguém
viu": é uma senha que esteve aberta.

## 2. 🔴 URGENTE — aplicar a migration do Supabase

Arquivo: **`docs/supabase/001-auth-e-rls.sql`**

Enquanto ela não for aplicada, o banco continua exatamente como foi
encontrado (verificado por sondagem, sem alterar nenhum dado):

| Alguém sem login consegue… | Hoje |
|---|---|
| ler a senha do painel | **sim** |
| criar produto | **sim** |
| editar produto | **sim** |
| apagar produto | **sim** |
| ler os pedidos dos clientes | **sim** |
| alterar pedidos | **sim** |

Como aplicar: Supabase Dashboard → **SQL Editor** → colar o arquivo inteiro
→ Run. Depois seguir a seção **6** que está no fim do próprio arquivo:

1. criar o usuário da May em *Authentication → Users* com uma **senha nova**;
2. registrar esse usuário na tabela `admins` (o SQL está lá);
3. desligar *Enable email signups* em *Authentication → Providers → Email*
   (hoje qualquer pessoa pode criar conta no projeto);
4. rodar os quatro `curl` de conferência — os três primeiros têm que passar
   a falhar, e a vitrine tem que continuar respondendo 200;
5. entrar em `/admin` com o e-mail e a senha novos e confirmar que criar,
   editar e apagar produto continuam funcionando.

**Enquanto os passos 1 a 5 não estiverem feitos, o painel não está seguro.**
O `/admin` já não guarda mais senha nenhuma e já usa login de verdade, mas
quem decide o que pode ser lido e escrito é o banco — e o banco ainda não
recebeu as regras.

---

## 3. Vídeo do hero sem marca d'água

Detalhado em `ASSET_GAPS.md`, seção 0. Resumo: o vídeo antigo tinha
"KlingAI 3.0" gravado na imagem e **saiu do ar**. O hero da Edição 01 usa
hoje o quadro-fonte da mesma cena, `foto2.jpeg`, que é limpo.

Para o movimento voltar, é preciso uma exportação sem marca (plano pago do
Kling) ou uma filmagem equivalente.

## 4. Fotografia de maquiagem para a Edição 02

Detalhado em `ASSET_GAPS.md`, seção 1. O lugar na página já está pronto e
comentado; hoje ele é ocupado por pigmento, não por foto emprestada de outra
edição.

## 5. Domínio próprio

Detalhado em `ASSET_GAPS.md`, seção 7. Sugestão: `maylumina.com.br`,
apontado na Vercel em *Settings → Domains*. Depois é só atualizar o endereço
em `canonical`, `og:*`, `sitemap.xml` e `robots.txt`.
