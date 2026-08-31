import Sidebar from "../../components/Sidebar.jsx";
import Header from "../../components/Header.jsx";
import { ArrowDownToLine, ArrowUpFromLine, Landmark, TrendingUp } from "lucide-react";
import { useMemo, useState } from "react";
import { Area, AreaChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import "./Dashboard.css";
import "./LivroCaixa.css";

const moeda = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" });
const dataCompleta = new Intl.DateTimeFormat("pt-BR");
const dataCurta = new Intl.DateTimeFormat("pt-BR", { day: "2-digit", month: "short" });
const formasPagamento = { 0: "Pix", 1: "Crédito", 2: "Débito", 3: "Boleto" };
const statusDespesa = { 0: "Pendente", 1: "Confirmado" };

function normalizarMovimentos(entradas, despesas) {
    const recebimentos = entradas.map((item) => ({ ...item, tipo: "Entrada", sinal: 1, statusTexto: item.situacao || "Confirmado" }));
    const pagamentos = despesas.map((item) => ({ ...item, tipo: "Despesa", sinal: -1, statusTexto: statusDespesa[item.status] || "Pendente" }));
    return [...recebimentos, ...pagamentos].sort((a, b) => String(b.data || "").localeCompare(String(a.data || "")));
}

export default function LivroCaixa({ usuario, saldoInicial = 0, entradas = [], despesas = [], onLogout }) {
    const [projeto, setProjeto] = useState("");
    const [categoria, setCategoria] = useState("");
    const [tipo, setTipo] = useState("");
    const movimentos = useMemo(() => normalizarMovimentos(entradas, despesas), [entradas, despesas]);
    const totalEntradas = useMemo(() => entradas.reduce((soma, item) => soma + Number(item.valor || 0), 0), [entradas]);
    const totalSaidas = useMemo(() => despesas.reduce((soma, item) => soma + Number(item.valor || 0), 0), [despesas]);
    const saldoAtual = Number(saldoInicial) + totalEntradas - totalSaidas;

    const projetos = useMemo(() => [...new Set(movimentos.map((item) => item.projetoNome).filter(Boolean))], [movimentos]);
    const categorias = useMemo(() => [...new Set(movimentos.map((item) => item.categoria).filter(Boolean))], [movimentos]);
    const filtrados = useMemo(() => movimentos.filter((item) => (!projeto || item.projetoNome === projeto) && (!categoria || item.categoria === categoria) && (!tipo || item.tipo === tipo)), [movimentos, projeto, categoria, tipo]);

    const evolucao = useMemo(() => {
        let saldo = Number(saldoInicial);
        return [...movimentos].reverse().map((item) => {
            saldo += Number(item.valor || 0) * item.sinal;
            return { data: item.data, rotulo: item.data ? dataCurta.format(new Date(`${item.data}T12:00:00`)) : "", saldo };
        });
    }, [movimentos, saldoInicial]);

    return <div className="app"><Sidebar paginaAtiva="Livro-caixa" tipoUsuario={usuario.tipo} onLogout={onLogout} /><div className="main"><Header usuario={usuario} /><main className="livro-content">
        <div className="livro-title"><h1>Livro-caixa</h1><p>Histórico cronológico único de todas as movimentações da Missão</p></div>
        <section className="livro-summary">
            <article><span className="livro-icon blue"><Landmark size={17} /></span><small>Saldo inicial</small><strong>{moeda.format(Number(saldoInicial))}</strong></article>
            <article><span className="livro-icon green"><ArrowDownToLine size={17} /></span><small>Total de entradas</small><strong>{moeda.format(totalEntradas)}</strong></article>
            <article><span className="livro-icon red"><ArrowUpFromLine size={17} /></span><small>Total de saídas</small><strong>{moeda.format(totalSaidas)}</strong></article>
            <article><span className="livro-icon blue"><TrendingUp size={17} /></span><small>Saldo atual</small><strong>{moeda.format(saldoAtual)}</strong></article>
        </section>
        <section className="livro-chart"><h2>Evolução do saldo</h2>{evolucao.length ? <ResponsiveContainer width="100%" height={220}><AreaChart data={evolucao}><defs><linearGradient id="saldoFill" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor="#3470ff" stopOpacity={0.2}/><stop offset="100%" stopColor="#3470ff" stopOpacity={0.02}/></linearGradient></defs><CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e8edf5"/><XAxis dataKey="rotulo" tickLine={false} axisLine={false} fontSize={10}/><YAxis tickFormatter={(valor) => moeda.format(valor)} tickLine={false} axisLine={false} fontSize={9} width={78}/><Tooltip formatter={(valor) => moeda.format(valor)} /><Area type="monotone" dataKey="saldo" stroke="#3470ff" strokeWidth={2} fill="url(#saldoFill)" /></AreaChart></ResponsiveContainer> : <div className="livro-chart-empty">A evolução aparecerá quando houver movimentações.</div>}</section>
        <section className="livro-filters"><select value={projeto} onChange={(event) => setProjeto(event.target.value)}><option value="">Todos os projetos</option>{projetos.map((nome) => <option key={nome} value={nome}>{nome}</option>)}</select><select value={categoria} onChange={(event) => setCategoria(event.target.value)}><option value="">Todas as categorias</option>{categorias.map((nome) => <option key={nome} value={nome}>{nome}</option>)}</select><select value={tipo} onChange={(event) => setTipo(event.target.value)}><option value="">Todos os tipos</option><option value="Entrada">Entradas</option><option value="Despesa">Despesas</option></select></section>
        <section className="livro-table-card">{filtrados.length === 0 ? <div className="livro-empty"><Landmark size={25}/><strong>Nenhuma movimentação encontrada</strong><span>Os registros de entradas e despesas aparecerão aqui.</span></div> : <div className="livro-table-scroll"><table><thead><tr><th>DATA</th><th>DESCRIÇÃO</th><th>PROJETO</th><th>CATEGORIA</th><th>TIPO</th><th>VALOR</th><th>FORMA</th><th>SITUAÇÃO</th></tr></thead><tbody>{filtrados.map((item) => <tr key={`${item.tipo}-${item.id}`}><td>{item.data ? dataCompleta.format(new Date(`${item.data}T12:00:00`)) : "-"}</td><td><strong>{item.descricao || "-"}</strong></td><td>{item.projetoNome || "-"}</td><td>{item.categoria || "-"}</td><td><span className={`livro-type ${item.tipo.toLowerCase()}`}>{item.tipo}</span></td><td className={item.sinal > 0 ? "livro-value entrada" : "livro-value despesa"}>{item.sinal > 0 ? "+" : "-"} {moeda.format(Number(item.valor || 0))}</td><td>{formasPagamento[item.formaRecebimento] ?? "-"}</td><td><span className={`livro-status ${item.statusTexto === "Confirmado" ? "ok" : "pending"}`}>{item.statusTexto}</span></td></tr>)}</tbody></table></div>}</section>
    </main></div></div>;
}
