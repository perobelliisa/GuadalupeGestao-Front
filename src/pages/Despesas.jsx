// Esta página mostra todas as despesas e permite abrir uma despesa para edição.
import Sidebar from "../../components/Sidebar.jsx";
import Header from "../../components/Header.jsx";
import { useState } from "react";
import { useNavigate } from "react-router-dom";
import EditorMovimentacao from "../../components/EditorMovimentacao.jsx";
import "./Dashboard.css";
import "../../components/Movimentacoes.css";
import "./Despesas.css";

function dinheiro(valor) {
    return "R$ " + Number(valor || 0).toFixed(2).replace(".", ",");
}

function dataBrasileira(data) {
    if (!data) return "-";
    const partes = data.split("-");
    return partes[2] + "/" + partes[1] + "/" + partes[0];
}

function formaDePagamento(codigo) {
    if (codigo === 0 || codigo === "0") return "Pix";
    if (codigo === 1 || codigo === "1") return "Crédito";
    if (codigo === 2 || codigo === "2") return "Débito";
    if (codigo === 3 || codigo === "3") return "Boleto";
    return "-";
}

export default function Despesas({ usuario, apiUrl, despesas = [], onAtualizar, onLogout }) {
    // Guarda a despesa clicada para mostrar a tela de edição.
    const navigate = useNavigate();
    const [selecionada, setSelecionada] = useState(null);
    // Estas variáveis são preenchidas pelo for e usadas no resumo e na tabela.
    const despesasMostradas = [];
    let total = 0;
    let pagas = 0;

    for (let posicao = 0; posicao < despesas.length; posicao += 1) {
        const despesa = despesas[posicao];
        total += Number(despesa.valor || 0);
        if (String(despesa.status) === "1") pagas += 1;

        despesasMostradas.push(despesa);
    }

    // Cria uma linha visual para cada despesa que será mostrada.
    const linhasDaTabela = [];
    for (let posicao = 0; posicao < despesasMostradas.length; posicao += 1) {
        const despesa = despesasMostradas[posicao];
        const status = String(despesa.status) === "1" ? "Pago" : "Não pago";
        linhasDaTabela.push(<tr key={despesa.id_livro_caixa} className="mov-row-clickable" onClick={() => setSelecionada(despesa)}>
            <td>{dataBrasileira(despesa.dia)}</td><td><strong>{despesa.descricao || "-"}</strong></td><td>{despesa.fornecedor || "-"}</td>
            <td>{despesa.conta || "-"}</td><td>{dataBrasileira(despesa.vencimento)}</td>
            <td className="despesa-value">- {dinheiro(despesa.valor)}</td><td>{formaDePagamento(despesa.forma_pagamento)}</td><td>{status}</td>
        </tr>);
    }

    // Parte visual da página: título, resumo, tabela e edição condicional.
    return <div className="app"><Sidebar paginaAtiva="Despesas" tipoUsuario={usuario.tipo} onLogout={onLogout} /><div className="main"><Header usuario={usuario} /><main className="entradas-content">
        <div className="entradas-titlebar"><div><h1>Despesas</h1><p>Todos os pagamentos registrados pela Missão</p></div><button type="button" className="entradas-primary" onClick={() => navigate("/despesas/nova")}>+ Nova despesa</button></div>
        <section className="entradas-summary"><article><span className="summary-icon blue">R$</span><div><small>Total no período</small><strong>{dinheiro(total)}</strong></div></article><article><span className="summary-icon teal">-</span><div><small>Despesas registradas</small><strong>{despesas.length}</strong></div></article><article><span className="summary-icon green">✓</span><div><small>Pagas</small><strong>{pagas}</strong></div></article></section>
        <section className="entradas-table-card">{despesasMostradas.length === 0 ? <div className="entradas-empty"><strong>Nenhuma despesa encontrada</strong><span>As despesas aparecerão aqui após o primeiro registro.</span></div> : <div className="entradas-table-scroll"><table><thead><tr><th>DATA</th><th>DESCRIÇÃO</th><th>FORNECEDOR</th><th>LOCAL DO VALOR</th><th>VENCIMENTO</th><th>VALOR</th><th>FORMA</th><th>STATUS</th></tr></thead><tbody>{linhasDaTabela}</tbody></table></div>}</section>
    </main></div>{selecionada && <EditorMovimentacao item={selecionada} tipo="Despesa" apiUrl={apiUrl} onFechar={() => setSelecionada(null)} onSalvar={onAtualizar} />}</div>;
}
