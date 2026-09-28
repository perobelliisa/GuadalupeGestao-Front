const normalizar = (valor) => String(valor ?? "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLocaleLowerCase("pt-BR");

export function filtrarPendencias(pendencias, filtros, nomeProjeto) {
    if (filtros.inicio && filtros.fim && filtros.inicio > filtros.fim) return [];
    const termos = normalizar(filtros.busca).trim().split(/\s+/).filter(Boolean);
    return pendencias.filter((item) => {
        const texto = normalizar(`${item.descricao ?? ""} ${nomeProjeto(item.conta)} ${item.responsavel_nome} ${item.prioridade}`);
        return termos.every((termo) => texto.includes(termo))
            && (!filtros.projeto || String(item.conta ?? "sem-projeto") === filtros.projeto)
            && (!filtros.responsavel || String(item.responsavel_id ?? "sem-responsavel") === filtros.responsavel)
            && (!filtros.prioridade || item.prioridade === filtros.prioridade)
            && (!filtros.inicio || item.vencimento >= filtros.inicio)
            && (!filtros.fim || item.vencimento <= filtros.fim);
    });
}
