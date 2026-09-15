// Esta página contém o formulário usado para cadastrar uma nova entrada.
import Sidebar from "../../components/Sidebar.jsx";
import Header from "../../components/Header.jsx";
import CampoMovimentacao from "../../components/CampoMovimentacao.jsx";
import CategoriaMovimentacao from "../../components/CategoriaMovimentacao.jsx";
import OrigemMovimentacao from "../../components/OrigemMovimentacao.jsx";
import AnexoMovimentacao from "../../components/AnexoMovimentacao.jsx";
import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import "./Dashboard.css";
import "../../components/Movimentacoes.css";
import "../../components/FormularioMovimentacao.css";
import "./NovaEntrada.css";

const FORMAS_PAGAMENTO = [
    { valor: "0", label: "Pix" },
    { valor: "1", label: "Crédito" },
    { valor: "2", label: "Débito" },
    { valor: "3", label: "Boleto" },
    { valor: "4", label: "Parcelamento" },
    { valor: "5", label: "Dinheiro" }
];

// Obtém a data de hoje no fuso local para limitar o campo de recebimento.
function obterDataLocal() {
    const agora = new Date();
    const diferencaFuso = agora.getTimezoneOffset() * 60000;
    return new Date(agora.getTime() - diferencaFuso).toISOString().slice(0, 10);
}

export default function NovaEntrada({ usuario, categorias = [], origens = [], onRegistrar, onLogout }) {
    const navigate = useNavigate();
    const dataMaxima = obterDataLocal();
    const [arquivo, setArquivo] = useState("");
    const [projetos, setProjetos] = useState([]);
    const [carregandoProjetos, setCarregandoProjetos] = useState(true);
    const [erroProjetos, setErroProjetos] = useState("");
    const [erro, setErro] = useState("");
    const [salvando, setSalvando] = useState(false);

    useEffect(() => {
        const controller = new AbortController();

        async function carregarProjetos() {
            try {
                const resposta = await fetch("/api/projetos", { credentials: "include", signal: controller.signal });
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
    }, []);

    async function registrar(event) {
        event.preventDefault();
        // Lê todos os campos do formulário e monta o objeto que será enviado à API.
        const entrada = Object.fromEntries(new FormData(event.currentTarget).entries());
        // 0 representa uma entrada no banco de dados.
        if (entrada.dia > dataMaxima) {
            setErro("A data do recebimento não pode ser futura.");
            return;
        }
        // Inputs sempre devolvem texto; o valor precisa ser convertido em número.
        entrada.valor = Number(String(entrada.valor).replace(",", "."));
        entrada.projeto_nome = projetos.find((projeto) => String(projeto.id_projeto) === String(entrada.conta))?.nome || "";
        setErro("");
        setSalvando(true);
        try {
            await onRegistrar(entrada);
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
                        <div className="entradas-titlebar"><div><h1>Novo recebimento</h1><p>Registre um valor recebido pela Missão</p></div><button className="entradas-primary" type="submit" disabled={salvando}>{salvando ? "Registrando..." : "Registrar recebimento"}</button></div>
                        {erro && <p className="mov-form-error" role="alert">{erro}</p>}
                        <section className="entrada-panel"><h2>Detalhes do recebimento</h2><div className="entrada-grid">
                            <label className="entrada-field full"><span>Descrição do recebimento<b>*</b></span><input name="descricao" placeholder="Ex.: contribuição para a campanha de alimentos" required /></label>
                            <label className="entrada-field"><span>Valor recebido<b>*</b></span><input name="valor" type="number" min="0.01" step="0.01" required /></label>
                            <label className="entrada-field"><span>Data do recebimento<b>*</b></span><input name="dia" type="date" max={dataMaxima} required /></label>
                            <CategoriaMovimentacao categorias={categorias} tipo={0} />
                            {/* O backend legado recebe o identificador do projeto no campo numérico CONTA. */}
                            <label className="entrada-field"><span>Projeto ou missão em geral<b>*</b></span><select name="conta" required disabled={carregandoProjetos || Boolean(erroProjetos)}><option value="" disabled>{carregandoProjetos ? "Carregando projetos..." : erroProjetos || "Selecione uma opção"}</option><option value="0">Missão Guadalupe — sem projeto específico</option>{projetos.map((projeto) => <option key={projeto.id_projeto} value={projeto.id_projeto}>{projeto.nome}</option>)}</select></label>
                        </div></section>
                        <section className="entrada-panel"><h2>Origem e recebimento</h2><div className="entrada-grid">
                            <OrigemMovimentacao label="Fonte do recurso" origens={origens} placeholder="Ex.: doador, empresa parceira ou evento" />
                            <CampoMovimentacao label="Meio de recebimento" name="forma_pagamento" opcoes={FORMAS_PAGAMENTO} required />
                        </div></section>
                        <section className="entrada-panel"><h2>Comprovantes e anexos</h2><p>Anexe documentos relacionados a este registro</p><AnexoMovimentacao arquivo={arquivo} onChange={(event) => setArquivo(event.target.files[0]?.name || "")} /></section>
                        <section className="entrada-panel"><h2>Observações</h2><label className="entrada-field"><span>Observação</span><textarea name="observacao" /></label></section>
                    </form>
                </main>
            </div>
        </div>
    );
}
