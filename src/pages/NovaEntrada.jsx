import Sidebar from "../../components/Sidebar.jsx";
import Header from "../../components/Header.jsx";
import CampoMovimentacao from "../../components/CampoMovimentacao.jsx";
import AnexoMovimentacao from "../../components/AnexoMovimentacao.jsx";
import { Save } from "lucide-react";
import { useState } from "react";
import { useNavigate } from "react-router-dom";
import "./Dashboard.css";
import "../../components/Movimentacoes.css";
import "../../components/FormularioMovimentacao.css";
import "./NovaEntrada.css";

const FORMAS_PAGAMENTO = [
    { valor: "0", label: "Pix" },
    { valor: "1", label: "Crédito" },
    { valor: "2", label: "Débito" },
    { valor: "3", label: "Boleto" }
];

export default function NovaEntrada({ usuario, opcoes = {}, onRegistrar, onLogout }) {
    const navigate = useNavigate();
    const [arquivo, setArquivo] = useState("");
    const [erro, setErro] = useState("");
    const [salvando, setSalvando] = useState(false);

    async function registrar(event) {
        event.preventDefault();
        const entrada = Object.fromEntries(new FormData(event.currentTarget).entries());
        entrada.id_livro_caixa = crypto.randomUUID();
        entrada.tipo = 0;
        entrada.valor = Number(String(entrada.valor).replace(",", "."));
        setErro("");
        setSalvando(true);
        try {
            await onRegistrar?.(entrada);
            navigate("/entradas", { replace: true });
        } catch (error) {
            setErro(error.message);
        } finally {
            setSalvando(false);
        }
    }

    return (
        <div className="app">
            <Sidebar paginaAtiva="Entradas" tipoUsuario={usuario.tipo} onLogout={onLogout} />
            <div className="main">
                <Header usuario={usuario} />
                <main className="entradas-content nova-entrada-content">
                    <form id="nova-entrada-form" onSubmit={registrar} className="entrada-form">
                        <div className="entradas-titlebar"><div><h1>Nova entrada</h1></div><button className="entradas-primary" type="submit" disabled={salvando}><Save size={16} /> {salvando ? "Registrando..." : "Registrar entrada"}</button></div>
                        {erro && <p className="mov-form-error" role="alert">{erro}</p>}
                        <section className="entrada-panel"><h2>Identificação</h2><div className="entrada-grid">
                            <label className="entrada-field full"><span>Descrição<b>*</b></span><input name="descricao" required /></label>
                            <label className="entrada-field"><span>Valor<b>*</b></span><input name="valor" type="number" min="0.01" step="0.01" required /></label>
                            <label className="entrada-field"><span>Data<b>*</b></span><input name="dia" type="date" required /></label>
                            <CampoMovimentacao label="Categoria" name="id_categoria" opcoes={opcoes.categorias} inputType="number" required />
                            <label className="entrada-field"><span>Conta<b>*</b></span><input name="conta" type="number" required /></label>
                        </div></section>
                        <section className="entrada-panel"><h2>Origem e pagamento</h2><div className="entrada-grid">
                            <label className="entrada-field"><span>Origem<b>*</b></span><input name="origem" required /></label>
                            <CampoMovimentacao label="Forma de pagamento" name="forma_pagamento" opcoes={FORMAS_PAGAMENTO} />
                        </div></section>
                        <section className="entrada-panel"><h2>Comprovantes e anexos</h2><p>Anexe documentos relacionados a este registro</p><AnexoMovimentacao arquivo={arquivo} onChange={(event) => setArquivo(event.target.files[0]?.name || "")} /></section>
                        <section className="entrada-panel"><h2>Observações</h2><label className="entrada-field"><span>Observação</span><textarea name="observacao" /></label></section>
                    </form>
                </main>
            </div>
        </div>
    );
}
