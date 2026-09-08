// Esta página mostra as doações, seus filtros e a edição de uma doação escolhida.
import Sidebar from "../../components/Sidebar.jsx";
import Header from "../../components/Header.jsx";
import { useState } from "react";
import { useNavigate } from "react-router-dom";
import EditorCadastroFinanceiro from "../../components/EditorCadastroFinanceiro.jsx";
import "./Dashboard.css";
import "../../components/Movimentacoes.css";
import "./Doacoes.css";

function dinheiro(valor) {
    if (valor === "" || valor === null || valor === undefined) return "-";
    return "R$ " + Number(valor).toFixed(2).replace(".", ",");
}

function dataBrasileira(data) {
    if (!data) return "-";
    const partes = data.split("-");
    return partes[2] + "/" + partes[1] + "/" + partes[0];
}

export default function Doacoes({ usuario, apiUrl, doacoes = [], onAtualizar, onLogout }) {
    // Estados dos dois filtros e da doação que o usuário escolheu editar.
    const navigate = useNavigate();
    const [tipo, setTipo] = useState("");
    const [projeto, setProjeto] = useState("");
    const [selecionada, setSelecionada] = useState(null);
    // Listas e contadores que serão preenchidos ao percorrer as doações.
    const doacoesMostradas = [];
    const tipos = [];
    const projetos = [];
    const doadores = [];
    let comQuantidade = 0;

    for (let posicao = 0; posicao < doacoes.length; posicao += 1) {
        const doacao = doacoes[posicao];
        if (Number(doacao.quantidade) > 0) comQuantidade += 1;

        let doadorJaExiste = false;
        for (let indiceDoador = 0; indiceDoador < doadores.length; indiceDoador += 1) {
            if (doadores[indiceDoador] === doacao.doador) doadorJaExiste = true;
        }
        if (doacao.doador && !doadorJaExiste) doadores.push(doacao.doador);

        let tipoJaExiste = false;
        for (let indiceTipo = 0; indiceTipo < tipos.length; indiceTipo += 1) {
            if (tipos[indiceTipo] === doacao.tipo) tipoJaExiste = true;
        }
        if (doacao.tipo !== "" && doacao.tipo !== null && doacao.tipo !== undefined && !tipoJaExiste) tipos.push(doacao.tipo);

        const nomeDoProjeto = doacao.projeto_nome || doacao.id_projeto;
        let projetoJaExiste = false;
        for (let indiceProjeto = 0; indiceProjeto < projetos.length; indiceProjeto += 1) {
            if (String(projetos[indiceProjeto].id) === String(doacao.id_projeto)) projetoJaExiste = true;
        }
        if (doacao.id_projeto && !projetoJaExiste) projetos.push({ id: doacao.id_projeto, nome: nomeDoProjeto });

        const tipoCorreto = tipo === "" || String(doacao.tipo) === tipo;
        const projetoCorreto = projeto === "" || String(doacao.id_projeto) === projeto;
        if (tipoCorreto && projetoCorreto) doacoesMostradas.push(doacao);
    }

    // Cria as opções dos campos de filtro e as linhas visuais da tabela.
    const opcoesDeTipo = [];
    for (let posicao = 0; posicao < tipos.length; posicao += 1) opcoesDeTipo.push(<option key={tipos[posicao]} value={tipos[posicao]}>{tipos[posicao]}</option>);
    const opcoesDeProjeto = [];
    for (let posicao = 0; posicao < projetos.length; posicao += 1) opcoesDeProjeto.push(<option key={projetos[posicao].id} value={projetos[posicao].id}>{projetos[posicao].nome}</option>);
    const linhasDaTabela = [];
    for (let posicao = 0; posicao < doacoesMostradas.length; posicao += 1) {
        const doacao = doacoesMostradas[posicao];
        linhasDaTabela.push(<tr key={doacao.id_doacao} className="mov-row-clickable" onClick={() => setSelecionada(doacao)}><td><strong>{doacao.doador || "-"}</strong></td><td>{dataBrasileira(doacao.dia)}</td><td>{doacao.tipo}</td><td>{dinheiro(doacao.valor)}</td><td>{doacao.quantidade || "-"}</td><td>{doacao.projeto_nome || doacao.id_projeto || "-"}</td><td>{doacao.descricao || "-"}</td></tr>);
    }

    // Parte visual da página: título, resumo, filtros, tabela e edição condicional.
    return <div className="app"><Sidebar paginaAtiva="Doações" tipoUsuario={usuario.tipo} onLogout={onLogout} /><div className="main"><Header usuario={usuario} /><main className="entradas-content">
        <div className="entradas-titlebar"><div><h1>Doações</h1><p>Todas as contribuições recebidas pela Missão</p></div><button className="entradas-primary" type="button" onClick={() => navigate("/doacoes/nova")}>+ Nova doação</button></div>
        <section className="entradas-summary"><article><span className="summary-icon donation">+</span><div><small>Doações no período</small><strong>{doacoes.length}</strong></div></article><article><span className="summary-icon blue">#</span><div><small>Doadores distintos</small><strong>{doadores.length}</strong></div></article><article><span className="summary-icon material">#</span><div><small>Com quantidade informada</small><strong>{comQuantidade}</strong></div></article></section>
        <section className="doacoes-filters"><select value={tipo} onChange={(event) => setTipo(event.target.value)}><option value="">Todos os tipos</option>{opcoesDeTipo}</select><select value={projeto} onChange={(event) => setProjeto(event.target.value)}><option value="">Todos os projetos</option>{opcoesDeProjeto}</select></section>
        <section className="doacoes-table-card">{doacoesMostradas.length === 0 ? <div className="entradas-empty"><strong>Nenhuma doação encontrada</strong><span>As doações cadastradas aparecerão aqui.</span></div> : <div className="entradas-table-scroll"><table><thead><tr><th>DOADOR</th><th>DATA</th><th>TIPO</th><th>VALOR</th><th>QUANTIDADE</th><th>PROJETO</th><th>DESCRIÇÃO</th></tr></thead><tbody>{linhasDaTabela}</tbody></table></div>}</section>
        {selecionada && <EditorCadastroFinanceiro item={selecionada} tipo="Doação" apiUrl={apiUrl} onFechar={() => setSelecionada(null)} onSalvar={onAtualizar} />}
    </main></div></div>;
}
