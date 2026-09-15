// Esta página contém o formulário usado para cadastrar uma nova despesa.
import Sidebar from "../../components/Sidebar.jsx";
import Header from "../../components/Header.jsx";
import CampoMovimentacao from "../../components/CampoMovimentacao.jsx";
import AnexoMovimentacao from "../../components/AnexoMovimentacao.jsx";
import { useState } from "react";
import { useNavigate } from "react-router-dom";
import "./Dashboard.css";
import "../../components/Movimentacoes.css";
import "../../components/FormularioMovimentacao.css";
import "./NovaDespesa.css";

const FORMAS_PAGAMENTO = [{ valor: "0", label: "Pix" }, { valor: "1", label: "Crédito" }, { valor: "2", label: "Débito" }, { valor: "3", label: "Boleto" }];
const RECORRENCIAS = [{ valor: "0", label: "Não recorrente" }, { valor: "1", label: "Todo dia" }, { valor: "2", label: "A cada 15 dias" }, { valor: "3", label: "A cada 30 dias" }];
const STATUS = [{ valor: "0", label: "Não pago" }, { valor: "1", label: "Pago" }];

export default function NovaDespesa({ usuario, onRegistrar, onLogout }) {
    const navigate = useNavigate();
    const [arquivo, setArquivo] = useState("");
    const [erro, setErro] = useState("");
    const [salvando, setSalvando] = useState(false);

    async function registrar(event) {
        event.preventDefault();
        // Lê todos os campos do formulário e monta o objeto que será enviado à API.
        const despesa = Object.fromEntries(new FormData(event.currentTarget).entries());
        // 1 representa uma despesa no banco de dados.
        // Inputs sempre devolvem texto; o valor precisa ser convertido em número.
        despesa.valor = Number(String(despesa.valor).replace(",", "."));
        setErro("");
        setSalvando(true);
        try {
            await onRegistrar(despesa);
            navigate("/despesas", { replace: true });
        } catch (error) {
            setErro(error.message);
        } finally {
            setSalvando(false);
        }
    }

    return <div className="app"><Sidebar paginaAtiva="Despesas" tipoUsuario={usuario.tipo} onLogout={onLogout} /><div className="main"><Header usuario={usuario} /><main className="entradas-content nova-despesa-content"><form id="nova-despesa-form" onSubmit={registrar} className="entrada-form">
        <div className="entradas-titlebar"><div><h1>Nova despesa</h1></div><button className="entradas-primary" type="submit" disabled={salvando}>{salvando ? "Registrando..." : "Registrar despesa"}</button></div>
        {erro && <p className="mov-form-error" role="alert">{erro}</p>}
        <section className="entrada-panel"><h2>Identificação</h2><div className="entrada-grid">
            <label className="entrada-field full"><span>Descrição<b>*</b></span><input name="descricao" required /></label>
            <label className="entrada-field"><span>Valor<b>*</b></span><input name="valor" type="number" min="0.01" step="0.01" required /></label>
            <label className="entrada-field"><span>Data<b>*</b></span><input name="dia" type="date" required /></label>
            <label className="entrada-field"><span>Conta bancária ou caixa<b>*</b></span><input name="conta" type="number" min="0" placeholder="Ex.: número da conta" required /></label>
        </div></section>
        <section className="entrada-panel"><h2>Pagamento</h2><div className="entrada-grid">
            <label className="entrada-field"><span>De onde veio o pagamento?<b>*</b></span><input name="origem" placeholder="Ex.: caixa, banco ou transferência" required /></label>
            <label className="entrada-field"><span>Fornecedor</span><input name="fornecedor" /></label>
            <CampoMovimentacao label="Forma de pagamento" name="forma_pagamento" opcoes={FORMAS_PAGAMENTO} />
            <CampoMovimentacao label="Status" name="status" opcoes={STATUS} />
            <label className="entrada-field"><span>Vencimento</span><input name="vencimento" type="date" /></label>
        </div></section>
        <section className="entrada-panel"><h2>Recorrência</h2><div className="entrada-grid">
            <CampoMovimentacao label="Recorrência" name="recorrencia" opcoes={RECORRENCIAS} />
            <label className="entrada-field"><span>Data de início</span><input name="dia_inicio" type="date" /></label>
            <label className="entrada-field"><span>Data de fim</span><input name="dia_fim" type="date" /></label>
        </div></section>
        <section className="entrada-panel"><h2>Comprovantes e anexos</h2><p>Anexe documentos relacionados a este registro</p><AnexoMovimentacao arquivo={arquivo} onChange={(event) => setArquivo(event.target.files[0]?.name || "")} /></section>
        <section className="entrada-panel"><h2>Observações</h2><label className="entrada-field"><span>Observação</span><textarea name="observacao" /></label></section>
    </form></main></div></div>;
}
