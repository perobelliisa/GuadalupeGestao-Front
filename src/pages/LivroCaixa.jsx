// Esta página junta entradas e despesas em uma única tabela de livro-caixa.
import Sidebar from "../../components/Sidebar.jsx";
import Header from "../../components/Header.jsx";
import { useState } from "react";
import { useNavigate } from "react-router-dom";
import "./Dashboard.css";
import "./LivroCaixa.css";

// Formata um valor numérico no padrão de moeda brasileira.
function dinheiro(valor) {
    return "R$ " + Number(valor || 0).toFixed(2).replace(".", ",");
}

// Converte datas ISO para o formato usado pela interface.
function dataBrasileira(data) {
    if (!data) return "-";
    const partes = data.split("-");
    return partes[2] + "/" + partes[1] + "/" + partes[0];
}

// Traduz os códigos de pagamento armazenados no banco.
function formaDePagamento(codigo) {
    if (codigo === 0 || codigo === "0") return "Pix";
    if (codigo === 1 || codigo === "1") return "Crédito";
    if (codigo === 2 || codigo === "2") return "Débito";
    if (codigo === 3 || codigo === "3") return "Boleto";
    if (codigo === 4 || codigo === "4") return "Parcelamento";
    if (codigo === 5 || codigo === "5") return "Dinheiro";
    return "-";
}

// Busca o nome da categoria para exibir na tabela unificada.
function nomeDaCategoria(codigo, categoriasDisponiveis) {
    const categoria = categoriasDisponiveis.find((opcao) => String(opcao.id ?? opcao.valor) === String(codigo));
    return categoria?.nome || codigo || "-";
}

// Busca o nome do projeto ou identifica a missão geral pelo código zero.
function nomeDoProjeto(codigo, projetosDisponiveis) {
    if (String(codigo) === "0") return "Missão Guadalupe";
    const projeto = projetosDisponiveis.find((item) => String(item.id_projeto) === String(codigo));
    return projeto?.nome || codigo || "-";
}

// Decide se a coluna deve mostrar missão geral ou projeto.
function nomeDoLocal(movimento, projetosDisponiveis) {
    if (movimento.tipoTexto === "Entrada") return nomeDoProjeto(movimento.conta, projetosDisponiveis);
    if (String(movimento.conta) === "0") return "Missão Guadalupe";
    return nomeDoProjeto(movimento.conta, projetosDisponiveis);
}

export default function LivroCaixa({ usuario, entradas = [], despesas = [], categoriasDisponiveis = [], projetosDisponiveis = [], onLogout }) {
    const navigate = useNavigate();
    // Estados que guardam as escolhas feitas nos três filtros da página.
    const [contaEscolhida, setContaEscolhida] = useState("");
    const [categoriaEscolhida, setCategoriaEscolhida] = useState("");
    const [tipoEscolhido, setTipoEscolhido] = useState("");
    // Listas usadas para juntar entradas e despesas e montar os filtros.
    const movimentos = [];
    const contas = [];
    const categoriasEncontradas = [];
    let totalEntradas = 0;
    let totalSaidas = 0;

    // Primeiro adiciona todas as entradas na lista única de movimentos.
    for (let posicao = 0; posicao < entradas.length; posicao += 1) {
        const entrada = entradas[posicao];
        movimentos.push({ ...entrada, tipoTexto: "Entrada", sinal: 1 });
        totalEntradas += Number(entrada.valor || 0);
    }

    // Depois adiciona todas as despesas na mesma lista.
    for (let posicao = 0; posicao < despesas.length; posicao += 1) {
        const despesa = despesas[posicao];
        movimentos.push({ ...despesa, tipoTexto: "Despesa", sinal: -1 });
        if (String(despesa.status) === "1") totalSaidas += Number(despesa.valor || 0);
    }

    // Organiza os movimentos pela data, do mais recente para o mais antigo.
    movimentos.sort((primeiro, segundo) => String(segundo.dia || "").localeCompare(String(primeiro.dia || "")));
    const movimentosMostrados = [];

    for (let posicao = 0; posicao < movimentos.length; posicao += 1) {
        const movimento = movimentos[posicao];
        let contaJaExiste = false;
        for (let indiceConta = 0; indiceConta < contas.length; indiceConta += 1) {
            if (contas[indiceConta] === movimento.conta) contaJaExiste = true;
        }
        if (movimento.conta !== "" && movimento.conta !== null && movimento.conta !== undefined && !contaJaExiste) contas.push(movimento.conta);

        let categoriaJaExiste = false;
        for (let indiceCategoria = 0; indiceCategoria < categoriasEncontradas.length; indiceCategoria += 1) {
            if (categoriasEncontradas[indiceCategoria] === movimento.id_categoria) categoriaJaExiste = true;
        }
        if (movimento.id_categoria !== "" && movimento.id_categoria !== null && movimento.id_categoria !== undefined && !categoriaJaExiste) categoriasEncontradas.push(movimento.id_categoria);

        const contaCorreta = contaEscolhida === "" || String(movimento.conta) === contaEscolhida;
        const categoriaCorreta = categoriaEscolhida === "" || String(movimento.id_categoria) === categoriaEscolhida;
        const tipoCorreto = tipoEscolhido === "" || movimento.tipoTexto === tipoEscolhido;
        if (contaCorreta && categoriaCorreta && tipoCorreto) movimentosMostrados.push(movimento);
    }

    // Transforma contas, categorias e movimentos em elementos que o React pode mostrar.
    const opcoesDeConta = [];
    for (let posicao = 0; posicao < contas.length; posicao += 1) opcoesDeConta.push(<option key={contas[posicao]} value={contas[posicao]}>{String(contas[posicao]) === "0" ? "Missão Guadalupe" : nomeDoProjeto(contas[posicao], projetosDisponiveis)}</option>);
    const opcoesDeCategoria = [];
    for (let posicao = 0; posicao < categoriasEncontradas.length; posicao += 1) opcoesDeCategoria.push(<option key={categoriasEncontradas[posicao]} value={categoriasEncontradas[posicao]}>{nomeDaCategoria(categoriasEncontradas[posicao], categoriasDisponiveis)}</option>);
    const linhasDaTabela = [];
    for (let posicao = 0; posicao < movimentosMostrados.length; posicao += 1) {
        const movimento = movimentosMostrados[posicao];
        const status = movimento.tipoTexto === "Entrada" ? (String(movimento.status) === "1" ? "Confirmado" : "Pendente") : (String(movimento.status) === "1" ? "Confirmado" : "Pendente");
        linhasDaTabela.push(<tr key={movimento.id_livro_caixa}><td>{dataBrasileira(movimento.dia)}</td><td><strong>{movimento.descricao || "-"}</strong></td><td>{nomeDaCategoria(movimento.id_categoria, categoriasDisponiveis)}</td><td>{nomeDoLocal(movimento, projetosDisponiveis)}</td><td>{movimento.tipoTexto}</td><td className={movimento.sinal === 1 ? "livro-value entrada" : "livro-value despesa"}>{movimento.sinal === 1 ? "+" : "-"} {dinheiro(movimento.valor)}</td><td>{formaDePagamento(movimento.forma_pagamento)}</td><td>{status}</td></tr>);
    }

    // Saldo atual = tudo que entrou - tudo que saiu.
    const saldoAtual = totalEntradas - totalSaidas;
    // Parte visual da página: resumo, filtros e tabela de movimentos.
    return <div className="app"><Sidebar paginaAtiva="Livro-caixa" tipoUsuario={usuario.tipo} onLogout={onLogout} /><div className="main"><Header usuario={usuario} /><main className="livro-content">
        <div className="livro-title"><div><h1>Livro-caixa</h1><p>Histórico de entradas e despesas da Missão</p></div><div className="livro-actions"><button type="button" className="livro-action receita" onClick={() => navigate("/entradas/nova")}>+ Recebimento</button><button type="button" className="livro-action despesa" onClick={() => navigate("/despesas/nova")}>+ Despesa</button></div></div>
        <section className="livro-summary">
            <article className="livro-card entradas"><span className="livro-icon green">↑</span><div><small>Total de entradas</small><strong>{dinheiro(totalEntradas)}</strong><span>Valores recebidos</span></div></article>
            <article className="livro-card saidas"><span className="livro-icon red">↓</span><div><small>Total de saídas</small><strong>{dinheiro(totalSaidas)}</strong><span>Pagamentos realizados</span></div></article>
            <article className="livro-card saldo"><span className="livro-icon blue">=</span><div><small>Saldo atual</small><strong>{dinheiro(saldoAtual)}</strong><span>Resultado do período</span></div></article>
        </section>
        <section className="livro-filters"><select value={contaEscolhida} onChange={(event) => setContaEscolhida(event.target.value)}><option value="">Todos os projetos / casas</option>{opcoesDeConta}</select><select value={categoriaEscolhida} onChange={(event) => setCategoriaEscolhida(event.target.value)}><option value="">Todas as categorias</option>{opcoesDeCategoria}</select><select value={tipoEscolhido} onChange={(event) => setTipoEscolhido(event.target.value)}><option value="">Todos os tipos</option><option value="Entrada">Entradas</option><option value="Despesa">Despesas</option></select></section>
        <section className="livro-table-card">{movimentosMostrados.length === 0 ? <div className="livro-empty"><strong>Nenhuma movimentação encontrada</strong><span>Os registros de entradas e despesas aparecerão aqui.</span></div> : <div className="livro-table-scroll"><table><thead><tr><th>DATA</th><th>DESCRIÇÃO</th><th>CATEGORIA</th><th>PROJETO / CASA DE MISSÃO</th><th>TIPO</th><th>VALOR</th><th>FORMA</th><th>SITUAÇÃO</th></tr></thead><tbody>{linhasDaTabela}</tbody></table></div>}</section>
    </main></div></div>;
}
