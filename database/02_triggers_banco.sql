-- ARQUIVO DE AUDITORIA: execute conectado ao banco BANCO.FDB.
-- Cada tabela tem tres gatilhos: INSERT (AFTER), UPDATE (BEFORE) e DELETE (BEFORE).
-- TG = trigger/gatilho; AI = AFTER INSERT; AU = AFTER UPDATE; AD = AFTER DELETE.
-- NEW significa os valores que a linha tera depois da operacao; OLD significa os valores anteriores.
-- V_ANTIGO e V_NOVO sao variaveis de texto que guardam os valores antigos e novos dos campos.
-- || junta textos. Ex.: 'NOME=' || NEW.NOME junta o rotulo NOME com o valor da coluna.
-- CAST(valor AS VARCHAR(...)) converte numero/data/outro tipo em texto para guardar no historico.
-- SUBSTRING(texto FROM 1 FOR 450) pega o texto desde o caractere 1, limitado a 450 caracteres.
-- SUBSTRING(texto FROM 1 FOR 8191) faz o mesmo, limitado a 8191 caracteres (tamanho de CAMPO_ANTIGO/NOVO).
-- COALESCE(a, b, ...) devolve a primeira opcao que nao seja NULL; aqui NULL vira '<NULL>' ou um texto de reserva.
-- NULLIF(valor, '') transforma texto vazio em NULL; assim COALESCE consegue usar o valor alternativo.
-- RDB$GET_CONTEXT le o ID do usuario e o dispositivo que o backend informou para esta conexao.
-- SELECT U.EMAIL procura o email do usuario no banco principal, para identifica-lo no log.
-- EXECUTE STATEMENT executa no BANCOLOG um INSERT montado como texto por concatenacao, como no modelo da aula.
-- REPLACE duplica apostrofos que estejam nos dados para que eles nao fechem a string SQL antes da hora.
-- ON EXTERNAL DATA SOURCE aponta para o BANCOLOG.FDB separado; usuario e senha autorizam a conexao a ele.
-- CURRENT_TIMESTAMP registra a data e o horario em que o gatilho foi executado.
-- UPDATE/DELETE rodam BEFORE; o log registra a tentativa antes da conclusao da operacao.
-- O valor FOR 450 limita cada campo individual; o registro final ainda e limitado a 8191 caracteres.
-- Em USUARIO, SENHA_HASH e omitido de proposito para nao copiar credenciais para o historico.
-- SET TERM troca temporariamente o final de comando para ^; assim os ; dentro do gatilho nao encerram o CREATE TRIGGER.

-- Troca o terminador para ^ enquanto cada gatilho e criado.
SET TERM ^ ;

CREATE OR ALTER TRIGGER TG_AI_CATEGORIA -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR CATEGORIA -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE AFTER INSERT -- Executa depois de uma inclusao.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = ''; -- INSERT nao tem linha anterior (OLD), entao CAMPO_ANTIGO fica vazio.
  V_NOVO = 'ID_CATEGORIA=' || COALESCE(SUBSTRING(CAST(NEW.ID_CATEGORIA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'NOME=' || COALESCE(SUBSTRING(CAST(NEW.NOME AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo NOME; converte para texto, limita a 450 caracteres e representa NULL.
       'STATUS=' || COALESCE(SUBSTRING(CAST(NEW.STATUS AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo STATUS; converte para texto, limita a 450 caracteres e representa NULL.
       'TIPO=' || COALESCE(SUBSTRING(CAST(NEW.TIPO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo TIPO; converte para texto, limita a 450 caracteres e representa NULL.
       'DESCRICAO=' || COALESCE(SUBSTRING(CAST(NEW.DESCRICAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DESCRICAO; converte para texto, limita a 450 caracteres e representa NULL.
       'ID_USUARIO=' || COALESCE(SUBSTRING(CAST(NEW.ID_USUARIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_USUARIO; converte para texto, limita a 450 caracteres e representa NULL.
       'DISPOSITIVO=' || COALESCE(SUBSTRING(CAST(NEW.DISPOSITIVO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo DISPOSITIVO; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NEW.ID_USUARIO; -- Usa o ID_USUARIO da propria linha quando nao veio ID no contexto.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, NULLIF(NEW.DISPOSITIVO, ''), 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''CATEGORIA'', ''ID_CATEGORIA - NOME - STATUS - TIPO - DESCRICAO - ID_USUARIO - DISPOSITIVO'', ''INSERT'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AU_CATEGORIA -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR CATEGORIA -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE UPDATE -- Executa antes da alteracao; OLD sao os valores atuais e NEW os valores propostos.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'ID_CATEGORIA=' || COALESCE(SUBSTRING(CAST(OLD.ID_CATEGORIA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'NOME=' || COALESCE(SUBSTRING(CAST(OLD.NOME AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo NOME; converte para texto, limita a 450 caracteres e representa NULL.
       'STATUS=' || COALESCE(SUBSTRING(CAST(OLD.STATUS AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo STATUS; converte para texto, limita a 450 caracteres e representa NULL.
       'TIPO=' || COALESCE(SUBSTRING(CAST(OLD.TIPO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo TIPO; converte para texto, limita a 450 caracteres e representa NULL.
       'DESCRICAO=' || COALESCE(SUBSTRING(CAST(OLD.DESCRICAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DESCRICAO; converte para texto, limita a 450 caracteres e representa NULL.
       'ID_USUARIO=' || COALESCE(SUBSTRING(CAST(OLD.ID_USUARIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_USUARIO; converte para texto, limita a 450 caracteres e representa NULL.
       'DISPOSITIVO=' || COALESCE(SUBSTRING(CAST(OLD.DISPOSITIVO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo DISPOSITIVO; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = 'ID_CATEGORIA=' || COALESCE(SUBSTRING(CAST(NEW.ID_CATEGORIA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'NOME=' || COALESCE(SUBSTRING(CAST(NEW.NOME AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo NOME; converte para texto, limita a 450 caracteres e representa NULL.
       'STATUS=' || COALESCE(SUBSTRING(CAST(NEW.STATUS AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo STATUS; converte para texto, limita a 450 caracteres e representa NULL.
       'TIPO=' || COALESCE(SUBSTRING(CAST(NEW.TIPO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo TIPO; converte para texto, limita a 450 caracteres e representa NULL.
       'DESCRICAO=' || COALESCE(SUBSTRING(CAST(NEW.DESCRICAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DESCRICAO; converte para texto, limita a 450 caracteres e representa NULL.
       'ID_USUARIO=' || COALESCE(SUBSTRING(CAST(NEW.ID_USUARIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_USUARIO; converte para texto, limita a 450 caracteres e representa NULL.
       'DISPOSITIVO=' || COALESCE(SUBSTRING(CAST(NEW.DISPOSITIVO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo DISPOSITIVO; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NEW.ID_USUARIO; -- Usa o ID_USUARIO da propria linha quando nao veio ID no contexto.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, NULLIF(NEW.DISPOSITIVO, ''), 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''CATEGORIA'', ''ID_CATEGORIA - NOME - STATUS - TIPO - DESCRICAO - ID_USUARIO - DISPOSITIVO'', ''UPDATE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AD_CATEGORIA -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR CATEGORIA -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE DELETE -- Executa antes da exclusao, enquanto OLD ainda contem os dados da linha.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'ID_CATEGORIA=' || COALESCE(SUBSTRING(CAST(OLD.ID_CATEGORIA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'NOME=' || COALESCE(SUBSTRING(CAST(OLD.NOME AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo NOME; converte para texto, limita a 450 caracteres e representa NULL.
       'STATUS=' || COALESCE(SUBSTRING(CAST(OLD.STATUS AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo STATUS; converte para texto, limita a 450 caracteres e representa NULL.
       'TIPO=' || COALESCE(SUBSTRING(CAST(OLD.TIPO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo TIPO; converte para texto, limita a 450 caracteres e representa NULL.
       'DESCRICAO=' || COALESCE(SUBSTRING(CAST(OLD.DESCRICAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DESCRICAO; converte para texto, limita a 450 caracteres e representa NULL.
       'ID_USUARIO=' || COALESCE(SUBSTRING(CAST(OLD.ID_USUARIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_USUARIO; converte para texto, limita a 450 caracteres e representa NULL.
       'DISPOSITIVO=' || COALESCE(SUBSTRING(CAST(OLD.DISPOSITIVO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo DISPOSITIVO; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = ''; -- DELETE nao tem linha nova (NEW), entao CAMPO_NOVO fica vazio.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = OLD.ID_USUARIO; -- Usa o ID_USUARIO da propria linha quando nao veio ID no contexto.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, NULLIF(OLD.DISPOSITIVO, ''), 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''CATEGORIA'', ''ID_CATEGORIA - NOME - STATUS - TIPO - DESCRICAO - ID_USUARIO - DISPOSITIVO'', ''DELETE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AI_CONFIGURACAO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR CONFIGURACAO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE AFTER INSERT -- Executa depois de uma inclusao.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = ''; -- INSERT nao tem linha anterior (OLD), entao CAMPO_ANTIGO fica vazio.
  V_NOVO = 'ID_CONFIGURACAO=' || COALESCE(SUBSTRING(CAST(NEW.ID_CONFIGURACAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'INSTITUICAO=' || COALESCE(SUBSTRING(CAST(NEW.INSTITUICAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo INSTITUICAO; converte para texto, limita a 450 caracteres e representa NULL.
       'CNPJ=' || COALESCE(SUBSTRING(CAST(NEW.CNPJ AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo CNPJ; converte para texto, limita a 450 caracteres e representa NULL.
       'EMAIL=' || COALESCE(SUBSTRING(CAST(NEW.EMAIL AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo EMAIL; converte para texto, limita a 450 caracteres e representa NULL.
       'ENDERECO=' || COALESCE(SUBSTRING(CAST(NEW.ENDERECO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ENDERECO; converte para texto, limita a 450 caracteres e representa NULL.
       'FORMA_PAGAMENTO=' || COALESCE(SUBSTRING(CAST(NEW.FORMA_PAGAMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo FORMA_PAGAMENTO; converte para texto, limita a 450 caracteres e representa NULL.
       'UNIDADE_MEDIDA=' || COALESCE(SUBSTRING(CAST(NEW.UNIDADE_MEDIDA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo UNIDADE_MEDIDA; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NULL; -- Esta tabela nao tem ID_USUARIO na linha e o contexto nao informou o operador. -- Esta tabela nao tem coluna ID_USUARIO e o contexto nao informou um ID.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''CONFIGURACAO'', ''ID_CONFIGURACAO - INSTITUICAO - CNPJ - EMAIL - ENDERECO - FORMA_PAGAMENTO - UNIDADE_MEDIDA'', ''INSERT'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AU_CONFIGURACAO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR CONFIGURACAO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE UPDATE -- Executa antes da alteracao; OLD sao os valores atuais e NEW os valores propostos.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'ID_CONFIGURACAO=' || COALESCE(SUBSTRING(CAST(OLD.ID_CONFIGURACAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'INSTITUICAO=' || COALESCE(SUBSTRING(CAST(OLD.INSTITUICAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo INSTITUICAO; converte para texto, limita a 450 caracteres e representa NULL.
       'CNPJ=' || COALESCE(SUBSTRING(CAST(OLD.CNPJ AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo CNPJ; converte para texto, limita a 450 caracteres e representa NULL.
       'EMAIL=' || COALESCE(SUBSTRING(CAST(OLD.EMAIL AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo EMAIL; converte para texto, limita a 450 caracteres e representa NULL.
       'ENDERECO=' || COALESCE(SUBSTRING(CAST(OLD.ENDERECO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ENDERECO; converte para texto, limita a 450 caracteres e representa NULL.
       'FORMA_PAGAMENTO=' || COALESCE(SUBSTRING(CAST(OLD.FORMA_PAGAMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo FORMA_PAGAMENTO; converte para texto, limita a 450 caracteres e representa NULL.
       'UNIDADE_MEDIDA=' || COALESCE(SUBSTRING(CAST(OLD.UNIDADE_MEDIDA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo UNIDADE_MEDIDA; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = 'ID_CONFIGURACAO=' || COALESCE(SUBSTRING(CAST(NEW.ID_CONFIGURACAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'INSTITUICAO=' || COALESCE(SUBSTRING(CAST(NEW.INSTITUICAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo INSTITUICAO; converte para texto, limita a 450 caracteres e representa NULL.
       'CNPJ=' || COALESCE(SUBSTRING(CAST(NEW.CNPJ AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo CNPJ; converte para texto, limita a 450 caracteres e representa NULL.
       'EMAIL=' || COALESCE(SUBSTRING(CAST(NEW.EMAIL AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo EMAIL; converte para texto, limita a 450 caracteres e representa NULL.
       'ENDERECO=' || COALESCE(SUBSTRING(CAST(NEW.ENDERECO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ENDERECO; converte para texto, limita a 450 caracteres e representa NULL.
       'FORMA_PAGAMENTO=' || COALESCE(SUBSTRING(CAST(NEW.FORMA_PAGAMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo FORMA_PAGAMENTO; converte para texto, limita a 450 caracteres e representa NULL.
       'UNIDADE_MEDIDA=' || COALESCE(SUBSTRING(CAST(NEW.UNIDADE_MEDIDA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo UNIDADE_MEDIDA; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NULL; -- Esta tabela nao tem ID_USUARIO na linha e o contexto nao informou o operador. -- Esta tabela nao tem coluna ID_USUARIO e o contexto nao informou um ID.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''CONFIGURACAO'', ''ID_CONFIGURACAO - INSTITUICAO - CNPJ - EMAIL - ENDERECO - FORMA_PAGAMENTO - UNIDADE_MEDIDA'', ''UPDATE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AD_CONFIGURACAO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR CONFIGURACAO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE DELETE -- Executa antes da exclusao, enquanto OLD ainda contem os dados da linha.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'ID_CONFIGURACAO=' || COALESCE(SUBSTRING(CAST(OLD.ID_CONFIGURACAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'INSTITUICAO=' || COALESCE(SUBSTRING(CAST(OLD.INSTITUICAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo INSTITUICAO; converte para texto, limita a 450 caracteres e representa NULL.
       'CNPJ=' || COALESCE(SUBSTRING(CAST(OLD.CNPJ AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo CNPJ; converte para texto, limita a 450 caracteres e representa NULL.
       'EMAIL=' || COALESCE(SUBSTRING(CAST(OLD.EMAIL AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo EMAIL; converte para texto, limita a 450 caracteres e representa NULL.
       'ENDERECO=' || COALESCE(SUBSTRING(CAST(OLD.ENDERECO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ENDERECO; converte para texto, limita a 450 caracteres e representa NULL.
       'FORMA_PAGAMENTO=' || COALESCE(SUBSTRING(CAST(OLD.FORMA_PAGAMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo FORMA_PAGAMENTO; converte para texto, limita a 450 caracteres e representa NULL.
       'UNIDADE_MEDIDA=' || COALESCE(SUBSTRING(CAST(OLD.UNIDADE_MEDIDA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo UNIDADE_MEDIDA; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = ''; -- DELETE nao tem linha nova (NEW), entao CAMPO_NOVO fica vazio.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NULL; -- Esta tabela nao tem ID_USUARIO na linha e o contexto nao informou o operador. -- Esta tabela nao tem coluna ID_USUARIO e o contexto nao informou um ID.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''CONFIGURACAO'', ''ID_CONFIGURACAO - INSTITUICAO - CNPJ - EMAIL - ENDERECO - FORMA_PAGAMENTO - UNIDADE_MEDIDA'', ''DELETE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AI_DOACAO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR DOACAO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE AFTER INSERT -- Executa depois de uma inclusao.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = ''; -- INSERT nao tem linha anterior (OLD), entao CAMPO_ANTIGO fica vazio.
  V_NOVO = 'ID_DOACAO=' || COALESCE(SUBSTRING(CAST(NEW.ID_DOACAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'ID_PROJETO=' || COALESCE(SUBSTRING(CAST(NEW.ID_PROJETO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_PROJETO; converte para texto, limita a 450 caracteres e representa NULL.
       'DOADOR=' || COALESCE(SUBSTRING(CAST(NEW.DOADOR AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DOADOR; converte para texto, limita a 450 caracteres e representa NULL.
       'DIA=' || COALESCE(SUBSTRING(CAST(NEW.DIA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DIA; converte para texto, limita a 450 caracteres e representa NULL.
       'TIPO=' || COALESCE(SUBSTRING(CAST(NEW.TIPO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo TIPO; converte para texto, limita a 450 caracteres e representa NULL.
       'VALOR=' || COALESCE(SUBSTRING(CAST(NEW.VALOR AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo VALOR; converte para texto, limita a 450 caracteres e representa NULL.
       'QUANTIDADE=' || COALESCE(SUBSTRING(CAST(NEW.QUANTIDADE AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo QUANTIDADE; converte para texto, limita a 450 caracteres e representa NULL.
       'DESCRICAO=' || COALESCE(SUBSTRING(CAST(NEW.DESCRICAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo DESCRICAO; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NULL; -- Esta tabela nao tem ID_USUARIO na linha e o contexto nao informou o operador. -- Esta tabela nao tem coluna ID_USUARIO e o contexto nao informou um ID.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''DOACAO'', ''ID_DOACAO - ID_PROJETO - DOADOR - DIA - TIPO - VALOR - QUANTIDADE - DESCRICAO'', ''INSERT'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AU_DOACAO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR DOACAO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE UPDATE -- Executa antes da alteracao; OLD sao os valores atuais e NEW os valores propostos.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'ID_DOACAO=' || COALESCE(SUBSTRING(CAST(OLD.ID_DOACAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'ID_PROJETO=' || COALESCE(SUBSTRING(CAST(OLD.ID_PROJETO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_PROJETO; converte para texto, limita a 450 caracteres e representa NULL.
       'DOADOR=' || COALESCE(SUBSTRING(CAST(OLD.DOADOR AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DOADOR; converte para texto, limita a 450 caracteres e representa NULL.
       'DIA=' || COALESCE(SUBSTRING(CAST(OLD.DIA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DIA; converte para texto, limita a 450 caracteres e representa NULL.
       'TIPO=' || COALESCE(SUBSTRING(CAST(OLD.TIPO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo TIPO; converte para texto, limita a 450 caracteres e representa NULL.
       'VALOR=' || COALESCE(SUBSTRING(CAST(OLD.VALOR AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo VALOR; converte para texto, limita a 450 caracteres e representa NULL.
       'QUANTIDADE=' || COALESCE(SUBSTRING(CAST(OLD.QUANTIDADE AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo QUANTIDADE; converte para texto, limita a 450 caracteres e representa NULL.
       'DESCRICAO=' || COALESCE(SUBSTRING(CAST(OLD.DESCRICAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo DESCRICAO; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = 'ID_DOACAO=' || COALESCE(SUBSTRING(CAST(NEW.ID_DOACAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'ID_PROJETO=' || COALESCE(SUBSTRING(CAST(NEW.ID_PROJETO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_PROJETO; converte para texto, limita a 450 caracteres e representa NULL.
       'DOADOR=' || COALESCE(SUBSTRING(CAST(NEW.DOADOR AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DOADOR; converte para texto, limita a 450 caracteres e representa NULL.
       'DIA=' || COALESCE(SUBSTRING(CAST(NEW.DIA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DIA; converte para texto, limita a 450 caracteres e representa NULL.
       'TIPO=' || COALESCE(SUBSTRING(CAST(NEW.TIPO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo TIPO; converte para texto, limita a 450 caracteres e representa NULL.
       'VALOR=' || COALESCE(SUBSTRING(CAST(NEW.VALOR AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo VALOR; converte para texto, limita a 450 caracteres e representa NULL.
       'QUANTIDADE=' || COALESCE(SUBSTRING(CAST(NEW.QUANTIDADE AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo QUANTIDADE; converte para texto, limita a 450 caracteres e representa NULL.
       'DESCRICAO=' || COALESCE(SUBSTRING(CAST(NEW.DESCRICAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo DESCRICAO; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NULL; -- Esta tabela nao tem ID_USUARIO na linha e o contexto nao informou o operador. -- Esta tabela nao tem coluna ID_USUARIO e o contexto nao informou um ID.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''DOACAO'', ''ID_DOACAO - ID_PROJETO - DOADOR - DIA - TIPO - VALOR - QUANTIDADE - DESCRICAO'', ''UPDATE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AD_DOACAO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR DOACAO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE DELETE -- Executa antes da exclusao, enquanto OLD ainda contem os dados da linha.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'ID_DOACAO=' || COALESCE(SUBSTRING(CAST(OLD.ID_DOACAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'ID_PROJETO=' || COALESCE(SUBSTRING(CAST(OLD.ID_PROJETO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_PROJETO; converte para texto, limita a 450 caracteres e representa NULL.
       'DOADOR=' || COALESCE(SUBSTRING(CAST(OLD.DOADOR AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DOADOR; converte para texto, limita a 450 caracteres e representa NULL.
       'DIA=' || COALESCE(SUBSTRING(CAST(OLD.DIA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DIA; converte para texto, limita a 450 caracteres e representa NULL.
       'TIPO=' || COALESCE(SUBSTRING(CAST(OLD.TIPO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo TIPO; converte para texto, limita a 450 caracteres e representa NULL.
       'VALOR=' || COALESCE(SUBSTRING(CAST(OLD.VALOR AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo VALOR; converte para texto, limita a 450 caracteres e representa NULL.
       'QUANTIDADE=' || COALESCE(SUBSTRING(CAST(OLD.QUANTIDADE AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo QUANTIDADE; converte para texto, limita a 450 caracteres e representa NULL.
       'DESCRICAO=' || COALESCE(SUBSTRING(CAST(OLD.DESCRICAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo DESCRICAO; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = ''; -- DELETE nao tem linha nova (NEW), entao CAMPO_NOVO fica vazio.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NULL; -- Esta tabela nao tem ID_USUARIO na linha e o contexto nao informou o operador. -- Esta tabela nao tem coluna ID_USUARIO e o contexto nao informou um ID.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''DOACAO'', ''ID_DOACAO - ID_PROJETO - DOADOR - DIA - TIPO - VALOR - QUANTIDADE - DESCRICAO'', ''DELETE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AI_DOCUMENTO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR DOCUMENTO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE AFTER INSERT -- Executa depois de uma inclusao.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = ''; -- INSERT nao tem linha anterior (OLD), entao CAMPO_ANTIGO fica vazio.
  V_NOVO = 'ID_DOCUMENTO=' || COALESCE(SUBSTRING(CAST(NEW.ID_DOCUMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'ID_USUARIO=' || COALESCE(SUBSTRING(CAST(NEW.ID_USUARIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_USUARIO; converte para texto, limita a 450 caracteres e representa NULL.
       'NOME=' || COALESCE(SUBSTRING(CAST(NEW.NOME AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo NOME; converte para texto, limita a 450 caracteres e representa NULL.
       'CAMINHO=' || COALESCE(SUBSTRING(CAST(NEW.CAMINHO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo CAMINHO; converte para texto, limita a 450 caracteres e representa NULL.
       'DATA_ENVIO=' || COALESCE(SUBSTRING(CAST(NEW.DATA_ENVIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo DATA_ENVIO; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NEW.ID_USUARIO; -- Usa o ID_USUARIO da propria linha quando nao veio ID no contexto.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''DOCUMENTO'', ''ID_DOCUMENTO - ID_USUARIO - NOME - CAMINHO - DATA_ENVIO'', ''INSERT'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AU_DOCUMENTO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR DOCUMENTO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE UPDATE -- Executa antes da alteracao; OLD sao os valores atuais e NEW os valores propostos.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'ID_DOCUMENTO=' || COALESCE(SUBSTRING(CAST(OLD.ID_DOCUMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'ID_USUARIO=' || COALESCE(SUBSTRING(CAST(OLD.ID_USUARIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_USUARIO; converte para texto, limita a 450 caracteres e representa NULL.
       'NOME=' || COALESCE(SUBSTRING(CAST(OLD.NOME AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo NOME; converte para texto, limita a 450 caracteres e representa NULL.
       'CAMINHO=' || COALESCE(SUBSTRING(CAST(OLD.CAMINHO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo CAMINHO; converte para texto, limita a 450 caracteres e representa NULL.
       'DATA_ENVIO=' || COALESCE(SUBSTRING(CAST(OLD.DATA_ENVIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo DATA_ENVIO; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = 'ID_DOCUMENTO=' || COALESCE(SUBSTRING(CAST(NEW.ID_DOCUMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'ID_USUARIO=' || COALESCE(SUBSTRING(CAST(NEW.ID_USUARIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_USUARIO; converte para texto, limita a 450 caracteres e representa NULL.
       'NOME=' || COALESCE(SUBSTRING(CAST(NEW.NOME AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo NOME; converte para texto, limita a 450 caracteres e representa NULL.
       'CAMINHO=' || COALESCE(SUBSTRING(CAST(NEW.CAMINHO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo CAMINHO; converte para texto, limita a 450 caracteres e representa NULL.
       'DATA_ENVIO=' || COALESCE(SUBSTRING(CAST(NEW.DATA_ENVIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo DATA_ENVIO; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NEW.ID_USUARIO; -- Usa o ID_USUARIO da propria linha quando nao veio ID no contexto.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''DOCUMENTO'', ''ID_DOCUMENTO - ID_USUARIO - NOME - CAMINHO - DATA_ENVIO'', ''UPDATE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AD_DOCUMENTO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR DOCUMENTO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE DELETE -- Executa antes da exclusao, enquanto OLD ainda contem os dados da linha.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'ID_DOCUMENTO=' || COALESCE(SUBSTRING(CAST(OLD.ID_DOCUMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'ID_USUARIO=' || COALESCE(SUBSTRING(CAST(OLD.ID_USUARIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_USUARIO; converte para texto, limita a 450 caracteres e representa NULL.
       'NOME=' || COALESCE(SUBSTRING(CAST(OLD.NOME AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo NOME; converte para texto, limita a 450 caracteres e representa NULL.
       'CAMINHO=' || COALESCE(SUBSTRING(CAST(OLD.CAMINHO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo CAMINHO; converte para texto, limita a 450 caracteres e representa NULL.
       'DATA_ENVIO=' || COALESCE(SUBSTRING(CAST(OLD.DATA_ENVIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo DATA_ENVIO; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = ''; -- DELETE nao tem linha nova (NEW), entao CAMPO_NOVO fica vazio.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = OLD.ID_USUARIO; -- Usa o ID_USUARIO da propria linha quando nao veio ID no contexto.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''DOCUMENTO'', ''ID_DOCUMENTO - ID_USUARIO - NOME - CAMINHO - DATA_ENVIO'', ''DELETE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AI_DOCUMENTO_PROJETO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR DOCUMENTO_PROJETO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE AFTER INSERT -- Executa depois de uma inclusao.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = ''; -- INSERT nao tem linha anterior (OLD), entao CAMPO_ANTIGO fica vazio.
  V_NOVO = 'ID_DOCUMENTO=' || COALESCE(SUBSTRING(CAST(NEW.ID_DOCUMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'ID_PROJETO=' || COALESCE(SUBSTRING(CAST(NEW.ID_PROJETO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo ID_PROJETO; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NULL; -- Esta tabela nao tem ID_USUARIO na linha e o contexto nao informou o operador. -- Esta tabela nao tem coluna ID_USUARIO e o contexto nao informou um ID.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''DOCUMENTO_PROJETO'', ''ID_DOCUMENTO - ID_PROJETO'', ''INSERT'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AU_DOCUMENTO_PROJETO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR DOCUMENTO_PROJETO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE UPDATE -- Executa antes da alteracao; OLD sao os valores atuais e NEW os valores propostos.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'ID_DOCUMENTO=' || COALESCE(SUBSTRING(CAST(OLD.ID_DOCUMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'ID_PROJETO=' || COALESCE(SUBSTRING(CAST(OLD.ID_PROJETO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo ID_PROJETO; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = 'ID_DOCUMENTO=' || COALESCE(SUBSTRING(CAST(NEW.ID_DOCUMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'ID_PROJETO=' || COALESCE(SUBSTRING(CAST(NEW.ID_PROJETO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo ID_PROJETO; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NULL; -- Esta tabela nao tem ID_USUARIO na linha e o contexto nao informou o operador. -- Esta tabela nao tem coluna ID_USUARIO e o contexto nao informou um ID.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''DOCUMENTO_PROJETO'', ''ID_DOCUMENTO - ID_PROJETO'', ''UPDATE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AD_DOCUMENTO_PROJETO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR DOCUMENTO_PROJETO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE DELETE -- Executa antes da exclusao, enquanto OLD ainda contem os dados da linha.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'ID_DOCUMENTO=' || COALESCE(SUBSTRING(CAST(OLD.ID_DOCUMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'ID_PROJETO=' || COALESCE(SUBSTRING(CAST(OLD.ID_PROJETO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo ID_PROJETO; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = ''; -- DELETE nao tem linha nova (NEW), entao CAMPO_NOVO fica vazio.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NULL; -- Esta tabela nao tem ID_USUARIO na linha e o contexto nao informou o operador. -- Esta tabela nao tem coluna ID_USUARIO e o contexto nao informou um ID.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''DOCUMENTO_PROJETO'', ''ID_DOCUMENTO - ID_PROJETO'', ''DELETE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AI_EMPRESTIMO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR EMPRESTIMO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE AFTER INSERT -- Executa depois de uma inclusao.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = ''; -- INSERT nao tem linha anterior (OLD), entao CAMPO_ANTIGO fica vazio.
  V_NOVO = 'PARCELAS_PAGAS=' || COALESCE(SUBSTRING(CAST(NEW.PARCELAS_PAGAS AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'ID_EMPRESTIMO=' || COALESCE(SUBSTRING(CAST(NEW.ID_EMPRESTIMO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_EMPRESTIMO; converte para texto, limita a 450 caracteres e representa NULL.
       'ID_PROJETO=' || COALESCE(SUBSTRING(CAST(NEW.ID_PROJETO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_PROJETO; converte para texto, limita a 450 caracteres e representa NULL.
       'ID_USUARIO=' || COALESCE(SUBSTRING(CAST(NEW.ID_USUARIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_USUARIO; converte para texto, limita a 450 caracteres e representa NULL.
       'FINALIDADE=' || COALESCE(SUBSTRING(CAST(NEW.FINALIDADE AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo FINALIDADE; converte para texto, limita a 450 caracteres e representa NULL.
       'VALOR=' || COALESCE(SUBSTRING(CAST(NEW.VALOR AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo VALOR; converte para texto, limita a 450 caracteres e representa NULL.
       'DIA=' || COALESCE(SUBSTRING(CAST(NEW.DIA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DIA; converte para texto, limita a 450 caracteres e representa NULL.
       'DEVOLUCAO=' || COALESCE(SUBSTRING(CAST(NEW.DEVOLUCAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DEVOLUCAO; converte para texto, limita a 450 caracteres e representa NULL.
       'PARCELAS=' || COALESCE(SUBSTRING(CAST(NEW.PARCELAS AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo PARCELAS; converte para texto, limita a 450 caracteres e representa NULL.
       'VALIDADE=' || COALESCE(SUBSTRING(CAST(NEW.VALIDADE AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo VALIDADE; converte para texto, limita a 450 caracteres e representa NULL.
       'ORIGEM=' || COALESCE(SUBSTRING(CAST(NEW.ORIGEM AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo ORIGEM; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NEW.ID_USUARIO; -- Usa o ID_USUARIO da propria linha quando nao veio ID no contexto.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''EMPRESTIMO'', ''PARCELAS_PAGAS - ID_EMPRESTIMO - ID_PROJETO - ID_USUARIO - FINALIDADE - VALOR - DIA - DEVOLUCAO - PARCELAS - VALIDADE - ORIGEM'', ''INSERT'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AU_EMPRESTIMO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR EMPRESTIMO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE UPDATE -- Executa antes da alteracao; OLD sao os valores atuais e NEW os valores propostos.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'PARCELAS_PAGAS=' || COALESCE(SUBSTRING(CAST(OLD.PARCELAS_PAGAS AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'ID_EMPRESTIMO=' || COALESCE(SUBSTRING(CAST(OLD.ID_EMPRESTIMO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_EMPRESTIMO; converte para texto, limita a 450 caracteres e representa NULL.
       'ID_PROJETO=' || COALESCE(SUBSTRING(CAST(OLD.ID_PROJETO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_PROJETO; converte para texto, limita a 450 caracteres e representa NULL.
       'ID_USUARIO=' || COALESCE(SUBSTRING(CAST(OLD.ID_USUARIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_USUARIO; converte para texto, limita a 450 caracteres e representa NULL.
       'FINALIDADE=' || COALESCE(SUBSTRING(CAST(OLD.FINALIDADE AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo FINALIDADE; converte para texto, limita a 450 caracteres e representa NULL.
       'VALOR=' || COALESCE(SUBSTRING(CAST(OLD.VALOR AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo VALOR; converte para texto, limita a 450 caracteres e representa NULL.
       'DIA=' || COALESCE(SUBSTRING(CAST(OLD.DIA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DIA; converte para texto, limita a 450 caracteres e representa NULL.
       'DEVOLUCAO=' || COALESCE(SUBSTRING(CAST(OLD.DEVOLUCAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DEVOLUCAO; converte para texto, limita a 450 caracteres e representa NULL.
       'PARCELAS=' || COALESCE(SUBSTRING(CAST(OLD.PARCELAS AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo PARCELAS; converte para texto, limita a 450 caracteres e representa NULL.
       'VALIDADE=' || COALESCE(SUBSTRING(CAST(OLD.VALIDADE AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo VALIDADE; converte para texto, limita a 450 caracteres e representa NULL.
       'ORIGEM=' || COALESCE(SUBSTRING(CAST(OLD.ORIGEM AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo ORIGEM; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = 'PARCELAS_PAGAS=' || COALESCE(SUBSTRING(CAST(NEW.PARCELAS_PAGAS AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'ID_EMPRESTIMO=' || COALESCE(SUBSTRING(CAST(NEW.ID_EMPRESTIMO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_EMPRESTIMO; converte para texto, limita a 450 caracteres e representa NULL.
       'ID_PROJETO=' || COALESCE(SUBSTRING(CAST(NEW.ID_PROJETO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_PROJETO; converte para texto, limita a 450 caracteres e representa NULL.
       'ID_USUARIO=' || COALESCE(SUBSTRING(CAST(NEW.ID_USUARIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_USUARIO; converte para texto, limita a 450 caracteres e representa NULL.
       'FINALIDADE=' || COALESCE(SUBSTRING(CAST(NEW.FINALIDADE AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo FINALIDADE; converte para texto, limita a 450 caracteres e representa NULL.
       'VALOR=' || COALESCE(SUBSTRING(CAST(NEW.VALOR AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo VALOR; converte para texto, limita a 450 caracteres e representa NULL.
       'DIA=' || COALESCE(SUBSTRING(CAST(NEW.DIA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DIA; converte para texto, limita a 450 caracteres e representa NULL.
       'DEVOLUCAO=' || COALESCE(SUBSTRING(CAST(NEW.DEVOLUCAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DEVOLUCAO; converte para texto, limita a 450 caracteres e representa NULL.
       'PARCELAS=' || COALESCE(SUBSTRING(CAST(NEW.PARCELAS AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo PARCELAS; converte para texto, limita a 450 caracteres e representa NULL.
       'VALIDADE=' || COALESCE(SUBSTRING(CAST(NEW.VALIDADE AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo VALIDADE; converte para texto, limita a 450 caracteres e representa NULL.
       'ORIGEM=' || COALESCE(SUBSTRING(CAST(NEW.ORIGEM AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo ORIGEM; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NEW.ID_USUARIO; -- Usa o ID_USUARIO da propria linha quando nao veio ID no contexto.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''EMPRESTIMO'', ''PARCELAS_PAGAS - ID_EMPRESTIMO - ID_PROJETO - ID_USUARIO - FINALIDADE - VALOR - DIA - DEVOLUCAO - PARCELAS - VALIDADE - ORIGEM'', ''UPDATE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AD_EMPRESTIMO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR EMPRESTIMO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE DELETE -- Executa antes da exclusao, enquanto OLD ainda contem os dados da linha.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'PARCELAS_PAGAS=' || COALESCE(SUBSTRING(CAST(OLD.PARCELAS_PAGAS AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'ID_EMPRESTIMO=' || COALESCE(SUBSTRING(CAST(OLD.ID_EMPRESTIMO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_EMPRESTIMO; converte para texto, limita a 450 caracteres e representa NULL.
       'ID_PROJETO=' || COALESCE(SUBSTRING(CAST(OLD.ID_PROJETO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_PROJETO; converte para texto, limita a 450 caracteres e representa NULL.
       'ID_USUARIO=' || COALESCE(SUBSTRING(CAST(OLD.ID_USUARIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_USUARIO; converte para texto, limita a 450 caracteres e representa NULL.
       'FINALIDADE=' || COALESCE(SUBSTRING(CAST(OLD.FINALIDADE AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo FINALIDADE; converte para texto, limita a 450 caracteres e representa NULL.
       'VALOR=' || COALESCE(SUBSTRING(CAST(OLD.VALOR AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo VALOR; converte para texto, limita a 450 caracteres e representa NULL.
       'DIA=' || COALESCE(SUBSTRING(CAST(OLD.DIA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DIA; converte para texto, limita a 450 caracteres e representa NULL.
       'DEVOLUCAO=' || COALESCE(SUBSTRING(CAST(OLD.DEVOLUCAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DEVOLUCAO; converte para texto, limita a 450 caracteres e representa NULL.
       'PARCELAS=' || COALESCE(SUBSTRING(CAST(OLD.PARCELAS AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo PARCELAS; converte para texto, limita a 450 caracteres e representa NULL.
       'VALIDADE=' || COALESCE(SUBSTRING(CAST(OLD.VALIDADE AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo VALIDADE; converte para texto, limita a 450 caracteres e representa NULL.
       'ORIGEM=' || COALESCE(SUBSTRING(CAST(OLD.ORIGEM AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo ORIGEM; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = ''; -- DELETE nao tem linha nova (NEW), entao CAMPO_NOVO fica vazio.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = OLD.ID_USUARIO; -- Usa o ID_USUARIO da propria linha quando nao veio ID no contexto.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''EMPRESTIMO'', ''PARCELAS_PAGAS - ID_EMPRESTIMO - ID_PROJETO - ID_USUARIO - FINALIDADE - VALOR - DIA - DEVOLUCAO - PARCELAS - VALIDADE - ORIGEM'', ''DELETE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AI_ITEM_DOACAO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR ITEM_DOACAO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE AFTER INSERT -- Executa depois de uma inclusao.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = ''; -- INSERT nao tem linha anterior (OLD), entao CAMPO_ANTIGO fica vazio.
  V_NOVO = 'ID_DOACAO=' || COALESCE(SUBSTRING(CAST(NEW.ID_DOACAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'ID_PRODUTO=' || COALESCE(SUBSTRING(CAST(NEW.ID_PRODUTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_PRODUTO; converte para texto, limita a 450 caracteres e representa NULL.
       'ID_ITEM_DOACAO=' || COALESCE(SUBSTRING(CAST(NEW.ID_ITEM_DOACAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_ITEM_DOACAO; converte para texto, limita a 450 caracteres e representa NULL.
       'QUANTIDADE=' || COALESCE(SUBSTRING(CAST(NEW.QUANTIDADE AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo QUANTIDADE; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NULL; -- Esta tabela nao tem ID_USUARIO na linha e o contexto nao informou o operador. -- Esta tabela nao tem coluna ID_USUARIO e o contexto nao informou um ID.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''ITEM_DOACAO'', ''ID_DOACAO - ID_PRODUTO - ID_ITEM_DOACAO - QUANTIDADE'', ''INSERT'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AU_ITEM_DOACAO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR ITEM_DOACAO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE UPDATE -- Executa antes da alteracao; OLD sao os valores atuais e NEW os valores propostos.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'ID_DOACAO=' || COALESCE(SUBSTRING(CAST(OLD.ID_DOACAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'ID_PRODUTO=' || COALESCE(SUBSTRING(CAST(OLD.ID_PRODUTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_PRODUTO; converte para texto, limita a 450 caracteres e representa NULL.
       'ID_ITEM_DOACAO=' || COALESCE(SUBSTRING(CAST(OLD.ID_ITEM_DOACAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_ITEM_DOACAO; converte para texto, limita a 450 caracteres e representa NULL.
       'QUANTIDADE=' || COALESCE(SUBSTRING(CAST(OLD.QUANTIDADE AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo QUANTIDADE; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = 'ID_DOACAO=' || COALESCE(SUBSTRING(CAST(NEW.ID_DOACAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'ID_PRODUTO=' || COALESCE(SUBSTRING(CAST(NEW.ID_PRODUTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_PRODUTO; converte para texto, limita a 450 caracteres e representa NULL.
       'ID_ITEM_DOACAO=' || COALESCE(SUBSTRING(CAST(NEW.ID_ITEM_DOACAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_ITEM_DOACAO; converte para texto, limita a 450 caracteres e representa NULL.
       'QUANTIDADE=' || COALESCE(SUBSTRING(CAST(NEW.QUANTIDADE AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo QUANTIDADE; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NULL; -- Esta tabela nao tem ID_USUARIO na linha e o contexto nao informou o operador. -- Esta tabela nao tem coluna ID_USUARIO e o contexto nao informou um ID.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''ITEM_DOACAO'', ''ID_DOACAO - ID_PRODUTO - ID_ITEM_DOACAO - QUANTIDADE'', ''UPDATE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AD_ITEM_DOACAO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR ITEM_DOACAO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE DELETE -- Executa antes da exclusao, enquanto OLD ainda contem os dados da linha.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'ID_DOACAO=' || COALESCE(SUBSTRING(CAST(OLD.ID_DOACAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'ID_PRODUTO=' || COALESCE(SUBSTRING(CAST(OLD.ID_PRODUTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_PRODUTO; converte para texto, limita a 450 caracteres e representa NULL.
       'ID_ITEM_DOACAO=' || COALESCE(SUBSTRING(CAST(OLD.ID_ITEM_DOACAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_ITEM_DOACAO; converte para texto, limita a 450 caracteres e representa NULL.
       'QUANTIDADE=' || COALESCE(SUBSTRING(CAST(OLD.QUANTIDADE AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo QUANTIDADE; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = ''; -- DELETE nao tem linha nova (NEW), entao CAMPO_NOVO fica vazio.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NULL; -- Esta tabela nao tem ID_USUARIO na linha e o contexto nao informou o operador. -- Esta tabela nao tem coluna ID_USUARIO e o contexto nao informou um ID.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''ITEM_DOACAO'', ''ID_DOACAO - ID_PRODUTO - ID_ITEM_DOACAO - QUANTIDADE'', ''DELETE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AI_LIVRO_CAIXA -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR LIVRO_CAIXA -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE AFTER INSERT -- Executa depois de uma inclusao.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = ''; -- INSERT nao tem linha anterior (OLD), entao CAMPO_ANTIGO fica vazio.
  V_NOVO = 'ID_LIVRO_CAIXA=' || COALESCE(SUBSTRING(CAST(NEW.ID_LIVRO_CAIXA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'ID_CATEGORIA=' || COALESCE(SUBSTRING(CAST(NEW.ID_CATEGORIA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_CATEGORIA; converte para texto, limita a 450 caracteres e representa NULL.
       'DESCRICAO=' || COALESCE(SUBSTRING(CAST(NEW.DESCRICAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DESCRICAO; converte para texto, limita a 450 caracteres e representa NULL.
       'TIPO=' || COALESCE(SUBSTRING(CAST(NEW.TIPO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo TIPO; converte para texto, limita a 450 caracteres e representa NULL.
       'VALOR=' || COALESCE(SUBSTRING(CAST(NEW.VALOR AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo VALOR; converte para texto, limita a 450 caracteres e representa NULL.
       'DIA=' || COALESCE(SUBSTRING(CAST(NEW.DIA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DIA; converte para texto, limita a 450 caracteres e representa NULL.
       'VENCIMENTO=' || COALESCE(SUBSTRING(CAST(NEW.VENCIMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo VENCIMENTO; converte para texto, limita a 450 caracteres e representa NULL.
       'FORNECEDOR=' || COALESCE(SUBSTRING(CAST(NEW.FORNECEDOR AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo FORNECEDOR; converte para texto, limita a 450 caracteres e representa NULL.
       'STATUS=' || COALESCE(SUBSTRING(CAST(NEW.STATUS AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo STATUS; converte para texto, limita a 450 caracteres e representa NULL.
       'RECORRENCIA=' || COALESCE(SUBSTRING(CAST(NEW.RECORRENCIA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo RECORRENCIA; converte para texto, limita a 450 caracteres e representa NULL.
       'DIA_INICIO=' || COALESCE(SUBSTRING(CAST(NEW.DIA_INICIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DIA_INICIO; converte para texto, limita a 450 caracteres e representa NULL.
       'DIA_FIM=' || COALESCE(SUBSTRING(CAST(NEW.DIA_FIM AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DIA_FIM; converte para texto, limita a 450 caracteres e representa NULL.
       'CONTA=' || COALESCE(SUBSTRING(CAST(NEW.CONTA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo CONTA; converte para texto, limita a 450 caracteres e representa NULL.
       'ORIGEM=' || COALESCE(SUBSTRING(CAST(NEW.ORIGEM AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ORIGEM; converte para texto, limita a 450 caracteres e representa NULL.
       'FORMA_PAGAMENTO=' || COALESCE(SUBSTRING(CAST(NEW.FORMA_PAGAMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo FORMA_PAGAMENTO; converte para texto, limita a 450 caracteres e representa NULL.
       'OBSERVACAO=' || COALESCE(SUBSTRING(CAST(NEW.OBSERVACAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo OBSERVACAO; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NULL; -- Esta tabela nao tem ID_USUARIO na linha e o contexto nao informou o operador. -- Esta tabela nao tem coluna ID_USUARIO e o contexto nao informou um ID.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''LIVRO_CAIXA'', ''ID_LIVRO_CAIXA - ID_CATEGORIA - DESCRICAO - TIPO - VALOR - DIA - VENCIMENTO - FORNECEDOR - STATUS - RECORRENCIA - DIA_INICIO - DIA_FIM - CONTA - ORIGEM - FORMA_PAGAMENTO - OBSERVACAO'', ''INSERT'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AU_LIVRO_CAIXA -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR LIVRO_CAIXA -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE UPDATE -- Executa antes da alteracao; OLD sao os valores atuais e NEW os valores propostos.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'ID_LIVRO_CAIXA=' || COALESCE(SUBSTRING(CAST(OLD.ID_LIVRO_CAIXA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'ID_CATEGORIA=' || COALESCE(SUBSTRING(CAST(OLD.ID_CATEGORIA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_CATEGORIA; converte para texto, limita a 450 caracteres e representa NULL.
       'DESCRICAO=' || COALESCE(SUBSTRING(CAST(OLD.DESCRICAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DESCRICAO; converte para texto, limita a 450 caracteres e representa NULL.
       'TIPO=' || COALESCE(SUBSTRING(CAST(OLD.TIPO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo TIPO; converte para texto, limita a 450 caracteres e representa NULL.
       'VALOR=' || COALESCE(SUBSTRING(CAST(OLD.VALOR AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo VALOR; converte para texto, limita a 450 caracteres e representa NULL.
       'DIA=' || COALESCE(SUBSTRING(CAST(OLD.DIA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DIA; converte para texto, limita a 450 caracteres e representa NULL.
       'VENCIMENTO=' || COALESCE(SUBSTRING(CAST(OLD.VENCIMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo VENCIMENTO; converte para texto, limita a 450 caracteres e representa NULL.
       'FORNECEDOR=' || COALESCE(SUBSTRING(CAST(OLD.FORNECEDOR AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo FORNECEDOR; converte para texto, limita a 450 caracteres e representa NULL.
       'STATUS=' || COALESCE(SUBSTRING(CAST(OLD.STATUS AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo STATUS; converte para texto, limita a 450 caracteres e representa NULL.
       'RECORRENCIA=' || COALESCE(SUBSTRING(CAST(OLD.RECORRENCIA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo RECORRENCIA; converte para texto, limita a 450 caracteres e representa NULL.
       'DIA_INICIO=' || COALESCE(SUBSTRING(CAST(OLD.DIA_INICIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DIA_INICIO; converte para texto, limita a 450 caracteres e representa NULL.
       'DIA_FIM=' || COALESCE(SUBSTRING(CAST(OLD.DIA_FIM AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DIA_FIM; converte para texto, limita a 450 caracteres e representa NULL.
       'CONTA=' || COALESCE(SUBSTRING(CAST(OLD.CONTA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo CONTA; converte para texto, limita a 450 caracteres e representa NULL.
       'ORIGEM=' || COALESCE(SUBSTRING(CAST(OLD.ORIGEM AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ORIGEM; converte para texto, limita a 450 caracteres e representa NULL.
       'FORMA_PAGAMENTO=' || COALESCE(SUBSTRING(CAST(OLD.FORMA_PAGAMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo FORMA_PAGAMENTO; converte para texto, limita a 450 caracteres e representa NULL.
       'OBSERVACAO=' || COALESCE(SUBSTRING(CAST(OLD.OBSERVACAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo OBSERVACAO; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = 'ID_LIVRO_CAIXA=' || COALESCE(SUBSTRING(CAST(NEW.ID_LIVRO_CAIXA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'ID_CATEGORIA=' || COALESCE(SUBSTRING(CAST(NEW.ID_CATEGORIA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_CATEGORIA; converte para texto, limita a 450 caracteres e representa NULL.
       'DESCRICAO=' || COALESCE(SUBSTRING(CAST(NEW.DESCRICAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DESCRICAO; converte para texto, limita a 450 caracteres e representa NULL.
       'TIPO=' || COALESCE(SUBSTRING(CAST(NEW.TIPO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo TIPO; converte para texto, limita a 450 caracteres e representa NULL.
       'VALOR=' || COALESCE(SUBSTRING(CAST(NEW.VALOR AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo VALOR; converte para texto, limita a 450 caracteres e representa NULL.
       'DIA=' || COALESCE(SUBSTRING(CAST(NEW.DIA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DIA; converte para texto, limita a 450 caracteres e representa NULL.
       'VENCIMENTO=' || COALESCE(SUBSTRING(CAST(NEW.VENCIMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo VENCIMENTO; converte para texto, limita a 450 caracteres e representa NULL.
       'FORNECEDOR=' || COALESCE(SUBSTRING(CAST(NEW.FORNECEDOR AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo FORNECEDOR; converte para texto, limita a 450 caracteres e representa NULL.
       'STATUS=' || COALESCE(SUBSTRING(CAST(NEW.STATUS AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo STATUS; converte para texto, limita a 450 caracteres e representa NULL.
       'RECORRENCIA=' || COALESCE(SUBSTRING(CAST(NEW.RECORRENCIA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo RECORRENCIA; converte para texto, limita a 450 caracteres e representa NULL.
       'DIA_INICIO=' || COALESCE(SUBSTRING(CAST(NEW.DIA_INICIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DIA_INICIO; converte para texto, limita a 450 caracteres e representa NULL.
       'DIA_FIM=' || COALESCE(SUBSTRING(CAST(NEW.DIA_FIM AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DIA_FIM; converte para texto, limita a 450 caracteres e representa NULL.
       'CONTA=' || COALESCE(SUBSTRING(CAST(NEW.CONTA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo CONTA; converte para texto, limita a 450 caracteres e representa NULL.
       'ORIGEM=' || COALESCE(SUBSTRING(CAST(NEW.ORIGEM AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ORIGEM; converte para texto, limita a 450 caracteres e representa NULL.
       'FORMA_PAGAMENTO=' || COALESCE(SUBSTRING(CAST(NEW.FORMA_PAGAMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo FORMA_PAGAMENTO; converte para texto, limita a 450 caracteres e representa NULL.
       'OBSERVACAO=' || COALESCE(SUBSTRING(CAST(NEW.OBSERVACAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo OBSERVACAO; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NULL; -- Esta tabela nao tem ID_USUARIO na linha e o contexto nao informou o operador. -- Esta tabela nao tem coluna ID_USUARIO e o contexto nao informou um ID.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''LIVRO_CAIXA'', ''ID_LIVRO_CAIXA - ID_CATEGORIA - DESCRICAO - TIPO - VALOR - DIA - VENCIMENTO - FORNECEDOR - STATUS - RECORRENCIA - DIA_INICIO - DIA_FIM - CONTA - ORIGEM - FORMA_PAGAMENTO - OBSERVACAO'', ''UPDATE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AD_LIVRO_CAIXA -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR LIVRO_CAIXA -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE DELETE -- Executa antes da exclusao, enquanto OLD ainda contem os dados da linha.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'ID_LIVRO_CAIXA=' || COALESCE(SUBSTRING(CAST(OLD.ID_LIVRO_CAIXA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'ID_CATEGORIA=' || COALESCE(SUBSTRING(CAST(OLD.ID_CATEGORIA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ID_CATEGORIA; converte para texto, limita a 450 caracteres e representa NULL.
       'DESCRICAO=' || COALESCE(SUBSTRING(CAST(OLD.DESCRICAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DESCRICAO; converte para texto, limita a 450 caracteres e representa NULL.
       'TIPO=' || COALESCE(SUBSTRING(CAST(OLD.TIPO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo TIPO; converte para texto, limita a 450 caracteres e representa NULL.
       'VALOR=' || COALESCE(SUBSTRING(CAST(OLD.VALOR AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo VALOR; converte para texto, limita a 450 caracteres e representa NULL.
       'DIA=' || COALESCE(SUBSTRING(CAST(OLD.DIA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DIA; converte para texto, limita a 450 caracteres e representa NULL.
       'VENCIMENTO=' || COALESCE(SUBSTRING(CAST(OLD.VENCIMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo VENCIMENTO; converte para texto, limita a 450 caracteres e representa NULL.
       'FORNECEDOR=' || COALESCE(SUBSTRING(CAST(OLD.FORNECEDOR AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo FORNECEDOR; converte para texto, limita a 450 caracteres e representa NULL.
       'STATUS=' || COALESCE(SUBSTRING(CAST(OLD.STATUS AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo STATUS; converte para texto, limita a 450 caracteres e representa NULL.
       'RECORRENCIA=' || COALESCE(SUBSTRING(CAST(OLD.RECORRENCIA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo RECORRENCIA; converte para texto, limita a 450 caracteres e representa NULL.
       'DIA_INICIO=' || COALESCE(SUBSTRING(CAST(OLD.DIA_INICIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DIA_INICIO; converte para texto, limita a 450 caracteres e representa NULL.
       'DIA_FIM=' || COALESCE(SUBSTRING(CAST(OLD.DIA_FIM AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo DIA_FIM; converte para texto, limita a 450 caracteres e representa NULL.
       'CONTA=' || COALESCE(SUBSTRING(CAST(OLD.CONTA AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo CONTA; converte para texto, limita a 450 caracteres e representa NULL.
       'ORIGEM=' || COALESCE(SUBSTRING(CAST(OLD.ORIGEM AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ORIGEM; converte para texto, limita a 450 caracteres e representa NULL.
       'FORMA_PAGAMENTO=' || COALESCE(SUBSTRING(CAST(OLD.FORMA_PAGAMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo FORMA_PAGAMENTO; converte para texto, limita a 450 caracteres e representa NULL.
       'OBSERVACAO=' || COALESCE(SUBSTRING(CAST(OLD.OBSERVACAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo OBSERVACAO; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = ''; -- DELETE nao tem linha nova (NEW), entao CAMPO_NOVO fica vazio.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NULL; -- Esta tabela nao tem ID_USUARIO na linha e o contexto nao informou o operador. -- Esta tabela nao tem coluna ID_USUARIO e o contexto nao informou um ID.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''LIVRO_CAIXA'', ''ID_LIVRO_CAIXA - ID_CATEGORIA - DESCRICAO - TIPO - VALOR - DIA - VENCIMENTO - FORNECEDOR - STATUS - RECORRENCIA - DIA_INICIO - DIA_FIM - CONTA - ORIGEM - FORMA_PAGAMENTO - OBSERVACAO'', ''DELETE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AI_PAGAMENTO_RECORRENCIA -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR PAGAMENTO_RECORRENCIA -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE AFTER INSERT -- Executa depois de uma inclusao.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = ''; -- INSERT nao tem linha anterior (OLD), entao CAMPO_ANTIGO fica vazio.
  V_NOVO = 'ID_ORIGEM=' || COALESCE(SUBSTRING(CAST(NEW.ID_ORIGEM AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'VENCIMENTO=' || COALESCE(SUBSTRING(CAST(NEW.VENCIMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo VENCIMENTO; converte para texto, limita a 450 caracteres e representa NULL.
       'ID_PAGAMENTO=' || COALESCE(SUBSTRING(CAST(NEW.ID_PAGAMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo ID_PAGAMENTO; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NULL; -- Esta tabela nao tem ID_USUARIO na linha e o contexto nao informou o operador. -- Esta tabela nao tem coluna ID_USUARIO e o contexto nao informou um ID.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''PAGAMENTO_RECORRENCIA'', ''ID_ORIGEM - VENCIMENTO - ID_PAGAMENTO'', ''INSERT'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AU_PAGAMENTO_RECORRENCIA -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR PAGAMENTO_RECORRENCIA -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE UPDATE -- Executa antes da alteracao; OLD sao os valores atuais e NEW os valores propostos.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'ID_ORIGEM=' || COALESCE(SUBSTRING(CAST(OLD.ID_ORIGEM AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'VENCIMENTO=' || COALESCE(SUBSTRING(CAST(OLD.VENCIMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo VENCIMENTO; converte para texto, limita a 450 caracteres e representa NULL.
       'ID_PAGAMENTO=' || COALESCE(SUBSTRING(CAST(OLD.ID_PAGAMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo ID_PAGAMENTO; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = 'ID_ORIGEM=' || COALESCE(SUBSTRING(CAST(NEW.ID_ORIGEM AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'VENCIMENTO=' || COALESCE(SUBSTRING(CAST(NEW.VENCIMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo VENCIMENTO; converte para texto, limita a 450 caracteres e representa NULL.
       'ID_PAGAMENTO=' || COALESCE(SUBSTRING(CAST(NEW.ID_PAGAMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo ID_PAGAMENTO; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NULL; -- Esta tabela nao tem ID_USUARIO na linha e o contexto nao informou o operador. -- Esta tabela nao tem coluna ID_USUARIO e o contexto nao informou um ID.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''PAGAMENTO_RECORRENCIA'', ''ID_ORIGEM - VENCIMENTO - ID_PAGAMENTO'', ''UPDATE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AD_PAGAMENTO_RECORRENCIA -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR PAGAMENTO_RECORRENCIA -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE DELETE -- Executa antes da exclusao, enquanto OLD ainda contem os dados da linha.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'ID_ORIGEM=' || COALESCE(SUBSTRING(CAST(OLD.ID_ORIGEM AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'VENCIMENTO=' || COALESCE(SUBSTRING(CAST(OLD.VENCIMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo VENCIMENTO; converte para texto, limita a 450 caracteres e representa NULL.
       'ID_PAGAMENTO=' || COALESCE(SUBSTRING(CAST(OLD.ID_PAGAMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo ID_PAGAMENTO; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = ''; -- DELETE nao tem linha nova (NEW), entao CAMPO_NOVO fica vazio.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NULL; -- Esta tabela nao tem ID_USUARIO na linha e o contexto nao informou o operador. -- Esta tabela nao tem coluna ID_USUARIO e o contexto nao informou um ID.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''PAGAMENTO_RECORRENCIA'', ''ID_ORIGEM - VENCIMENTO - ID_PAGAMENTO'', ''DELETE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AI_PRODUTO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR PRODUTO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE AFTER INSERT -- Executa depois de uma inclusao.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = ''; -- INSERT nao tem linha anterior (OLD), entao CAMPO_ANTIGO fica vazio.
  V_NOVO = 'ID_PRODUTO=' || COALESCE(SUBSTRING(CAST(NEW.ID_PRODUTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'NOME=' || COALESCE(SUBSTRING(CAST(NEW.NOME AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo NOME; converte para texto, limita a 450 caracteres e representa NULL.
       'DESCRICAO=' || COALESCE(SUBSTRING(CAST(NEW.DESCRICAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo DESCRICAO; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NULL; -- Esta tabela nao tem ID_USUARIO na linha e o contexto nao informou o operador. -- Esta tabela nao tem coluna ID_USUARIO e o contexto nao informou um ID.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''PRODUTO'', ''ID_PRODUTO - NOME - DESCRICAO'', ''INSERT'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AU_PRODUTO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR PRODUTO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE UPDATE -- Executa antes da alteracao; OLD sao os valores atuais e NEW os valores propostos.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'ID_PRODUTO=' || COALESCE(SUBSTRING(CAST(OLD.ID_PRODUTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'NOME=' || COALESCE(SUBSTRING(CAST(OLD.NOME AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo NOME; converte para texto, limita a 450 caracteres e representa NULL.
       'DESCRICAO=' || COALESCE(SUBSTRING(CAST(OLD.DESCRICAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo DESCRICAO; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = 'ID_PRODUTO=' || COALESCE(SUBSTRING(CAST(NEW.ID_PRODUTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'NOME=' || COALESCE(SUBSTRING(CAST(NEW.NOME AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo NOME; converte para texto, limita a 450 caracteres e representa NULL.
       'DESCRICAO=' || COALESCE(SUBSTRING(CAST(NEW.DESCRICAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo DESCRICAO; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NULL; -- Esta tabela nao tem ID_USUARIO na linha e o contexto nao informou o operador. -- Esta tabela nao tem coluna ID_USUARIO e o contexto nao informou um ID.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''PRODUTO'', ''ID_PRODUTO - NOME - DESCRICAO'', ''UPDATE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AD_PRODUTO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR PRODUTO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE DELETE -- Executa antes da exclusao, enquanto OLD ainda contem os dados da linha.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'ID_PRODUTO=' || COALESCE(SUBSTRING(CAST(OLD.ID_PRODUTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'NOME=' || COALESCE(SUBSTRING(CAST(OLD.NOME AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo NOME; converte para texto, limita a 450 caracteres e representa NULL.
       'DESCRICAO=' || COALESCE(SUBSTRING(CAST(OLD.DESCRICAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo DESCRICAO; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = ''; -- DELETE nao tem linha nova (NEW), entao CAMPO_NOVO fica vazio.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NULL; -- Esta tabela nao tem ID_USUARIO na linha e o contexto nao informou o operador. -- Esta tabela nao tem coluna ID_USUARIO e o contexto nao informou um ID.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''PRODUTO'', ''ID_PRODUTO - NOME - DESCRICAO'', ''DELETE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AI_PROJETO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR PROJETO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE AFTER INSERT -- Executa depois de uma inclusao.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = ''; -- INSERT nao tem linha anterior (OLD), entao CAMPO_ANTIGO fica vazio.
  V_NOVO = 'ID_PROJETO=' || COALESCE(SUBSTRING(CAST(NEW.ID_PROJETO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'NOME=' || COALESCE(SUBSTRING(CAST(NEW.NOME AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo NOME; converte para texto, limita a 450 caracteres e representa NULL.
       'ORCAMENTO=' || COALESCE(SUBSTRING(CAST(NEW.ORCAMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ORCAMENTO; converte para texto, limita a 450 caracteres e representa NULL.
       'DESCRICAO=' || COALESCE(SUBSTRING(CAST(NEW.DESCRICAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo DESCRICAO; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NULL; -- Esta tabela nao tem ID_USUARIO na linha e o contexto nao informou o operador. -- Esta tabela nao tem coluna ID_USUARIO e o contexto nao informou um ID.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''PROJETO'', ''ID_PROJETO - NOME - ORCAMENTO - DESCRICAO'', ''INSERT'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AU_PROJETO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR PROJETO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE UPDATE -- Executa antes da alteracao; OLD sao os valores atuais e NEW os valores propostos.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'ID_PROJETO=' || COALESCE(SUBSTRING(CAST(OLD.ID_PROJETO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'NOME=' || COALESCE(SUBSTRING(CAST(OLD.NOME AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo NOME; converte para texto, limita a 450 caracteres e representa NULL.
       'ORCAMENTO=' || COALESCE(SUBSTRING(CAST(OLD.ORCAMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ORCAMENTO; converte para texto, limita a 450 caracteres e representa NULL.
       'DESCRICAO=' || COALESCE(SUBSTRING(CAST(OLD.DESCRICAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo DESCRICAO; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = 'ID_PROJETO=' || COALESCE(SUBSTRING(CAST(NEW.ID_PROJETO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'NOME=' || COALESCE(SUBSTRING(CAST(NEW.NOME AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo NOME; converte para texto, limita a 450 caracteres e representa NULL.
       'ORCAMENTO=' || COALESCE(SUBSTRING(CAST(NEW.ORCAMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ORCAMENTO; converte para texto, limita a 450 caracteres e representa NULL.
       'DESCRICAO=' || COALESCE(SUBSTRING(CAST(NEW.DESCRICAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo DESCRICAO; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NULL; -- Esta tabela nao tem ID_USUARIO na linha e o contexto nao informou o operador. -- Esta tabela nao tem coluna ID_USUARIO e o contexto nao informou um ID.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''PROJETO'', ''ID_PROJETO - NOME - ORCAMENTO - DESCRICAO'', ''UPDATE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AD_PROJETO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR PROJETO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE DELETE -- Executa antes da exclusao, enquanto OLD ainda contem os dados da linha.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'ID_PROJETO=' || COALESCE(SUBSTRING(CAST(OLD.ID_PROJETO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'NOME=' || COALESCE(SUBSTRING(CAST(OLD.NOME AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo NOME; converte para texto, limita a 450 caracteres e representa NULL.
       'ORCAMENTO=' || COALESCE(SUBSTRING(CAST(OLD.ORCAMENTO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo ORCAMENTO; converte para texto, limita a 450 caracteres e representa NULL.
       'DESCRICAO=' || COALESCE(SUBSTRING(CAST(OLD.DESCRICAO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo DESCRICAO; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = ''; -- DELETE nao tem linha nova (NEW), entao CAMPO_NOVO fica vazio.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NULL; -- Esta tabela nao tem ID_USUARIO na linha e o contexto nao informou o operador. -- Esta tabela nao tem coluna ID_USUARIO e o contexto nao informou um ID.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''PROJETO'', ''ID_PROJETO - NOME - ORCAMENTO - DESCRICAO'', ''DELETE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AI_USUARIO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR USUARIO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE AFTER INSERT -- Executa depois de uma inclusao.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = ''; -- INSERT nao tem linha anterior (OLD), entao CAMPO_ANTIGO fica vazio.
  V_NOVO = 'ID_USUARIO=' || COALESCE(SUBSTRING(CAST(NEW.ID_USUARIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'NOME=' || COALESCE(SUBSTRING(CAST(NEW.NOME AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo NOME; converte para texto, limita a 450 caracteres e representa NULL.
       'EMAIL=' || COALESCE(SUBSTRING(CAST(NEW.EMAIL AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo EMAIL; converte para texto, limita a 450 caracteres e representa NULL.
       'SENHA_HASH=[VALOR OMITIDO]' || '; ' ||
       'STATUS=' || COALESCE(SUBSTRING(CAST(NEW.STATUS AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo STATUS; converte para texto, limita a 450 caracteres e representa NULL.
       'TIPO=' || COALESCE(SUBSTRING(CAST(NEW.TIPO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo TIPO; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NEW.ID_USUARIO; -- Usa o ID_USUARIO da propria linha quando nao veio ID no contexto.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, NEW.EMAIL, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''USUARIO'', ''ID_USUARIO - NOME - EMAIL - SENHA_HASH - STATUS - TIPO (SENHA_HASH OMITIDO)'', ''INSERT'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AU_USUARIO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR USUARIO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE UPDATE -- Executa antes da alteracao; OLD sao os valores atuais e NEW os valores propostos.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'ID_USUARIO=' || COALESCE(SUBSTRING(CAST(OLD.ID_USUARIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'NOME=' || COALESCE(SUBSTRING(CAST(OLD.NOME AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo NOME; converte para texto, limita a 450 caracteres e representa NULL.
       'EMAIL=' || COALESCE(SUBSTRING(CAST(OLD.EMAIL AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo EMAIL; converte para texto, limita a 450 caracteres e representa NULL.
       'SENHA_HASH=[VALOR OMITIDO]' || '; ' ||
       'STATUS=' || COALESCE(SUBSTRING(CAST(OLD.STATUS AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo STATUS; converte para texto, limita a 450 caracteres e representa NULL.
       'TIPO=' || COALESCE(SUBSTRING(CAST(OLD.TIPO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo TIPO; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = 'ID_USUARIO=' || COALESCE(SUBSTRING(CAST(NEW.ID_USUARIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'NOME=' || COALESCE(SUBSTRING(CAST(NEW.NOME AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo NOME; converte para texto, limita a 450 caracteres e representa NULL.
       'EMAIL=' || COALESCE(SUBSTRING(CAST(NEW.EMAIL AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo EMAIL; converte para texto, limita a 450 caracteres e representa NULL.
       'SENHA_HASH=[VALOR OMITIDO]' || '; ' ||
       'STATUS=' || COALESCE(SUBSTRING(CAST(NEW.STATUS AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo STATUS; converte para texto, limita a 450 caracteres e representa NULL.
       'TIPO=' || COALESCE(SUBSTRING(CAST(NEW.TIPO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo TIPO; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NEW.ID_USUARIO; -- Usa o ID_USUARIO da propria linha quando nao veio ID no contexto.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, NEW.EMAIL, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''USUARIO'', ''ID_USUARIO - NOME - EMAIL - SENHA_HASH - STATUS - TIPO (SENHA_HASH OMITIDO)'', ''UPDATE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AD_USUARIO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR USUARIO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE DELETE -- Executa antes da exclusao, enquanto OLD ainda contem os dados da linha.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'ID_USUARIO=' || COALESCE(SUBSTRING(CAST(OLD.ID_USUARIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'NOME=' || COALESCE(SUBSTRING(CAST(OLD.NOME AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo NOME; converte para texto, limita a 450 caracteres e representa NULL.
       'EMAIL=' || COALESCE(SUBSTRING(CAST(OLD.EMAIL AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo EMAIL; converte para texto, limita a 450 caracteres e representa NULL.
       'SENHA_HASH=[VALOR OMITIDO]' || '; ' ||
       'STATUS=' || COALESCE(SUBSTRING(CAST(OLD.STATUS AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Acrescenta o valor do campo STATUS; converte para texto, limita a 450 caracteres e representa NULL.
       'TIPO=' || COALESCE(SUBSTRING(CAST(OLD.TIPO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo TIPO; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = ''; -- DELETE nao tem linha nova (NEW), entao CAMPO_NOVO fica vazio.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = OLD.ID_USUARIO; -- Usa o ID_USUARIO da propria linha quando nao veio ID no contexto.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, OLD.EMAIL, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''USUARIO'', ''ID_USUARIO - NOME - EMAIL - SENHA_HASH - STATUS - TIPO (SENHA_HASH OMITIDO)'', ''DELETE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AI_USUARIO_PROJETO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR USUARIO_PROJETO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE AFTER INSERT -- Executa depois de uma inclusao.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = ''; -- INSERT nao tem linha anterior (OLD), entao CAMPO_ANTIGO fica vazio.
  V_NOVO = 'ID_USUARIO=' || COALESCE(SUBSTRING(CAST(NEW.ID_USUARIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'ID_PROJETO=' || COALESCE(SUBSTRING(CAST(NEW.ID_PROJETO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo ID_PROJETO; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NEW.ID_USUARIO; -- Usa o ID_USUARIO da propria linha quando nao veio ID no contexto.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''USUARIO_PROJETO'', ''ID_USUARIO - ID_PROJETO'', ''INSERT'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AU_USUARIO_PROJETO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR USUARIO_PROJETO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE UPDATE -- Executa antes da alteracao; OLD sao os valores atuais e NEW os valores propostos.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'ID_USUARIO=' || COALESCE(SUBSTRING(CAST(OLD.ID_USUARIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'ID_PROJETO=' || COALESCE(SUBSTRING(CAST(OLD.ID_PROJETO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo ID_PROJETO; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = 'ID_USUARIO=' || COALESCE(SUBSTRING(CAST(NEW.ID_USUARIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha nova usando NEW; este texto vai para CAMPO_NOVO.
       'ID_PROJETO=' || COALESCE(SUBSTRING(CAST(NEW.ID_PROJETO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo ID_PROJETO; converte para texto, limita a 450 caracteres e representa NULL.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = NEW.ID_USUARIO; -- Usa o ID_USUARIO da propria linha quando nao veio ID no contexto.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''USUARIO_PROJETO'', ''ID_USUARIO - ID_PROJETO'', ''UPDATE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

CREATE OR ALTER TRIGGER TG_AD_USUARIO_PROJETO -- Cria o gatilho ou atualiza sua definicao se ele ja existir.
FOR USUARIO_PROJETO -- Informa em qual tabela este gatilho vai observar alteracoes.
ACTIVE BEFORE DELETE -- Executa antes da exclusao, enquanto OLD ainda contem os dados da linha.
POSITION 100 -- Define a ordem de execucao em relacao a outros gatilhos da tabela.
AS -- Abaixo ficam as variaveis e as instrucoes do gatilho.
  DECLARE VARIABLE V_ANTIGO VARCHAR(8191); -- Texto que guardara os valores da linha antes da operacao.
  DECLARE VARIABLE V_NOVO VARCHAR(8191); -- Texto que guardara os valores da linha depois da operacao.
  DECLARE VARIABLE V_ID_USUARIO INTEGER; -- Numero do usuario que realizou a operacao.
  DECLARE VARIABLE V_EMAIL VARCHAR(254); -- Email que sera gravado em HISTORICO no BANCOLOG.
  DECLARE VARIABLE V_EMAIL_BANCO VARCHAR(254); -- Email encontrado na tabela USUARIO do BANCO.
  DECLARE VARIABLE V_DISPOSITIVO VARCHAR(254); -- Nome do dispositivo que sera gravado no historico.
  DECLARE VARIABLE V_CONTEXT_ID VARCHAR(20); -- ID_USUARIO lido do contexto da conexao; chega como texto.
  DECLARE VARIABLE V_CONTEXT_DISPOSITIVO VARCHAR(254); -- Dispositivo lido do contexto da conexao.
BEGIN -- Inicio das instrucoes executadas quando ocorrer o evento.
  V_ANTIGO = 'ID_USUARIO=' || COALESCE(SUBSTRING(CAST(OLD.ID_USUARIO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>') || '; ' || -- Monta o retrato da linha anterior usando OLD; este texto vai para CAMPO_ANTIGO.
       'ID_PROJETO=' || COALESCE(SUBSTRING(CAST(OLD.ID_PROJETO AS VARCHAR(8191)) FROM 1 FOR 450), '<NULL>'); -- Acrescenta o valor do campo ID_PROJETO; converte para texto, limita a 450 caracteres e representa NULL.
  V_NOVO = ''; -- DELETE nao tem linha nova (NEW), entao CAMPO_NOVO fica vazio.

  V_CONTEXT_ID = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'ID_USUARIO'), ''); -- Le o ID do operador enviado pelo backend; se vazio, fica NULL.
  IF (V_CONTEXT_ID IS NOT NULL) THEN -- Verifica se o backend informou quem esta operando.
    V_ID_USUARIO = CAST(V_CONTEXT_ID AS INTEGER); -- CAST converte o ID que veio como texto para numero inteiro.
  ELSE
    V_ID_USUARIO = OLD.ID_USUARIO; -- Usa o ID_USUARIO da propria linha quando nao veio ID no contexto.

  V_EMAIL_BANCO = NULL; -- Limpa a variavel antes de tentar buscar o email.
  IF (V_ID_USUARIO IS NOT NULL) THEN -- So procura email se houver um ID de usuario conhecido.
    SELECT U.EMAIL -- Comeca a consulta do email na tabela USUARIO.
    FROM USUARIO U -- Consulta a tabela USUARIO com o apelido U.
    WHERE U.ID_USUARIO = :V_ID_USUARIO -- Escolhe o usuario cujo ID corresponde ao operador.
    INTO :V_EMAIL_BANCO; -- Guarda o email encontrado na variavel V_EMAIL_BANCO.

  V_EMAIL = COALESCE(V_EMAIL_BANCO, 'NAO IDENTIFICADO'); -- COALESCE escolhe o primeiro email nao NULL; se todos faltarem, grava NAO IDENTIFICADO.

  V_CONTEXT_DISPOSITIVO = NULLIF(RDB$GET_CONTEXT('USER_SESSION', 'DISPOSITIVO'), ''); -- Le do contexto o dispositivo informado pelo backend.
  V_DISPOSITIVO = COALESCE(V_CONTEXT_DISPOSITIVO, 'NAO INFORMADO'); -- Usa o dispositivo do contexto; sem ele, usa a coluna da linha se existir; senao grava NAO INFORMADO.

  -- Monta o INSERT como texto concatenado, seguindo o modelo ensinado em aula.
  EXECUTE STATEMENT
    'INSERT INTO HISTORICO ' || -- Tabela de destino, no banco BANCOLOG.
    '(EMAIL, DISPOSITIVO, DATA_HORA, TABELA, CAMPO, ACAO, CAMPO_ANTIGO, CAMPO_NOVO) ' || -- Colunas que serao preenchidas.
    'VALUES (' || -- Inicia a lista de valores do INSERT.
    '''' || COALESCE(REPLACE(V_EMAIL, '''', ''''''), 'NAO IDENTIFICADO') || '''' || ', ' || -- Email; REPLACE duplica apostrofos e COALESCE define um valor reserva.
    '''' || COALESCE(REPLACE(V_DISPOSITIVO, '''', ''''''), 'NAO INFORMADO') || '''' || ', CURRENT_TIMESTAMP, ' || -- Dispositivo e data/horario da operacao.
    '''USUARIO_PROJETO'', ''ID_USUARIO - ID_PROJETO'', ''DELETE'', ' || -- Nome da tabela, campos auditados e tipo de acao.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_ANTIGO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ', ' || -- Valores antigos; SUBSTRING limita o texto ao tamanho da coluna de log.
    '''' || COALESCE(REPLACE(SUBSTRING(COALESCE(V_NOVO, '') FROM 1 FOR 8191), '''', ''''''), '') || '''' || ')' -- Valores novos e fechamento do INSERT.
  ON EXTERNAL DATA SOURCE -- Diz que o INSERT sera enviado a outro arquivo de banco.
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB' -- Caminho de rede/local para o arquivo BANCOLOG.FDB.
  AS USER 'SYSDBA' -- Usuario do Firebird usado para conectar ao BANCOLOG.
  PASSWORD 'sysdba'; -- Senha usada para conectar ao BANCOLOG.
END^ -- Fim do gatilho; ^ encerra a definicao completa do gatilho.

-- Restaura ; como terminador normal depois de criar os gatilhos.
SET TERM ; ^
COMMIT; -- Confirma no BANCO as definicoes dos gatilhos criados acima.

