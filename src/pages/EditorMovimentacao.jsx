import { AlertTriangle, Save, Trash2, X } from "lucide-react";
import { useEffect, useState } from "react";

const FORMAS = [{ valor: "0", nome: "Pix" }, { valor: "1", nome: "Crédito" }, { valor: "2", nome: "Débito" }, { valor: "3", nome: "Boleto" }];
const RECORRENCIAS = [{ valor: "0", nome: "Não recorrente" }, { valor: "1", nome: "Todo dia" }, { valor: "2", nome: "A cada 15 dias" }, { valor: "3", nome: "A cada 30 dias" }];

export default function EditorMovimentacao({ item, tipo, apiUrl, onFechar, onSalvar, onExcluir }) {
    const [confirmando, setConfirmando] = useState(false);
    const [projetos, setProjetos] = useState([]);

    useEffect(() => {
        const controller = new AbortController();
        fetch(`${apiUrl}/projetos`, { credentials: "include", signal: controller.signal })
            .then((resposta) => resposta.json())
            .then((dados) => setProjetos(Array.isArray(dados.projetos) ? dados.projetos : []))
            .catch(() => {});
        return () => controller.abort();
    }, [apiUrl]);

    useEffect(() => {
        function fecharComEscape(event) { if (event.key === "Escape") confirmando ? setConfirmando(false) : onFechar(); }
        window.addEventListener("keydown", fecharComEscape);
        return () => window.removeEventListener("keydown", fecharComEscape);
    }, [confirmando, onFechar]);

    function salvar(event) {
        event.preventDefault();
        const dados = Object.fromEntries(new FormData(event.currentTarget).entries());
        dados.valor = Number(String(dados.valor).replace(",", "."));
        dados.projetoNome = projetos.find((projeto) => String(projeto.id_projeto) === String(dados.projeto))?.nome || item.projetoNome || "";
        onSalvar(item.id, dados);
        onFechar();
    }

    const despesa = tipo === "Despesa";
    return <div className="mov-modal-overlay" onMouseDown={(event) => event.target === event.currentTarget && onFechar()}><form className="mov-modal" onSubmit={salvar} role="dialog" aria-modal="true">
        <header><div><h2>Editar {tipo.toLocaleLowerCase("pt-BR")}</h2><p>Atualize os dados do registro selecionado</p></div><button type="button" onClick={onFechar} aria-label="Fechar"><X size={18}/></button></header>
        <div className="mov-modal-grid">
            <label className="full"><span>Descrição *</span><input name="descricao" defaultValue={item.descricao} required /></label>
            <label><span>Valor *</span><input name="valor" type="number" min="0" step="0.01" defaultValue={item.valor} required /></label>
            <label><span>Data *</span><input name="data" type="date" defaultValue={item.data} required /></label>
            <label><span>Categoria</span><input name="categoria" defaultValue={item.categoria} /></label>
            <label><span>Projeto</span><select name="projeto" defaultValue={item.projeto || ""}><option value="">Sem projeto</option>{projetos.map((projeto) => <option key={projeto.id_projeto} value={projeto.id_projeto}>{projeto.nome}</option>)}</select></label>
            <label><span>Conta de destino *</span><input name="contaDestino" defaultValue={item.contaDestino} required /></label>
            <label><span>Origem *</span><input name="origem" defaultValue={item.origem} required /></label>
            <label><span>Forma de pagamento</span><select name="formaRecebimento" defaultValue={item.formaRecebimento ?? ""}><option value="">Selecione</option>{FORMAS.map((opcao) => <option key={opcao.valor} value={opcao.valor}>{opcao.nome}</option>)}</select></label>
            {despesa && <><label><span>Vencimento</span><input name="vencimento" type="date" defaultValue={item.vencimento} /></label><label><span>Fornecedor</span><input name="fornecedor" defaultValue={item.fornecedor} /></label><label><span>Recorrência</span><select name="recorrencia" defaultValue={item.recorrencia ?? ""}><option value="">Selecione</option>{RECORRENCIAS.map((opcao) => <option key={opcao.valor} value={opcao.valor}>{opcao.nome}</option>)}</select></label><label><span>Status</span><select name="status" defaultValue={item.status ?? "0"}><option value="0">Não pago</option><option value="1">Pago</option></select></label><label><span>Data de início</span><input name="dataInicio" type="date" defaultValue={item.dataInicio} /></label><label><span>Data de fim</span><input name="dataFim" type="date" defaultValue={item.dataFim} /></label></>}
            <label className="full"><span>Observações</span><textarea name="observacoes" defaultValue={item.observacoes} /></label>
        </div>
        <footer><button type="button" className="mov-delete" onClick={() => setConfirmando(true)}><Trash2 size={15}/> Excluir</button><div><button type="button" className="mov-cancel" onClick={onFechar}>Cancelar</button><button type="submit" className="mov-save"><Save size={15}/> Salvar alterações</button></div></footer>
        {confirmando && <div className="mov-confirm-overlay"><section role="alertdialog" aria-modal="true"><AlertTriangle size={24}/><h3>Excluir {tipo.toLocaleLowerCase("pt-BR")}?</h3><p>Esta ação não poderá ser desfeita.</p><div><button type="button" className="mov-cancel" onClick={() => setConfirmando(false)}>Cancelar</button><button type="button" className="mov-delete-confirm" onClick={() => { onExcluir(item.id); onFechar(); }}><Trash2 size={15}/> Excluir</button></div></section></div>}
    </form></div>;
}
