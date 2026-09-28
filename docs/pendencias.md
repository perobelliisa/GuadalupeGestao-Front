# Pendências financeiras

A página consulta `GET /pendencias` e mostra o primeiro vencimento ainda não pago de cada conta recorrente e de cada empréstimo parcelado, ordenados pela data mais antiga. Contas avulsas e empréstimos à vista não entram nessa lista.

- Alta: atrasadas, vencendo hoje ou em até dois dias.
- Média: de três a treze dias, cobrindo também o intervalo entre uma e duas semanas.
- Baixa: a partir de quatorze dias, sem limite superior.

Nas contas, `dia_inicio` é o primeiro vencimento. Os intervalos cadastrados são 15 dias, 30 dias, diário e semanal. `dia_fim` é inclusivo. Vencimentos atrasados não são descartados quando o período termina.

Nos empréstimos, as parcelas vencem mensalmente a partir da data de contratação, conforme o cálculo usado no cadastro. Dias 29, 30 e 31 são limitados ao último dia do mês sem alterar o dia de referência dos meses seguintes. A última parcela absorve diferenças de centavos.

## Pagamentos

A busca por texto considera descrição, projeto, responsável e prioridade, sem distinguir acentos ou maiúsculas. Os filtros por projeto, período de vencimento (limites inclusivos), responsável e prioridade podem ser combinados. O botão “Limpar filtros” restaura a lista; os cartões mostram as quantidades do resultado filtrado.

O responsável é o usuário vinculado ao empréstimo, obtido de `GET /emprestimos`. Contas recorrentes não possuem responsável cadastrado e aparecem como “Sem responsável”. Os filtros usam IDs para distinguir pessoas com o mesmo nome. Um período com data inicial posterior à final mostra um aviso.

`POST /pendencias/<tipo>/<id>/pagar` recebe o vencimento exibido na tela. O backend verifica novamente se é a próxima ocorrência aberta. Repetir a mesma requisição não paga outra parcela.

O status da despesa original corresponde ao primeiro vencimento. Para os seguintes, o backend registra uma despesa paga no livro-caixa e relaciona a ocorrência na tabela `PAGAMENTO_RECORRENCIA`, na mesma transação. O histórico permanece no banco após recarregar ou reiniciar. Reverter explicitamente o status de um pagamento reabre aquela ocorrência.

O pagamento de empréstimo avança `parcelas_pagas` em uma unidade, respeitando o total contratado. Pagar uma ocorrência não quita automaticamente toda a série. A linha seguinte pode ter a mesma descrição, mas terá outro vencimento ou número de parcela.

A tela remove a ocorrência somente após confirmação da API e consulta novamente os próximos vencimentos. Falhas de consulta são exibidas como erro, sem apresentar uma falsa mensagem de ausência de pendências. A lista também é atualizada ao voltar à janela e a cada minuto.

## Backend e verificação

No projeto irmão `GuadalupeGestao-Back`, os cálculos e consultas ficam em `function.py`, e as rotas de pendências ficam em `livro_caixa.py`. O `main.py` registra as rotas e cria a tabela de controle, caso ainda não exista. Os testes ficam separados em `tests/test_financeiro.py`. Reinicie o backend caso o recarregamento automático esteja desativado.

Na pasta do backend, execute:

```powershell
python -B -m unittest discover -s tests -p test_financeiro.py -v
```

Os testes usam um banco temporário isolado: limites de prioridade, calendários, atrasos, fim de recorrência, quitação, pagamento repetido, autenticação, dados inválidos, reversão, persistência ao reabrir o banco e rollback em caso de falha. Nenhum pagamento real é alterado pelos testes.
