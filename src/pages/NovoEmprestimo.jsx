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

export default function NovoEmprestimo({ usuario, apiUrl, onRegistrar, onLogout }) {
    // Estados usados para controlar o arquivo, projetos, mensagens e botão de salvar.
    const navigate = useNavigate();
    const [arquivo, setArquivo] = useState("");
    const [projetos, setProjetos] = useState([]);
    const [carregandoProjetos, setCarregandoProjetos] = useState(true);
    const [erroProjetos, setErroProjetos] = useState("");
    const [erro, setErro] = useState("");
    const [salvando, setSalvando] = useState(false);

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
        emprestimo.valor = emprestimo.valor === "" ? "" : Number(emprestimo.valor);
        emprestimo.parcelas = emprestimo.parcelas === "" ? "" : Number(emprestimo.parcelas);
        emprestimo.projeto_nome = projetos.find((item) => String(item.id_projeto) === String(emprestimo.id_projeto))?.nome || "";
        setErro("");
        setSalvando(true);
        try {
            await onRegistrar?.(emprestimo);
            navigate("/emprestimos", { replace: true });
        } catch (error) {
            setErro(error.message);
        } finally {
            setSalvando(false);
        }
    }

    // Parte visual do formulário, dividida em dados, devolução e anexo.
    return <div className="app"><Sidebar paginaAtiva="Empréstimos" tipoUsuario={usuario.tipo} onLogout={onLogout}/><div className="main"><Header usuario={usuario}/><main className="entradas-content novo-emprestimo-content"><form className="entrada-form" onSubmit={registrar}>
        <div className="entradas-titlebar"><div><h1>Novo empréstimo</h1><p>Registre um empréstimo recebido pela Missão</p></div><button className="entradas-primary" type="submit" disabled={salvando}>{salvando ? "Registrando..." : "Registrar empréstimo"}</button></div>
        {erro && <p className="mov-form-error" role="alert">{erro}</p>}
        <section className="entrada-panel"><h2>Dados do empréstimo</h2><div className="entrada-grid">
            <label className="entrada-field"><span>Origem<b>*</b></span><input name="origem" required /></label>
            <label className="entrada-field"><span>Valor<b>*</b></span><input name="valor" type="number" min="0.01" step="0.01" required /></label>
            <label className="entrada-field"><span>Data<b>*</b></span><input name="dia" type="date" required /></label>
            <label className="entrada-field"><span>Projeto<b>*</b></span><select name="id_projeto" defaultValue="" required disabled={carregandoProjetos || Boolean(erroProjetos)}><option value="">{carregandoProjetos ? "Carregando projetos..." : erroProjetos || (projetos.length ? "Selecione" : "Nenhum projeto cadastrado")}</option>{projetos.map((item) => <option key={item.id_projeto} value={item.id_projeto}>{item.nome}</option>)}</select></label>
            <label className="entrada-field full"><span>Finalidade<b>*</b></span><input name="finalidade" required /></label>
        </div></section>
        <section className="entrada-panel"><h2>Devolução</h2><div className="entrada-grid">
            <label className="entrada-field"><span>Data de vencimento<b>*</b></span><input name="devolucao" type="date" required /></label>
            <label className="entrada-field"><span>Parcelas<b>*</b></span><input name="parcelas" type="number" min="1" step="1" required /></label>
            <label className="entrada-field"><span>Validade</span><input name="validade" type="date" /></label>
        </div></section>
        <section className="entrada-panel"><h2>Comprovantes e anexos</h2><p>Anexe documentos relacionados a este registro</p><AnexoMovimentacao arquivo={arquivo} onChange={(event) => setArquivo(event.target.files[0]?.name || "")} /></section>
    </form></main></div></div>;
}
