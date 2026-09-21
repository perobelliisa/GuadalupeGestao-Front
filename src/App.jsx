// Importa as duas páginas disponíveis na aplicação.
import Login from "./pages/Login.jsx";
import Dashboard from "./pages/Dashboard.jsx";
import CadastroUsuario from "./pages/CadastroUsuario.jsx";
import Usuarios from "./pages/Usuarios.jsx";
import Entradas from "./pages/Entradas.jsx";
import NovaEntrada from "./pages/NovaEntrada.jsx";
import Despesas from "./pages/Despesas.jsx";
import NovaDespesa from "./pages/NovaDespesa.jsx";
import LivroCaixa from "./pages/LivroCaixa.jsx";
import Doacoes from "./pages/Doacoes.jsx";
import NovaDoacao from "./pages/NovaDoacao.jsx";
import Emprestimos from "./pages/Emprestimos.jsx";
import NovoEmprestimo from "./pages/NovoEmprestimo.jsx";
import Configuracoes from "./pages/Configuracoes.jsx";
import CentralProjetos from "./pages/Projetos.jsx";
import DocumentosProjetos from "./pages/DocumentosProjetos.jsx";
import Relatorios from "./pages/Relatorios.jsx";
import { useEffect, useState } from "react";
import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";

// Usa o proxy local para que o cookie de autenticação seja enviado em todas as chamadas.
// Centraliza o nome usado para salvar o usuário na sessão do navegador.
const CHAVE_USUARIO = "guadalupe.usuario";

// Recupera os dados públicos do usuário quando a página é recarregada.
function carregarUsuario() {
    try {
        // Procura primeiro na sessão atual e depois no armazenamento persistente.
        const usuarioSalvo = sessionStorage.getItem(CHAVE_USUARIO)
            || localStorage.getItem(CHAVE_USUARIO);

        // Só converte o texto quando realmente existe um usuário salvo.
        return usuarioSalvo ? JSON.parse(usuarioSalvo) : null;
    } catch {
        // Retorna ausência de usuário caso os dados armazenados estejam inválidos.
        return null;
    }
}

function montarOrigens(entradas, despesas) {
    const origens = [];
    const chaves = [];
    const movimentos = entradas.concat(despesas);
    for (let posicao = 0; posicao < movimentos.length; posicao += 1) {
        const origem = String(movimentos[posicao].origem || "").trim();
        const chave = origem.toLocaleLowerCase("pt-BR");
        if (origem && !chaves.includes(chave)) {
            origens.push(origem);
            chaves.push(chave);
        }
    }
    return origens.sort((primeira, segunda) => primeira.localeCompare(segunda, "pt-BR"));
}

// Componente raiz que controla autenticação e navegação.
// Componente raiz: mantém a sessão, carrega os dados e define as rotas.
export default function App({ api }) {
    // Inicializa o estado lendo a sessão apenas na primeira renderização.
    const [usuario, setUsuario] = useState(carregarUsuario);
    const [entradas, setEntradas] = useState([]);
    const [despesas, setDespesas] = useState([]);
    const [doacoes, setDoacoes] = useState([]);
    const [emprestimos, setEmprestimos] = useState([]);
    const [categorias, setCategorias] = useState([]);
    const [projetos, setProjetos] = useState([]);
    const origens = montarOrigens(entradas, despesas);
    // Autoriza a administração de usuários somente para o tipo zero do banco.
    const usuarioAdministrador = Number(usuario?.tipo) === 0;

    useEffect(() => {
        if (!usuario) return undefined;
        const controller = new AbortController();

        async function carregarLivroCaixa() {
            try {
                const respostas = await Promise.all([
                    fetch(`${api}/livro-caixa`, { credentials: "include", signal: controller.signal }),
                    fetch(`${api}/doacoes`, { credentials: "include", signal: controller.signal }),
                    fetch(`${api}/emprestimos`, { credentials: "include", signal: controller.signal }),
                    fetch(`${api}/categorias`, { credentials: "include", signal: controller.signal }),
                    fetch(`${api}/projetos`, { credentials: "include", signal: controller.signal })
                ]);
                const [dadosLivro, dadosDoacoes, dadosEmprestimos, dadosCategorias, dadosProjetos] = await Promise.all(
                    respostas.map((resposta) => resposta.json().catch(() => ({})))
                );
                const movimentacoes = Array.isArray(dadosLivro.movimentacoes) ? dadosLivro.movimentacoes : [];
                const projetosCarregados = Array.isArray(dadosProjetos.projetos) ? dadosProjetos.projetos : [];
                setProjetos(projetosCarregados);
                setEntradas(movimentacoes.filter((item) => Number(item.tipo) === 0).map((item) => ({
                    ...item,
                    projeto_nome: projetosCarregados.find((projeto) => String(projeto.id_projeto) === String(item.conta))?.nome || ""
                })));
                setDespesas(movimentacoes.filter((item) => Number(item.tipo) === 1));
                setDoacoes(Array.isArray(dadosDoacoes.doacoes) ? dadosDoacoes.doacoes : []);
                setEmprestimos(Array.isArray(dadosEmprestimos.emprestimos) ? dadosEmprestimos.emprestimos : []);
                setCategorias(Array.isArray(dadosCategorias.categorias) ? dadosCategorias.categorias : []);
            } catch (error) {
                if (error.name !== "AbortError") console.error("Erro ao carregar livro-caixa", error);
            }
        }

        carregarLivroCaixa();
        return () => controller.abort();
    }, [api, usuario?.id]);

    // Recebe a resposta de sucesso do login e registra somente dados públicos.
    function registrarLogin(dados) {
        // Seleciona os campos necessários para identificar o usuário na interface.
        const usuarioLogado = {
            id: dados.id_usuario,
            nome: dados.nome,
            tipo: dados.tipo
        };

        // Persiste o usuário durante a aba atual, sem armazenar senha ou token.
        sessionStorage.setItem(CHAVE_USUARIO, JSON.stringify(usuarioLogado));
        // Mantém os mesmos dados públicos disponíveis após atualizar a página.
        localStorage.setItem(CHAVE_USUARIO, JSON.stringify(usuarioLogado));
        // Atualiza imediatamente a interface com o usuário autenticado.
        setUsuario(usuarioLogado);
    }

    // Remove uma sessão local quando a API informar que a autenticação expirou.
    function encerrarSessao() {
        sessionStorage.removeItem(CHAVE_USUARIO);
        localStorage.removeItem(CHAVE_USUARIO);
        setUsuario(null);
    }

    async function enviarMovimento(rota, metodo, dados) {
        const formulario = new FormData();
        Object.entries(dados).forEach(([campo, valor]) => {
            if (!["id_livro_caixa", "id_doacao", "id_emprestimo", "projeto_nome"].includes(campo) && valor !== undefined && valor !== null) {
                formulario.append(campo, valor);
            }
        });
        const resposta = await fetch(`${api}${rota}`, { method: metodo, credentials: "include", body: formulario });
        const retorno = await resposta.json().catch(() => ({}));
        if (!resposta.ok || !retorno.sucesso) throw new Error(retorno.mensagem || retorno.erro || "Não foi possível salvar a movimentação.");
        return retorno;
    }

    async function atualizarCategorias() {
        const resposta = await fetch(`${api}/categorias`, { credentials: "include" });
        const dados = await resposta.json().catch(() => ({}));
        if (resposta.ok && Array.isArray(dados.categorias)) setCategorias(dados.categorias);
    }

    async function registrarEntrada(entrada) {
        const retorno = await enviarMovimento("/entradas", "POST", entrada);
        setEntradas((atuais) => [{ ...entrada, id_categoria: retorno.id_categoria, id_livro_caixa: retorno.id_livro_caixa, tipo: 0 }, ...atuais]);
        await atualizarCategorias();
    }

    async function atualizarEntrada(id, dados) {
        const retorno = await enviarMovimento(`/livro-caixa/${id}`, "PUT", dados);
        setEntradas((atuais) => atuais.map((item) => {
            if (item.id_livro_caixa !== id) return item;
            return {
                ...item,
                ...dados,
                id_categoria: retorno.id_categoria ?? item.id_categoria,
                projeto_nome: projetos.find((projeto) => String(projeto.id_projeto) === String(dados.conta))?.nome || ""
            };
        }));
        await atualizarCategorias();
    }

    async function registrarDespesa(despesa) {
        const retorno = await enviarMovimento("/despesas", "POST", despesa);
        setDespesas((atuais) => [{ ...despesa, id_categoria: retorno.id_categoria, id_livro_caixa: retorno.id_livro_caixa, tipo: 1 }, ...atuais]);
        await atualizarCategorias();
    }

    async function atualizarDespesa(id, dados) {
        const retorno = await enviarMovimento(`/livro-caixa/${id}`, "PUT", dados);
        setDespesas((atuais) => atuais.map((item) => item.id_livro_caixa === id ? { ...item, ...dados, id_categoria: retorno.id_categoria ?? item.id_categoria } : item));
        await atualizarCategorias();
    }

    function atualizarUsuarioLogado(dados) {
        const usuarioAtualizado = {
            ...usuario,
            nome: dados.nome,
            tipo: dados.tipo,
            email: dados.email,
            status: dados.status
        };
        sessionStorage.setItem(CHAVE_USUARIO, JSON.stringify(usuarioAtualizado));
        localStorage.setItem(CHAVE_USUARIO, JSON.stringify(usuarioAtualizado));
        setUsuario(usuarioAtualizado);
    }

    async function registrarDoacao(doacao) {
        const retorno = await enviarCadastro("/doacoes", doacao);
        const doacaoSalva = { ...doacao, id_doacao: retorno.id_doacao, anexo: retorno.anexo || "" };
        setDoacoes((atuais) => [doacaoSalva, ...atuais]);

        if (retorno.id_livro_caixa) {
            setEntradas((atuais) => [{
                id_livro_caixa: retorno.id_livro_caixa,
                id_doacao: retorno.id_doacao,
                id_categoria: "",
                descricao: doacao.descricao,
                tipo: 0,
                valor: Number(doacao.valor),
                dia: doacao.dia,
                conta: doacao.id_projeto || 0,
                projeto_nome: doacao.projeto_nome || "",
                origem: doacao.doador,
                forma_pagamento: "",
                observacao: ""
            }, ...atuais]);
        }
    }

    async function atualizarDoacao(id, dados) {
        const retorno = await enviarCadastro(`/doacoes/${id}`, dados, "PUT");
        setDoacoes((atuais) => atuais.map((item) => {
            if (item.id_doacao !== id) return item;
            return { ...item, ...dados, anexo: retorno.anexo || item.anexo };
        }));
        return retorno;
    }

    async function registrarEmprestimo(emprestimo) {
        const retorno = await enviarCadastro("/emprestimos", emprestimo);
        setEmprestimos((atuais) => [{ ...emprestimo, id_emprestimo: retorno.id_emprestimo }, ...atuais]);

        if (retorno.id_livro_caixa) {
            setEntradas((atuais) => [{
                id_livro_caixa: retorno.id_livro_caixa,
                id_emprestimo: retorno.id_emprestimo,
                id_categoria: "",
                descricao: emprestimo.finalidade,
                tipo: 0,
                valor: Number(emprestimo.valor),
                dia: emprestimo.dia,
                vencimento: emprestimo.devolucao,
                conta: "",
                origem: emprestimo.origem,
                forma_pagamento: "",
                observacao: ""
            }, ...atuais]);
        }
    }

    async function atualizarEmprestimo(id, dados) {
        const retorno = await enviarCadastro(`/emprestimos/${id}`, dados, "PUT");
        setEmprestimos((atuais) => atuais.map((item) => item.id_emprestimo === id
            ? { ...item, ...dados, parcelas_pagas: retorno.parcelas_pagas ?? dados.parcelas_pagas ?? item.parcelas_pagas ?? 0 }
            : item));
    }

    async function enviarCadastro(rota, dados, metodo = "POST") {
        const formulario = new FormData();
        Object.entries(dados).forEach(([campo, valor]) => {
            if (!["id_doacao", "id_emprestimo", "projeto_nome"].includes(campo) && valor !== undefined && valor !== null) {
                formulario.append(campo, valor);
            }
        });
        const resposta = await fetch(`${api}${rota}`, { method: metodo, credentials: "include", body: formulario });
        const retorno = await resposta.json().catch(() => ({}));
        if (!resposta.ok || !retorno.sucesso) throw new Error(retorno.mensagem || retorno.erro || "Não foi possível concluir o cadastro.");
        return retorno;
    }

    // Redireciona acessos protegidos para o login explicando o motivo ao usuário.
    const redirecionarParaLogin = (
        <Navigate
            to="/"
            replace
            state={{
                mensagem: {
                    tipo: "erro",
                    texto: "Você precisa estar autenticado para acessar esta página."
                }
            }}
        />
    );

    // Declara as páginas que podem ser acessadas por URL.
    return (
        // Habilita navegação por histórico do navegador.
        <BrowserRouter>
            {/* Agrupa todas as rotas da aplicação. */}
            <Routes>
                {/* Exibe o login na rota inicial e fornece API e callback de sucesso. */}
                <Route
                    path="/"
                    element={<Login apiUrl={api} onLogin={registrarLogin} />}
                />
                {/* Protege a dashboard: sem usuário, volta para o login. */}
                <Route
                    path="/dashboard"
          element={
              usuario
                ? <Dashboard
                    usuario={usuario}
                    entradas={entradas}
                    despesas={despesas}
                    doacoes={doacoes}
                    projetos={projetos}
                    onLogout={encerrarSessao}
                  />
                : redirecionarParaLogin
                    }
                />
                {/* Centraliza os projetos cadastrados e suas movimentações financeiras. */}
                <Route
                    path="/projetos"
                    element={
                        usuario
                            ? <CentralProjetos
                                usuario={usuario}
                                entradas={entradas}
                                despesas={despesas}
                                projetos={projetos}
                                onLogout={encerrarSessao}
                            />
                            : redirecionarParaLogin
                    }
                />
                <Route
                    path="/documentos"
                    element={
                        usuario
                            ? <DocumentosProjetos
                                usuario={usuario}
                                apiUrl={api}
                                projetos={projetos}
                                onLogout={encerrarSessao}
                            />
                            : redirecionarParaLogin
                    }
                />
                <Route
                    path="/relatorios"
                    element={
                        usuario
                            ? <Relatorios
                                usuario={usuario}
                                apiUrl={api}
                                entradas={entradas}
                                despesas={despesas}
                                doacoes={doacoes}
                                emprestimos={emprestimos}
                                projetos={projetos}
                                onLogout={encerrarSessao}
                            />
                            : redirecionarParaLogin
                    }
                />
                <Route
                    path="/entradas"
                    element={
                        usuario
                            ? <Entradas usuario={usuario} apiUrl={api} entradas={entradas} categorias={categorias} projetos={projetos} origens={origens} onAtualizar={atualizarEntrada} onLogout={encerrarSessao} />
                            : redirecionarParaLogin
                    }
                />
                <Route
                    path="/entradas/nova"
                    element={
                        usuario
                            ? <NovaEntrada
                                usuario={usuario}
                                apiUrl={api}
                                categorias={categorias}
                                origens={origens}
                                onRegistrar={registrarEntrada}
                                onLogout={encerrarSessao}
                            />
                            : redirecionarParaLogin
                    }
                />
                <Route
                    path="/despesas"
                    element={
                        usuario
                            ? <Despesas usuario={usuario} apiUrl={api} despesas={despesas} categorias={categorias} projetos={projetos} origens={origens} onAtualizar={atualizarDespesa} onLogout={encerrarSessao} />
                            : redirecionarParaLogin
                    }
                />
                <Route
                    path="/despesas/nova"
                    element={
                        usuario
                            ? <NovaDespesa usuario={usuario} apiUrl={api} categorias={categorias} projetos={projetos} origens={origens} onRegistrar={registrarDespesa} onLogout={encerrarSessao} />
                            : redirecionarParaLogin
                    }
                />
                <Route
                    path="/livro-caixa"
                    element={
                        usuario
                            ? <LivroCaixa
                                usuario={usuario}
                                entradas={entradas}
                                despesas={despesas}
                                categoriasDisponiveis={categorias}
                                projetosDisponiveis={projetos}
                                onLogout={encerrarSessao}
                            />
                            : redirecionarParaLogin
                    }
                />
                <Route
                    path="/doacoes"
                    element={
                        usuario
                            ? <Doacoes usuario={usuario} apiUrl={api} doacoes={doacoes} onAtualizar={atualizarDoacao} onLogout={encerrarSessao} />
                            : redirecionarParaLogin
                    }
                />
                <Route
                    path="/doacoes/nova"
                    element={
                        usuario
                            ? <NovaDoacao usuario={usuario} apiUrl={api} opcoes={{}} onRegistrar={registrarDoacao} onLogout={encerrarSessao} />
                            : redirecionarParaLogin
                    }
                />
                <Route
                    path="/emprestimos"
                    element={
                        usuario
                            ? <Emprestimos usuario={usuario} emprestimos={emprestimos} projetos={projetos} onAtualizar={atualizarEmprestimo} onLogout={encerrarSessao} />
                            : redirecionarParaLogin
                    }
                />
                <Route
                    path="/emprestimos/novo"
                    element={
                        usuario
                            ? <NovoEmprestimo usuario={usuario} apiUrl={api} onRegistrar={registrarEmprestimo} onLogout={encerrarSessao} />
                            : redirecionarParaLogin
                    }
                />
                <Route
                    path="/configuracoes"
                    element={
                        usuario
                            ? <Configuracoes
                                usuario={usuario}
                                apiUrl={api}
                                onUsuarioAtualizado={atualizarUsuarioLogado}
                                onLogout={encerrarSessao}
                            />
                            : redirecionarParaLogin
                    }
                />
                {/* Protege a página de cadastro com a mesma sessão da dashboard. */}
                <Route
                    path="/usuarios"
                    element={
                        usuarioAdministrador
                            ? <Usuarios
                                usuario={usuario}
                                apiUrl={api}
                                onSessaoInvalida={encerrarSessao}
                                onLogout={encerrarSessao}
                            />
                            : usuario
                                ? <Navigate to="/dashboard" replace />
                                : redirecionarParaLogin
                    }
                />
                {/* Mantém o cadastro em uma rota separada da listagem. */}
                <Route
                    path="/usuarios/novo"
                    element={
                        usuarioAdministrador
                            ? <CadastroUsuario
                                usuario={usuario}
                                apiUrl={api}
                                onLogout={encerrarSessao}
                            />
                            : usuario
                                ? <Navigate to="/dashboard" replace />
                                : redirecionarParaLogin
                    }
                />
                {/* Redireciona qualquer endereço desconhecido para a página inicial. */}
                <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
        </BrowserRouter>
  );
}
