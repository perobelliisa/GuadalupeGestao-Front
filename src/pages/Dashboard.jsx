
// Importa os componentes que formam cada região da dashboard.
// Esta página é o painel inicial mostrado após o login.
import Sidebar from "../../components/Sidebar.jsx";
import Header from "../../components/Header.jsx";
import Cards from "../../components/Card.jsx";
import Grafico from "../../components/Grafico.jsx";
import Projetos from "../../components/Tabela.jsx";
import { useLocation } from "react-router-dom";
// Importa os estilos exclusivos da estrutura da página.
import "./Dashboard.css";

// Converte valores vindos do banco para número, aceitando também o formato brasileiro.
function numero(valor) {
    if (typeof valor === "number") return Number.isFinite(valor) ? valor : 0;

    const texto = String(valor ?? "").trim();
    if (!texto) return 0;

    const normalizado = texto.includes(",")
        ? texto.replace(/\./g, "").replace(",", ".")
        : texto;

    const resultado = Number(normalizado);
    return Number.isFinite(resultado) ? resultado : 0;
}

// Apresenta os valores financeiros sempre no padrão usado no sistema.
function dinheiro(valor) {
    return new Intl.NumberFormat("pt-BR", {
        style: "currency",
        currency: "BRL"
    }).format(numero(valor));
}

// Lê uma data sem deslocá-la por causa do fuso horário do navegador.
function partesDaData(valor) {
    const texto = String(valor ?? "").slice(0, 10);
    const partes = texto.split("-").map(Number);

    if (partes.length !== 3 || partes.some((parte) => !Number.isInteger(parte))) {
        return null;
    }

    const [ano, mes, dia] = partes;
    if (!ano || mes < 1 || mes > 12 || dia < 1 || dia > 31) return null;

    return { ano, mes, dia };
}

// Verifica se um lançamento pertence ao mês atual.
function eDoMesAtual(data, hoje = new Date()) {
    const partes = partesDaData(data);
    return Boolean(
        partes
        && partes.ano === hoje.getFullYear()
        && partes.mes === hoje.getMonth() + 1
    );
}

// Soma apenas despesas pagas, pois despesas pendentes ainda não saíram do caixa.
function somarDespesasPagas(despesas, filtro = () => true) {
    return despesas.reduce((total, despesa) => {
        if (Number(despesa.status) !== 1 || !filtro(despesa)) return total;
        return total + numero(despesa.valor);
    }, 0);
}

// Agrupa entradas e despesas pagas por mês para alimentar o gráfico.
function montarFluxo(entradas, despesas) {
    const meses = new Map();
    const registrar = (movimento, campo) => {
        const partes = partesDaData(movimento.dia);
        if (!partes) return;

        const chave = `${partes.ano}-${String(partes.mes).padStart(2, "0")}`;
        const atual = meses.get(chave) || {
            chave,
            ano: partes.ano,
            mesNumero: partes.mes,
            entradas: 0,
            despesas: 0
        };

        atual[campo] += numero(movimento.valor);
        meses.set(chave, atual);
    };

    entradas.forEach((entrada) => registrar(entrada, "entradas"));
    despesas.filter((despesa) => Number(despesa.status) === 1)
        .forEach((despesa) => registrar(despesa, "despesas"));

    return Array.from(meses.values())
        .sort((a, b) => a.chave.localeCompare(b.chave))
        .map((item) => ({
            mes: new Date(item.ano, item.mesNumero - 1, 1)
                .toLocaleDateString("pt-BR", { month: "short", year: "2-digit" })
                .replace(".", ""),
            entradas: item.entradas,
            despesas: item.despesas
        }));
}

// Monta a situação de cada projeto usando as movimentações ligadas pelo campo CONTA.
function montarSituacaoProjetos(projetos, entradas, despesas) {
    const cores = ["blue", "green", "yellow", "red", "purple", "orange"];

    return projetos.map((projeto, indice) => {
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
        const totalDespesas = somarDespesasPagas(despesasDoProjeto);
        const gastoDoMes = somarDespesasPagas(
            despesasDoProjeto,
            (despesa) => eDoMesAtual(despesa.dia)
        );
        const saldo = totalEntradas - totalDespesas;
        const possuiMovimentacoes = entradasDoProjeto.length > 0 || despesasDoProjeto.length > 0;

        return {
            id: projeto.id_projeto,
            nome: projeto.nome,
            cor: cores[indice % cores.length],
            responsavel: "Não informado",
            status: possuiMovimentacoes ? "Em acompanhamento" : "Sem movimentação",
            tipoStatus: possuiMovimentacoes ? "andamento" : "estrutura",
            saldo: `${dinheiro(saldo)} / ${dinheiro(gastoDoMes)}`,
            saldoNegativo: saldo < 0,
            pendencia: "—"
        };
    });
}

// Calcula todos os indicadores a partir das listas já carregadas pelo App.
function montarDadosDashboard({ entradas, despesas, doacoes, projetos }) {
    const saldoGeral = entradas.reduce((total, entrada) => total + numero(entrada.valor), 0)
        - somarDespesasPagas(despesas);
    const entradasMes = entradas.reduce(
        (total, entrada) => eDoMesAtual(entrada.dia) ? total + numero(entrada.valor) : total,
        0
    );
    const despesasMes = somarDespesasPagas(
        despesas,
        (despesa) => eDoMesAtual(despesa.dia)
    );

    return {
        saldoGeral: dinheiro(saldoGeral),
        entradasMes: dinheiro(entradasMes),
        despesasMes: dinheiro(despesasMes),
        doacoesRecebidas: `${doacoes.length} ${doacoes.length === 1 ? "registro" : "registros"}`,
        fluxo: montarFluxo(entradas, despesas),
        projetos: montarSituacaoProjetos(projetos, entradas, despesas)
    };
}

// Recebe as listas reais carregadas pelo App e apresenta o resumo da gestão.
export default function Dashboard({ usuario, entradas = [], despesas = [], doacoes = [], projetos = [], onLogout }) {
    const location = useLocation();
    const mensagem = location.state?.mensagem;
    const dados = montarDadosDashboard({ entradas, despesas, doacoes, projetos });

    // Monta a estrutura visual da dashboard.
    return (
        // Contêiner principal que posiciona sidebar e conteúdo lado a lado.
        <div className="app">

            {/* Menu lateral da aplicação. */}
            <Sidebar tipoUsuario={usuario.tipo} onLogout={onLogout} />

            {/* Área principal que contém cabeçalho e conteúdo. */}
            <div className="main">

                {/* Cabeçalho recebe o usuário real obtido no login. */}
                <Header usuario={usuario} />

                {/* Conteúdo central da visão geral. */}
                <main className="content">

                    {mensagem && (
                        <p
                            id="mensagem-retorno"
                            data-testid="mensagem-retorno"
                            className="mensagem-retorno mensagem-retorno-sucesso"
                            role="status"
                        >
                            {mensagem}
                        </p>
                    )}

                    {/* Título e descrição da página atual. */}
                    <div className="page-header">

                        <div>
                            <h1>Visão geral da Missão</h1>

                            <p>
                                Acompanhe as finanças, pendências e
                                projetos da instituição
                            </p>
                        </div>

                    </div>

                    {/* Indicadores calculados com os lançamentos e doações reais. */}
                    <Cards
                        saldoGeral={dados?.saldoGeral}
                        entradasMes={dados?.entradasMes}
                        despesasMes={dados?.despesasMes}
                        doacoesRecebidas={dados?.doacoesRecebidas}
                    />

                    {/* Limita o gráfico à largura definida no layout de referência. */}
                    <div className="chart-column">
                        {/* Mostra entradas e despesas pagas agrupadas por mês. */}
                        <Grafico dados={dados.fluxo} />
                    </div>

                    {/* Mostra os projetos cadastrados e o saldo calculado pelas movimentações. */}
                    <Projetos dados={dados.projetos} />

                </main>

            </div>

        </div>
    );
}

