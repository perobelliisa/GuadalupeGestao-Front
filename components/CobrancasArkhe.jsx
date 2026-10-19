import { useCallback, useEffect, useRef, useState } from "react";
import { QRCodeSVG } from "qrcode.react";
import { API_URL } from "../src/config/api.js";
import "./CobrancasArkhe.css";

const CHAVE = "guadalupe.arkhe.solicitacao";
const ROTULOS = { criando: "Criação não confirmada", verificar: "Conferir com a Arkhé", falhou: "Criação recusada", pendente: "Aguardando pagamento", pago: "Recebido" };
const dinheiro = (valor) => Number(valor).toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
function recuperar() {
    try { return JSON.parse(sessionStorage.getItem(CHAVE) || "null"); } catch { return null; }
}
async function chamar(caminho, opcoes = {}) {
    const resposta = await fetch(`${API_URL}/integracoes/arkhe${caminho}`, { credentials: "include", ...opcoes });
    const dados = await resposta.json().catch(() => ({}));
    if (!resposta.ok || !dados.sucesso) throw new Error(dados.mensagem || "Não foi possível acessar a integração Arkhé.");
    return dados;
}

export default function CobrancasArkhe({ projetos = [], onRecebimento }) {
    const [cobrancas, setCobrancas] = useState([]);
    const [carregando, setCarregando] = useState(true);
    const [formulario, setFormulario] = useState(false);
    const [valorLivre, setValorLivre] = useState(true);
    const [erro, setErro] = useState("");
    const [erroSincronizacao, setErroSincronizacao] = useState("");
    const [mensagem, setMensagem] = useState("");
    const [ocupado, setOcupado] = useState("");
    const [solicitacao, setSolicitacao] = useState(recuperar);
    const [limite, setLimite] = useState(10);
    const trava = useRef(false);
    const montado = useRef(true);
    const consultas = useRef(new Map());
    const confirmadas = useRef(new Set());
    const recebimentoRef = useRef(onRecebimento);
    const pendentes = JSON.stringify(cobrancas.filter((item) => item.situacao === "pendente").map((item) => item.id));

    useEffect(() => { recebimentoRef.current = onRecebimento; }, [onRecebimento]);

    const consultarStatus = useCallback((id) => {
        if (!consultas.current.has(id)) {
            const promessa = chamar(`/cobrancas/${encodeURIComponent(id)}/consultar`, { method: "POST" })
                .finally(() => consultas.current.delete(id));
            consultas.current.set(id, promessa);
        }
        return consultas.current.get(id);
    }, []);

    const aplicarConsulta = useCallback((cobranca) => {
        if (!montado.current) return;
        setCobrancas((atuais) => atuais.map((item) => item.id === cobranca.id ? cobranca : item));
        if (cobranca.situacao === "pago" && !confirmadas.current.has(cobranca.id)) {
            confirmadas.current.add(cobranca.id);
            setMensagem("Pagamento confirmado. A doação e a entrada no livro-caixa foram registradas.");
            recebimentoRef.current?.();
        }
    }, []);

    useEffect(() => {
        montado.current = true;
        const controller = new AbortController();
        chamar("/cobrancas", { signal: controller.signal })
            .then((dados) => setCobrancas(dados.cobrancas))
            .catch((error) => { if (error.name !== "AbortError") setErro(error.message); })
            .finally(() => { if (!controller.signal.aborted) setCarregando(false); });
        return () => { montado.current = false; controller.abort(); };
    }, []);

    useEffect(() => {
        const ids = JSON.parse(pendentes);
        if (carregando || !ids.length) {
            setErroSincronizacao("");
            return undefined;
        }
        let cancelado = false;
        let emCurso = false;
        async function sincronizar() {
            if (cancelado || emCurso || trava.current || document.visibilityState === "hidden") return;
            emCurso = true;
            let falha = "";
            try {
                for (const id of ids) {
                    if (cancelado || trava.current || document.visibilityState === "hidden") break;
                    try {
                        const dados = await consultarStatus(id);
                        if (!cancelado) aplicarConsulta(dados.cobranca);
                    } catch {
                        falha = "Não foi possível verificar os pagamentos automaticamente. Uma nova consulta será feita em instantes.";
                    }
                }
                if (!cancelado) setErroSincronizacao(falha);
            } finally { emCurso = false; }
        }
        sincronizar();
        const intervalo = window.setInterval(sincronizar, 5000);
        window.addEventListener("focus", sincronizar);
        document.addEventListener("visibilitychange", sincronizar);
        return () => {
            cancelado = true;
            window.clearInterval(intervalo);
            window.removeEventListener("focus", sincronizar);
            document.removeEventListener("visibilitychange", sincronizar);
        };
    }, [carregando, pendentes, consultarStatus, aplicarConsulta]);

    async function atualizar() {
        const dados = await chamar("/cobrancas");
        if (montado.current) setCobrancas(dados.cobrancas);
    }
    async function executar(chave, operacao) {
        if (trava.current) return;
        trava.current = true;
        setOcupado(chave); setErro(""); setMensagem("");
        try { await operacao(); }
        catch (error) { if (montado.current) setErro(error.message || "Não foi possível concluir a operação."); }
        finally { trava.current = false; if (montado.current) setOcupado(""); }
    }
    async function enviar(salva) {
        await executar("criar", async () => {
            // O mesmo ID é reutilizado após falhas e recargas, evitando outra cobrança no banco.
            sessionStorage.setItem(CHAVE, JSON.stringify(salva));
            setSolicitacao(salva);
            let dados;
            try {
                dados = await chamar("/cobrancas", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(salva) });
            } catch (error) { await atualizar().catch(() => {}); throw error; }
            sessionStorage.removeItem(CHAVE);
            if (!montado.current) return;
            setSolicitacao(null); setFormulario(false);
            setCobrancas((atuais) => [dados.cobranca, ...atuais.filter((item) => item.id !== dados.cobranca.id)]);
            setMensagem(dados.cobranca.situacao === "pendente"
                ? "Cobrança disponível. O pagamento será verificado automaticamente."
                : "Solicitação recuperada. Confira a situação na lista antes de criar outra cobrança.");
        });
    }
    function criar(event) {
        event.preventDefault();
        const dados = Object.fromEntries(new FormData(event.currentTarget));
        enviar({ ...dados, valor_livre: valorLivre, ...(!valorLivre ? { valor: Number(dados.valor) } : {}), id: crypto.randomUUID() });
    }
    function consultar(cobranca) {
        executar(cobranca.id, async () => {
            const dados = await consultarStatus(cobranca.id);
            if (!montado.current) return;
            aplicarConsulta(dados.cobranca);
            setErroSincronizacao("");
            if (dados.cobranca.situacao !== "pago") setMensagem("A Arkhé ainda informa que esta cobrança aguarda pagamento.");
        });
    }

    return <section className="arkhe-panel" aria-labelledby="titulo-arkhe" aria-busy={Boolean(ocupado) || carregando}>
        <header className="arkhe-header"><div><h2 id="titulo-arkhe">Gerar QR Code para doação</h2></div>
            <div className="arkhe-acoes"><button type="button" disabled={Boolean(ocupado) || carregando} onClick={() => executar("atualizar", atualizar)}>Atualizar lista</button><button type="button" disabled={Boolean(ocupado) || Boolean(solicitacao) || carregando || Boolean(erro && !cobrancas.length)} aria-expanded={formulario} onClick={() => setFormulario(!formulario)}>{formulario ? "Fechar formulário" : "+ Gerar cobrança Pix"}</button></div>
        </header>
        {erro && <p className="arkhe-aviso erro" role="alert">{erro}</p>}
        {erroSincronizacao && <p className="arkhe-aviso erro" role="alert">{erroSincronizacao}</p>}
        {mensagem && <p className="arkhe-aviso" role="status">{mensagem}</p>}
        {solicitacao && <div className="arkhe-aviso" role="status"><p>Há uma solicitação sem resposta confirmada para {solicitacao.doador}, {solicitacao.valor_livre ? "com valor escolhido pelo doador" : `de ${dinheiro(solicitacao.valor)}`}. Recupere a solicitação antes de criar outra cobrança.</p><button type="button" disabled={Boolean(ocupado)} onClick={() => enviar(solicitacao)}>{ocupado === "criar" ? "Recuperando..." : "Recuperar solicitação"}</button></div>}
        {formulario && !solicitacao && <form className="arkhe-form" onSubmit={criar}>
            <label>Doador<input name="doador" maxLength={100} required disabled={Boolean(ocupado)} /></label>
            <label>Valor da doação<select value={valorLivre ? "livre" : "fixo"} onChange={(event) => setValorLivre(event.target.value === "livre")} disabled={Boolean(ocupado)}><option value="livre">O doador escolhe o valor</option><option value="fixo">Definir valor agora</option></select></label>
            {!valorLivre && <label>Valor (R$)<input name="valor" type="number" min="0.01" max="999999999.99" step="0.01" required disabled={Boolean(ocupado)} /></label>}
            <label>Projeto<select name="id_projeto" defaultValue="" disabled={Boolean(ocupado)}><option value="">Sem projeto</option>{projetos.map((p) => <option value={p.id_projeto} key={p.id_projeto}>{p.nome}</option>)}</select></label>
            <label>Descrição<input name="descricao" maxLength={200} disabled={Boolean(ocupado)} /></label>
            <p>A doação será registrada após a confirmação do pagamento. Este código é para pagamento dentro da Arkhé.</p>
            <button type="submit" disabled={Boolean(ocupado)}>{ocupado === "criar" ? "Gerando..." : "Gerar cobrança"}</button>
        </form>}
        {carregando ? <p role="status">Carregando cobranças...</p> : cobrancas.length === 0 ? null : <div className="arkhe-lista">
            {cobrancas.slice(0, limite).map((item) => <article key={item.id} className="arkhe-cobranca">
                <div className="arkhe-resumo"><strong>{item.doador}</strong><strong>{item.valor_livre && item.valor == null ? "Valor escolhido pelo doador" : dinheiro(item.valor)}</strong><span className={`arkhe-situacao ${item.situacao}`}>{ROTULOS[item.situacao] || "Conferir situação"}</span></div>
                <p>{item.id_cobranca ? `Cobrança Arkhé #${item.id_cobranca}` : "Solicitação sem identificação bancária"}{item.descricao ? ` · ${item.descricao}` : ""}</p>
                {item.id_projeto && <p>Projeto: {projetos.find((p) => String(p.id_projeto) === String(item.id_projeto))?.nome || item.id_projeto}</p>}
                {item.situacao === "pendente" && item.codigo_pagamento && <div className="arkhe-qr">
                    <QRCodeSVG value={item.codigo_pagamento} size={240} level="M" marginSize={4} bgColor="#ffffff" fgColor="#000000" role="img" title={`QR Code da cobrança Arkhé #${item.id_cobranca}`} />
                </div>}
                {item.situacao === "pendente" && <><label className="arkhe-codigo">Código de pagamento Arkhé<textarea readOnly value={item.codigo_pagamento || ""} onFocus={(event) => event.target.select()} /></label><div className="arkhe-acoes"><button type="button" disabled={Boolean(ocupado)} onClick={() => executar(`copiar-${item.id}`, async () => { await navigator.clipboard.writeText(item.codigo_pagamento); if (montado.current) setMensagem("Código de pagamento copiado."); })}>Copiar código</button><button type="button" disabled={Boolean(ocupado)} onClick={() => consultar(item)}>{ocupado === item.id ? "Consultando..." : "Consultar pagamento"}</button></div></>}
                {item.situacao === "pago" && <p>Doação registrada #{item.id_doacao}.</p>}
                {["criando", "verificar"].includes(item.situacao) && <p className="arkhe-atencao">A criação pode ter sido recebida pelo banco. Confira com a Arkhé antes de gerar outra cobrança para esta doação.</p>}
            </article>)}
            {cobrancas.length > limite && <button type="button" onClick={() => setLimite(limite + 10)}>Mostrar mais cobranças</button>}
        </div>}
    </section>;
}
