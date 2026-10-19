# Integração com a Arkhé

## Implementação local

A página **Doações** inclui o painel **Gerar QR Code para doação** para os tipos de usuário 0 e 1. Ele permite gerar cobranças com valor livre ou fixo, exibir o QR Code, copiar o código e recuperar solicitações após falha. O código é interno da Arkhé.

O padrão é **O doador escolhe o valor**: o QR é criado sem quantia e o pagador informa o valor no app Arkhé. Em **Definir valor agora**, a Missão preenche a quantia antes de gerar. A consulta bancária informa o valor efetivamente pago, que é usado na doação e na entrada do livro-caixa. Cada QR permite um pagamento; para outra doação, gere outro.

O projeto irmão `GuadalupeGestao-Back` contém `arkhe.py`, registrado em `main.py`, e `tests/test_arkhe.py`. A tabela `ARKHE_COBRANCA` é criada automaticamente no Firebird, sem modificar os registros existentes. O backend confirma a cobrança na Arkhé antes de registrar a doação e a entrada na mesma transação.

As credenciais foram salvas em `arkhe.local.json` **somente no backend**, ignorado pelo Git. Para outra máquina, use `arkhe.local.example.json` ou as variáveis de ambiente `ARKHE_API_URL`, `ARKHE_CLIENT_ID` e `ARKHE_CLIENT_SECRET`. Reinicie o Flask após configurar. A troca do Client ID separa o histórico da integração anterior.

O arquivo local `.env.local` deste frontend aponta `API_TARGET` para `http://127.0.0.1:5000`. Ele também é ignorado pelo Git. A alteração anterior do usuário em `vite.config.js` foi preservada.

### Uso

1. Inicie o backend: na pasta `GuadalupeGestao-Back`, execute `.\.venv\Scripts\python.exe -B main.py`.
2. Inicie o frontend com `npm.cmd run dev` e entre com um usuário autorizado.
3. Em **Doações**, clique em **Gerar cobrança Pix**, informe o doador e selecione **O doador escolhe o valor** ou **Definir valor agora**. Projeto e descrição são opcionais.
4. Envie o código ao doador para pagamento dentro da Arkhé.
5. Mantenha a página **Doações** aberta. As cobranças pendentes são consultadas automaticamente a cada cinco segundos enquanto a aba estiver visível, e também ao voltar à janela. Quando a Arkhé confirmar, a doação e o livro-caixa são atualizados. O botão **Consultar pagamento** continua disponível.

A consulta automática não cria cobranças. Requisições simultâneas para a mesma cobrança compartilham a consulta em andamento, e cobranças recebidas deixam de ser consultadas. Se a conexão falhar, a tela informa a falha e tenta novamente no próximo ciclo. Ao sair da página, o acompanhamento automático é interrompido e retomado quando a página for aberta novamente.

Uma cobrança pendente não entra nos totais recebidos. Repetir a confirmação não duplica lançamentos. O UUID da solicitação é salvo na aba durante a criação; após falha ou recarga, **Recuperar solicitação** reutiliza esse identificador. O backend não repete o POST externo para um identificador já reservado. Uma resposta bancária perdida exige conferência com a Arkhé, pois a API documentada não oferece chave de idempotência nem pesquisa de cobrança por referência do integrador.

A data contábil usada é a data da confirmação no Guadalupe, em UTC-3. A consulta documentada não informa a data efetiva do pagamento. Não há execução de pagamentos de despesas nesta implementação; esse endpoint ainda depende do outro grupo.

### Rotas do Guadalupe

| Método | Caminho | Uso |
| --- | --- | --- |
| GET | `/integracoes/arkhe/conta` | Validar a conta vinculada, sem expor credenciais |
| GET | `/integracoes/arkhe/cobrancas` | Listar o histórico persistente |
| POST | `/integracoes/arkhe/cobrancas` | Criar ou recuperar por UUID (`id`, `doador`, `valor`, `id_projeto`, `descricao`) |
| POST | `/integracoes/arkhe/cobrancas/{uuid}/consultar` | Consultar e registrar o recebimento confirmado |

No React, as rotas usam o prefixo `/api` e os cookies existentes do Guadalupe. O navegador não recebe as credenciais Arkhé.

### Verificação realizada

- Conta real: consultas de leitura retornaram HTTP 200, inclusive pelo cliente Python do backend. Nenhuma cobrança ou transferência real foi executada.
- Testes isolados no backend: `python -B -m unittest discover -s tests -p test_arkhe.py -v`.
- Firebird temporário com banco Arkhé simulado: criação da tabela, persistência, consultas simultâneas, lançamento pelas funções reais do livro-caixa e confirmação repetida.
- Chrome headless com API simulada: formulário, perda de resposta, recuperação após recarga, consulta pendente, confirmação, atualização das doações e tela de 390 px.
- Build do Vite e lint do código fonte. Os avisos preexistentes do lint não pertencem ao módulo Arkhé.

## Levantamento inicial

Contrato identificado em 19/10/2026 a partir da documentação incluída no JavaScript público da [página de integrações](https://arkhe-frontend.zbbquj.easypanel.host/dashboard/integracoes). A leitura autenticada da conta foi validada. A criação e o pagamento ainda precisam de validação ponta a ponta com contas de teste do outro grupo.

## Contrato publicado

Backend: `https://arkhe-backend.zbbquj.easypanel.host`.

Todas as chamadas externas exigem os headers `X-Client-ID` e `X-Client-Secret`. Na conta PJ, a opção **Nova integração** gera essas credenciais. O secret aparece somente na criação.

| Método | Caminho | Finalidade |
| --- | --- | --- |
| GET | `/api/v1/conta` | Dados da conta PJ vinculada |
| GET | `/api/v1/saldo` | Saldo atual |
| GET | `/api/v1/movimentacoes` | Entradas e saídas |
| GET | `/api/v1/resumo-financeiro` | Receitas, despesas e saldo do período |
| POST | `/api/v1/cobrancas/pix` | Criar cobrança Pix Arkhé |
| POST | `/api/v1/cobrancas/pix/qrcode` | Criar QR com valor livre ou fixo |
| GET | `/api/v1/cobrancas/pix/{id_cobranca}` | Consultar cobrança e pagamento |

Movimentações e resumo aceitam `data_inicio` e `data_fim` no formato `YYYY-MM-DD`. Sem datas, usam o primeiro dia do mês atual até hoje.

A integração usa `POST /api/v1/cobrancas/pix/qrcode`: envie `{"valor_livre":true}` para valor livre ou `{"valor":125.50}` para valor fixo. A resposta contém `id_cobranca`, `valor` (nulo enquanto uma cobrança livre estiver pendente), `valor_livre`, `codigo_pagamento`, `qr_code_svg`, `status` e `tipo_cobranca`. O frontend desenha o QR a partir do próprio `codigo_pagamento`. A documentação descreve cobranças internas da Arkhé, sem garantir compatibilidade com outros bancos.

A migração acrescenta `VALOR_LIVRE` à tabela local e preserva as cobranças anteriores como fixas. Internamente, zero é usado apenas como marcador para o valor ainda desconhecido; ele não é enviado à Arkhé nem registrado como doação. Ao confirmar o pagamento, o valor deve ser positivo, finito e ter no máximo duas casas decimais. A quantia informada pelo banco é gravada na mesma transação que a doação e o livro-caixa.

Na consulta, `status: 0` significa pendente e `status: 1` significa pago. Erros usam status HTTP e podem retornar `mensagem`.

## Aplicação no Guadalupe

Fluxo proposto: navegador → backend Flask do Guadalupe → API Arkhé. As credenciais devem ficar no ambiente do Flask, fora do React, de variáveis `VITE_*`, do armazenamento do navegador e do repositório.

O cadastro atual em `NovaDoacao.jsx` registra uma contribuição já recebida e pode criar sua entrada no livro-caixa. Por isso, a cobrança pendente deve ter persistência própria no backend. Criar uma cobrança não deve registrar uma doação recebida.

Após consultar e confirmar o pagamento na Arkhé, o backend deve registrar a doação e a entrada uma única vez, vinculadas ao `id_cobranca` externo com restrição de unicidade. Consultas repetidas não podem duplicar os lançamentos. A vinculação ao projeto e os dados locais do doador precisam acompanhar a cobrança no Guadalupe, pois a criação publicada recebe apenas o valor.

O frontend deve permitir gerar a cobrança, apresentar o código de pagamento e consultar seu status, preservando a cobrança após recarregar a página. O retorno do navegador não basta para confirmar recebimento. A documentação consultada não publica webhook; inicialmente, a confirmação pode ser feita por consulta ao backend.

O endpoint atual `/pendencias/<tipo>/<id>/pagar` do Guadalupe registra uma baixa contábil. A API externa documentada da Arkhé não lista envio de Pix nem pagamento de boletos. Para executar pagamentos de despesas, solicitar ao outro grupo o contrato correspondente. Consultar saídas no extrato é um recurso diferente de executar pagamentos.

## Pendências com o outro grupo

- Confirmação do outro grupo sobre execução de pagamentos, ambiente de testes e tratamento de tentativas de criação cuja resposta seja perdida. A documentação consultada não especifica chave de idempotência para criar cobranças; evitar repetição automática desse POST.
- Validação de uma cobrança e de seu pagamento entre contas de teste da Arkhé. Os testes automatizados do recebimento usam a API simulada.
