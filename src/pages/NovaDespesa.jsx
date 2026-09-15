// Esta página contém o formulário usado para cadastrar uma nova despesa.
import Sidebar from "../../components/Sidebar.jsx";
import Header from "../../components/Header.jsx";
import CampoMovimentacao from "../../components/CampoMovimentacao.jsx";
import CategoriaMovimentacao from "../../components/CategoriaMovimentacao.jsx";
import OrigemMovimentacao from "../../components/OrigemMovimentacao.jsx";
import RecorrenciaMovimentacao, { validarRecorrencia } from "../../components/RecorrenciaMovimentacao.jsx";
import AnexoMovimentacao from "../../components/AnexoMovimentacao.jsx";
import { useState } from "react";
import { useNavigate } from "react-router-dom";
import "./Dashboard.css";
import "../../components/Movimentacoes.css";
import "../../components/FormularioMovimentacao.css";
import "./NovaDespesa.css";

const FORMAS_PAGAMENTO = [{ valor: "0", label: "Pix" }, { valor: "1", label: "Crédito" }, { valor: "2", label: "Débito" }, { valor: "3", label: "Boleto" }, { valor: "4", label: "Parcelamento" }, { valor: "5", label: "Dinheiro" }];
const STATUS = [{ valor: "0", label: "Não pago" }, { valor: "1", label: "Pago" }];

// Obtém a data atual no fuso local para impedir lançamentos futuros.
function obterDataLocal() {
    const agora = new Date();
    const diferencaFuso = agora.getTimezoneOffset() * 60000;
    return new Date(agora.getTime() - diferencaFuso).toISOString().slice(0, 10);
}

export default function NovaDespesa({ usuario, categorias = [], projetos = [], origens = [], onRegistrar, onLogout }) {
    const navigate = useNavigate();
    const dataMaxima = obterDataLocal();
    const [arquivo, setArquivo] = useState("");
    const [erro, setErro] = useState("");
    const [salvando, setSalvando] = useState(false);

    async function registrar(event) {
        event.preventDefault();
        // Lê todos os campos do formulário e monta o objeto que será enviado à API.
        const despesa = Object.fromEntries(new FormData(event.currentTarget).entries());
        const erroRecorrencia = validarRecorrencia(despesa);
        if (erroRecorrencia) {
            setErro(erroRecorrencia);
            return;
        }
        if (despesa.dia > dataMaxima) {
            setErro("A data da despesa não pode ser futura.");
            return;
        }
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
            <label className="entrada-field"><span>Data<b>*</b></span><input name="dia" type="date" max={dataMaxima} required /></label>
            <CategoriaMovimentacao categorias={categorias} tipo={1} />
        </div></section>
        <section className="entrada-panel"><h2>Pagamento</h2><div className="entrada-grid">
            <OrigemMovimentacao label="De onde veio o pagamento?" origens={origens} placeholder="Ex.: caixa, banco ou transferência" />
            <label className="entrada-field"><span>Fornecedor</span><input name="fornecedor" /></label>
            <label className="entrada-field"><span>Projeto ou casa de missão<b>*</b></span><select name="conta" defaultValue="0" required><option value="0">Missão Guadalupe</option>{projetos.map((projeto) => <option key={projeto.id_projeto} value={projeto.id_projeto}>{projeto.nome}</option>)}</select></label>
            <CampoMovimentacao label="Forma de pagamento" name="forma_pagamento" opcoes={FORMAS_PAGAMENTO} required />
            <CampoMovimentacao label="Status" name="status" opcoes={STATUS} />
        </div></section>
        <section className="entrada-panel"><h2>Recorrência</h2><div className="entrada-grid">
            <RecorrenciaMovimentacao />
        </div></section>
        <section className="entrada-panel"><h2>Comprovantes e anexos</h2><p>Anexe documentos relacionados a este registro</p><AnexoMovimentacao arquivo={arquivo} onChange={(event) => setArquivo(event.target.files[0]?.name || "")} /></section>
        <section className="entrada-panel"><h2>Observações</h2><label className="entrada-field"><span>Observação</span><textarea name="observacao" /></label></section>
    </form></main></div></div>;
}
