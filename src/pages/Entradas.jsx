// Esta página mostra todas as entradas e permite abrir uma entrada para edição.
import Sidebar from "../../components/Sidebar.jsx";
import Header from "../../components/Header.jsx";
import { useState } from "react";
import { useNavigate } from "react-router-dom";
import EditorMovimentacao from "../../components/EditorMovimentacao.jsx";
import "./Dashboard.css";
import "../../components/Movimentacoes.css";
import "./Entradas.css";

// Formata o número recebido da API como moeda brasileira.
function formatarDinheiro(valor) {
    const numero = Number(valor || 0);
    return "R$ " + numero.toFixed(2).replace(".", ",");
}

// Converte uma data ISO para o formato dia/mês/ano.
function formatarData(data) {
    if (!data) return "-";
    const partes = data.split("-");
    return partes[2] + "/" + partes[1] + "/" + partes[0];
}

// Converte o código salvo no banco para o texto da forma de recebimento.
function nomeDaFormaDePagamento(codigo) {
    if (codigo === 0 || codigo === "0") return "Pix";
    if (codigo === 1 || codigo === "1") return "Crédito";
    if (codigo === 2 || codigo === "2") return "Débito";
    if (codigo === 3 || codigo === "3") return "Boleto";
    if (codigo === 4 || codigo === "4") return "Parcelamento";
    if (codigo === 5 || codigo === "5") return "Dinheiro";
    return "-";
}

// Encontra o nome da categoria usando o ID da movimentação.
function nomeDaCategoria(codigo, categorias) {
    const categoria = categorias.find((opcao) => String(opcao.id ?? opcao.valor) === String(codigo));
    return categoria?.nome || codigo || "-";
}

// Mostra a missão geral ou o projeto ligado ao recebimento.
function nomeDoProjeto(codigo, projetos) {
    if (String(codigo) === "0") return "Missão Guadalupe";
    const projeto = projetos.find((item) => String(item.id_projeto) === String(codigo));
    return projeto?.nome || codigo || "-";
}

// Exibe os recebimentos, seus totais e o editor da linha selecionada.
export default function Entradas({ usuario, apiUrl, entradas = [], categorias = [], projetos = [], origens = [], onAtualizar, onLogout }) {
    // Guarda a entrada clicada; ela será enviada para o componente de edição.
    const navigate = useNavigate();
    const [selecionada, setSelecionada] = useState(null);

    // Variáveis usadas para montar o resumo e as linhas da tabela.
    let total = 0;
    let confirmadas = 0;
    const entradasMostradas = [];

    for (let posicao = 0; posicao < entradas.length; posicao += 1) {
        const entrada = entradas[posicao];
        total += Number(entrada.valor || 0);
        if (Number(entrada.status) === 1) confirmadas += 1;

        entradasMostradas.push(entrada);
    }

    // Cada repetição cria uma linha visual da tabela.
    const linhasDaTabela = [];
    for (let posicao = 0; posicao < entradasMostradas.length; posicao += 1) {
        const entrada = entradasMostradas[posicao];
        linhasDaTabela.push(
            <tr key={entrada.id_livro_caixa} className="mov-row-clickable" onClick={() => setSelecionada(entrada)}>
                <td>{formatarData(entrada.dia)}</td><td><strong>{entrada.descricao || "-"}</strong></td>
                <td>{nomeDaCategoria(entrada.id_categoria, categorias)}</td><td>{entrada.projeto_nome || nomeDoProjeto(entrada.conta, projetos)}</td><td>{entrada.origem || "-"}</td>
                <td className="entrada-value">+ {formatarDinheiro(entrada.valor)}</td><td>{nomeDaFormaDePagamento(entrada.forma_pagamento)}</td>
            </tr>
        );
    }

    // Parte visual da página: título, resumo, tabela e edição condicional.
    return <div className="app"><Sidebar paginaAtiva="Entradas" tipoUsuario={usuario.tipo} onLogout={onLogout} /><div className="main"><Header usuario={usuario} /><main className="entradas-content">
        <div className="entradas-titlebar"><div><h1>Entradas</h1><p>Todos os recebimentos registrados pela Missão</p></div><button type="button" className="entradas-primary" onClick={() => navigate("/entradas/nova")}>+ Nova entrada</button></div>
        <section className="entradas-summary"><article><span className="summary-icon blue">R$</span><div><small>Total no período</small><strong>{formatarDinheiro(total)}</strong></div></article><article><span className="summary-icon teal">+</span><div><small>Entradas registradas</small><strong>{entradas.length}</strong></div></article><article><span className="summary-icon green">✓</span><div><small>Confirmadas</small><strong>{confirmadas}</strong></div></article></section>
        <section className="entradas-table-card">{entradasMostradas.length === 0 ? <div className="entradas-empty"><strong>Nenhuma entrada encontrada</strong><span>As entradas aparecerão aqui após o primeiro registro.</span></div> : <div className="entradas-table-scroll"><table><thead><tr><th>DATA</th><th>DESCRIÇÃO</th><th>CATEGORIA</th><th>PROJETO</th><th>QUEM ENVIOU</th><th>VALOR</th><th>FORMA</th></tr></thead><tbody>{linhasDaTabela}</tbody></table></div>}</section>
    </main></div>{selecionada && <EditorMovimentacao item={selecionada} tipo="Entrada" apiUrl={apiUrl} categorias={categorias} projetos={projetos} origens={origens} onFechar={() => setSelecionada(null)} onSalvar={onAtualizar} />}</div>;
}
