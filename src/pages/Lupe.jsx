import { useEffect, useLayoutEffect, useRef, useState } from "react";
import { Mic, MicOff, PanelLeft, Plus, RefreshCw, Send, Trash2, X } from "lucide-react";
import Sidebar from "../../components/Sidebar.jsx";
import { carregarConversa, conversar, criarConversa, decidirAcao, excluirConversa, listarAcoes, listarConversas, salvarConversa } from "../services/lupe.js";
import AcoesLupe from "./AcoesLupe.jsx";
import "./Lupe.css";
import { montarMensagensLupe } from "../services/mensagensLupe.js";

function TextoResposta({ texto }) {
    return texto.split(/(\*\*[\s\S]+?\*\*)/g).map((parte, indice) => indice % 2 ? <strong key={indice}>{parte.slice(2, -2)}</strong> : parte);
}

export default function Lupe({ usuario, onLogout, onAlteracaoSistema }) {
    const [conversa, setConversa] = useState(criarConversa);
    const mensagensVisiveis = montarMensagensLupe(conversa);
    const [historico, setHistorico] = useState([]);
    const [acoes, setAcoes] = useState([]);
    const [texto, setTexto] = useState("");
    const [ouvindo, setOuvindo] = useState(false);
    const [pendente, setPendente] = useState("");
    const [enviando, setEnviando] = useState(false);
    const [operando, setOperando] = useState(false);
    const [pronto, setPronto] = useState(false);
    const [erro, setErro] = useState("");
    const [avisoAcao, setAvisoAcao] = useState("");
    const [erroSalvar, setErroSalvar] = useState(null);
    const [historicoAberto, setHistoricoAberto] = useState(false);
    const ocupado = useRef(false);
    const montado = useRef(true);
    const atual = useRef(conversa);
    const naoSalva = useRef(false);
    const fim = useRef(null);
    const entrada = useRef(null);
    const reconhecimento = useRef(null);
    const botaoHistorico = useRef(null);
    const fecharHistorico = useRef(null);
    const geracao = useRef(0);
    const prontoAtual = useRef(pronto);
    const atualizarFinanceiro = useRef(onAlteracaoSistema);
    atualizarFinanceiro.current = onAlteracaoSistema;
    useEffect(() => { if (conversa.revisaoAvisos) atualizarFinanceiro.current?.(); }, [conversa.id, conversa.revisaoAvisos]);
    atual.current = conversa;
    naoSalva.current = Boolean(erroSalvar);
    prontoAtual.current = pronto;
    const textoAtual = useRef(texto);
    const ultimoAvisoVisto = useRef(0);
    textoAtual.current = texto;
    ultimoAvisoVisto.current = Math.max(ultimoAvisoVisto.current, conversa.revisaoAvisos || 0);

    useEffect(() => { setAvisoAcao(""); }, [conversa.id]);

    useEffect(() => {
        if (!avisoAcao) return;
        const timer = setTimeout(() => setAvisoAcao(""), 12000);
        return () => clearTimeout(timer);
    }, [avisoAcao]);

    async function atualizar() {
        if (ocupado.current || naoSalva.current) return;
        ocupado.current = true;
        geracao.current++;
        setOperando(true);
        setErro("");
        try {
            const lista = await listarConversas(usuario.id);
            const selecionada = atual.current;
            const recebimento = !prontoAtual.current && !selecionada.mensagens.length && lista[0]?.revisaoAvisos > 0 && lista[0];
            const idSelecionado = recebimento ? recebimento.id : selecionada.id;
            const [salva, propostas] = await Promise.all([
                recebimento || (selecionada.mensagens.length && lista.some(item => item.id === selecionada.id)) ? carregarConversa(usuario.id, idSelecionado) : null,
                listarAcoes(usuario.id, idSelecionado),
            ]);
            if (!montado.current) return;
            setHistorico(lista);
            if (salva) setConversa(salva);
            setAcoes(propostas);
            setPronto(true);
        } catch (falha) {
            if (montado.current) setErro(falha.message);
        } finally {
            ocupado.current = false;
            if (montado.current) setOperando(false);
        }
    }

    useEffect(() => {
        montado.current = true;
        atualizar();
        return () => {
            montado.current = false;
            reconhecimento.current?.stop();
            reconhecimento.current = null;
        };
    }, [usuario.id]);

    useEffect(() => {
        let encerrado = false;
        let consultando = false;
        let timer;
        const ativo = () => !encerrado && !document.hidden;
        async function sincronizar() {
            clearTimeout(timer);
            if (!ativo() || consultando) return;
            consultando = true;
            const versao = geracao.current;
            const selecionada = atual.current;
            const podeAplicar = () => ativo() && montado.current && !ocupado.current && !naoSalva.current && geracao.current === versao && atual.current.id === selecionada.id;
            try {
                if (ocupado.current || naoSalva.current) return;
                const [lista, propostas] = await Promise.all([listarConversas(usuario.id), listarAcoes(usuario.id, selecionada.id)]);
                const novoRecebimento = !selecionada.mensagens.length && !selecionada.revisao && !textoAtual.current.trim() && lista[0]?.revisaoAvisos > ultimoAvisoVisto.current && lista[0];
                if (novoRecebimento) {
                    const recebida = await carregarConversa(usuario.id, novoRecebimento.id);
                    if (podeAplicar() && !textoAtual.current.trim()) { setHistorico(lista); setConversa(recebida); setAcoes([]); }
                    return;
                }
                const item = lista.find(item => item.id === selecionada.id);
                const salva = item && (item.revisao !== selecionada.revisao || (item.revisaoAvisos || 0) !== (selecionada.revisaoAvisos || 0))
                    ? await carregarConversa(usuario.id, selecionada.id) : null;
                if (!podeAplicar()) return;
                setHistorico(lista);
                setAcoes(propostas);
                if (salva) setConversa(salva);
                else if (!item && selecionada.revisao > 0) { setConversa(criarConversa()); setAcoes([]); }
                if (!prontoAtual.current) { setPronto(true); setErro(""); }
            } catch {
                // Mantém a conversa e o rascunho; uma falha temporária será tentada novamente.
            } finally {
                consultando = false;
                if (ativo()) timer = setTimeout(sincronizar, 4000);
            }
        }
        function retomar() {
            if (document.hidden) { geracao.current++; clearTimeout(timer); }
            else sincronizar();
        }
        timer = setTimeout(sincronizar, 4000);
        window.addEventListener("focus", retomar);
        window.addEventListener("online", retomar);
        document.addEventListener("visibilitychange", retomar);
        return () => {
            encerrado = true;
            clearTimeout(timer);
            window.removeEventListener("focus", retomar);
            window.removeEventListener("online", retomar);
            document.removeEventListener("visibilitychange", retomar);
        };
    }, [usuario.id]);

    useEffect(() => { fim.current?.scrollIntoView({ behavior: "smooth", block: "nearest" }); }, [conversa.id, conversa.mensagens.length, conversa.revisaoAvisos, pendente, acoes.length]);

    function ajustarEntrada() {
        const campo = entrada.current;
        if (!campo) return;
        campo.style.height = "auto";
        const altura = campo.scrollHeight;
        campo.style.height = Math.min(altura, 176) + "px";
        campo.style.overflowY = altura > 176 ? "auto" : "hidden";
    }

    useLayoutEffect(ajustarEntrada, [texto]);
    useEffect(() => {
        window.addEventListener("resize", ajustarEntrada);
        return () => window.removeEventListener("resize", ajustarEntrada);
    }, []);

    useEffect(() => {
        if (!historicoAberto) return;
        fecharHistorico.current?.focus();
        function fechar(event) {
            if (event.key === "Escape") {
                setHistoricoAberto(false);
                botaoHistorico.current?.focus();
            }
        }
        window.addEventListener("keydown", fechar);
        return () => window.removeEventListener("keydown", fechar);
    }, [historicoAberto]);

    async function guardar(nova) {
        try {
            const resultado = await salvarConversa(usuario.id, nova);
            if (montado.current) {
                if (nova.id !== atual.current.id) setAcoes([]);
                setConversa(resultado.conversa);
                setHistorico(resultado.conversas);
                setErroSalvar(null);
            }
        } catch (falha) {
            if (montado.current) setErroSalvar({ conflito: falha.status === 409, texto: falha.status === 409
                ? "Esta conversa mudou em outro dispositivo. Salve sua resposta como uma nova conversa para preservar as duas versões."
                : "A resposta chegou, mas não foi possível sincronizar. Mantenha a tela aberta e tente salvar novamente." });
        }
    }

    async function enviar(event, sugestao) {
        event?.preventDefault();
        const mensagem = (sugestao ?? texto).trim();
        if (!mensagem || mensagem.length > 2000 || ocupado.current || erroSalvar || !pronto) return;
        ocupado.current = true;
        geracao.current++;
        setEnviando(true);
        setErro("");
        setAvisoAcao("");
        setTexto("");
        setPendente(mensagem);
        try {
            const resultado = await conversar(usuario.id, mensagem, conversa.mensagens, conversa.id);
            const nova = { ...conversa, atualizadaEm: new Date().toISOString(), mensagens: [...conversa.mensagens, { papel: "usuario", texto: mensagem }, { papel: "lupe", texto: resultado.resposta }] };
            if (montado.current) { setConversa(nova); setPendente(""); setAcoes(resultado.acoes); setAvisoAcao(""); }
            await guardar(nova);
        } catch (falha) {
            if (montado.current) { setTexto(mensagem); setErro(falha.message); }
        } finally {
            ocupado.current = false;
            if (montado.current) { setEnviando(false); setPendente(""); }
        }
    }

    function alternarMicrofone() {
        if (reconhecimento.current) {
            reconhecimento.current.stop();
            return;
        }

        const ReconhecimentoDeFala = window.SpeechRecognition || window.webkitSpeechRecognition;
        if (!ReconhecimentoDeFala) {
            setErro("O reconhecimento de voz não está disponível neste navegador. Tente usar Chrome ou Edge.");
            return;
        }

        const fala = new ReconhecimentoDeFala();
        fala.lang = "pt-BR";
        fala.continuous = false;
        fala.interimResults = false;
        fala.maxAlternatives = 1;
        fala.onstart = () => {
            if (montado.current) { setOuvindo(true); setErro(""); }
        };
        fala.onresult = event => {
            const transcricao = Array.from(event.results)
                .filter(resultado => resultado.isFinal)
                .map(resultado => resultado[0]?.transcript || "")
                .join(" ")
                .trim();
            if (!transcricao) {
                if (montado.current) setErro("Não consegui reconhecer a fala. Tente novamente.");
                return;
            }
            if (montado.current) setTexto(transcricao);
            // A fala vira texto no navegador e segue pelo mesmo caminho do chat escrito.
            void enviar(null, transcricao);
        };
        fala.onerror = event => {
            if (!montado.current || event.error === "aborted") return;
            const mensagens = {
                "not-allowed": "Permita o acesso ao microfone nas configurações do navegador.",
                "service-not-allowed": "O serviço de reconhecimento de voz não está disponível.",
                "no-speech": "Não detectei uma fala. Tente novamente.",
                "audio-capture": "Não encontrei um microfone disponível.",
            };
            setErro(mensagens[event.error] || "Não foi possível reconhecer o áudio. Tente novamente.");
        };
        fala.onend = () => {
            if (reconhecimento.current === fala) reconhecimento.current = null;
            if (montado.current) setOuvindo(false);
        };

        reconhecimento.current = fala;
        try {
            fala.start();
        } catch {
            reconhecimento.current = null;
            setOuvindo(false);
            setErro("Não consegui iniciar o microfone. Tente novamente.");
        }
    }

    async function tentarSalvar() {
        if (ocupado.current) return;
        ocupado.current = true;
        geracao.current++;
        setOperando(true);
        try { await guardar(erroSalvar?.conflito ? { ...conversa, id: criarConversa().id, revisao: 0 } : conversa); }
        finally { ocupado.current = false; if (montado.current) setOperando(false); }
    }

    async function abrir(id) {
        if (ocupado.current || erroSalvar) return;
        ocupado.current = true;
        geracao.current++;
        setOperando(true);
        setErro("");
        try {
            const [salva, propostas] = await Promise.all([carregarConversa(usuario.id, id), listarAcoes(usuario.id, id)]);
            if (montado.current) { setConversa(salva); setAcoes(propostas); setTexto(""); setHistoricoAberto(false); }
        } catch (falha) { if (montado.current) setErro(falha.message); }
        finally { ocupado.current = false; if (montado.current) setOperando(false); }
    }

    async function excluir(item) {
        if (ocupado.current || erroSalvar || !window.confirm("Excluir esta conversa da sua conta em todos os dispositivos?")) return;
        ocupado.current = true;
        geracao.current++;
        setOperando(true);
        setErro("");
        try {
            const lista = await excluirConversa(usuario.id, item.id);
            if (!montado.current) return;
            setHistorico(lista);
            if (conversa.id === item.id) { setConversa(criarConversa()); setAcoes([]); setTexto(""); }
        } catch (falha) { if (montado.current) setErro(falha.message); }
        finally { ocupado.current = false; if (montado.current) setOperando(false); }
    }

    async function responderProposta(acao, confirmar) {
        if (ocupado.current || erroSalvar || acao.conversa_id !== conversa.id) return;
        ocupado.current = true;
        geracao.current++;
        setOperando(true);
        setErro("");
        setAvisoAcao("");
        try {
            const resultado = await decidirAcao(usuario.id, acao.id, confirmar);
            if (montado.current) setAcoes(atuais => atuais.map(item => item.id === acao.id ? resultado.acao : item));
            if (confirmar && ['concluida', 'incerta'].includes(resultado.acao.estado)) onAlteracaoSistema?.();
            if (!['concluida', 'cancelada'].includes(resultado.acao.estado)) {
                if (montado.current) setAvisoAcao(resultado.resposta);
            }
            const salva = resultado.conversa || await carregarConversa(usuario.id, conversa.id);
            if (montado.current) setConversa(salva);
        } catch (falha) {
            if (montado.current) setAvisoAcao(falha.message);
            try {
                const propostas = await listarAcoes(usuario.id, conversa.id);
                if (montado.current) setAcoes(propostas);
            } catch { /* Não repete confirmações automaticamente. */ }
        } finally {
            ocupado.current = false;
            if (montado.current) setOperando(false);
        }
    }

    const bloqueado = enviando || operando;
    return <div className="app lupe-app"><Sidebar paginaAtiva="Lupe" tipoUsuario={usuario.tipo} onLogout={onLogout} /><main className="lupe-layout">
        {historicoAberto && <button className="lupe-overlay" aria-label="Fechar histórico" onClick={() => setHistoricoAberto(false)} />}
        <aside id="lupe-historico" className={`lupe-historico ${historicoAberto ? "lupe-historico-aberto" : ""}`} aria-label="Histórico de conversas">
            <div className="lupe-historico-topo"><h2>Conversas</h2><button ref={fecharHistorico} className="lupe-icone lupe-fechar-historico" aria-label="Fechar histórico" onClick={() => setHistoricoAberto(false)}><X size={20} /></button></div>
            <div className="lupe-lista-conversas">
                {!historico.length && <p className="lupe-vazio">Nenhuma conversa ainda</p>}
                {historico.map(item => <div className={`lupe-item ${conversa.id === item.id ? "lupe-item-ativo" : ""}`} key={item.id}>
                    <button className="lupe-abrir" title={item.titulo} disabled={bloqueado || !!erroSalvar} onClick={() => abrir(item.id)} aria-current={conversa.id === item.id ? "true" : undefined}>{item.titulo}</button>
                    <button className="lupe-excluir lupe-icone" aria-label={`Excluir conversa: ${item.titulo}`} title="Excluir conversa" disabled={bloqueado || !!erroSalvar} onClick={() => excluir(item)}><Trash2 size={16} /></button>
                </div>)}
            </div>
        </aside>
        <section className="lupe-chat" aria-label="Chat com a Lupe">
            <header className="lupe-cabecalho">
                <img className="lupe-marca" src="/Lupe.png" alt="" /><h1>Lupe</h1>
                <div className="lupe-acoes">
                    <button ref={botaoHistorico} className="lupe-nova lupe-ver-historico" aria-label="Ver histórico" title="Ver histórico" aria-expanded={historicoAberto} aria-controls="lupe-historico" onClick={() => setHistoricoAberto(true)}><PanelLeft size={19} /><span>Ver histórico</span></button>
                    <button className="lupe-nova" aria-label="Nova conversa" title="Nova conversa" disabled={bloqueado || !!erroSalvar} onClick={() => { geracao.current++; setConversa(criarConversa()); setAcoes([]); setTexto(""); setErro(""); setHistoricoAberto(false); }}><Plus size={18} /><span>Nova conversa</span></button>
                    <button className="lupe-icone" aria-label="Atualizar conversas" title="Atualizar conversas" disabled={bloqueado || !!erroSalvar} onClick={atualizar}><RefreshCw size={18} className={operando ? "lupe-girando" : undefined} /></button>
                </div>
            </header>
            <div className="lupe-mensagens">
                {!mensagensVisiveis.length && !pendente && <div className="lupe-boas-vindas"><img className="lupe-mascote" src="/Lupe.png" alt="Lupe" /><h2>Como posso ajudar?</h2></div>}
                {mensagensVisiveis.map(mensagem => <article key={mensagem.chave} className={`lupe-balao lupe-${mensagem.papel}`} aria-label={mensagem.papel === "lupe" ? "Lupe" : "Você"}><div>{mensagem.papel === "lupe" ? <TextoResposta texto={mensagem.texto} /> : mensagem.texto}</div></article>)}
                {!!pendente && <article className="lupe-balao lupe-usuario" aria-label="Você"><div>{pendente}</div></article>}
                <AcoesLupe acoes={acoes} ocupado={bloqueado || !!erroSalvar} onDecidir={responderProposta} />
                <div className="lupe-status" role="status">{enviando && <><span className="lupe-pontos" aria-hidden="true"><i /><i /><i /></span><span className="lupe-sr-only">Lupe está respondendo...</span></>}</div><div ref={fim} />
            </div>
            {!!erro && <div className="lupe-erro" role="alert">{erro}{!pronto && <button disabled={bloqueado} onClick={atualizar}>Tentar novamente</button>}</div>}
            {!!avisoAcao && <div className="lupe-aviso-acao" role="alert"><span>{avisoAcao}</span><button aria-label="Fechar aviso" onClick={() => setAvisoAcao("")}>×</button></div>}
            {!!erroSalvar && <div className="lupe-erro" role="alert">{erroSalvar.texto}<button disabled={bloqueado} onClick={tentarSalvar}>{erroSalvar.conflito ? "Salvar como nova conversa" : "Tentar salvar conversa"}</button></div>}
            <form className="lupe-compositor" onSubmit={enviar}>
                <div className="lupe-campo">
                    <textarea ref={entrada} id="lupe-mensagem" aria-label="Mensagem para a Lupe" placeholder="Digite uma mensagem" maxLength={2000} rows={1} value={texto} onChange={event => setTexto(event.target.value)} onKeyDown={event => {
                        if (event.key === "Enter" && !event.shiftKey && !event.nativeEvent.isComposing) enviar(event);
                    }} disabled={bloqueado || !pronto} />
                    <button type="button" className={`lupe-microfone ${ouvindo ? "lupe-microfone-ouvindo" : ""}`} aria-label={ouvindo ? "Parar de ouvir" : "Enviar mensagem por áudio"} title={ouvindo ? "Parar de ouvir" : "Enviar mensagem por áudio"} aria-pressed={ouvindo} disabled={bloqueado || !pronto} onClick={alternarMicrofone}>{ouvindo ? <MicOff size={20} /> : <Mic size={20} />}</button>
                    <button type="submit" className="lupe-enviar" aria-label="Enviar mensagem" title="Enviar mensagem" disabled={bloqueado || !pronto || !texto.trim()}><Send size={20} /></button>
                </div>
                {ouvindo && <span className="lupe-voz-status" role="status">Ouvindo… fale sua mensagem.</span>}
            </form>
        </section>
    </main></div>;
}

