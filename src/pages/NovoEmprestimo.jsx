// Esta página contém o formulário usado para cadastrar um novo empréstimo.
import Sidebar from "../../components/Sidebar.jsx";
import Header from "../../components/Header.jsx";
import AnexoMovimentacao from "../../components/AnexoMovimentacao.jsx";
import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import "./Dashboard.css";
import "../../components/Movimentacoes.css";
import "../../components/FormularioMovimentacao.css";
import "./NovoEmprestimo.css";

function adicionarMeses(data, quantidade) {
    if (!data || !quantidade) return "";

    const [ano, mes, dia] = data.split("-").map(Number);
    const resultado = new Date(ano, mes - 1 + Number(quantidade), 1);
    const ultimoDiaDoMes = new Date(resultado.getFullYear(), resultado.getMonth() + 1, 0).getDate();
    resultado.setDate(Math.min(dia, ultimoDiaDoMes));

    const anoResultado = resultado.getFullYear();
    const mesResultado = String(resultado.getMonth() + 1).padStart(2, "0");
    const diaResultado = String(resultado.getDate()).padStart(2, "0");
    return `${anoResultado}-${mesResultado}-${diaResultado}`;
}

function dataBrasileira(data) {
    if (!data) return "";
    const [ano, mes, dia] = data.split("-");
    return `${dia}/${mes}/${ano}`;
}

export default function NovoEmprestimo({ usuario, apiUrl, onRegistrar, onLogout }) {
    // Estados usados para controlar o arquivo, projetos, mensagens e botão de salvar.
    const navigate = useNavigate();
    const [arquivo, setArquivo] = useState("");
    const [projetos, setProjetos] = useState([]);
    const [carregandoProjetos, setCarregandoProjetos] = useState(true);
    const [erroProjetos, setErroProjetos] = useState("");
    const [erro, setErro] = useState("");
    const [salvando, setSalvando] = useState(false);
    const [formaPagamento, setFormaPagamento] = useState("");
    const [valor, setValor] = useState("");
    const [parcelas, setParcelas] = useState("");
    const [dataEmprestimo, setDataEmprestimo] = useState("");
    const [confirmando, setConfirmando] = useState(false);
    const [emprestimoPendente, setEmprestimoPendente] = useState(null);
    const hoje = new Date();
    const anoHoje = hoje.getFullYear();
    const mesHoje = String(hoje.getMonth() + 1).padStart(2, "0");
    const diaHoje = String(hoje.getDate()).padStart(2, "0");
    const dataHoje = `${anoHoje}-${mesHoje}-${diaHoje}`;
    const parcelasEfetivas = formaPagamento === "avista" ? 1 : Number(parcelas);
    const dataDevolucao = adicionarMeses(dataEmprestimo, parcelasEfetivas);
    const valorDaParcela = Number(valor) > 0 && Number(parcelas) > 1
        ? Number(valor / Number(parcelas)).toLocaleString("pt-BR", { style: "currency", currency: "BRL" })
        : "";

    // Busca a lista de projetos quando a página é aberta.
    useEffect(() => {
        const controller = new AbortController();
        async function carregarProjetos() {
            try {
                const resposta = await fetch(`${apiUrl}/projetos`, { credentials: "include", signal: controller.signal });
                const dados = await resposta.json().catch(() => ({}));
                if (!resposta.ok || !dados.sucesso) throw new Error(dados.mensagem || dados.erro || "Não foi possível carregar os projetos.");
                setProjetos(Array.isArray(dados.projetos) ? dados.projetos : []);
            } catch (error) {
                if (error.name !== "AbortError") setErroProjetos(error.message);
            } finally {
                if (!controller.signal.aborted) setCarregandoProjetos(false);
            }
        }
        carregarProjetos();
        return () => controller.abort();
    }, [apiUrl]);

    // Lê os campos preenchidos, prepara o empréstimo e pede para o App salvá-lo.
    async function registrar(event) {
        event.preventDefault();
        const emprestimo = Object.fromEntries(new FormData(event.currentTarget).entries());
        emprestimo.valor = Number(emprestimo.valor);
        // À vista é salva como uma única parcela; em parcelado usa a quantidade escolhida.
        emprestimo.parcelas = formaPagamento === "avista" ? 1 : Number(parcelas);
        emprestimo.devolucao = adicionarMeses(emprestimo.dia, emprestimo.parcelas);
        emprestimo.projeto_nome = projetos.find((item) => String(item.id_projeto) === String(emprestimo.id_projeto))?.nome || "";
        setEmprestimoPendente(emprestimo);
        setConfirmando(true);
    }

    async function confirmarRegistro() {
        setConfirmando(false);
        setErro("");
        setSalvando(true);
        try {
            await onRegistrar?.(emprestimoPendente);
            navigate("/emprestimos", { replace: true });
        } catch (error) {
            setErro(error.message);
        } finally {
            setSalvando(false);
            setEmprestimoPendente(null);
        }
    }

    function cancelarRegistro() {
        setConfirmando(false);
        setEmprestimoPendente(null);
    }

    // Parte visual do formulário, dividida em dados, devolução e anexo.
    return <div className="app"><Sidebar paginaAtiva="Empréstimos" tipoUsuario={usuario.tipo} onLogout={onLogout}/><div className="main"><Header usuario={usuario}/><main className="entradas-content novo-emprestimo-content"><form className="entrada-form" onSubmit={registrar}>
        <div className="entradas-titlebar"><div><h1>Novo empréstimo</h1><p>Registre um empréstimo recebido pela Missão</p></div><button className="entradas-primary" type="submit" disabled={salvando}>{salvando ? "Registrando..." : "Registrar empréstimo"}</button></div>
        {erro && <p className="mov-form-error" role="alert">{erro}</p>}
        <section className="entrada-panel"><h2>Dados do empréstimo</h2><div className="entrada-grid">
            <label className="entrada-field"><span>Origem<b>*</b></span><input name="origem" required /></label>
            <label className="entrada-field"><span>Valor<b>*</b></span><input name="valor" type="number" min="0.01" step="0.01" value={valor} onChange={(event) => setValor(event.target.value)} required /></label>
            <label className="entrada-field"><span>Data<b>*</b></span><input name="dia" type="date" max={dataHoje} value={dataEmprestimo} onChange={(event) => setDataEmprestimo(event.target.value)} required /></label>
            <label className="entrada-field"><span>Projeto<b>*</b></span><select name="id_projeto" defaultValue="" required disabled={carregandoProjetos || Boolean(erroProjetos)}><option value="">{carregandoProjetos ? "Carregando projetos..." : erroProjetos || (projetos.length ? "Selecione" : "Nenhum projeto cadastrado")}</option>{projetos.map((item) => <option key={item.id_projeto} value={item.id_projeto}>{item.nome}</option>)}</select></label>
            <label className="entrada-field full"><span>Finalidade<b>*</b></span><input name="finalidade" required /></label>
        </div></section>
        <section className="entrada-panel"><h2>Devolução</h2><div className="entrada-grid">
            <label className="entrada-field"><span>Data prevista de devolução<b>*</b></span><input type="hidden" name="devolucao" value={dataDevolucao} /><input className="entrada-campo-calculado" type="text" value={dataDevolucao ? dataBrasileira(dataDevolucao) : "Será calculada automaticamente"} readOnly aria-readonly="true" /></label>
            <label className="entrada-field"><span>Forma de pagamento<b>*</b></span><select name="forma_pagamento" value={formaPagamento} onChange={(event) => setFormaPagamento(event.target.value)} required><option value="" disabled>Selecione</option><option value="avista">À vista</option><option value="parcelado">Parcelado</option></select></label>
            {formaPagamento === "parcelado" && <><label className="entrada-field"><span>Número de parcelas<b>*</b></span><select value={parcelas} onChange={(event) => setParcelas(event.target.value)} required><option value="" disabled>Selecione</option>{Array.from({ length: 11 }, (_, indice) => <option key={indice + 2} value={indice + 2}>{indice + 2}x</option>)}</select></label>{valorDaParcela && <label className="entrada-field"><span>Valor de cada parcela</span><input value={valorDaParcela} readOnly /></label>}</>}
        </div></section>
        <section className="entrada-panel"><h2>Comprovantes e anexos</h2><p>Anexe documentos relacionados a este registro</p><AnexoMovimentacao arquivo={arquivo} onChange={(event) => setArquivo(event.target.files[0]?.name || "")} /></section>
    </form>{confirmando && <div className="emprestimo-confirmacao" role="dialog" aria-modal="true"><div><h2>Confirmar empréstimo</h2><p>Tem certeza que deseja criar este empréstimo? Depois de salvo, os valores não poderão ser alterados.</p><div><button type="button" onClick={cancelarRegistro}>Cancelar</button><button type="button" onClick={confirmarRegistro}>Confirmar empréstimo</button></div></div></div>}</main></div></div>;
}
