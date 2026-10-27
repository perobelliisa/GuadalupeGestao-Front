import test from 'node:test';
import assert from 'node:assert/strict';
import { detalhesLog } from './detalhesLog.js';

test('compara campos e traduz o tipo sem trocar valores', () => {
    const rows = detalhesLog({ campos: 'NOME - VALOR - TIPO', antes: 'Doação - 5000.00 - 0', depois: 'Doação - 4000.00 - 1', acao: 'UPDATE', tabela: 'LIVRO_CAIXA' });
    assert.equal(rows[0].mudou, false);
    assert.equal(rows[1].mudou, true);
    assert.match(rows[1].depois, /4\.000,00/);
    assert.equal(rows[2].depois, 'Despesa');
});
test('texto legado ambíguo não é atribuído a campos errados', () => {
    assert.equal(detalhesLog({ campos: 'NOME - VALOR', antes: 'Nome - com separador - 1', depois: 'Nome - 2', acao: 'UPDATE' }), null);
});
test('inclusão e exclusão preservam ausência de registro', () => {
    assert.equal(detalhesLog({ campos: 'NOME', depois: 'Maria', acao: 'INSERT' })[0].antes, '—');
    assert.equal(detalhesLog({ campos: 'NOME', antes: 'Maria', acao: 'DELETE' })[0].depois, '—');
});
