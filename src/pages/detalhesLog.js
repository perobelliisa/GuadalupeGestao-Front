const nomes = { DESCRICAO: 'Descrição', VALOR: 'Valor', DIA: 'Data', VENCIMENTO: 'Vencimento',
    STATUS: 'Situação', TIPO: 'Tipo', NOME: 'Nome', DOADOR: 'Doador', EMAIL: 'E-mail',
    DISPOSITIVO: 'Dispositivo', ORIGEM: 'Origem', CONTA: 'Projeto / conta', FORNECEDOR: 'Fornecedor',
    QUANTIDADE: 'Quantidade', FORMA_PAGAMENTO: 'Forma de pagamento', OBSERVACAO: 'Observação',
    RECORRENCIA: 'Recorrência', DIA_INICIO: 'Data inicial', DIA_FIM: 'Data final' };
const tipos = { LIVRO_CAIXA: { 0: 'Entrada', 1: 'Despesa' }, USUARIO: { 0: 'Administrador', 1: 'Financeiro', 2: 'Voluntário' }, DOACAO: { 0: 'Dinheiro', 1: 'Alimento', 2: 'Roupa', 3: 'Tecido', 4: 'Outro' } };

export function formatarValor(campo, valor, tabela) {
    if (valor === undefined || valor === null || valor === '') return '—';
    if (campo === 'TIPO' && tipos[tabela]?.[valor] !== undefined) return tipos[tabela][valor];
    if (campo === 'STATUS') {
        const estados = tabela === 'LIVRO_CAIXA' ? { 0: 'Pendente', 1: 'Pago' } :
            ['USUARIO', 'CATEGORIA'].includes(tabela) ? { 0: 'Ativo', 1: 'Inativo' } : null;
        if (estados?.[valor] !== undefined) return estados[valor];
    }
    if (campo === 'VALOR' && Number.isFinite(Number(valor))) return Number(valor).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
    if (/^\d{4}-\d{2}-\d{2}$/.test(valor)) return valor.split('-').reverse().join('/');
    return String(valor);
}

export function detalhesLog(item) {
    const campos = (item.campos || '').split(' - ');
    const antes = item.acao === 'INSERT' ? null : (item.antes || '').split(' - ');
    const depois = item.acao === 'DELETE' ? null : (item.depois || '').split(' - ');
    // O formato legado usa o mesmo separador dentro de textos livres. Quando
    // houver ambiguidade, preserva os dados brutos em vez de trocar os campos.
    if ((antes && antes.length !== campos.length) || (depois && depois.length !== campos.length)) return null;
    return campos.map((campo, i) => ({ campo, nome: nomes[campo] || campo.replaceAll('_', ' '),
        antes: formatarValor(campo, antes?.[i], item.tabela),
        depois: formatarValor(campo, depois?.[i], item.tabela),
        mudou: item.acao !== 'UPDATE' || antes[i] !== depois[i] }));
}
