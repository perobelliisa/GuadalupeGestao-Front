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
import { useState } from "react";
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
    // Autoriza a administração de usuários somente para o tipo zero do banco.
    const usuarioAdministrador = Number(usuario?.tipo) === 0;

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

    function registrarEntrada(entrada) {
        setEntradas((atuais) => [entrada, ...atuais]);
    }

    function atualizarEntrada(id, dados) {
        setEntradas((atuais) => atuais.map((item) => item.id === id ? { ...item, ...dados } : item));
    }

    function excluirEntrada(id) {
        setEntradas((atuais) => atuais.filter((item) => item.id !== id));
    }

    function registrarDespesa(despesa) {
        setDespesas((atuais) => [despesa, ...atuais]);
    }

    function atualizarDespesa(id, dados) {
        setDespesas((atuais) => atuais.map((item) => item.id === id ? { ...item, ...dados } : item));
    }

    function excluirDespesa(id) {
        setDespesas((atuais) => atuais.filter((item) => item.id !== id));
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
                            ? <Entradas usuario={usuario} apiUrl={api} entradas={entradas} onAtualizar={atualizarEntrada} onExcluir={excluirEntrada} onLogout={encerrarSessao} />
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
                                opcoes={{}}
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
                            ? <Despesas usuario={usuario} apiUrl={api} despesas={despesas} onAtualizar={atualizarDespesa} onExcluir={excluirDespesa} onLogout={encerrarSessao} />
                            : redirecionarParaLogin
                    }
                />
                <Route
                    path="/despesas/nova"
                    element={
                        usuario
                            ? <NovaDespesa usuario={usuario} apiUrl={api} opcoes={{}} onRegistrar={registrarDespesa} onLogout={encerrarSessao} />
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
