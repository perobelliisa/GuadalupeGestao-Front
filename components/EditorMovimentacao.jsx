import { Save, X } from "lucide-react";
import { useEffect, useState } from "react";
import CategoriaMovimentacao from "./CategoriaMovimentacao.jsx";
import OrigemMovimentacao from "./OrigemMovimentacao.jsx";
import RecorrenciaMovimentacao, { validarRecorrencia } from "./RecorrenciaMovimentacao.jsx";
import "./EditorMovimentacao.css";

const FORMAS = [{ valor: "0", nome: "Pix" }, { valor: "1", nome: "Crédito" }, { valor: "2", nome: "Débito" }, { valor: "3", nome: "Boleto" }, { valor: "4", nome: "Parcelamento" }, { valor: "5", nome: "Dinheiro" }];
function obterDataLocal() {
    const agora = new Date();
    const diferencaFuso = agora.getTimezoneOffset() * 60000;
    return new Date(agora.getTime() - diferencaFuso).toISOString().slice(0, 10);
}

export default function EditorMovimentacao({ item, tipo, categorias = [], projetos = [], origens = [], onFechar, onSalvar }) {
    const dataMaxima = obterDataLocal();
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
        const erroRecorrencia = validarRecorrencia(dados);
        if (erroRecorrencia) {
            setErro(erroRecorrencia);
            return;
        }
        if (dados.dia > dataMaxima) {
            setErro("A data da movimentação não pode ser futura.");
            return;
        }
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
            <label><span>Data *</span><input name="dia" type="date" max={dataMaxima} defaultValue={item.dia} required /></label>
            <CategoriaMovimentacao categorias={categorias} tipo={despesa ? 1 : 0} defaultValue={item.id_categoria ?? ""} />
            <label><span>{despesa ? "Projeto ou casa de missão" : "Projeto ou missão em geral"} *</span><select name="conta" defaultValue={item.conta ?? "0"} required><option value="" disabled>Selecione o projeto ou a missão</option><option value="0">Missão Guadalupe — sem projeto específico</option>{projetos.map((projeto) => <option key={projeto.id_projeto} value={projeto.id_projeto}>{projeto.nome}</option>)}</select></label>
            <OrigemMovimentacao label={despesa ? "De onde veio o pagamento?" : "Quem enviou o valor?"} origens={origens} placeholder={despesa ? "Ex.: caixa, banco ou transferência" : "Pessoa, empresa ou evento"} defaultValue={item.origem || ""} />
            <label><span>{despesa ? "Como foi pago?" : "Como o valor foi recebido?"} *</span><select name="forma_pagamento" defaultValue={item.forma_pagamento ?? ""} required><option value="" disabled>Selecione</option>{FORMAS.map((opcao) => <option key={opcao.valor} value={opcao.valor}>{opcao.nome}</option>)}</select></label>
            {despesa && <><label><span>Fornecedor</span><input name="fornecedor" defaultValue={item.fornecedor} /></label><RecorrenciaMovimentacao defaultRecorrencia={item.recorrencia} defaultInicio={item.dia_inicio} defaultFim={item.dia_fim} /><label><span>Status</span><select name="status" defaultValue={item.status ?? "0"}><option value="0">Não pago</option><option value="1">Pago</option></select></label></>}
            <label className="full"><span>Observação</span><textarea name="observacao" defaultValue={item.observacao} /></label>
        </div>
        {erro && <p className="mov-modal-error" role="alert">{erro}</p>}
        <footer><div><button type="button" className="mov-cancel" onClick={onFechar} disabled={processando}>Cancelar</button><button type="submit" className="mov-save" disabled={processando}><Save size={15}/> {processando ? "Salvando..." : "Salvar alterações"}</button></div></footer>
    </form></div>;
}
