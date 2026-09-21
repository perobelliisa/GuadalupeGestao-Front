import { useMemo, useState } from "react";
import { Download, FileBarChart, FolderKanban, Heart, Printer, Search, WalletCards } from "lucide-react";
import Sidebar from "../../components/Sidebar.jsx";
import Header from "../../components/Header.jsx";
import "./Relatorios.css";

const TIPOS = [
    { id: "entrada", nome: "Entradas" },
    { id: "saida", nome: "Saídas" },
    { id: "doacao", nome: "Doações" },
    { id: "emprestimo", nome: "Empréstimos" }
];

function numero(valor) {
    if (typeof valor === "number") return Number.isFinite(valor) ? valor : 0;
    const texto = String(valor ?? "").trim();
    const normalizado = texto.includes(",") ? texto.replace(/\./g, "").replace(",", ".") : texto;
    const resultado = Number(normalizado);
    return Number.isFinite(resultado) ? resultado : 0;
}

function dinheiro(valor) {
    return new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(numero(valor));
}

function dataBr(valor) {
    if (!valor) return "—";
    const data = new Date(`${String(valor).slice(0, 10)}T12:00:00`);
    return Number.isNaN(data.getTime()) ? "—" : new Intl.DateTimeFormat("pt-BR").format(data);
}

function idProjeto(item) {
    return item.id_projeto ?? item.conta ?? "";
}

function nomeProjeto(item, projetos) {
    return item.projeto_nome || projetos.find((projeto) => String(projeto.id_projeto) === String(idProjeto(item)))?.nome || "Sem projeto";
}

function criarLinhas(entradas, despesas, doacoes, emprestimos, projetos) {
    return [
        ...entradas.map((item) => ({ id: `e-${item.id_livro_caixa}`, tipo: "entrada", tipoNome: "Entrada", data: item.dia, descricao: item.descricao || "Entrada", projeto: nomeProjeto(item, projetos), projetoId: idProjeto(item), valor: numero(item.valor) })),
        ...despesas.map((item) => ({ id: `s-${item.id_livro_caixa}`, tipo: "saida", tipoNome: "Saída", data: item.dia, descricao: item.descricao || "Saída", projeto: nomeProjeto(item, projetos), projetoId: idProjeto(item), valor: numero(item.valor) })),
        ...doacoes.map((item) => ({ id: `d-${item.id_doacao}`, tipo: "doacao", tipoNome: "Doação", data: item.dia || item.data, descricao: item.descricao || item.doador || "Doação recebida", projeto: nomeProjeto(item, projetos), projetoId: idProjeto(item), valor: numero(item.valor), detalhe: item.doador ? `Doador: ${item.doador}` : "" })),
        ...emprestimos.map((item) => ({ id: `p-${item.id_emprestimo}`, tipo: "emprestimo", tipoNome: "Empréstimo", data: item.dia, descricao: item.finalidade || "Empréstimo", projeto: nomeProjeto(item, projetos), projetoId: idProjeto(item), valor: numero(item.valor), detalhe: item.origem ? `Origem: ${item.origem}` : "" }))
    ].sort((a, b) => String(b.data || "").localeCompare(String(a.data || "")));
}

export default function Relatorios({ usuario, apiUrl, entradas = [], despesas = [], doacoes = [], emprestimos = [], projetos = [], onLogout }) {
    const [tipos, setTipos] = useState(TIPOS.map((tipo) => tipo.id));
    const [inicio, setInicio] = useState("");
    const [fim, setFim] = useState("");
    const [projeto, setProjeto] = useState("");
    const [busca, setBusca] = useState("");
    const [relatorioGerado, setRelatorioGerado] = useState(false);
    const [baixandoPdf, setBaixandoPdf] = useState(false);
    const [erroPdf, setErroPdf] = useState("");
    const todasLinhas = useMemo(() => criarLinhas(entradas, despesas, doacoes, emprestimos, projetos), [entradas, despesas, doacoes, emprestimos, projetos]);
    const linhas = useMemo(() => todasLinhas.filter((linha) => {
        const data = String(linha.data || "").slice(0, 10);
        const termo = busca.trim().toLocaleLowerCase("pt-BR");
        return tipos.includes(linha.tipo)
            && (!inicio || data >= inicio)
            && (!fim || data <= fim)
            && (!projeto || String(linha.projetoId) === String(projeto))
            && (!termo || `${linha.descricao} ${linha.projeto} ${linha.detalhe}`.toLocaleLowerCase("pt-BR").includes(termo));
    }), [todasLinhas, tipos, inicio, fim, projeto, busca]);

    const totais = useMemo(() => ({
        entradas: linhas.filter((linha) => linha.tipo === "entrada").reduce((total, linha) => total + linha.valor, 0),
        saidas: linhas.filter((linha) => linha.tipo === "saida").reduce((total, linha) => total + linha.valor, 0),
        doacoes: linhas.filter((linha) => linha.tipo === "doacao").reduce((total, linha) => total + linha.valor, 0),
        emprestimos: linhas.filter((linha) => linha.tipo === "emprestimo").reduce((total, linha) => total + linha.valor, 0)
    }), [linhas]);

    function alternarTipo(tipo) {
        setTipos((atuais) => atuais.includes(tipo) ? atuais.filter((item) => item !== tipo) : [...atuais, tipo]);
        setRelatorioGerado(false);
    }

    function aplicarModelo(modelo) {
        if (modelo === "financeiro") setTipos(["entrada", "saida"]);
        if (modelo === "projeto") setTipos(TIPOS.map((tipo) => tipo.id));
        if (modelo === "doacoes") setTipos(["doacao"]);
        setRelatorioGerado(false);
        document.querySelector(".relatorios-filtros")?.scrollIntoView({ behavior: "smooth", block: "start" });
    }

    function exportarCsv() {
        const cabecalho = ["Data", "Tipo", "Descrição", "Projeto", "Valor"];
        const conteudo = [cabecalho, ...linhas.map((linha) => [dataBr(linha.data), linha.tipoNome, linha.descricao, linha.projeto, linha.valor.toFixed(2).replace(".", ",")])]
            .map((colunas) => colunas.map((valor) => `"${String(valor).replace(/"/g, '""')}"`).join(";"))
            .join("\n");
        const url = URL.createObjectURL(new Blob([`\uFEFF${conteudo}`], { type: "text/csv;charset=utf-8" }));
        const link = document.createElement("a");
        link.href = url;
        link.download = `relatorio-guadalupe-${new Date().toISOString().slice(0, 10)}.csv`;
        link.click();
        URL.revokeObjectURL(url);
    }

    async function baixarPdf() {
        setBaixandoPdf(true);
        setErroPdf("");
        try {
            const parametros = new URLSearchParams({ tipos: tipos.join(",") });
            if (inicio) parametros.set("inicio", inicio);
            if (fim) parametros.set("fim", fim);
            if (projeto) parametros.set("projeto", projeto);
            const resposta = await fetch(`${apiUrl}/relatorios/pdf?${parametros}`, { credentials: "include" });
            if (!resposta.ok) {
                const dados = await resposta.json().catch(() => ({}));
                throw new Error(dados.mensagem || dados.erro || "Não foi possível gerar o PDF.");
            }
            const url = URL.createObjectURL(await resposta.blob());
            const link = document.createElement("a");
            link.href = url;
            link.download = `relatorio-guadalupe-${new Date().toISOString().slice(0, 10)}.pdf`;
            link.click();
            URL.revokeObjectURL(url);
        } catch (erro) {
            setErroPdf(erro.message);
        } finally {
            setBaixandoPdf(false);
        }
    }

    return <div className="app">
        <Sidebar paginaAtiva="Relatórios" tipoUsuario={usuario.tipo} onLogout={onLogout} />
        <div className="main">
            <Header usuario={usuario} />
            <main className="relatorios-content">
                <header className="relatorios-title"><h1>Relatórios</h1><p>Gere relatórios institucionais com os dados registrados no sistema.</p></header>

                <section className="relatorios-modelos">
                    <button onClick={() => aplicarModelo("financeiro")}><span className="azul"><WalletCards size={20} /></span><strong>Financeiro geral</strong><p>Entradas, saídas e saldo consolidado da Missão</p><small>Configurar relatório →</small></button>
                    <button onClick={() => aplicarModelo("projeto")}><span className="roxo"><FolderKanban size={20} /></span><strong>Financeiro por projeto</strong><p>Movimentações financeiras de cada projeto</p><small>Configurar relatório →</small></button>
                    <button onClick={() => aplicarModelo("doacoes")}><span className="vermelho"><Heart size={20} /></span><strong>Doações</strong><p>Volume, origem e destino das doações recebidas</p><small>Configurar relatório →</small></button>
                </section>

                <section className="relatorios-filtros">
                    <div className="relatorios-section-title"><FileBarChart size={19} /><div><h2>Configurar relatório</h2><p>Combine os filtros para gerar o documento desejado.</p></div></div>
                    <div className="relatorios-tipos"><span>Tipos de registro</span><div>{TIPOS.map((tipo) => <label key={tipo.id}><input type="checkbox" checked={tipos.includes(tipo.id)} onChange={() => alternarTipo(tipo.id)} /> {tipo.nome}</label>)}</div></div>
                    <div className="relatorios-filter-grid">
                        <label><span>Data inicial</span><input type="date" value={inicio} onChange={(event) => { setInicio(event.target.value); setRelatorioGerado(false); }} /></label>
                        <label><span>Data final</span><input type="date" value={fim} onChange={(event) => { setFim(event.target.value); setRelatorioGerado(false); }} /></label>
                        <label><span>Projeto</span><select value={projeto} onChange={(event) => { setProjeto(event.target.value); setRelatorioGerado(false); }}><option value="">Todos os projetos</option>{projetos.map((item) => <option key={item.id_projeto} value={item.id_projeto}>{item.nome}</option>)}</select></label>
                    </div>
                    <button className="relatorios-generate" disabled={!tipos.length} onClick={() => setRelatorioGerado(true)}><FileBarChart size={17} /> Gerar relatório</button>
                </section>

                {relatorioGerado && <section className="relatorio-resultado">
                    <div className="relatorio-print-header"><div><img src="/Guadalupe Gestões (1).png" alt="" /><div><strong>Guadalupe Gestões</strong><span>Relatório institucional</span></div></div><small>Gerado em {dataBr(new Date().toISOString())}</small></div>
                    <div className="relatorio-result-title"><div><h2>Relatório de movimentações</h2><p>{inicio || fim ? `Período: ${inicio ? dataBr(inicio) : "início"} até ${fim ? dataBr(fim) : "hoje"}` : "Todos os períodos"} · {projeto ? projetos.find((item) => String(item.id_projeto) === String(projeto))?.nome : "Todos os projetos"}</p></div><div className="relatorio-actions"><button onClick={baixarPdf} disabled={baixandoPdf}><Printer size={16} /> {baixandoPdf ? "Gerando PDF..." : "Baixar PDF"}</button><button onClick={exportarCsv}><Download size={16} /> Exportar CSV</button></div></div>
                    {erroPdf && <div className="relatorio-pdf-error">{erroPdf}</div>}
                    <div className="relatorio-resumos"><article><span>Entradas</span><strong>{dinheiro(totais.entradas)}</strong></article><article><span>Saídas</span><strong>{dinheiro(totais.saidas)}</strong></article><article><span>Doações</span><strong>{dinheiro(totais.doacoes)}</strong></article><article><span>Empréstimos</span><strong>{dinheiro(totais.emprestimos)}</strong></article><article className="saldo"><span>Saldo financeiro</span><strong>{dinheiro(totais.entradas - totais.saidas)}</strong></article></div>
                    <label className="relatorio-search"><Search size={15} /><input placeholder="Buscar no relatório..." value={busca} onChange={(event) => setBusca(event.target.value)} /></label>
                    <div className="relatorio-table-wrap"><table><thead><tr><th>Data</th><th>Tipo</th><th>Descrição</th><th>Projeto</th><th>Valor</th></tr></thead><tbody>{linhas.length ? linhas.map((linha) => <tr key={linha.id}><td>{dataBr(linha.data)}</td><td><span className={`relatorio-tipo ${linha.tipo}`}>{linha.tipoNome}</span></td><td><strong>{linha.descricao}</strong>{linha.detalhe && <small>{linha.detalhe}</small>}</td><td>{linha.projeto}</td><td>{dinheiro(linha.valor)}</td></tr>) : <tr><td colSpan="5" className="relatorio-vazio">Nenhum registro encontrado com os filtros selecionados.</td></tr>}</tbody></table></div>
                    <footer className="relatorio-print-footer">{linhas.length} registro(s) encontrado(s)</footer>
                </section>}
            </main>
        </div>
    </div>;
}
