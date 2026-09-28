import { test } from "node:test";
import assert from "node:assert/strict";
import { filtrarPendencias } from "./filtrarPendencias.js";

const vazios = { busca: "", projeto: "", inicio: "", fim: "", responsavel: "", prioridade: "" };
const itens = [
    { id: 1, descricao: "Manutenção", conta: 0, responsavel_id: null, responsavel_nome: "Sem responsável", prioridade: "Alta", vencimento: "2026-09-01" },
    { id: 2, descricao: "Reforma", conta: 2, responsavel_id: 8, responsavel_nome: "João", prioridade: "Média", vencimento: "2026-09-15" },
    { id: 3, descricao: "Reforma", conta: 2, responsavel_id: 9, responsavel_nome: "João", prioridade: "Baixa", vencimento: "2026-09-30" }
];
const nome = (id) => id === 0 ? "Missão Guadalupe" : "Casa São José";
const filtrar = (filtros) => filtrarPendencias(itens, { ...vazios, ...filtros }, nome).map((item) => item.id);

test("busca ignora acentos e caixa e combina palavras de campos diferentes", () => {
    assert.deepEqual(filtrar({ busca: "  REFORMA joao jose " }), [2, 3]);
    assert.deepEqual(filtrar({ busca: "manutencao" }), [1]);
});
test("combina todos os filtros e inclui os limites do período", () => {
    assert.deepEqual(filtrar({ busca: "reforma", projeto: "2", responsavel: "8", prioridade: "Média", inicio: "2026-09-15", fim: "2026-09-15" }), [2]);
});
test("distingue responsáveis homônimos, projeto zero e ausência de responsável", () => {
    assert.deepEqual(filtrar({ responsavel: "9" }), [3]);
    assert.deepEqual(filtrar({ projeto: "0", responsavel: "sem-responsavel" }), [1]);
});
test("intervalo inválido e busca sem correspondência não retornam resultados", () => {
    assert.deepEqual(filtrar({ inicio: "2026-10-01", fim: "2026-09-01" }), []);
    assert.deepEqual(filtrar({ busca: "inexistente" }), []);
});
test("limpar os filtros restaura todos os itens e aceita limites isolados", () => {
    assert.deepEqual(filtrar({}), [1, 2, 3]);
    assert.deepEqual(filtrar({ inicio: "2026-09-15" }), [2, 3]);
    assert.deepEqual(filtrar({ fim: "2026-09-15" }), [1, 2]);
});
