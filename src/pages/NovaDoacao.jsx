// Esta página contém o formulário usado para cadastrar uma nova doação.
import Sidebar from "../../components/Sidebar.jsx";
import Header from "../../components/Header.jsx";
import AnexoMovimentacao from "../../components/AnexoMovimentacao.jsx";
import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import "./Dashboard.css";
import "../../components/Movimentacoes.css";
import "../../components/FormularioMovimentacao.css";
import "./NovaDoacao.css";

export default function NovaDoacao({ usuario, apiUrl, opcoes = {}, onRegistrar, onLogout }) {
    // Estados usados para controlar o arquivo, projetos, mensagens e botão de salvar.
    const navigate = useNavigate();
    const [arquivo, setArquivo] = useState("");
    const [projetos, setProjetos] = useState([]);
    const [carregandoProjetos, setCarregandoProjetos] = useState(true);
    const [erroProjetos, setErroProjetos] = useState("");
    const [erro, setErro] = useState("");
    const [salvando, setSalvando] = useState(false);
    const [tipo, setTipo] = useState("");

    // Busca os projetos para preencher o campo Projeto quando a página abre.
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

    // Lê o formulário, prepara a doação e pede para o App salvá-la.
    async function registrar(event) {
        event.preventDefault();
        // Lê os campos preenchidos pelo usuário.
        const doacao = Object.fromEntries(new FormData(event.currentTarget).entries());
        // Campos vazios continuam vazios; os preenchidos viram números.
        doacao.valor = doacao.valor === undefined || doacao.valor === "" ? "" : Number(doacao.valor);
        doacao.quantidade = doacao.quantidade === undefined || doacao.quantidade === "" ? "" : Number(doacao.quantidade);
        doacao.tipo = Number(doacao.tipo);
        // Guarda o nome do projeto para atualizar a tela logo após salvar.
        doacao.projeto_nome = projetos.find((item) => String(item.id_projeto) === String(doacao.id_projeto))?.nome || "";
        setErro("");
        setSalvando(true);
        try {
            await onRegistrar(doacao);
            navigate("/doacoes", { replace: true });
        } catch (error) {
            setErro(error.message);
        } finally {
            setSalvando(false);
        }
    }

    // Parte visual do formulário, dividida em dados, destino e anexo.
    return <div className="app"><Sidebar paginaAtiva="Doações" tipoUsuario={usuario.tipo} onLogout={onLogout}/><div className="main"><Header usuario={usuario}/><main className="entradas-content nova-doacao-content"><form className="entrada-form" onSubmit={registrar}>
        <div className="entradas-titlebar"><div><h1>Nova doação</h1><p>Registre uma nova contribuição recebida pela Missão</p></div><button className="entradas-primary" type="submit" disabled={salvando}>{salvando ? "Registrando..." : "Registrar doação"}</button></div>
        {erro && <p className="mov-form-error" role="alert">{erro}</p>}
        <section className="entrada-panel"><h2>Dados da doação</h2><div className="entrada-grid">
            <label className="entrada-field"><span>Doador<b>*</b></span><input name="doador" required /></label>
            <label className="entrada-field"><span>Data<b>*</b></span><input name="dia" type="date" required /></label>
            <label className="entrada-field"><span>Tipo<b>*</b></span><select name="tipo" value={tipo} onChange={(event) => setTipo(event.target.value)} required><option value="" disabled>Selecione</option><option value="0">Dinheiro</option><option value="1">Alimento</option><option value="2">Roupa</option><option value="3">Tecido</option><option value="4">Outro</option></select></label>
            {(tipo === "0" || tipo === "4") && <label className="entrada-field"><span>Valor<b>*</b></span><input name="valor" type="number" min="0.01" step="0.01" required /></label>}
            {tipo === "1" && <label className="entrada-field"><span>Kg/L<b>*</b></span><input name="quantidade" type="number" min="0.01" step="0.01" required /></label>}
            {tipo === "2" && <label className="entrada-field"><span>Quantidade<b>*</b></span><input name="quantidade" type="number" min="1" step="1" required /></label>}
            {tipo === "3" && <label className="entrada-field"><span>Metros<b>*</b></span><input name="quantidade" type="number" min="0.01" step="0.01" required /></label>}
            {tipo === "4" && <label className="entrada-field"><span>Quantidade<b>*</b></span><input name="quantidade" type="number" min="1" step="1" required /></label>}
        </div></section>
        <section className="entrada-panel"><h2>Destinação</h2><div className="entrada-grid">
            <label className="entrada-field"><span>Projeto</span><select name="id_projeto" defaultValue="" disabled={carregandoProjetos || Boolean(erroProjetos)}><option value="">{carregandoProjetos ? "Carregando projetos..." : erroProjetos || (projetos.length ? "Sem projeto" : "Nenhum projeto cadastrado")}</option>{projetos.map((item) => <option key={item.id_projeto} value={item.id_projeto}>{item.nome}</option>)}</select></label>
            <label className="entrada-field full"><span>Descrição</span><textarea name="descricao" /></label>
        </div></section>
        <section className="entrada-panel"><h2>Comprovantes e anexos</h2><p>Anexe documentos relacionados a este registro</p><AnexoMovimentacao arquivo={arquivo} onChange={(event) => setArquivo(event.target.files[0]?.name || "")} /></section>
    </form></main></div></div>;
}
