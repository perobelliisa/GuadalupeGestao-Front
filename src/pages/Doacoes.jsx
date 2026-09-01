import Sidebar from "../../components/Sidebar.jsx";
import Header from "../../components/Header.jsx";
import { Gift, Heart, Package, Plus, Search, UsersRound } from "lucide-react";
import { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import EditorCadastroFinanceiro from "../../components/EditorCadastroFinanceiro.jsx";
import "./Dashboard.css";
import "../../components/Movimentacoes.css";
import "./Doacoes.css";

const moeda = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" });
const data = new Intl.DateTimeFormat("pt-BR");

export default function Doacoes({ usuario, apiUrl, doacoes = [], onAtualizar, onLogout }) {
    const navigate = useNavigate();
    const [busca, setBusca] = useState("");
    const [tipo, setTipo] = useState("");
    const [projeto, setProjeto] = useState("");
    const [selecionada, setSelecionada] = useState(null);
    const doadores = useMemo(() => new Set(doacoes.map((item) => item.doador).filter(Boolean)).size, [doacoes]);
    const emEspecie = useMemo(() => doacoes.filter((item) => Number(item.quantidade) > 0).length, [doacoes]);
    const projetos = useMemo(() => [...new Map(doacoes.filter((item) => item.id_projeto).map((item) => [String(item.id_projeto), item.projeto_nome || item.id_projeto])).entries()], [doacoes]);
    const filtradas = useMemo(() => {
        const termo = busca.trim().toLocaleLowerCase("pt-BR");
        return doacoes.filter((item) => (!tipo || String(item.tipo) === tipo) && (!projeto || String(item.id_projeto) === projeto) && (!termo || [item.doador, item.descricao].some((valor) => String(valor ?? "").toLocaleLowerCase("pt-BR").includes(termo))));
    }, [busca, doacoes, projeto, tipo]);

    return <div className="app"><Sidebar paginaAtiva="Doações" tipoUsuario={usuario.tipo} onLogout={onLogout} /><div className="main"><Header usuario={usuario} /><main className="entradas-content" onClick={(event) => { const linha = event.target.closest("tbody tr"); if (linha) setSelecionada(filtradas[linha.rowIndex - 1]); }}>
        <div className="entradas-titlebar"><div><h1>Doações</h1><p>Todas as contribuições recebidas pela Missão</p></div><button className="entradas-primary" type="button" onClick={() => navigate("/doacoes/nova")}><Plus size={16}/> Nova doação</button></div>
        <section className="entradas-summary"><article><span className="summary-icon donation"><Heart size={19}/></span><div><small>Doações no período</small><strong>{doacoes.length}</strong></div></article><article><span className="summary-icon blue"><UsersRound size={19}/></span><div><small>Doadores distintos</small><strong>{doadores}</strong></div></article><article><span className="summary-icon material"><Package size={19}/></span><div><small>Com quantidade informada</small><strong>{emEspecie}</strong></div></article></section>
        <section className="doacoes-filters"><label><Search size={16}/><input value={busca} onChange={(event) => setBusca(event.target.value)} placeholder="Buscar por doador ou descrição..."/></label><select value={tipo} onChange={(event) => setTipo(event.target.value)}><option value="">Todos os tipos</option>{[...new Set(doacoes.map((item) => item.tipo).filter((valor) => valor !== "" && valor != null))].map((valor) => <option key={valor} value={valor}>{valor}</option>)}</select><select value={projeto} onChange={(event) => setProjeto(event.target.value)}><option value="">Todos os projetos</option>{projetos.map(([id, nome]) => <option key={id} value={id}>{nome}</option>)}</select></section>
        <section className="doacoes-table-card">{filtradas.length === 0 ? <div className="entradas-empty"><Gift size={26}/><strong>Nenhuma doação encontrada</strong><span>As doações cadastradas aparecerão aqui.</span></div> : <div className="entradas-table-scroll"><table><thead><tr><th>DOADOR</th><th>DATA</th><th>TIPO</th><th>VALOR</th><th>QUANTIDADE</th><th>PROJETO</th><th>DESCRIÇÃO</th></tr></thead><tbody>{filtradas.map((item) => <tr key={item.id_doacao}><td><strong>{item.doador}</strong></td><td>{item.dia ? data.format(new Date(`${item.dia}T12:00:00`)) : "-"}</td><td><span className="doacao-type">{item.tipo}</span></td><td>{item.valor !== "" && item.valor != null ? moeda.format(Number(item.valor)) : "-"}</td><td>{item.quantidade || "-"}</td><td>{item.projeto_nome || item.id_projeto || "-"}</td><td>{item.descricao || "-"}</td></tr>)}</tbody></table></div>}</section>
        {selecionada && <EditorCadastroFinanceiro item={selecionada} tipo="Doação" apiUrl={apiUrl} onFechar={() => setSelecionada(null)} onSalvar={onAtualizar} />}
    </main></div></div>;
}
