// Página que reúne os projetos cadastrados e os valores ligados a cada um.
import { useMemo, useState } from "react";
import { Flag, FolderKanban, Search, TrendingUp } from "lucide-react";
import Sidebar from "../../components/Sidebar.jsx";
import Header from "../../components/Header.jsx";
import "./Projetos.css";

// Converte valores da API para número, inclusive quando vierem no formato brasileiro.
function numero(valor) {
    if (typeof valor === "number") return Number.isFinite(valor) ? valor : 0;
    const texto = String(valor ?? "").trim();
    const normalizado = texto.includes(",")
        ? texto.replace(/\./g, "").replace(",", ".")
        : texto;
    const resultado = Number(normalizado);
    return Number.isFinite(resultado) ? resultado : 0;
}

// Formata os valores financeiros seguindo o padrão usado no restante do sistema.
function dinheiro(valor) {
    return new Intl.NumberFormat("pt-BR", {
        style: "currency",
        currency: "BRL"
    }).format(numero(valor));
}

// Identifica o mês sem sofrer alteração de fuso horário.
function eDoMesAtual(data, hoje = new Date()) {
    const partes = String(data ?? "").slice(0, 10).split("-").map(Number);
    return partes.length === 3
        && partes[0] === hoje.getFullYear()
        && partes[1] === hoje.getMonth() + 1;
}

// Calcula saldo e pendências de um projeto usando o campo CONTA do livro-caixa.
function resumoDoProjeto(projeto, entradas, despesas) {
    const idProjeto = String(projeto.id_projeto);
    const entradasDoProjeto = entradas.filter(
        (entrada) => String(entrada.conta ?? "0") === idProjeto
    );
    const despesasDoProjeto = despesas.filter(
        (despesa) => String(despesa.conta ?? "0") === idProjeto
    );
    const totalEntradas = entradasDoProjeto.reduce(
        (total, entrada) => total + numero(entrada.valor),
        0
    );
    const despesasPagas = despesasDoProjeto.filter((despesa) => Number(despesa.status) === 1);
    const totalDespesas = despesasPagas.reduce(
        (total, despesa) => total + numero(despesa.valor),
        0
    );
    const gastoDoMes = despesasPagas
        .filter((despesa) => eDoMesAtual(despesa.dia))
        .reduce((total, despesa) => total + numero(despesa.valor), 0);
    const pendencias = despesasDoProjeto.filter((despesa) => Number(despesa.status) !== 1).length;
    const saldo = totalEntradas - totalDespesas;
    const possuiMovimentacoes = entradasDoProjeto.length > 0 || despesasDoProjeto.length > 0;

    return {
        ...projeto,
        descricao: projeto.descricao || "Movimentações financeiras vinculadas a este projeto.",
        saldo,
        gastoDoMes,
        pendencias,
        status: pendencias > 0
            ? "Atenção"
            : possuiMovimentacoes ? "Em andamento" : "Sem movimentação",
        tipoStatus: pendencias > 0
            ? "atencao"
            : possuiMovimentacoes ? "andamento" : "estrutura"
    };
}

// Renderiza a central de projetos com busca, filtro e resumo financeiro.
export default function CentralProjetos({ usuario, entradas = [], despesas = [], projetos = [], onLogout }) {
    const [busca, setBusca] = useState("");
    const [statusSelecionado, setStatusSelecionado] = useState("");

    // Recalcula os dados somente quando os lançamentos recebidos pelo App mudam.
    const projetosComResumo = useMemo(
        () => projetos.map((projeto) => resumoDoProjeto(projeto, entradas, despesas)),
        [projetos, entradas, despesas]
    );
    const projetosFiltrados = projetosComResumo.filter((projeto) => {
        const correspondeBusca = projeto.nome.toLocaleLowerCase("pt-BR")
            .includes(busca.trim().toLocaleLowerCase("pt-BR"));
        const correspondeStatus = !statusSelecionado || projeto.tipoStatus === statusSelecionado;
        return correspondeBusca && correspondeStatus;
    });
    const saldoConsolidado = entradas.reduce((total, entrada) => total + numero(entrada.valor), 0)
        - despesas
            .filter((despesa) => Number(despesa.status) === 1)
            .reduce((total, despesa) => total + numero(despesa.valor), 0);
    const pendenciasAbertas = despesas.filter((despesa) => Number(despesa.status) !== 1).length;

    return (
        <div className="app">
            {/* Menu lateral com a Central de Projetos marcada como página atual. */}
            <Sidebar paginaAtiva="Central de Projetos" tipoUsuario={usuario.tipo} onLogout={onLogout} />

            <div className="main">
                {/* Cabeçalho padrão da aplicação. */}
                <Header usuario={usuario} />

                <main className="central-projetos-content">
                    {/* Título e explicação da finalidade da página. */}
                    <div className="central-projetos-titlebar">
                        <div>
                            <h1>Central de Projetos</h1>
                            <p>Consulte os projetos sociais e os valores movimentados em cada um.</p>
                        </div>
                    </div>

                    {/* Indicadores gerais calculados com os dados carregados pelo App. */}
                    <section className="central-projetos-summary">
                        <article>
                            <span className="central-summary-icon blue"><FolderKanban size={20} /></span>
                            <div><small>Projetos cadastrados</small><strong>{projetos.length}</strong></div>
                        </article>
                        <article>
                            <span className="central-summary-icon green"><TrendingUp size={20} /></span>
                            <div><small>Saldo consolidado</small><strong>{dinheiro(saldoConsolidado)}</strong></div>
                        </article>
                        <article>
                            <span className="central-summary-icon yellow"><Flag size={20} /></span>
                            <div><small>Pendências abertas</small><strong>{pendenciasAbertas}</strong></div>
                        </article>
                    </section>

                    {/* Ferramentas simples para encontrar um projeto rapidamente. */}
                    <section className="central-projetos-filtros">
                        <label className="central-projetos-busca">
                            <Search size={16} aria-hidden="true" />
                            <input
                                type="search"
                                value={busca}
                                onChange={(event) => setBusca(event.target.value)}
                                placeholder="Buscar projeto..."
                                aria-label="Buscar projeto"
                            />
                        </label>
                        <select
                            value={statusSelecionado}
                            onChange={(event) => setStatusSelecionado(event.target.value)}
                            aria-label="Filtrar projetos por status"
                        >
                            <option value="">Todos os status</option>
                            <option value="andamento">Em andamento</option>
                            <option value="atencao">Atenção</option>
                            <option value="estrutura">Sem movimentação</option>
                        </select>
                    </section>

                    {/* Cards dos projetos reais; não há ação de acesso individual. */}
                    <section className="central-projetos-grid">
                        {projetosFiltrados.length === 0 ? (
                            <div className="central-projetos-vazio">
                                <strong>Nenhum projeto encontrado</strong>
                                <span>Os projetos cadastrados aparecerão aqui.</span>
                            </div>
                        ) : projetosFiltrados.map((projeto, indice) => (
                            <article className={`projeto-resumo-card cor-${indice % 6}`} key={projeto.id_projeto}>
                                <div className="projeto-resumo-topo">
                                    <div className="projeto-resumo-identificacao">
                                        <span className="projeto-resumo-icone"><FolderKanban size={18} /></span>
                                        <div>
                                            <h2>{projeto.nome}</h2>
                                            <p>Responsável: Não informado</p>
                                        </div>
                                    </div>
                                    <span className={`projeto-resumo-status ${projeto.tipoStatus}`}>
                                        {projeto.status}
                                    </span>
                                </div>
                                <p className="projeto-resumo-descricao">{projeto.descricao}</p>
                                <div className="projeto-resumo-financeiro">
                                    <span>Saldo / Gasto do mês</span>
                                    <strong className={projeto.saldo < 0 ? "negativo" : ""}>
                                        {dinheiro(projeto.saldo)} / {dinheiro(projeto.gastoDoMes)}
                                    </strong>
                                </div>
                            </article>
                        ))}
                    </section>
                </main>
            </div>
        </div>
    );
}
