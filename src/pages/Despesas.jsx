import Sidebar from "../../components/Sidebar.jsx";
import Header from "../../components/Header.jsx";
import { CalendarClock, CircleCheck, Plus, ReceiptText, Search } from "lucide-react";
import { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import EditorMovimentacao from "../../components/EditorMovimentacao.jsx";
import "./Dashboard.css";
import "../../components/Movimentacoes.css";
import "./Despesas.css";

const moeda = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" });
const data = new Intl.DateTimeFormat("pt-BR");
const formasPagamento = { 0: "Pix", 1: "Crédito", 2: "Débito", 3: "Boleto" };
const statusDespesa = { 0: "Não pago", 1: "Pago" };

export default function Despesas({ usuario, apiUrl, despesas = [], onAtualizar, onExcluir, onLogout }) {
    const navigate = useNavigate();
    const [busca, setBusca] = useState("");
    const [selecionada, setSelecionada] = useState(null);
    const filtradas = useMemo(() => {
        const termo = busca.trim().toLocaleLowerCase("pt-BR");
        return termo ? despesas.filter((item) => [item.descricao, item.fornecedor, item.origem, item.id_categoria].some((valor) => String(valor ?? "").toLocaleLowerCase("pt-BR").includes(termo))) : despesas;
    }, [busca, despesas]);
    const total = useMemo(() => despesas.reduce((soma, item) => soma + Number(item.valor || 0), 0), [despesas]);
    const pagas = useMemo(() => despesas.filter((item) => String(item.status) === "1").length, [despesas]);

    return <div className="app"><Sidebar paginaAtiva="Despesas" tipoUsuario={usuario.tipo} onLogout={onLogout} /><div className="main"><Header usuario={usuario} /><main className="entradas-content">
        <div className="entradas-titlebar"><div><h1>Despesas</h1><p>Todos os pagamentos registrados pela Missão</p></div><button type="button" className="entradas-primary" onClick={() => navigate("/despesas/nova")}><Plus size={16} /> Nova despesa</button></div>
        <section className="entradas-summary"><article><span className="summary-icon blue"><ReceiptText size={19} /></span><div><small>Total no período</small><strong>{moeda.format(total)}</strong></div></article><article><span className="summary-icon teal"><CalendarClock size={19} /></span><div><small>Despesas registradas</small><strong>{despesas.length}</strong></div></article><article><span className="summary-icon green"><CircleCheck size={19} /></span><div><small>Pagas</small><strong>{pagas}</strong></div></article></section>
        <label className="entradas-search"><Search size={16} /><input value={busca} onChange={(event) => setBusca(event.target.value)} placeholder="Buscar por descrição ou fornecedor..." /></label>
        <section className="entradas-table-card">{filtradas.length === 0 ? <div className="entradas-empty"><ReceiptText size={26} /><strong>{busca ? "Nenhuma despesa encontrada" : "Nenhuma despesa registrada"}</strong><span>{busca ? "Tente buscar usando outro termo." : "As despesas aparecerão aqui após o primeiro registro."}</span></div> : <div className="entradas-table-scroll"><table><thead><tr><th>DATA</th><th>DESCRIÇÃO</th><th>FORNECEDOR</th><th>CATEGORIA</th><th>CONTA</th><th>VENCIMENTO</th><th>VALOR</th><th>FORMA</th><th>STATUS</th></tr></thead><tbody>{filtradas.map((item) => <tr key={item.id_livro_caixa} className="mov-row-clickable" tabIndex="0" role="button" onClick={() => setSelecionada(item)} onKeyDown={(event) => { if (event.key === "Enter" || event.key === " ") { event.preventDefault(); setSelecionada(item); } }}><td>{item.dia ? data.format(new Date(`${item.dia}T12:00:00`)) : "-"}</td><td><strong>{item.descricao || "-"}</strong></td><td>{item.fornecedor || "-"}</td><td>{item.id_categoria || "-"}</td><td>{item.conta || "-"}</td><td>{item.vencimento ? data.format(new Date(`${item.vencimento}T12:00:00`)) : "-"}</td><td className="despesa-value">- {moeda.format(Number(item.valor || 0))}</td><td>{formasPagamento[item.forma_pagamento] ?? "-"}</td><td><span className={`despesa-status status-${item.status}`}>{statusDespesa[item.status] ?? "-"}</span></td></tr>)}</tbody></table></div>}</section>
        {selecionada && <EditorMovimentacao item={selecionada} tipo="Despesa" apiUrl={apiUrl} onFechar={() => setSelecionada(null)} onSalvar={onAtualizar} onExcluir={onExcluir} />}
    </main></div></div>;
}
