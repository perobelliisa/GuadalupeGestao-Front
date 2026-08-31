import Sidebar from "../../components/Sidebar.jsx";
import Header from "../../components/Header.jsx";
import { ArrowDownToLine, CalendarCheck, Plus, Search, WalletCards } from "lucide-react";
import { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import EditorMovimentacao from "./EditorMovimentacao.jsx";
import "./Dashboard.css";
import "./Entradas.css";

const moeda = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" });
const data = new Intl.DateTimeFormat("pt-BR");
const formasPagamento = { 0: "Pix", 1: "Crédito", 2: "Débito", 3: "Boleto" };

export default function Entradas({ usuario, apiUrl, entradas = [], onAtualizar, onExcluir, onLogout }) {
    const navigate = useNavigate();
    const [busca, setBusca] = useState("");
    const [selecionada, setSelecionada] = useState(null);

    const resumo = useMemo(() => ({
        total: entradas.reduce((soma, item) => soma + Number(item.valor || 0), 0),
        registradas: entradas.length,
        confirmadas: entradas.filter((item) => item.situacao === "Confirmado").length
    }), [entradas]);

    const entradasFiltradas = useMemo(() => {
        const termo = busca.trim().toLocaleLowerCase("pt-BR");
        if (!termo) return entradas;
        return entradas.filter((item) =>
            [item.descricao, item.origem, item.projetoNome, item.categoria]
                .some((valor) => String(valor ?? "").toLocaleLowerCase("pt-BR").includes(termo))
        );
    }, [busca, entradas]);

    return (
        <div className="app">
            <Sidebar paginaAtiva="Entradas" tipoUsuario={usuario.tipo} onLogout={onLogout} />
            <div className="main">
                <Header usuario={usuario} />
                <main className="entradas-content">
                    <div className="entradas-titlebar">
                        <div><h1>Entradas</h1><p>Todos os recebimentos registrados pela Missão</p></div>
                        <button type="button" className="entradas-primary" onClick={() => navigate("/entradas/nova")}>
                            <Plus size={16} /> Nova entrada
                        </button>
                    </div>

                    <section className="entradas-summary" aria-label="Resumo das entradas">
                        <article><span className="summary-icon blue"><WalletCards size={19} /></span><div><small>Total no período</small><strong>{moeda.format(resumo.total)}</strong></div></article>
                        <article><span className="summary-icon teal"><ArrowDownToLine size={19} /></span><div><small>Entradas registradas</small><strong>{resumo.registradas}</strong></div></article>
                        <article><span className="summary-icon green"><CalendarCheck size={19} /></span><div><small>Confirmadas</small><strong>{resumo.confirmadas}</strong></div></article>
                    </section>

                    <label className="entradas-search">
                        <Search size={16} />
                        <input value={busca} onChange={(event) => setBusca(event.target.value)} placeholder="Buscar por descrição ou origem..." />
                    </label>

                    <section className="entradas-table-card">
                        {entradasFiltradas.length === 0 ? (
                            <div className="entradas-empty">
                                <ArrowDownToLine size={26} />
                                <strong>{busca ? "Nenhuma entrada encontrada" : "Nenhuma entrada registrada"}</strong>
                                <span>{busca ? "Tente buscar usando outro termo." : "As entradas aparecerão aqui após o primeiro registro."}</span>
                            </div>
                        ) : (
                            <div className="entradas-table-scroll"><table>
                                <thead><tr><th>DATA</th><th>DESCRIÇÃO</th><th>PROJETO</th><th>CATEGORIA</th><th>VALOR</th><th>FORMA</th><th>SITUAÇÃO</th></tr></thead>
                                <tbody>{entradasFiltradas.map((item) => (
                                    <tr key={item.id} className="mov-row-clickable" tabIndex="0" role="button" onClick={() => setSelecionada(item)} onKeyDown={(event) => { if (event.key === "Enter" || event.key === " ") { event.preventDefault(); setSelecionada(item); } }}>
                                        <td>{item.data ? data.format(new Date(`${item.data}T12:00:00`)) : "-"}</td>
                                        <td><strong>{item.descricao || "-"}</strong></td><td>{item.projetoNome || "-"}</td><td>{item.categoria || "-"}</td>
                                        <td className="entrada-value">+ {moeda.format(Number(item.valor || 0))}</td><td>{formasPagamento[item.formaRecebimento] ?? item.formaRecebimento ?? "-"}</td>
                                        <td><span className="entrada-status">{item.situacao || "-"}</span></td>
                                    </tr>
                                ))}</tbody>
                            </table></div>
                        )}
                    </section>
                </main>
            </div>
            {selecionada && <EditorMovimentacao item={selecionada} tipo="Entrada" apiUrl={apiUrl} onFechar={() => setSelecionada(null)} onSalvar={onAtualizar} onExcluir={onExcluir} />}
        </div>
    );
}
