// Importa as duas páginas disponíveis na aplicação.
import Login from "./pages/Login.jsx";
import Dashboard from "./pages/Dashboard.jsx";
// Importa a página administrativa de criação de usuários.
import CadastroUsuario from "./pages/CadastroUsuario.jsx";
// Importa a página que lista os usuários cadastrados.
import Usuarios from "./pages/Usuarios.jsx";
// useState mantém o usuário autenticado enquanto a aplicação está aberta.
import { useState } from "react";
// Componentes do React Router controlam as URLs e os redirecionamentos.
import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";

// Define a URL da API pelo ambiente e usa o servidor local apenas como alternativa.
const API_URL = import.meta.env.VITE_API_URL || "http://localhost:5000";
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
export default function App() {
    // Inicializa o estado lendo a sessão apenas na primeira renderização.
    const [usuario, setUsuario] = useState(carregarUsuario);
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

    // Declara as páginas que podem ser acessadas por URL.
    return (
        // Habilita navegação por histórico do navegador.
        <BrowserRouter>
            {/* Agrupa todas as rotas da aplicação. */}
            <Routes>
                {/* Exibe o login na rota inicial e fornece API e callback de sucesso. */}
                <Route
                    path="/"
                    element={<Login apiUrl={API_URL} onLogin={registrarLogin} />}
                />
                {/* Protege a dashboard: sem usuário, volta para o login. */}
                <Route
                    path="/dashboard"
          element={
            usuario
              ? <Dashboard usuario={usuario} />
              : <Navigate to="/" replace />
                    }
                />
                {/* Protege a página de cadastro com a mesma sessão da dashboard. */}
                <Route
                    path="/usuarios"
                    element={
                        usuarioAdministrador
                            ? <Usuarios usuario={usuario} apiUrl={API_URL} />
                            : <Navigate to={usuario ? "/dashboard" : "/"} replace />
                    }
                />
                {/* Mantém o cadastro em uma rota separada da listagem. */}
                <Route
                    path="/usuarios/novo"
                    element={
                        usuarioAdministrador
                            ? <CadastroUsuario usuario={usuario} apiUrl={API_URL} />
                            : <Navigate to={usuario ? "/dashboard" : "/"} replace />
                    }
                />
                {/* Redireciona qualquer endereço desconhecido para a página inicial. */}
                <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
        </BrowserRouter>
  );
}
