import Sidebar from "../../components/Sidebar.jsx";
import Header from "../../components/Header.jsx";
import { Banknote, CalendarClock, Landmark, Plus } from "lucide-react";
import { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import EditorCadastroFinanceiro from "../../components/EditorCadastroFinanceiro.jsx";
import "./Dashboard.css";
import "../../components/Movimentacoes.css";
import "./Emprestimos.css";

const moeda = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" });
const data = new Intl.DateTimeFormat("pt-BR");

export default function Emprestimos({ usuario, apiUrl, emprestimos = [], onAtualizar, onLogout }) {
    const navigate = useNavigate();
    const [selecionado, setSelecionado] = useState(null);
    const total = useMemo(() => emprestimos.reduce((soma, item) => soma + Number(item.valor || 0), 0), [emprestimos]);
    const comParcelas = useMemo(() => emprestimos.filter((item) => Number(item.parcelas) > 0).length, [emprestimos]);
    const proximos = useMemo(() => {
        const hoje = new Date();
        return emprestimos.filter((item) => item.devolucao && new Date(`${item.devolucao}T23:59:59`) >= hoje).length;
    }, [emprestimos]);

    return <div className="app"><Sidebar paginaAtiva="Empréstimos" tipoUsuario={usuario.tipo} onLogout={onLogout}/><div className="main"><Header usuario={usuario}/><main className="entradas-content" onClick={(event) => { const linha = event.target.closest("tbody tr"); if (linha) setSelecionado(emprestimos[linha.rowIndex - 1]); }}>
        <div className="entradas-titlebar"><div><h1>Empréstimos</h1><p>Empréstimos recebidos para financiar as atividades da Missão</p></div><button className="entradas-primary" type="button" onClick={() => navigate("/emprestimos/novo")}><Plus size={16}/> Novo empréstimo</button></div>
        <section className="entradas-summary"><article><span className="summary-icon blue"><Landmark size={19}/></span><div><small>Total emprestado</small><strong>{moeda.format(total)}</strong></div></article><article><span className="summary-icon teal"><Banknote size={19}/></span><div><small>Com parcelas informadas</small><strong>{comParcelas}</strong></div></article><article><span className="summary-icon loan"><CalendarClock size={19}/></span><div><small>Devoluções futuras</small><strong>{proximos}</strong></div></article></section>
        <section className="emprestimos-table-card">{emprestimos.length === 0 ? <div className="entradas-empty"><Landmark size={26}/><strong>Nenhum empréstimo registrado</strong><span>Os empréstimos cadastrados aparecerão aqui.</span></div> : <div className="entradas-table-scroll"><table><thead><tr><th>ORIGEM</th><th>VALOR</th><th>DATA</th><th>PROJETO</th><th>PARCELAS</th><th>DEVOLUÇÃO</th><th>VALIDADE</th><th>FINALIDADE</th></tr></thead><tbody>{emprestimos.map((item) => <tr key={item.id_emprestimo}><td><strong>{item.origem || "-"}</strong></td><td>{moeda.format(Number(item.valor || 0))}</td><td>{item.dia ? data.format(new Date(`${item.dia}T12:00:00`)) : "-"}</td><td>{item.projeto_nome || item.id_projeto || "-"}</td><td>{item.parcelas || "-"}</td><td>{item.devolucao ? data.format(new Date(`${item.devolucao}T12:00:00`)) : "-"}</td><td>{item.validade ? data.format(new Date(`${item.validade}T12:00:00`)) : "-"}</td><td>{item.finalidade || "-"}</td></tr>)}</tbody></table></div>}</section>
        {selecionado && <EditorCadastroFinanceiro item={selecionado} tipo="Empréstimo" apiUrl={apiUrl} onFechar={() => setSelecionado(null)} onSalvar={onAtualizar} />}
    </main></div></div>;
}
