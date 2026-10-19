-- Este arquivo deve ser executado conectado ao banco BANCOLOG.FDB.
-- ALTER TABLE modifica a estrutura da tabela HISTORICO que ja existe.
-- CAMPO guarda os nomes dos campos registrados; aumenta para ate 1000 caracteres.
ALTER TABLE HISTORICO ALTER CAMPO TYPE VARCHAR(1000);
-- CAMPO_ANTIGO guarda os valores antes da alteracao ou exclusao; ate 8191 caracteres.
ALTER TABLE HISTORICO ALTER CAMPO_ANTIGO TYPE VARCHAR(8191);
-- CAMPO_NOVO guarda os valores depois da inclusao ou alteracao; ate 8191 caracteres.
ALTER TABLE HISTORICO ALTER CAMPO_NOVO TYPE VARCHAR(8191);
-- Confirma as alteracoes no banco.
COMMIT;
