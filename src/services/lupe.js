import { API_URL } from "../config/api.js";

export function criarConversa() {
    const agora = new Date().toISOString();
    return { id: globalThis.crypto?.randomUUID?.() || Date.now().toString(36) + "-" + Math.random().toString(36).slice(2), criadaEm: agora, atualizadaEm: agora, revisao: 0, mensagens: [] };
}

async function solicitar(usuarioId, caminho, opcoes = {}) {
    const controle = new AbortController();
    const tempo = setTimeout(() => controle.abort(), caminho === "/chat" ? 120000 : 60000);
    try {
        const resposta = await fetch(`${API_URL}/lupe${caminho}`, {
            ...opcoes, credentials: "include", signal: controle.signal,
            headers: { "Content-Type": "application/json", "X-Lupe-Usuario": String(usuarioId) },
        });
        const dados = await resposta.json().catch(() => ({}));
        if (!resposta.ok || dados.sucesso !== true) {
            const erro = new Error(dados.mensagem || (resposta.status === 404 ? "Atualize e reinicie o backend para acessar a Lupe e seu histórico." : "Não foi possível acessar a Lupe. Tente novamente."));
            erro.status = resposta.status;
            throw erro;
        }
        return dados;
    } catch (erro) {
        if (erro.name === "AbortError") throw new Error("A Lupe demorou para responder. Tente novamente.");
        if (erro instanceof TypeError) throw new Error("Não foi possível conectar ao servidor. Confira sua conexão.");
        throw erro;
    } finally { clearTimeout(tempo); }
}

export async function listarConversas(usuarioId) {
    const dados = await solicitar(usuarioId, "/conversas");
    if (!Array.isArray(dados.conversas)) throw new Error("O histórico retornado é inválido.");
    return dados.conversas;
}

export async function carregarConversa(usuarioId, id) {
    const dados = await solicitar(usuarioId, "/conversas/" + encodeURIComponent(id));
    if (!dados.conversa || !Array.isArray(dados.conversa.mensagens)) throw new Error("A conversa retornada é inválida.");
    return dados.conversa;
}

export function salvarConversa(usuarioId, conversa) {
    return solicitar(usuarioId, "/conversas/" + encodeURIComponent(conversa.id), { method: "PUT", body: JSON.stringify(conversa) });
}

export async function excluirConversa(usuarioId, id) {
    return (await solicitar(usuarioId, "/conversas/" + encodeURIComponent(id), { method: "DELETE" })).conversas;
}

export async function conversar(usuarioId, texto, historico, conversaId) {
    const mensagens = [...historico.slice(-20).map(item => ({ papel: item.papel, texto: item.texto })), { papel: "usuario", texto: texto.trim() }];
    while (mensagens.length > 1 && mensagens.reduce((soma, item) => soma + item.texto.length, 0) > 40000) mensagens.splice(0, 2);
    const dados = await solicitar(usuarioId, "/chat", { method: "POST", body: JSON.stringify({ mensagens, conversa_id: conversaId }) });
    if (typeof dados.resposta !== "string" || !dados.resposta.trim()) throw new Error("A Lupe não conseguiu responder. Tente novamente.");
    return { resposta: dados.resposta.trim(), acoes: Array.isArray(dados.acoes) ? dados.acoes : [] };
}

export async function listarAcoes(usuarioId, conversaId) {
    const dados = await solicitar(usuarioId, "/acoes?conversa_id=" + encodeURIComponent(conversaId));
    if (!Array.isArray(dados.acoes)) throw new Error("Não foi possível carregar as propostas da Lupe.");
    return dados.acoes;
}

export function decidirAcao(usuarioId, id, confirmar) {
    return solicitar(usuarioId, "/acoes/" + encodeURIComponent(id) + (confirmar ? "/confirmar" : "/cancelar"), { method: "POST", body: JSON.stringify(confirmar ? { confirmar: true } : {}) });
}
