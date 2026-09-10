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

Arquivo: **`docs/supabase/001-auth-e-rls.sql`** (versão 2 — a versão 1 tinha
buracos, ver o fim do arquivo)

Enquanto ela não for aplicada, o banco continua exatamente como foi
encontrado (verificado por sondagem, sem alterar nenhum dado):

| Alguém sem login consegue… | Hoje |
|---|---|
| ler a senha do painel | **sim** |
| criar / editar / apagar produto | **sim** |
| ler os pedidos dos clientes | **sim** |
| alterar ou apagar pedidos | **sim** |
| ler pedido_itens | **sim** |

E, como o cadastro público está aberto, qualquer pessoa que criasse uma
conta poderia **apagar as tabelas inteiras com um comando** — `TRUNCATE`
não passa por Row Level Security. Isso foi reproduzido em ensaio.

### 2.1 Onde clicar, exatamente

1. Abrir **https://supabase.com/dashboard** e entrar na conta.
2. Escolher o projeto **`rkwlumnrlzmusdccwvxd`** (é o que o site usa).
3. No menu da esquerda, clicar em **SQL Editor**.
4. Clicar em **+ New query**.
5. Abrir o arquivo `docs/supabase/001-auth-e-rls.sql` deste repositório,
   **selecionar tudo, copiar e colar** na janela do SQL Editor.
6. Clicar em **Run** (ou Ctrl+Enter).

O arquivo é uma transação só: ou entra inteiro, ou não entra nada. Ele
**não apaga nenhuma linha** de produto ou pedido. A única coisa que ele
destrói de propósito é a coluna `admin_config.senha_hash`, e isso é
irreversível.

### 2.2 O que tem de aparecer

No fim da execução o próprio arquivo roda seis conferências. O esperado:

- `rls_ligado` = **true** nas cinco tabelas;
- exatamente **7 policies**, nenhuma a mais;
- a busca por `senha_hash` volta **0 linhas**;
- contagens: **produtos = 2**, pedidos = 0, pedido_itens = 0,
  admin_config = 1 (a linha continua, só a coluna sumiu);
- `admins_registrados` = **0** — é o passo 2.3 que resolve;
- nenhuma linha com `TRUNCATE`/`TRIGGER`/`REFERENCES`.

Se a contagem de produtos vier diferente de 2, **pare e me chame**.

### 2.3 Criar o administrador de verdade

Enquanto `public.admins` estiver vazia, **ninguém administra o site — nem
você**. Os dados ficam intactos, mas o painel não deixa salvar nada.

1. Menu da esquerda → **Authentication** → **Users** → **Add user** →
   *Create new user*.
2. Preencher o e-mail que você quiser usar e uma **senha nova**. Marcar
   **Auto Confirm User**.
   A senha antiga esteve publicamente legível: não serve nem aqui nem em
   lugar nenhum.
3. Voltar ao **SQL Editor** e rodar, trocando o e-mail:

   ```sql
   insert into public.admins (user_id)
   select id from auth.users where email = 'SEU_EMAIL_AQUI'
   on conflict (user_id) do nothing;

   select count(*) from public.admins;   -- tem de voltar 1
   ```

4. Menu da esquerda → **Authentication** → **Providers** → **Email** →
   desligar **Enable email signups** → **Save**.

### 2.4 Conferir e me avisar

Depois disso, me diga que aplicou. Eu rodo os testes de autorização ao
vivo contra o banco real, com a chave anon pública, e te devolvo a matriz
final. Os comandos de conferência também estão na seção 8.4 do próprio
arquivo `.sql`, se você quiser rodar antes.

Só depois desses testes passarem é que dá para dizer que o painel está
seguro.

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
