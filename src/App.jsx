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

// Componente raiz que controla autenticação e navegação.
export default function App({ api }) {
    // Inicializa o estado lendo a sessão apenas na primeira renderização.
    const [usuario, setUsuario] = useState(carregarUsuario);
    const [entradas, setEntradas] = useState([]);
    const [despesas, setDespesas] = useState([]);
    const [doacoes, setDoacoes] = useState([]);
    const [emprestimos, setEmprestimos] = useState([]);
    const [categorias, setCategorias] = useState([]);
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
                    fetch(`${api}/categorias`, { credentials: "include", signal: controller.signal })
                ]);
                const [dadosLivro, dadosDoacoes, dadosEmprestimos, dadosCategorias] = await Promise.all(
                    respostas.map((resposta) => resposta.json().catch(() => ({})))
                );
                const movimentacoes = Array.isArray(dadosLivro.movimentacoes) ? dadosLivro.movimentacoes : [];
                setEntradas(movimentacoes.filter((item) => Number(item.tipo) === 0));
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
            if (!["id_livro_caixa", "id_doacao", "id_emprestimo"].includes(campo) && valor !== undefined && valor !== null) {
                formulario.append(campo, valor);
            }
        });
        const resposta = await fetch(`${api}${rota}`, { method: metodo, credentials: "include", body: formulario });
        const retorno = await resposta.json().catch(() => ({}));
        if (!resposta.ok || !retorno.sucesso) throw new Error(retorno.mensagem || retorno.erro || "Não foi possível salvar a movimentação.");
        return retorno;
    }

    async function registrarEntrada(entrada) {
        const retorno = await enviarMovimento("/entradas", "POST", entrada);
        setEntradas((atuais) => [{ ...entrada, id_livro_caixa: retorno.id_livro_caixa, tipo: 0 }, ...atuais]);
    }

    async function atualizarEntrada(id, dados) {
        await enviarMovimento(`/livro-caixa/${id}`, "PUT", dados);
        setEntradas((atuais) => atuais.map((item) => item.id_livro_caixa === id ? { ...item, ...dados } : item));
    }

    async function registrarDespesa(despesa) {
        const retorno = await enviarMovimento("/despesas", "POST", despesa);
        setDespesas((atuais) => [{ ...despesa, id_livro_caixa: retorno.id_livro_caixa, tipo: 1 }, ...atuais]);
    }

    async function atualizarDespesa(id, dados) {
        await enviarMovimento(`/livro-caixa/${id}`, "PUT", dados);
        setDespesas((atuais) => atuais.map((item) => item.id_livro_caixa === id ? { ...item, ...dados } : item));
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
        setDoacoes((atuais) => [{ ...doacao, id_doacao: retorno.id_doacao }, ...atuais]);

        if (retorno.id_livro_caixa) {
            setEntradas((atuais) => [{
                id_livro_caixa: retorno.id_livro_caixa,
                id_doacao: retorno.id_doacao,
                id_categoria: "",
                descricao: doacao.descricao,
                tipo: 0,
                valor: Number(doacao.valor),
                dia: doacao.dia,
                conta: "",
                origem: doacao.doador,
                forma_pagamento: "",
                observacao: ""
            }, ...atuais]);
        }
    }

    async function atualizarDoacao(id, dados) {
        await enviarCadastro(`/doacoes/${id}`, dados, "PUT");
        setDoacoes((atuais) => atuais.map((item) => item.id_doacao === id ? { ...item, ...dados } : item));
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
        await enviarCadastro(`/emprestimos/${id}`, dados, "PUT");
        setEmprestimos((atuais) => atuais.map((item) => item.id_emprestimo === id ? { ...item, ...dados } : item));
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
              ? <Dashboard usuario={usuario} onLogout={encerrarSessao} />
              : redirecionarParaLogin
                    }
                />
                <Route
                    path="/entradas"
                    element={
                        usuario
                            ? <Entradas usuario={usuario} apiUrl={api} entradas={entradas} categorias={categorias} onAtualizar={atualizarEntrada} onLogout={encerrarSessao} />
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
                                opcoes={{ categorias }}
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
                            ? <Despesas usuario={usuario} apiUrl={api} despesas={despesas} categorias={categorias} onAtualizar={atualizarDespesa} onLogout={encerrarSessao} />
                            : redirecionarParaLogin
                    }
                />
                <Route
                    path="/despesas/nova"
                    element={
                        usuario
                            ? <NovaDespesa usuario={usuario} apiUrl={api} opcoes={{ categorias }} onRegistrar={registrarDespesa} onLogout={encerrarSessao} />
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
                            ? <Emprestimos usuario={usuario} apiUrl={api} emprestimos={emprestimos} onAtualizar={atualizarEmprestimo} onLogout={encerrarSessao} />
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
