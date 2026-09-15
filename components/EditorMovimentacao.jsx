import { Save, X } from "lucide-react";
import { useEffect, useState } from "react";
import "./EditorMovimentacao.css";

const FORMAS = [{ valor: "0", nome: "Pix" }, { valor: "1", nome: "Crédito" }, { valor: "2", nome: "Débito" }, { valor: "3", nome: "Boleto" }];
const RECORRENCIAS = [{ valor: "0", nome: "Não recorrente" }, { valor: "1", nome: "Todo dia" }, { valor: "2", nome: "A cada 15 dias" }, { valor: "3", nome: "A cada 30 dias" }];

export default function EditorMovimentacao({ item, tipo, projetos = [], onFechar, onSalvar }) {
    const [processando, setProcessando] = useState(false);
    const [erro, setErro] = useState("");
    const despesa = tipo === "Despesa";

    useEffect(() => {
        function fecharComEscape(event) { if (event.key === "Escape") onFechar(); }
        window.addEventListener("keydown", fecharComEscape);
        return () => window.removeEventListener("keydown", fecharComEscape);
    }, [onFechar]);

    async function salvar(event) {
        event.preventDefault();
        const dados = Object.fromEntries(new FormData(event.currentTarget).entries());
        dados.valor = Number(String(dados.valor).replace(",", "."));
        setErro("");
        setProcessando(true);
        try {
            await onSalvar(item.id_livro_caixa, dados);
            onFechar();
        } catch (error) {
            setErro(error.message);
        } finally {
            setProcessando(false);
        }
    }

    return <div className="mov-modal-overlay" onMouseDown={(event) => event.target === event.currentTarget && onFechar()}><form className="mov-modal" onSubmit={salvar} role="dialog" aria-modal="true">
        <header><div><h2>Editar {tipo.toLocaleLowerCase("pt-BR")}</h2><p>Atualize os dados do registro selecionado</p></div><button type="button" onClick={onFechar} aria-label="Fechar"><X size={18}/></button></header>
        <div className="mov-modal-grid">
            <label className="full"><span>Descrição *</span><input name="descricao" defaultValue={item.descricao} required /></label>
            <label><span>Valor *</span><input name="valor" type="number" min="0.01" step="0.01" defaultValue={item.valor} required /></label>
            <label><span>Data *</span><input name="dia" type="date" defaultValue={item.dia} required /></label>
            <label><span>{despesa ? "Conta bancária ou caixa" : "Projeto relacionado"} *</span>{despesa ? <input name="conta" type="number" min="0" defaultValue={item.conta} required /> : <select name="conta" defaultValue={item.conta ?? ""} required><option value="" disabled>Selecione o projeto</option>{projetos.map((projeto) => <option key={projeto.id_projeto} value={projeto.id_projeto}>{projeto.nome}</option>)}</select>}</label>
            <label><span>{despesa ? "De onde veio o pagamento?" : "Quem enviou o valor?"} *</span><input name="origem" placeholder={despesa ? "Ex.: caixa, banco ou transferência" : "Pessoa, empresa ou evento"} defaultValue={item.origem} required /></label>
            <label><span>{despesa ? "Como foi pago?" : "Como o valor foi recebido?"}</span><select name="forma_pagamento" defaultValue={item.forma_pagamento ?? ""}><option value="">Selecione</option>{FORMAS.map((opcao) => <option key={opcao.valor} value={opcao.valor}>{opcao.nome}</option>)}</select></label>
            {despesa && <><label><span>Vencimento</span><input name="vencimento" type="date" defaultValue={item.vencimento} /></label><label><span>Fornecedor</span><input name="fornecedor" defaultValue={item.fornecedor} /></label><label><span>Recorrência</span><select name="recorrencia" defaultValue={item.recorrencia ?? ""}><option value="">Selecione</option>{RECORRENCIAS.map((opcao) => <option key={opcao.valor} value={opcao.valor}>{opcao.nome}</option>)}</select></label><label><span>Status</span><select name="status" defaultValue={item.status ?? "0"}><option value="0">Não pago</option><option value="1">Pago</option></select></label><label><span>Data de início</span><input name="dia_inicio" type="date" defaultValue={item.dia_inicio} /></label><label><span>Data de fim</span><input name="dia_fim" type="date" defaultValue={item.dia_fim} /></label></>}
            <label className="full"><span>Observação</span><textarea name="observacao" defaultValue={item.observacao} /></label>
        </div>
        {erro && <p className="mov-modal-error" role="alert">{erro}</p>}
        <footer><div><button type="button" className="mov-cancel" onClick={onFechar} disabled={processando}>Cancelar</button><button type="submit" className="mov-save" disabled={processando}><Save size={15}/> {processando ? "Salvando..." : "Salvar alterações"}</button></div></footer>
    </form></div>;
}
