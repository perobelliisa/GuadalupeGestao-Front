import { Save, X } from "lucide-react";
import { useEffect, useState } from "react";
import AnexoMovimentacao from "./AnexoMovimentacao.jsx";
import "./EditorMovimentacao.css";

export default function EditorCadastroFinanceiro({ item, tipo, apiUrl, onFechar, onSalvar }) {
    const [projetos, setProjetos] = useState([]);
    const [processando, setProcessando] = useState(false);
    const [erro, setErro] = useState("");
    const [idProjeto, setIdProjeto] = useState(String(item.id_projeto ?? ""));
    const [tipoDoacao, setTipoDoacao] = useState(String(item.tipo ?? ""));
    const doacao = tipo === "Doação";
    const ontem = new Date();
    ontem.setDate(ontem.getDate() - 1);
    const anoOntem = ontem.getFullYear();
    const mesOntem = String(ontem.getMonth() + 1).padStart(2, "0");
    const diaOntem = String(ontem.getDate()).padStart(2, "0");
    const dataMaximaDoacao = `${anoOntem}-${mesOntem}-${diaOntem}`;
    const hoje = new Date();
    const anoHoje = hoje.getFullYear();
    const mesHoje = String(hoje.getMonth() + 1).padStart(2, "0");
    const diaHoje = String(hoje.getDate()).padStart(2, "0");
    const dataHoje = `${anoHoje}-${mesHoje}-${diaHoje}`;
    let nomeAnexo = "";
    let imagemAnexo = "";
    if (item.anexo) {
        const partesAnexo = item.anexo.split("/");
        nomeAnexo = partesAnexo[partesAnexo.length - 1];
        if (item.anexo.endsWith(".jpg") || item.anexo.endsWith(".jpeg") || item.anexo.endsWith(".png")) {
            imagemAnexo = `${apiUrl}${item.anexo}`;
        }
    }

    useEffect(() => {
        const controller = new AbortController();
        async function carregarProjetos() {
            try {
                const resposta = await fetch(`${apiUrl}/projetos`, { credentials: "include", signal: controller.signal });
                const texto = await resposta.text();
                let dados = {};
                if (texto) dados = JSON.parse(texto);
                if (!resposta.ok || !dados.sucesso) throw new Error("Não foi possível carregar os projetos.");

                const lista = dados.projetos || [];
                let projetoAtualEncontrado = false;
                for (let posicao = 0; posicao < lista.length; posicao += 1) {
                    if (String(lista[posicao].id_projeto) === String(item.id_projeto)) projetoAtualEncontrado = true;
                }
                if (item.id_projeto && !projetoAtualEncontrado) {
                    lista.push({ id_projeto: item.id_projeto, nome: item.projeto_nome || "Projeto selecionado" });
                }
                setProjetos(lista);
            } catch (error) {
                if (error.name === "AbortError") return;
                if (item.id_projeto) {
                    setProjetos([{ id_projeto: item.id_projeto, nome: item.projeto_nome || "Projeto selecionado" }]);
                    setErro("");
                    return;
                }
                setErro("Não foi possível carregar os projetos.");
            }
        }
        carregarProjetos();
        return () => controller.abort();
    }, [apiUrl, item.id_projeto, item.projeto_nome]);

    async function salvar(event) {
        event.preventDefault();
        setErro("");
        setProcessando(true);
        try {
            const dados = Object.fromEntries(new FormData(event.currentTarget).entries());
            dados.projeto_nome = "";
            for (let posicao = 0; posicao < projetos.length; posicao += 1) {
                if (String(projetos[posicao].id_projeto) === String(idProjeto)) dados.projeto_nome = projetos[posicao].nome;
            }
            await onSalvar(doacao ? item.id_doacao : item.id_emprestimo, dados);
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
            {doacao ? <><label><span>Doador *</span><input name="doador" defaultValue={item.doador} required /></label><label><span>Tipo *</span><select name="tipo" value={tipoDoacao} onChange={(event) => setTipoDoacao(event.target.value)} required><option value="" disabled>Selecione</option><option value="0">Dinheiro</option><option value="1">Alimento</option><option value="2">Roupa</option><option value="3">Tecido</option><option value="4">Outro</option></select></label><label><span>Data *</span><input name="dia" type="date" max={dataMaximaDoacao} defaultValue={item.dia} required /></label>{(tipoDoacao === "0" || tipoDoacao === "4") && <label><span>Valor</span><input name="valor" type="number" min="0.01" step="0.01" defaultValue={item.valor ?? ""} required /></label>}{tipoDoacao === "1" && <label><span>Kg/L</span><input name="quantidade" type="number" min="0.01" step="0.01" defaultValue={item.quantidade ?? ""} required /></label>}{tipoDoacao === "2" && <label><span>Quantidade</span><input name="quantidade" type="number" min="1" step="1" defaultValue={item.quantidade ?? ""} required /></label>}{tipoDoacao === "3" && <label><span>Metros</span><input name="quantidade" type="number" min="0.01" step="0.01" defaultValue={item.quantidade ?? ""} required /></label>}{tipoDoacao === "4" && <label><span>Quantidade</span><input name="quantidade" type="number" min="1" step="1" defaultValue={item.quantidade ?? ""} required /></label>}<label className="full"><span>Descrição</span><textarea name="descricao" defaultValue={item.descricao} /></label></> : <><label><span>Origem *</span><input name="origem" defaultValue={item.origem} required /></label><label><span>Valor *</span><input name="valor" type="number" min="0.01" step="0.01" defaultValue={item.valor} required /></label><label><span>Data *</span><input name="dia" type="date" max={dataHoje} defaultValue={item.dia} required /></label><label><span>Data prevista de devolução *</span><input name="devolucao" type="date" min={dataHoje} defaultValue={item.devolucao} required /></label><label><span>Parcelas *</span><input name="parcelas" type="number" min="1" step="1" defaultValue={item.parcelas} required /></label><label className="full"><span>Finalidade *</span><input name="finalidade" defaultValue={item.finalidade} required /></label></>}
            <label><span>Projeto{!doacao && " *"}</span><select name="id_projeto" value={idProjeto} onChange={(event) => setIdProjeto(event.target.value)} required={!doacao}><option value="">{doacao ? "Sem projeto" : "Selecione"}</option>{projetos.map((projeto) => <option key={projeto.id_projeto} value={projeto.id_projeto}>{projeto.nome}</option>)}</select></label>
            <div className="full mov-anexo-field"><span>Novo anexo</span><AnexoMovimentacao arquivo={nomeAnexo} imagemInicial={imagemAnexo} /></div>
        </div>
        {erro && <p className="mov-modal-error" role="alert">{erro}</p>}
        <footer><div><button type="button" className="mov-cancel" onClick={onFechar} disabled={processando}>Cancelar</button><button type="submit" className="mov-save" disabled={processando}><Save size={15}/> {processando ? "Salvando..." : "Salvar alterações"}</button></div></footer>
    </form></div>;
}
