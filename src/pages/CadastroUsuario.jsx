// Importa os componentes compartilhados com a dashboard.
// Esta página contém o formulário de cadastro de um usuário do sistema.
import Sidebar from "../../components/Sidebar.jsx";
import Header from "../../components/Header.jsx";
// Importa o ícone exibido no botão principal.
import { UserPlus } from "lucide-react";
// useEffect carrega os projetos e useState controla os dados da interface.
import { useEffect, useState } from "react";
// useNavigate abre a listagem depois do cadastro concluído.
import { useNavigate } from "react-router-dom";
// Importa a estrutura compartilhada, as cores globais e os estilos da página.
import "./Dashboard.css";
import "./CadastroUsuario.css";

// Exibe o formulário e recebe o usuário autenticado e o endereço central da API.
export default function CadastroUsuario({ usuario, apiUrl, onLogout }) {

    // Cria a função de navegação entre páginas.
    const navigate = useNavigate();
    // Guarda a mensagem amigável de sucesso ou erro.
    const [mensagem, setMensagem] = useState(null);
    // Bloqueia novos envios enquanto o cadastro está sendo processado.
    const [carregando, setCarregando] = useState(false);
    // Guarda o perfil escolhido para controlar as permissões exibidas.
    const [tipo, setTipo] = useState("0");
    // Armazena os projetos reais devolvidos pelo backend.
    const [projetos, setProjetos] = useState([]);
    // Guarda uma falha amigável caso os projetos não possam ser carregados.
    const [erroProjetos, setErroProjetos] = useState("");

    // Busca as opções de projeto existentes no banco ao abrir a página.
    useEffect(() => {
        const controller = new AbortController();

        async function carregarProjetos() {
            try {
                const resposta = await fetch(`${apiUrl}/projetos`, {
                    credentials: "include",
                    signal: controller.signal
                });
                const dados = await resposta.json().catch(() => ({}));

                if (!resposta.ok || !dados.sucesso) {
                    throw new Error(
                        dados.mensagem || dados.erro || "O servidor não informou o motivo do erro."
                    );
                }

                setProjetos(Array.isArray(dados.projetos) ? dados.projetos : []);
            } catch (error) {
                if (error.name !== "AbortError") {
                    setErroProjetos(error.message);
                }
            }
        }

        carregarProjetos();

        return () => controller.abort();
    }, [apiUrl]);

    // Envia os campos no formato multipart/form-data esperado pelo Flask.
    async function cadastrarUsuario(event) {
        event.preventDefault();

        // Mantém a referência para limpar o formulário depois do sucesso.
        const formulario = event.currentTarget;
        // FormData usa diretamente os atributos name de todos os campos.
        const dadosFormulario = new FormData(formulario);

        // Remove retorno antigo e sinaliza o início da requisição.
        setMensagem(null);
        setCarregando(true);

        try {
            // Chama o endpoint de cadastro sem definir Content-Type manualmente.
            const resposta = await fetch(`${apiUrl}/cadastro`, {
                method: "POST",
                credentials: "include",
                body: dadosFormulario
            });

            // Evita erro técnico quando o servidor não responder em JSON.
            const dados = await resposta.json().catch(() => ({}));

            // Considera tanto o status HTTP quanto o campo sucesso da API.
            if (!resposta.ok || !dados.sucesso) {
                const mensagemDaApi = dados.mensagem || dados.erro;
                throw new Error(mensagemDaApi || "O servidor não informou o motivo do erro.");
            }

            // Informa o sucesso usando preferencialmente a mensagem do backend.
            setMensagem({
                tipo: "sucesso",
                texto: dados.mensagem
            });

            // Limpa todos os campos depois que o backend confirmar o cadastro.
            formulario.reset();
            // Volta o perfil controlado para a opção inicial do formulário.
            setTipo("0");
            // Aguarda a mensagem de sucesso e abre a lista atualizada.
            await new Promise((resolve) => setTimeout(resolve, 900));
            navigate("/usuarios", {
                replace: true,
                state: { mensagem: dados.mensagem }
            });
        } catch (error) {
            // Transforma falha de conexão em uma orientação legível.
            const texto = error instanceof TypeError
                ? "Não foi possível conectar ao servidor. Verifique se a API está ligada."
                : error.message;

            setMensagem({
                tipo: "erro",
                texto: texto || "Ocorreu um problema ao criar o usuário."
            });
        } finally {
            // Libera o botão independentemente do resultado.
            setCarregando(false);
        }
    }

    // Monta a página usando a mesma estrutura visual da dashboard.
    return (
        <div className="app">

            {/* Mantém o item Usuários destacado no menu lateral. */}
            <Sidebar paginaAtiva="Usuários" tipoUsuario={usuario.tipo} onLogout={onLogout} />

            {/* Agrupa o cabeçalho e o conteúdo da página. */}
            <div className="main">

                {/* Exibe o usuário autenticado, sem nome fixo. */}
                <Header usuario={usuario} />

                {/* Área principal do cadastro. */}
                <main className="cadastro-usuario-content">

                    {/* Cabeçalho da página com título, descrição e ação principal. */}
                    <div className="cadastro-usuario-header">
                        <div>
                            <h1>Novo usuário</h1>
                            <p>Crie uma nova conta de acesso à plataforma</p>
                        </div>

                        {/* Envia o formulário identificado pelo atributo form. */}
                        <button
                            type="submit"
                            form="form-novo-usuario"
                            className="btn-criar-usuario"
                            disabled={carregando}
                        >
                            <UserPlus size={15} />
                            {carregando ? "Criando..." : "Criar usuário"}
                        </button>
                    </div>

                    {/* Formulário preparado para a futura integração com a API. */}
                    <form
                        id="form-novo-usuario"
                        className="cadastro-usuario-form"
                        onSubmit={cadastrarUsuario}
                        noValidate
                    >

                        {/* Primeiro painel com os dados principais da conta. */}
                        <section className="cadastro-panel">
                            <h2>Dados de acesso</h2>

                            {/* Campo obrigatório para o nome completo. */}
                            <div className="cadastro-field cadastro-field-full">
                                <label htmlFor="nome">
                                    Nome <span>*</span>
                                </label>
                                <input
                                    id="nome"
                                    name="nome"
                                    type="text"
                                    autoComplete="name"
                                    required
                                />
                            </div>

                            {/* Campo obrigatório para o e-mail da conta. */}
                            <div className="cadastro-field cadastro-field-full">
                                <label htmlFor="email">
                                    E-mail <span>*</span>
                                </label>
                                <input
                                    id="email"
                                    name="email"
                                    type="email"
                                    autoComplete="email"
                                    required
                                />
                            </div>

                            {/* Organiza senha e confirmação lado a lado em telas maiores. */}
                            <div className="cadastro-fields-row">
                                <div className="cadastro-field">
                                    <label htmlFor="senha">
                                        Senha <span>*</span>
                                    </label>
                                    <input
                                        id="senha"
                                        name="senha"
                                        type="password"
                                        autoComplete="new-password"
                                        minLength="10"
                                        required
                                    />
                                    <small>
                                        Use 10 caracteres, com maiúscula, minúscula, número e símbolo.
                                    </small>
                                </div>

                                <div className="cadastro-field">
                                    <label htmlFor="conf_senha">
                                        Confirmar senha <span>*</span>
                                    </label>
                                    <input
                                        id="conf_senha"
                                        name="conf_senha"
                                        type="password"
                                        autoComplete="new-password"
                                        minLength="10"
                                        required
                                    />
                                </div>
                            </div>

                            {/* Usa os padrões aceitos pelo backend até existirem listas próprias. */}
                            <div className="cadastro-fields-row">
                                <div className="cadastro-field">
                                    <label htmlFor="tipo">
                                        Perfil de acesso <span>*</span>
                                    </label>
                                    <select
                                        id="tipo"
                                        name="tipo"
                                        value={tipo}
                                        onChange={(event) => setTipo(event.target.value)}
                                        required
                                    >
                                        <option value="0">Adm geral</option>
                                        <option value="1">Financeiro</option>
                                        <option value="2">Voluntário</option>
                                    </select>
                                </div>

                                <div className="cadastro-field">
                                    <label htmlFor="status">
                                        Status <span>*</span>
                                    </label>
                                    <select id="status" name="status" defaultValue="0" required>
                                        <option value="0">Ativo</option>
                                        <option value="1">Inativo</option>
                                    </select>
                                </div>
                            </div>
                        </section>

                        {/* Segundo painel destinado às permissões por projeto. */}
                        <section className="cadastro-panel">
                            <h2>Projetos permitidos</h2>

                            {/* Administradores possuem acesso automático a todos os projetos. */}
                            {tipo === "0" && (
                                <p className="cadastro-projetos-aviso">Todos os projetos</p>
                            )}

                            {/* O perfil financeiro não recebe permissão para projetos. */}
                            {tipo === "1" && (
                                <p className="cadastro-projetos-aviso">Nenhum projeto</p>
                            )}

                            {/* Voluntários podem receber uma ou mais permissões vindas da API. */}
                            {tipo === "2" && (
                                erroProjetos ? (
                                    <p className="cadastro-projetos-erro" role="alert">
                                        {erroProjetos}
                                    </p>
                                ) : projetos.length === 0 ? (
                                    <p className="cadastro-projetos-aviso">
                                        Nenhum projeto cadastrado.
                                    </p>
                                ) : (
                                    <div className="cadastro-projetos-opcoes">
                                        {projetos.map((projeto) => (
                                            <label
                                                className="cadastro-projeto-check"
                                                key={projeto.id_projeto}
                                            >
                                                <input
                                                    type="checkbox"
                                                    name="projetos"
                                                    value={projeto.id_projeto}
                                                />
                                                <span>{projeto.nome}</span>
                                            </label>
                                        ))}
                                    </div>
                                )
                            )}
                        </section>

                        {/* Exibe o retorno da API com semântica acessível. */}
                        {mensagem && (
                            <p
                                id="mensagem-retorno"
                                data-testid="mensagem-retorno"
                                role={mensagem.tipo === "erro" ? "alert" : "status"}
                                className={`cadastro-mensagem ${
                                    mensagem.tipo === "erro"
                                        ? "cadastro-mensagem-erro"
                                        : "cadastro-mensagem-sucesso"
                                }`}
                            >
                                {mensagem.texto}
                            </p>
                        )}

                    </form>

                </main>

            </div>

        </div>
    );
}
