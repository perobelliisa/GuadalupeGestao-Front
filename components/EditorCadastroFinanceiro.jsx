import { Save, X } from "lucide-react";
import { useEffect, useState } from "react";
import "./EditorMovimentacao.css";

export default function EditorCadastroFinanceiro({ item, tipo, apiUrl, onFechar, onSalvar }) {
    const [projetos, setProjetos] = useState([]);
    const [processando, setProcessando] = useState(false);
    const [erro, setErro] = useState("");
    const doacao = tipo === "Doação";

    useEffect(() => {
        const controller = new AbortController();
        fetch(`${apiUrl}/projetos`, { credentials: "include", signal: controller.signal })
            .then((resposta) => resposta.json().then((dados) => ({ resposta, dados })))
            .then(({ resposta, dados }) => {
                if (!resposta.ok || !dados.sucesso) throw new Error(dados.mensagem || "Não foi possível carregar os projetos.");
                setProjetos(dados.projetos || []);
            })
            .catch((error) => { if (error.name !== "AbortError") setErro(error.message); });
        return () => controller.abort();
    }, [apiUrl]);

    async function salvar(event) {
        event.preventDefault();
        setErro("");
        setProcessando(true);
        try {
            await onSalvar(doacao ? item.id_doacao : item.id_emprestimo, Object.fromEntries(new FormData(event.currentTarget).entries()));
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
            {doacao ? <><label><span>Doador *</span><input name="doador" defaultValue={item.doador} required /></label><label><span>Tipo *</span><input name="tipo" type="number" defaultValue={item.tipo} required /></label><label><span>Data *</span><input name="dia" type="date" defaultValue={item.dia} required /></label><label><span>Valor</span><input name="valor" type="number" min="0.01" step="0.01" defaultValue={item.valor ?? ""} /></label><label><span>Quantidade</span><input name="quantidade" type="number" min="1" step="1" defaultValue={item.quantidade ?? ""} /></label><label className="full"><span>Descrição</span><textarea name="descricao" defaultValue={item.descricao} /></label></> : <><label><span>Origem *</span><input name="origem" defaultValue={item.origem} required /></label><label><span>Valor *</span><input name="valor" type="number" min="0.01" step="0.01" defaultValue={item.valor} required /></label><label><span>Data *</span><input name="dia" type="date" defaultValue={item.dia} required /></label><label><span>Data prevista de devolução *</span><input name="devolucao" type="date" defaultValue={item.devolucao} required /></label><label><span>Parcelas *</span><input name="parcelas" type="number" min="1" step="1" defaultValue={item.parcelas} required /></label><label className="full"><span>Finalidade *</span><input name="finalidade" defaultValue={item.finalidade} required /></label></>}
            <label><span>Projeto{!doacao && " *"}</span><select name="id_projeto" defaultValue={item.id_projeto ?? ""} required={!doacao}><option value="">{doacao ? "Sem projeto" : "Selecione"}</option>{projetos.map((projeto) => <option key={projeto.id_projeto} value={projeto.id_projeto}>{projeto.nome}</option>)}</select></label>
            <label className="full"><span>Novo anexo</span><input name="anexo" type="file" accept=".pdf,.jpg,.jpeg,.png" /></label>
        </div>
        {erro && <p className="mov-modal-error" role="alert">{erro}</p>}
        <footer><div><button type="button" className="mov-cancel" onClick={onFechar} disabled={processando}>Cancelar</button><button type="submit" className="mov-save" disabled={processando}><Save size={15}/> {processando ? "Salvando..." : "Salvar alterações"}</button></div></footer>
    </form></div>;
}
