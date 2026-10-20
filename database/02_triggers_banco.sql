-- Execute conectado ao BANCO.FDB, depois de preparar HISTORICO com 01_historico_bancolog.sql.
-- Os valores sao concatenados com o separador " - " e enviados por parametros ao BANCOLOG.
-- A concatenacao com texto permite registrar numeros e datas; valores nulos ficam vazios.
-- Sem ID_USUARIO ou DISPOSITIVO na tabela, o log usa NAO IDENTIFICADO ou NAO INFORMADO.
-- SENHA_HASH nao e copiado para o historico.
-- Os textos completos devem caber nos 8191 caracteres de CAMPO_ANTIGO e CAMPO_NOVO.

SET TERM ^ ;

CREATE OR ALTER TRIGGER TG_AI_CATEGORIA
FOR CATEGORIA
AFTER INSERT
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    SELECT U.EMAIL
    FROM USUARIO U
    WHERE U.ID_USUARIO = NEW.ID_USUARIO
    INTO :V_EMAIL;

    V_ANTIGO = '';

    V_NOVO =
        COALESCE('' || NEW.ID_CATEGORIA, '') || ' - ' ||
        COALESCE('' || NEW.NOME, '') || ' - ' ||
        COALESCE('' || NEW.STATUS, '') || ' - ' ||
        COALESCE('' || NEW.TIPO, '') || ' - ' ||
        COALESCE('' || NEW.DESCRICAO, '') || ' - ' ||
        COALESCE('' || NEW.ID_USUARIO, '') || ' - ' ||
        COALESCE('' || NEW.DISPOSITIVO, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        NEW.DISPOSITIVO,
        'CATEGORIA',
        'ID_CATEGORIA - NOME - STATUS - TIPO - DESCRICAO - ID_USUARIO - DISPOSITIVO',
        'INSERT',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AU_CATEGORIA
FOR CATEGORIA
AFTER UPDATE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    SELECT U.EMAIL
    FROM USUARIO U
    WHERE U.ID_USUARIO = NEW.ID_USUARIO
    INTO :V_EMAIL;

    V_ANTIGO =
        COALESCE('' || OLD.ID_CATEGORIA, '') || ' - ' ||
        COALESCE('' || OLD.NOME, '') || ' - ' ||
        COALESCE('' || OLD.STATUS, '') || ' - ' ||
        COALESCE('' || OLD.TIPO, '') || ' - ' ||
        COALESCE('' || OLD.DESCRICAO, '') || ' - ' ||
        COALESCE('' || OLD.ID_USUARIO, '') || ' - ' ||
        COALESCE('' || OLD.DISPOSITIVO, '');

    V_NOVO =
        COALESCE('' || NEW.ID_CATEGORIA, '') || ' - ' ||
        COALESCE('' || NEW.NOME, '') || ' - ' ||
        COALESCE('' || NEW.STATUS, '') || ' - ' ||
        COALESCE('' || NEW.TIPO, '') || ' - ' ||
        COALESCE('' || NEW.DESCRICAO, '') || ' - ' ||
        COALESCE('' || NEW.ID_USUARIO, '') || ' - ' ||
        COALESCE('' || NEW.DISPOSITIVO, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        NEW.DISPOSITIVO,
        'CATEGORIA',
        'ID_CATEGORIA - NOME - STATUS - TIPO - DESCRICAO - ID_USUARIO - DISPOSITIVO',
        'UPDATE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AD_CATEGORIA
FOR CATEGORIA
AFTER DELETE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    SELECT U.EMAIL
    FROM USUARIO U
    WHERE U.ID_USUARIO = OLD.ID_USUARIO
    INTO :V_EMAIL;

    V_ANTIGO =
        COALESCE('' || OLD.ID_CATEGORIA, '') || ' - ' ||
        COALESCE('' || OLD.NOME, '') || ' - ' ||
        COALESCE('' || OLD.STATUS, '') || ' - ' ||
        COALESCE('' || OLD.TIPO, '') || ' - ' ||
        COALESCE('' || OLD.DESCRICAO, '') || ' - ' ||
        COALESCE('' || OLD.ID_USUARIO, '') || ' - ' ||
        COALESCE('' || OLD.DISPOSITIVO, '');

    V_NOVO = '';

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        OLD.DISPOSITIVO,
        'CATEGORIA',
        'ID_CATEGORIA - NOME - STATUS - TIPO - DESCRICAO - ID_USUARIO - DISPOSITIVO',
        'DELETE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AI_CONFIGURACAO
FOR CONFIGURACAO
AFTER INSERT
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = 'NAO IDENTIFICADO';

    V_ANTIGO = '';

    V_NOVO =
        COALESCE('' || NEW.ID_CONFIGURACAO, '') || ' - ' ||
        COALESCE('' || NEW.INSTITUICAO, '') || ' - ' ||
        COALESCE('' || NEW.CNPJ, '') || ' - ' ||
        COALESCE('' || NEW.EMAIL, '') || ' - ' ||
        COALESCE('' || NEW.ENDERECO, '') || ' - ' ||
        COALESCE('' || NEW.FORMA_PAGAMENTO, '') || ' - ' ||
        COALESCE('' || NEW.UNIDADE_MEDIDA, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'CONFIGURACAO',
        'ID_CONFIGURACAO - INSTITUICAO - CNPJ - EMAIL - ENDERECO - FORMA_PAGAMENTO - UNIDADE_MEDIDA',
        'INSERT',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AU_CONFIGURACAO
FOR CONFIGURACAO
AFTER UPDATE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = 'NAO IDENTIFICADO';

    V_ANTIGO =
        COALESCE('' || OLD.ID_CONFIGURACAO, '') || ' - ' ||
        COALESCE('' || OLD.INSTITUICAO, '') || ' - ' ||
        COALESCE('' || OLD.CNPJ, '') || ' - ' ||
        COALESCE('' || OLD.EMAIL, '') || ' - ' ||
        COALESCE('' || OLD.ENDERECO, '') || ' - ' ||
        COALESCE('' || OLD.FORMA_PAGAMENTO, '') || ' - ' ||
        COALESCE('' || OLD.UNIDADE_MEDIDA, '');

    V_NOVO =
        COALESCE('' || NEW.ID_CONFIGURACAO, '') || ' - ' ||
        COALESCE('' || NEW.INSTITUICAO, '') || ' - ' ||
        COALESCE('' || NEW.CNPJ, '') || ' - ' ||
        COALESCE('' || NEW.EMAIL, '') || ' - ' ||
        COALESCE('' || NEW.ENDERECO, '') || ' - ' ||
        COALESCE('' || NEW.FORMA_PAGAMENTO, '') || ' - ' ||
        COALESCE('' || NEW.UNIDADE_MEDIDA, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'CONFIGURACAO',
        'ID_CONFIGURACAO - INSTITUICAO - CNPJ - EMAIL - ENDERECO - FORMA_PAGAMENTO - UNIDADE_MEDIDA',
        'UPDATE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AD_CONFIGURACAO
FOR CONFIGURACAO
AFTER DELETE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = 'NAO IDENTIFICADO';

    V_ANTIGO =
        COALESCE('' || OLD.ID_CONFIGURACAO, '') || ' - ' ||
        COALESCE('' || OLD.INSTITUICAO, '') || ' - ' ||
        COALESCE('' || OLD.CNPJ, '') || ' - ' ||
        COALESCE('' || OLD.EMAIL, '') || ' - ' ||
        COALESCE('' || OLD.ENDERECO, '') || ' - ' ||
        COALESCE('' || OLD.FORMA_PAGAMENTO, '') || ' - ' ||
        COALESCE('' || OLD.UNIDADE_MEDIDA, '');

    V_NOVO = '';

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'CONFIGURACAO',
        'ID_CONFIGURACAO - INSTITUICAO - CNPJ - EMAIL - ENDERECO - FORMA_PAGAMENTO - UNIDADE_MEDIDA',
        'DELETE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AI_DOACAO
FOR DOACAO
AFTER INSERT
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = 'NAO IDENTIFICADO';

    V_ANTIGO = '';

    V_NOVO =
        COALESCE('' || NEW.ID_DOACAO, '') || ' - ' ||
        COALESCE('' || NEW.ID_PROJETO, '') || ' - ' ||
        COALESCE('' || NEW.DOADOR, '') || ' - ' ||
        COALESCE('' || NEW.DIA, '') || ' - ' ||
        COALESCE('' || NEW.TIPO, '') || ' - ' ||
        COALESCE('' || NEW.VALOR, '') || ' - ' ||
        COALESCE('' || NEW.QUANTIDADE, '') || ' - ' ||
        COALESCE('' || NEW.DESCRICAO, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'DOACAO',
        'ID_DOACAO - ID_PROJETO - DOADOR - DIA - TIPO - VALOR - QUANTIDADE - DESCRICAO',
        'INSERT',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AU_DOACAO
FOR DOACAO
AFTER UPDATE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = 'NAO IDENTIFICADO';

    V_ANTIGO =
        COALESCE('' || OLD.ID_DOACAO, '') || ' - ' ||
        COALESCE('' || OLD.ID_PROJETO, '') || ' - ' ||
        COALESCE('' || OLD.DOADOR, '') || ' - ' ||
        COALESCE('' || OLD.DIA, '') || ' - ' ||
        COALESCE('' || OLD.TIPO, '') || ' - ' ||
        COALESCE('' || OLD.VALOR, '') || ' - ' ||
        COALESCE('' || OLD.QUANTIDADE, '') || ' - ' ||
        COALESCE('' || OLD.DESCRICAO, '');

    V_NOVO =
        COALESCE('' || NEW.ID_DOACAO, '') || ' - ' ||
        COALESCE('' || NEW.ID_PROJETO, '') || ' - ' ||
        COALESCE('' || NEW.DOADOR, '') || ' - ' ||
        COALESCE('' || NEW.DIA, '') || ' - ' ||
        COALESCE('' || NEW.TIPO, '') || ' - ' ||
        COALESCE('' || NEW.VALOR, '') || ' - ' ||
        COALESCE('' || NEW.QUANTIDADE, '') || ' - ' ||
        COALESCE('' || NEW.DESCRICAO, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'DOACAO',
        'ID_DOACAO - ID_PROJETO - DOADOR - DIA - TIPO - VALOR - QUANTIDADE - DESCRICAO',
        'UPDATE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AD_DOACAO
FOR DOACAO
AFTER DELETE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = 'NAO IDENTIFICADO';

    V_ANTIGO =
        COALESCE('' || OLD.ID_DOACAO, '') || ' - ' ||
        COALESCE('' || OLD.ID_PROJETO, '') || ' - ' ||
        COALESCE('' || OLD.DOADOR, '') || ' - ' ||
        COALESCE('' || OLD.DIA, '') || ' - ' ||
        COALESCE('' || OLD.TIPO, '') || ' - ' ||
        COALESCE('' || OLD.VALOR, '') || ' - ' ||
        COALESCE('' || OLD.QUANTIDADE, '') || ' - ' ||
        COALESCE('' || OLD.DESCRICAO, '');

    V_NOVO = '';

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'DOACAO',
        'ID_DOACAO - ID_PROJETO - DOADOR - DIA - TIPO - VALOR - QUANTIDADE - DESCRICAO',
        'DELETE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AI_DOCUMENTO
FOR DOCUMENTO
AFTER INSERT
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    SELECT U.EMAIL
    FROM USUARIO U
    WHERE U.ID_USUARIO = NEW.ID_USUARIO
    INTO :V_EMAIL;

    V_ANTIGO = '';

    V_NOVO =
        COALESCE('' || NEW.ID_DOCUMENTO, '') || ' - ' ||
        COALESCE('' || NEW.ID_USUARIO, '') || ' - ' ||
        COALESCE('' || NEW.NOME, '') || ' - ' ||
        COALESCE('' || NEW.CAMINHO, '') || ' - ' ||
        COALESCE('' || NEW.DATA_ENVIO, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'DOCUMENTO',
        'ID_DOCUMENTO - ID_USUARIO - NOME - CAMINHO - DATA_ENVIO',
        'INSERT',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AU_DOCUMENTO
FOR DOCUMENTO
AFTER UPDATE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    SELECT U.EMAIL
    FROM USUARIO U
    WHERE U.ID_USUARIO = NEW.ID_USUARIO
    INTO :V_EMAIL;

    V_ANTIGO =
        COALESCE('' || OLD.ID_DOCUMENTO, '') || ' - ' ||
        COALESCE('' || OLD.ID_USUARIO, '') || ' - ' ||
        COALESCE('' || OLD.NOME, '') || ' - ' ||
        COALESCE('' || OLD.CAMINHO, '') || ' - ' ||
        COALESCE('' || OLD.DATA_ENVIO, '');

    V_NOVO =
        COALESCE('' || NEW.ID_DOCUMENTO, '') || ' - ' ||
        COALESCE('' || NEW.ID_USUARIO, '') || ' - ' ||
        COALESCE('' || NEW.NOME, '') || ' - ' ||
        COALESCE('' || NEW.CAMINHO, '') || ' - ' ||
        COALESCE('' || NEW.DATA_ENVIO, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'DOCUMENTO',
        'ID_DOCUMENTO - ID_USUARIO - NOME - CAMINHO - DATA_ENVIO',
        'UPDATE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AD_DOCUMENTO
FOR DOCUMENTO
AFTER DELETE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    SELECT U.EMAIL
    FROM USUARIO U
    WHERE U.ID_USUARIO = OLD.ID_USUARIO
    INTO :V_EMAIL;

    V_ANTIGO =
        COALESCE('' || OLD.ID_DOCUMENTO, '') || ' - ' ||
        COALESCE('' || OLD.ID_USUARIO, '') || ' - ' ||
        COALESCE('' || OLD.NOME, '') || ' - ' ||
        COALESCE('' || OLD.CAMINHO, '') || ' - ' ||
        COALESCE('' || OLD.DATA_ENVIO, '');

    V_NOVO = '';

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'DOCUMENTO',
        'ID_DOCUMENTO - ID_USUARIO - NOME - CAMINHO - DATA_ENVIO',
        'DELETE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AI_DOCUMENTO_PROJETO
FOR DOCUMENTO_PROJETO
AFTER INSERT
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = 'NAO IDENTIFICADO';

    V_ANTIGO = '';

    V_NOVO =
        COALESCE('' || NEW.ID_DOCUMENTO, '') || ' - ' ||
        COALESCE('' || NEW.ID_PROJETO, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'DOCUMENTO_PROJETO',
        'ID_DOCUMENTO - ID_PROJETO',
        'INSERT',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AU_DOCUMENTO_PROJETO
FOR DOCUMENTO_PROJETO
AFTER UPDATE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = 'NAO IDENTIFICADO';

    V_ANTIGO =
        COALESCE('' || OLD.ID_DOCUMENTO, '') || ' - ' ||
        COALESCE('' || OLD.ID_PROJETO, '');

    V_NOVO =
        COALESCE('' || NEW.ID_DOCUMENTO, '') || ' - ' ||
        COALESCE('' || NEW.ID_PROJETO, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'DOCUMENTO_PROJETO',
        'ID_DOCUMENTO - ID_PROJETO',
        'UPDATE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AD_DOCUMENTO_PROJETO
FOR DOCUMENTO_PROJETO
AFTER DELETE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = 'NAO IDENTIFICADO';

    V_ANTIGO =
        COALESCE('' || OLD.ID_DOCUMENTO, '') || ' - ' ||
        COALESCE('' || OLD.ID_PROJETO, '');

    V_NOVO = '';

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'DOCUMENTO_PROJETO',
        'ID_DOCUMENTO - ID_PROJETO',
        'DELETE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AI_EMPRESTIMO
FOR EMPRESTIMO
AFTER INSERT
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    SELECT U.EMAIL
    FROM USUARIO U
    WHERE U.ID_USUARIO = NEW.ID_USUARIO
    INTO :V_EMAIL;

    V_ANTIGO = '';

    V_NOVO =
        COALESCE('' || NEW.PARCELAS_PAGAS, '') || ' - ' ||
        COALESCE('' || NEW.ID_EMPRESTIMO, '') || ' - ' ||
        COALESCE('' || NEW.ID_PROJETO, '') || ' - ' ||
        COALESCE('' || NEW.ID_USUARIO, '') || ' - ' ||
        COALESCE('' || NEW.FINALIDADE, '') || ' - ' ||
        COALESCE('' || NEW.VALOR, '') || ' - ' ||
        COALESCE('' || NEW.DIA, '') || ' - ' ||
        COALESCE('' || NEW.DEVOLUCAO, '') || ' - ' ||
        COALESCE('' || NEW.PARCELAS, '') || ' - ' ||
        COALESCE('' || NEW.VALIDADE, '') || ' - ' ||
        COALESCE('' || NEW.ORIGEM, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'EMPRESTIMO',
        'PARCELAS_PAGAS - ID_EMPRESTIMO - ID_PROJETO - ID_USUARIO - FINALIDADE - VALOR - DIA - DEVOLUCAO - PARCELAS - VALIDADE - ORIGEM',
        'INSERT',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AU_EMPRESTIMO
FOR EMPRESTIMO
AFTER UPDATE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    SELECT U.EMAIL
    FROM USUARIO U
    WHERE U.ID_USUARIO = NEW.ID_USUARIO
    INTO :V_EMAIL;

    V_ANTIGO =
        COALESCE('' || OLD.PARCELAS_PAGAS, '') || ' - ' ||
        COALESCE('' || OLD.ID_EMPRESTIMO, '') || ' - ' ||
        COALESCE('' || OLD.ID_PROJETO, '') || ' - ' ||
        COALESCE('' || OLD.ID_USUARIO, '') || ' - ' ||
        COALESCE('' || OLD.FINALIDADE, '') || ' - ' ||
        COALESCE('' || OLD.VALOR, '') || ' - ' ||
        COALESCE('' || OLD.DIA, '') || ' - ' ||
        COALESCE('' || OLD.DEVOLUCAO, '') || ' - ' ||
        COALESCE('' || OLD.PARCELAS, '') || ' - ' ||
        COALESCE('' || OLD.VALIDADE, '') || ' - ' ||
        COALESCE('' || OLD.ORIGEM, '');

    V_NOVO =
        COALESCE('' || NEW.PARCELAS_PAGAS, '') || ' - ' ||
        COALESCE('' || NEW.ID_EMPRESTIMO, '') || ' - ' ||
        COALESCE('' || NEW.ID_PROJETO, '') || ' - ' ||
        COALESCE('' || NEW.ID_USUARIO, '') || ' - ' ||
        COALESCE('' || NEW.FINALIDADE, '') || ' - ' ||
        COALESCE('' || NEW.VALOR, '') || ' - ' ||
        COALESCE('' || NEW.DIA, '') || ' - ' ||
        COALESCE('' || NEW.DEVOLUCAO, '') || ' - ' ||
        COALESCE('' || NEW.PARCELAS, '') || ' - ' ||
        COALESCE('' || NEW.VALIDADE, '') || ' - ' ||
        COALESCE('' || NEW.ORIGEM, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'EMPRESTIMO',
        'PARCELAS_PAGAS - ID_EMPRESTIMO - ID_PROJETO - ID_USUARIO - FINALIDADE - VALOR - DIA - DEVOLUCAO - PARCELAS - VALIDADE - ORIGEM',
        'UPDATE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AD_EMPRESTIMO
FOR EMPRESTIMO
AFTER DELETE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    SELECT U.EMAIL
    FROM USUARIO U
    WHERE U.ID_USUARIO = OLD.ID_USUARIO
    INTO :V_EMAIL;

    V_ANTIGO =
        COALESCE('' || OLD.PARCELAS_PAGAS, '') || ' - ' ||
        COALESCE('' || OLD.ID_EMPRESTIMO, '') || ' - ' ||
        COALESCE('' || OLD.ID_PROJETO, '') || ' - ' ||
        COALESCE('' || OLD.ID_USUARIO, '') || ' - ' ||
        COALESCE('' || OLD.FINALIDADE, '') || ' - ' ||
        COALESCE('' || OLD.VALOR, '') || ' - ' ||
        COALESCE('' || OLD.DIA, '') || ' - ' ||
        COALESCE('' || OLD.DEVOLUCAO, '') || ' - ' ||
        COALESCE('' || OLD.PARCELAS, '') || ' - ' ||
        COALESCE('' || OLD.VALIDADE, '') || ' - ' ||
        COALESCE('' || OLD.ORIGEM, '');

    V_NOVO = '';

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'EMPRESTIMO',
        'PARCELAS_PAGAS - ID_EMPRESTIMO - ID_PROJETO - ID_USUARIO - FINALIDADE - VALOR - DIA - DEVOLUCAO - PARCELAS - VALIDADE - ORIGEM',
        'DELETE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AI_ITEM_DOACAO
FOR ITEM_DOACAO
AFTER INSERT
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = 'NAO IDENTIFICADO';

    V_ANTIGO = '';

    V_NOVO =
        COALESCE('' || NEW.ID_DOACAO, '') || ' - ' ||
        COALESCE('' || NEW.ID_PRODUTO, '') || ' - ' ||
        COALESCE('' || NEW.ID_ITEM_DOACAO, '') || ' - ' ||
        COALESCE('' || NEW.QUANTIDADE, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'ITEM_DOACAO',
        'ID_DOACAO - ID_PRODUTO - ID_ITEM_DOACAO - QUANTIDADE',
        'INSERT',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AU_ITEM_DOACAO
FOR ITEM_DOACAO
AFTER UPDATE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = 'NAO IDENTIFICADO';

    V_ANTIGO =
        COALESCE('' || OLD.ID_DOACAO, '') || ' - ' ||
        COALESCE('' || OLD.ID_PRODUTO, '') || ' - ' ||
        COALESCE('' || OLD.ID_ITEM_DOACAO, '') || ' - ' ||
        COALESCE('' || OLD.QUANTIDADE, '');

    V_NOVO =
        COALESCE('' || NEW.ID_DOACAO, '') || ' - ' ||
        COALESCE('' || NEW.ID_PRODUTO, '') || ' - ' ||
        COALESCE('' || NEW.ID_ITEM_DOACAO, '') || ' - ' ||
        COALESCE('' || NEW.QUANTIDADE, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'ITEM_DOACAO',
        'ID_DOACAO - ID_PRODUTO - ID_ITEM_DOACAO - QUANTIDADE',
        'UPDATE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AD_ITEM_DOACAO
FOR ITEM_DOACAO
AFTER DELETE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = 'NAO IDENTIFICADO';

    V_ANTIGO =
        COALESCE('' || OLD.ID_DOACAO, '') || ' - ' ||
        COALESCE('' || OLD.ID_PRODUTO, '') || ' - ' ||
        COALESCE('' || OLD.ID_ITEM_DOACAO, '') || ' - ' ||
        COALESCE('' || OLD.QUANTIDADE, '');

    V_NOVO = '';

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'ITEM_DOACAO',
        'ID_DOACAO - ID_PRODUTO - ID_ITEM_DOACAO - QUANTIDADE',
        'DELETE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AI_LIVRO_CAIXA
FOR LIVRO_CAIXA
AFTER INSERT
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = 'NAO IDENTIFICADO';

    V_ANTIGO = '';

    V_NOVO =
        COALESCE('' || NEW.ID_LIVRO_CAIXA, '') || ' - ' ||
        COALESCE('' || NEW.ID_CATEGORIA, '') || ' - ' ||
        COALESCE('' || NEW.DESCRICAO, '') || ' - ' ||
        COALESCE('' || NEW.TIPO, '') || ' - ' ||
        COALESCE('' || NEW.VALOR, '') || ' - ' ||
        COALESCE('' || NEW.DIA, '') || ' - ' ||
        COALESCE('' || NEW.VENCIMENTO, '') || ' - ' ||
        COALESCE('' || NEW.FORNECEDOR, '') || ' - ' ||
        COALESCE('' || NEW.STATUS, '') || ' - ' ||
        COALESCE('' || NEW.RECORRENCIA, '') || ' - ' ||
        COALESCE('' || NEW.DIA_INICIO, '') || ' - ' ||
        COALESCE('' || NEW.DIA_FIM, '') || ' - ' ||
        COALESCE('' || NEW.CONTA, '') || ' - ' ||
        COALESCE('' || NEW.ORIGEM, '') || ' - ' ||
        COALESCE('' || NEW.FORMA_PAGAMENTO, '') || ' - ' ||
        COALESCE('' || NEW.OBSERVACAO, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'LIVRO_CAIXA',
        'ID_LIVRO_CAIXA - ID_CATEGORIA - DESCRICAO - TIPO - VALOR - DIA - VENCIMENTO - FORNECEDOR - STATUS - RECORRENCIA - DIA_INICIO - DIA_FIM - CONTA - ORIGEM - FORMA_PAGAMENTO - OBSERVACAO',
        'INSERT',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AU_LIVRO_CAIXA
FOR LIVRO_CAIXA
AFTER UPDATE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = 'NAO IDENTIFICADO';

    V_ANTIGO =
        COALESCE('' || OLD.ID_LIVRO_CAIXA, '') || ' - ' ||
        COALESCE('' || OLD.ID_CATEGORIA, '') || ' - ' ||
        COALESCE('' || OLD.DESCRICAO, '') || ' - ' ||
        COALESCE('' || OLD.TIPO, '') || ' - ' ||
        COALESCE('' || OLD.VALOR, '') || ' - ' ||
        COALESCE('' || OLD.DIA, '') || ' - ' ||
        COALESCE('' || OLD.VENCIMENTO, '') || ' - ' ||
        COALESCE('' || OLD.FORNECEDOR, '') || ' - ' ||
        COALESCE('' || OLD.STATUS, '') || ' - ' ||
        COALESCE('' || OLD.RECORRENCIA, '') || ' - ' ||
        COALESCE('' || OLD.DIA_INICIO, '') || ' - ' ||
        COALESCE('' || OLD.DIA_FIM, '') || ' - ' ||
        COALESCE('' || OLD.CONTA, '') || ' - ' ||
        COALESCE('' || OLD.ORIGEM, '') || ' - ' ||
        COALESCE('' || OLD.FORMA_PAGAMENTO, '') || ' - ' ||
        COALESCE('' || OLD.OBSERVACAO, '');

    V_NOVO =
        COALESCE('' || NEW.ID_LIVRO_CAIXA, '') || ' - ' ||
        COALESCE('' || NEW.ID_CATEGORIA, '') || ' - ' ||
        COALESCE('' || NEW.DESCRICAO, '') || ' - ' ||
        COALESCE('' || NEW.TIPO, '') || ' - ' ||
        COALESCE('' || NEW.VALOR, '') || ' - ' ||
        COALESCE('' || NEW.DIA, '') || ' - ' ||
        COALESCE('' || NEW.VENCIMENTO, '') || ' - ' ||
        COALESCE('' || NEW.FORNECEDOR, '') || ' - ' ||
        COALESCE('' || NEW.STATUS, '') || ' - ' ||
        COALESCE('' || NEW.RECORRENCIA, '') || ' - ' ||
        COALESCE('' || NEW.DIA_INICIO, '') || ' - ' ||
        COALESCE('' || NEW.DIA_FIM, '') || ' - ' ||
        COALESCE('' || NEW.CONTA, '') || ' - ' ||
        COALESCE('' || NEW.ORIGEM, '') || ' - ' ||
        COALESCE('' || NEW.FORMA_PAGAMENTO, '') || ' - ' ||
        COALESCE('' || NEW.OBSERVACAO, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'LIVRO_CAIXA',
        'ID_LIVRO_CAIXA - ID_CATEGORIA - DESCRICAO - TIPO - VALOR - DIA - VENCIMENTO - FORNECEDOR - STATUS - RECORRENCIA - DIA_INICIO - DIA_FIM - CONTA - ORIGEM - FORMA_PAGAMENTO - OBSERVACAO',
        'UPDATE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AD_LIVRO_CAIXA
FOR LIVRO_CAIXA
AFTER DELETE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = 'NAO IDENTIFICADO';

    V_ANTIGO =
        COALESCE('' || OLD.ID_LIVRO_CAIXA, '') || ' - ' ||
        COALESCE('' || OLD.ID_CATEGORIA, '') || ' - ' ||
        COALESCE('' || OLD.DESCRICAO, '') || ' - ' ||
        COALESCE('' || OLD.TIPO, '') || ' - ' ||
        COALESCE('' || OLD.VALOR, '') || ' - ' ||
        COALESCE('' || OLD.DIA, '') || ' - ' ||
        COALESCE('' || OLD.VENCIMENTO, '') || ' - ' ||
        COALESCE('' || OLD.FORNECEDOR, '') || ' - ' ||
        COALESCE('' || OLD.STATUS, '') || ' - ' ||
        COALESCE('' || OLD.RECORRENCIA, '') || ' - ' ||
        COALESCE('' || OLD.DIA_INICIO, '') || ' - ' ||
        COALESCE('' || OLD.DIA_FIM, '') || ' - ' ||
        COALESCE('' || OLD.CONTA, '') || ' - ' ||
        COALESCE('' || OLD.ORIGEM, '') || ' - ' ||
        COALESCE('' || OLD.FORMA_PAGAMENTO, '') || ' - ' ||
        COALESCE('' || OLD.OBSERVACAO, '');

    V_NOVO = '';

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'LIVRO_CAIXA',
        'ID_LIVRO_CAIXA - ID_CATEGORIA - DESCRICAO - TIPO - VALOR - DIA - VENCIMENTO - FORNECEDOR - STATUS - RECORRENCIA - DIA_INICIO - DIA_FIM - CONTA - ORIGEM - FORMA_PAGAMENTO - OBSERVACAO',
        'DELETE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AI_PAGAMENTO_RECORRENCIA
FOR PAGAMENTO_RECORRENCIA
AFTER INSERT
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = 'NAO IDENTIFICADO';

    V_ANTIGO = '';

    V_NOVO =
        COALESCE('' || NEW.ID_ORIGEM, '') || ' - ' ||
        COALESCE('' || NEW.VENCIMENTO, '') || ' - ' ||
        COALESCE('' || NEW.ID_PAGAMENTO, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'PAGAMENTO_RECORRENCIA',
        'ID_ORIGEM - VENCIMENTO - ID_PAGAMENTO',
        'INSERT',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AU_PAGAMENTO_RECORRENCIA
FOR PAGAMENTO_RECORRENCIA
AFTER UPDATE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = 'NAO IDENTIFICADO';

    V_ANTIGO =
        COALESCE('' || OLD.ID_ORIGEM, '') || ' - ' ||
        COALESCE('' || OLD.VENCIMENTO, '') || ' - ' ||
        COALESCE('' || OLD.ID_PAGAMENTO, '');

    V_NOVO =
        COALESCE('' || NEW.ID_ORIGEM, '') || ' - ' ||
        COALESCE('' || NEW.VENCIMENTO, '') || ' - ' ||
        COALESCE('' || NEW.ID_PAGAMENTO, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'PAGAMENTO_RECORRENCIA',
        'ID_ORIGEM - VENCIMENTO - ID_PAGAMENTO',
        'UPDATE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AD_PAGAMENTO_RECORRENCIA
FOR PAGAMENTO_RECORRENCIA
AFTER DELETE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = 'NAO IDENTIFICADO';

    V_ANTIGO =
        COALESCE('' || OLD.ID_ORIGEM, '') || ' - ' ||
        COALESCE('' || OLD.VENCIMENTO, '') || ' - ' ||
        COALESCE('' || OLD.ID_PAGAMENTO, '');

    V_NOVO = '';

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'PAGAMENTO_RECORRENCIA',
        'ID_ORIGEM - VENCIMENTO - ID_PAGAMENTO',
        'DELETE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AI_PRODUTO
FOR PRODUTO
AFTER INSERT
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = 'NAO IDENTIFICADO';

    V_ANTIGO = '';

    V_NOVO =
        COALESCE('' || NEW.ID_PRODUTO, '') || ' - ' ||
        COALESCE('' || NEW.NOME, '') || ' - ' ||
        COALESCE('' || NEW.DESCRICAO, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'PRODUTO',
        'ID_PRODUTO - NOME - DESCRICAO',
        'INSERT',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AU_PRODUTO
FOR PRODUTO
AFTER UPDATE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = 'NAO IDENTIFICADO';

    V_ANTIGO =
        COALESCE('' || OLD.ID_PRODUTO, '') || ' - ' ||
        COALESCE('' || OLD.NOME, '') || ' - ' ||
        COALESCE('' || OLD.DESCRICAO, '');

    V_NOVO =
        COALESCE('' || NEW.ID_PRODUTO, '') || ' - ' ||
        COALESCE('' || NEW.NOME, '') || ' - ' ||
        COALESCE('' || NEW.DESCRICAO, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'PRODUTO',
        'ID_PRODUTO - NOME - DESCRICAO',
        'UPDATE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AD_PRODUTO
FOR PRODUTO
AFTER DELETE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = 'NAO IDENTIFICADO';

    V_ANTIGO =
        COALESCE('' || OLD.ID_PRODUTO, '') || ' - ' ||
        COALESCE('' || OLD.NOME, '') || ' - ' ||
        COALESCE('' || OLD.DESCRICAO, '');

    V_NOVO = '';

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'PRODUTO',
        'ID_PRODUTO - NOME - DESCRICAO',
        'DELETE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AI_PROJETO
FOR PROJETO
AFTER INSERT
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = 'NAO IDENTIFICADO';

    V_ANTIGO = '';

    V_NOVO =
        COALESCE('' || NEW.ID_PROJETO, '') || ' - ' ||
        COALESCE('' || NEW.NOME, '') || ' - ' ||
        COALESCE('' || NEW.ORCAMENTO, '') || ' - ' ||
        COALESCE('' || NEW.DESCRICAO, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'PROJETO',
        'ID_PROJETO - NOME - ORCAMENTO - DESCRICAO',
        'INSERT',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AU_PROJETO
FOR PROJETO
AFTER UPDATE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = 'NAO IDENTIFICADO';

    V_ANTIGO =
        COALESCE('' || OLD.ID_PROJETO, '') || ' - ' ||
        COALESCE('' || OLD.NOME, '') || ' - ' ||
        COALESCE('' || OLD.ORCAMENTO, '') || ' - ' ||
        COALESCE('' || OLD.DESCRICAO, '');

    V_NOVO =
        COALESCE('' || NEW.ID_PROJETO, '') || ' - ' ||
        COALESCE('' || NEW.NOME, '') || ' - ' ||
        COALESCE('' || NEW.ORCAMENTO, '') || ' - ' ||
        COALESCE('' || NEW.DESCRICAO, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'PROJETO',
        'ID_PROJETO - NOME - ORCAMENTO - DESCRICAO',
        'UPDATE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AD_PROJETO
FOR PROJETO
AFTER DELETE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = 'NAO IDENTIFICADO';

    V_ANTIGO =
        COALESCE('' || OLD.ID_PROJETO, '') || ' - ' ||
        COALESCE('' || OLD.NOME, '') || ' - ' ||
        COALESCE('' || OLD.ORCAMENTO, '') || ' - ' ||
        COALESCE('' || OLD.DESCRICAO, '');

    V_NOVO = '';

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'PROJETO',
        'ID_PROJETO - NOME - ORCAMENTO - DESCRICAO',
        'DELETE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AI_USUARIO
FOR USUARIO
AFTER INSERT
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = NEW.EMAIL;

    V_ANTIGO = '';

    V_NOVO =
        COALESCE('' || NEW.ID_USUARIO, '') || ' - ' ||
        COALESCE('' || NEW.NOME, '') || ' - ' ||
        COALESCE('' || NEW.EMAIL, '') || ' - ' ||
        COALESCE('' || NEW.STATUS, '') || ' - ' ||
        COALESCE('' || NEW.TIPO, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'USUARIO',
        'ID_USUARIO - NOME - EMAIL - STATUS - TIPO',
        'INSERT',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AU_USUARIO
FOR USUARIO
AFTER UPDATE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = NEW.EMAIL;

    V_ANTIGO =
        COALESCE('' || OLD.ID_USUARIO, '') || ' - ' ||
        COALESCE('' || OLD.NOME, '') || ' - ' ||
        COALESCE('' || OLD.EMAIL, '') || ' - ' ||
        COALESCE('' || OLD.STATUS, '') || ' - ' ||
        COALESCE('' || OLD.TIPO, '');

    V_NOVO =
        COALESCE('' || NEW.ID_USUARIO, '') || ' - ' ||
        COALESCE('' || NEW.NOME, '') || ' - ' ||
        COALESCE('' || NEW.EMAIL, '') || ' - ' ||
        COALESCE('' || NEW.STATUS, '') || ' - ' ||
        COALESCE('' || NEW.TIPO, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'USUARIO',
        'ID_USUARIO - NOME - EMAIL - STATUS - TIPO',
        'UPDATE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AD_USUARIO
FOR USUARIO
AFTER DELETE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    V_EMAIL = OLD.EMAIL;

    V_ANTIGO =
        COALESCE('' || OLD.ID_USUARIO, '') || ' - ' ||
        COALESCE('' || OLD.NOME, '') || ' - ' ||
        COALESCE('' || OLD.EMAIL, '') || ' - ' ||
        COALESCE('' || OLD.STATUS, '') || ' - ' ||
        COALESCE('' || OLD.TIPO, '');

    V_NOVO = '';

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'USUARIO',
        'ID_USUARIO - NOME - EMAIL - STATUS - TIPO',
        'DELETE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AI_USUARIO_PROJETO
FOR USUARIO_PROJETO
AFTER INSERT
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    SELECT U.EMAIL
    FROM USUARIO U
    WHERE U.ID_USUARIO = NEW.ID_USUARIO
    INTO :V_EMAIL;

    V_ANTIGO = '';

    V_NOVO =
        COALESCE('' || NEW.ID_USUARIO, '') || ' - ' ||
        COALESCE('' || NEW.ID_PROJETO, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'USUARIO_PROJETO',
        'ID_USUARIO - ID_PROJETO',
        'INSERT',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AU_USUARIO_PROJETO
FOR USUARIO_PROJETO
AFTER UPDATE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    SELECT U.EMAIL
    FROM USUARIO U
    WHERE U.ID_USUARIO = NEW.ID_USUARIO
    INTO :V_EMAIL;

    V_ANTIGO =
        COALESCE('' || OLD.ID_USUARIO, '') || ' - ' ||
        COALESCE('' || OLD.ID_PROJETO, '');

    V_NOVO =
        COALESCE('' || NEW.ID_USUARIO, '') || ' - ' ||
        COALESCE('' || NEW.ID_PROJETO, '');

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'USUARIO_PROJETO',
        'ID_USUARIO - ID_PROJETO',
        'UPDATE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

CREATE OR ALTER TRIGGER TG_AD_USUARIO_PROJETO
FOR USUARIO_PROJETO
AFTER DELETE
AS
DECLARE VARIABLE V_EMAIL VARCHAR(254);
DECLARE VARIABLE V_ANTIGO VARCHAR(8191);
DECLARE VARIABLE V_NOVO VARCHAR(8191);
BEGIN

    SELECT U.EMAIL
    FROM USUARIO U
    WHERE U.ID_USUARIO = OLD.ID_USUARIO
    INTO :V_EMAIL;

    V_ANTIGO =
        COALESCE('' || OLD.ID_USUARIO, '') || ' - ' ||
        COALESCE('' || OLD.ID_PROJETO, '');

    V_NOVO = '';

    EXECUTE STATEMENT
    (
        'INSERT INTO HISTORICO
        (
            EMAIL,
            DISPOSITIVO,
            DATA_HORA,
            TABELA,
            CAMPO,
            ACAO,
            CAMPO_ANTIGO,
            CAMPO_NOVO
        )
        VALUES (?, ?, CURRENT_TIMESTAMP,
                ?, ?, ?, ?, ?)'
    )
    (
        :V_EMAIL,
        'NAO INFORMADO',
        'USUARIO_PROJETO',
        'ID_USUARIO - ID_PROJETO',
        'DELETE',
        :V_ANTIGO,
        :V_NOVO
    )
    ON EXTERNAL DATA SOURCE
    'localhost:C:\Users\Aluno\Desktop\GuadalupeGestao-Back\BANCOLOG.FDB'
    AS USER 'SYSDBA'
    PASSWORD 'sysdba';
END^

SET TERM ; ^
COMMIT;
