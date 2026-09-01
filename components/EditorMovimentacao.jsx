import { AlertTriangle, Save, Trash2, X } from "lucide-react";
import { useEffect, useState } from "react";
import "./EditorMovimentacao.css";

const FORMAS = [{ valor: "0", nome: "Pix" }, { valor: "1", nome: "Crédito" }, { valor: "2", nome: "Débito" }, { valor: "3", nome: "Boleto" }];
const RECORRENCIAS = [{ valor: "0", nome: "Não recorrente" }, { valor: "1", nome: "Todo dia" }, { valor: "2", nome: "A cada 15 dias" }, { valor: "3", nome: "A cada 30 dias" }];

export default function EditorMovimentacao({ item, tipo, onFechar, onSalvar, onExcluir }) {
    const [confirmando, setConfirmando] = useState(false);
    const despesa = tipo === "Despesa";

    useEffect(() => {
        function fecharComEscape(event) { if (event.key === "Escape") confirmando ? setConfirmando(false) : onFechar(); }
        window.addEventListener("keydown", fecharComEscape);
        return () => window.removeEventListener("keydown", fecharComEscape);
    }, [confirmando, onFechar]);

    function salvar(event) {
        event.preventDefault();
        const dados = Object.fromEntries(new FormData(event.currentTarget).entries());
        dados.tipo = despesa ? 1 : 0;
        dados.valor = Number(String(dados.valor).replace(",", "."));
        onSalvar(item.id_livro_caixa, dados);
        onFechar();
    }

    return <div className="mov-modal-overlay" onMouseDown={(event) => event.target === event.currentTarget && onFechar()}><form className="mov-modal" onSubmit={salvar} role="dialog" aria-modal="true">
        <header><div><h2>Editar {tipo.toLocaleLowerCase("pt-BR")}</h2><p>Atualize os dados do registro selecionado</p></div><button type="button" onClick={onFechar} aria-label="Fechar"><X size={18}/></button></header>
        <div className="mov-modal-grid">
            <label className="full"><span>Descrição *</span><input name="descricao" defaultValue={item.descricao} required /></label>
            <label><span>Valor *</span><input name="valor" type="number" min="0" step="0.01" defaultValue={item.valor} required /></label>
            <label><span>Data *</span><input name="dia" type="date" defaultValue={item.dia} required /></label>
            <label><span>Categoria</span><input name="id_categoria" type="number" defaultValue={item.id_categoria} /></label>
            <label><span>Conta *</span><input name="conta" type="number" defaultValue={item.conta} required /></label>
            <label><span>Origem *</span><input name="origem" defaultValue={item.origem} required /></label>
            <label><span>Forma de pagamento</span><select name="forma_pagamento" defaultValue={item.forma_pagamento ?? ""}><option value="">Selecione</option>{FORMAS.map((opcao) => <option key={opcao.valor} value={opcao.valor}>{opcao.nome}</option>)}</select></label>
            {despesa && <><label><span>Vencimento</span><input name="vencimento" type="date" defaultValue={item.vencimento} /></label><label><span>Fornecedor</span><input name="fornecedor" defaultValue={item.fornecedor} /></label><label><span>Recorrência</span><select name="recorrencia" defaultValue={item.recorrencia ?? ""}><option value="">Selecione</option>{RECORRENCIAS.map((opcao) => <option key={opcao.valor} value={opcao.valor}>{opcao.nome}</option>)}</select></label><label><span>Status</span><select name="status" defaultValue={item.status ?? "0"}><option value="0">Não pago</option><option value="1">Pago</option></select></label><label><span>Data de início</span><input name="dia_inicio" type="date" defaultValue={item.dia_inicio} /></label><label><span>Data de fim</span><input name="dia_fim" type="date" defaultValue={item.dia_fim} /></label></>}
            <label className="full"><span>Observação</span><textarea name="observacao" defaultValue={item.observacao} /></label>
        </div>
        <footer><button type="button" className="mov-delete" onClick={() => setConfirmando(true)}><Trash2 size={15}/> Excluir</button><div><button type="button" className="mov-cancel" onClick={onFechar}>Cancelar</button><button type="submit" className="mov-save"><Save size={15}/> Salvar alterações</button></div></footer>
        {confirmando && <div className="mov-confirm-overlay"><section role="alertdialog" aria-modal="true"><AlertTriangle size={24}/><h3>Excluir {tipo.toLocaleLowerCase("pt-BR")}?</h3><p>Esta ação não poderá ser desfeita.</p><div><button type="button" className="mov-cancel" onClick={() => setConfirmando(false)}>Cancelar</button><button type="button" className="mov-delete-confirm" onClick={() => { onExcluir(item.id_livro_caixa); onFechar(); }}><Trash2 size={15}/> Excluir</button></div></section></div>}
    </form></div>;
}
