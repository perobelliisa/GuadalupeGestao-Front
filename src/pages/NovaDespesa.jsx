import Sidebar from "../../components/Sidebar.jsx";
import Header from "../../components/Header.jsx";
import { Save, UploadCloud } from "lucide-react";
import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import "./Dashboard.css";
import "./Entradas.css";

const FORMAS_PAGAMENTO = [{ valor: "0", label: "Pix" }, { valor: "1", label: "Crédito" }, { valor: "2", label: "Débito" }, { valor: "3", label: "Boleto" }];
const RECORRENCIAS = [{ valor: "0", label: "Não recorrente" }, { valor: "1", label: "Todo dia" }, { valor: "2", label: "A cada 15 dias" }, { valor: "3", label: "A cada 30 dias" }];
const STATUS = [{ valor: "0", label: "Não pago" }, { valor: "1", label: "Pago" }];

function CampoSelect({ label, name, opcoes = [], required = false }) {
    return <label className="entrada-field"><span>{label}{required && <b>*</b>}</span>{opcoes.length ? <select name={name} required={required} defaultValue=""><option value="" disabled>Selecione</option>{opcoes.map((opcao) => <option key={opcao.id ?? opcao.valor} value={opcao.valor ?? opcao.id}>{opcao.nome ?? opcao.label}</option>)}</select> : <input name={name} required={required} placeholder={`Informe ${label.toLocaleLowerCase("pt-BR")}`} />}</label>;
}

export default function NovaDespesa({ usuario, apiUrl, opcoes = {}, onRegistrar, onLogout }) {
    const navigate = useNavigate();
    const [arquivo, setArquivo] = useState("");
    const [projetos, setProjetos] = useState([]);
    const [carregandoProjetos, setCarregandoProjetos] = useState(true);
    const [erroProjetos, setErroProjetos] = useState("");

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

    function registrar(event) {
        event.preventDefault();
        const despesa = Object.fromEntries(new FormData(event.currentTarget).entries());
        despesa.id = crypto.randomUUID();
        despesa.valor = Number(String(despesa.valor).replace(",", "."));
        despesa.projetoNome = projetos.find((projeto) => String(projeto.id_projeto) === String(despesa.projeto))?.nome || "";
        onRegistrar?.(despesa);
        navigate("/despesas", { replace: true });
    }

    return <div className="app"><Sidebar paginaAtiva="Despesas" tipoUsuario={usuario.tipo} onLogout={onLogout} /><div className="main"><Header usuario={usuario} /><main className="entradas-content nova-entrada-content"><form id="nova-despesa-form" onSubmit={registrar} className="entrada-form">
        <div className="entradas-titlebar"><div><h1>Nova despesa</h1></div><button className="entradas-primary" type="submit"><Save size={16} /> Registrar despesa</button></div>
        <section className="entrada-panel"><h2>Identificação</h2><div className="entrada-grid">
            <label className="entrada-field full"><span>Descrição<b>*</b></span><input name="descricao" required placeholder="Ex.: Compra de materiais" /></label>
            <label className="entrada-field"><span>Valor<b>*</b></span><input name="valor" type="number" min="0" step="0.01" required placeholder="R$ 0,00" /></label>
            <label className="entrada-field"><span>Data<b>*</b></span><input name="data" type="date" required /></label>
            <label className="entrada-field"><span>Vencimento</span><input name="vencimento" type="date" /></label>
            <CampoSelect label="Categoria" name="categoria" opcoes={opcoes.categorias} />
        </div></section>
        <section className="entrada-panel"><h2>Destinação</h2><div className="entrada-grid">
            <label className="entrada-field"><span>Projeto</span><select name="projeto" defaultValue="" disabled={carregandoProjetos || Boolean(erroProjetos)}><option value="" disabled>{carregandoProjetos ? "Carregando projetos..." : erroProjetos || (projetos.length ? "Selecione" : "Nenhum projeto cadastrado")}</option>{projetos.map((projeto) => <option key={projeto.id_projeto} value={projeto.id_projeto}>{projeto.nome}</option>)}</select></label>
            <CampoSelect label="Conta de destino" name="contaDestino" opcoes={opcoes.contas} required />
        </div></section>
        <section className="entrada-panel"><h2>Pagamento</h2><div className="entrada-grid">
            <label className="entrada-field"><span>Origem<b>*</b></span><input name="origem" required placeholder="Informe a origem" /></label>
            <label className="entrada-field"><span>Fornecedor</span><input name="fornecedor" placeholder="Informe o fornecedor" /></label>
            <CampoSelect label="Forma de pagamento" name="formaRecebimento" opcoes={FORMAS_PAGAMENTO} />
            <CampoSelect label="Status" name="status" opcoes={STATUS} />
        </div></section>
        <section className="entrada-panel"><h2>Recorrência</h2><div className="entrada-grid">
            <CampoSelect label="Recorrência" name="recorrencia" opcoes={RECORRENCIAS} />
            <label className="entrada-field"><span>Data de início</span><input name="dataInicio" type="date" /></label>
            <label className="entrada-field"><span>Data de fim</span><input name="dataFim" type="date" /></label>
        </div></section>
        <section className="entrada-panel"><h2>Comprovantes e anexos</h2><p>Anexe documentos relacionados a este registro</p><label className="entrada-upload"><UploadCloud size={22} /><strong>{arquivo || "Arraste arquivos ou clique para enviar"}</strong><span>PDF, JPG ou PNG</span><input name="anexo" type="file" accept=".pdf,.jpg,.jpeg,.png" onChange={(event) => setArquivo(event.target.files[0]?.name || "")} /></label><label className="entrada-field entrada-observacoes"><span>Observações</span><textarea name="observacoes" placeholder="Adicione observações relevantes sobre este registro" /></label></section>
    </form></main></div></div>;
}
