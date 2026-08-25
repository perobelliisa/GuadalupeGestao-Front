// Importa a barra lateral que contém os links de navegação do sistema.
import Sidebar from "../../components/Sidebar.jsx";
// Importa o cabeçalho que exibe os dados do usuário atualmente autenticado.
import Header from "../../components/Header.jsx";
// Importa somente os ícones utilizados nesta página para evitar código desnecessário.
import { AlertTriangle, Plus, Save, Search, SlidersHorizontal, Trash2, UsersRound, X } from "lucide-react";
// Importa useEffect para buscar os usuários e useState para guardar os estados da tela.
import { useEffect, useState } from "react";
// Importa os recursos de rota usados na navegação e nas mensagens entre páginas.
import { useLocation, useNavigate } from "react-router-dom";
// Importa as classes compartilhadas de estrutura, cores e posicionamento da dashboard.
import "./Dashboard.css";
// Importa as classes usadas exclusivamente pela página de listagem de usuários.
import "./Usuarios.css";

// Recebe o nome completo e devolve no máximo duas letras para formar o avatar.
function obterIniciais(nome = "") {
    // Inicia o tratamento usando uma string vazia quando o nome não for informado.
    return nome
        // Remove espaços que possam existir antes ou depois do nome.
        .trim()
        // Divide o nome em palavras, aceitando um ou vários espaços entre elas.
        .split(/\s+/)
        // Mantém apenas as duas primeiras palavras do nome.
        .slice(0, 2)
        // Obtém a primeira letra de cada uma das palavras selecionadas.
        .map((parte) => parte[0])
        // Junta as letras sem adicionar espaço entre elas.
        .join("")
        // Converte as iniciais para maiúsculas; usa dois traços quando não houver nome.
        .toUpperCase() || "--";
}

// Recebe o código numérico do perfil enviado pela API e devolve seu nome para exibição.
function formatarPerfil(tipo) {
    // Converte o valor para número porque a API também pode devolver o código como texto.
    if (Number(tipo) === 0) {
        // O código zero representa uma conta com administração geral.
        return "Adm geral";
    }

    // Verifica se a conta pertence ao setor financeiro.
    if (Number(tipo) === 1) {
        // O código um representa o perfil Financeiro.
        return "Financeiro";
    }

    // Verifica se a conta pertence a uma pessoa voluntária.
    if (Number(tipo) === 2) {
        // O código dois representa o perfil Voluntário.
        return "Voluntário";
    }

    // Evita mostrar códigos desconhecidos caso o banco devolva outro valor.
    return "Não informado";
}

// Converte o código numérico do status em um texto legível na tabela.
function formatarStatus(status) {
    // Considera zero como uma conta que está liberada para uso.
    if (Number(status) === 0) {
        return "Ativo";
    }

    // Considera um como uma conta que está desativada.
    if (Number(status) === 1) {
        return "Inativo";
    }

    // Trata qualquer valor fora do padrão sem expor um código estranho na interface.
    return "Não informado";
}

// Escolhe a classe CSS que dará a cor correta para cada status.
function obterClasseStatus(status) {
    // Contas ativas recebem a classe visual verde.
    if (Number(status) === 0) {
        return "usuarios-status-ativo";
    }

    // Contas inativas recebem a classe visual vermelha.
    if (Number(status) === 1) {
        return "usuarios-status-inativo";
    }

    // Valores desconhecidos recebem a aparência neutra de segurança.
    return "usuarios-status-desconhecido";
}

// Define o texto da coluna de projetos a partir do perfil e dos relacionamentos do banco.
function formatarProjetosPermitidos(item) {
    // Administradores possuem acesso automático a todos os projetos.
    if (Number(item.tipo) === 0) {
        return "Todos";
    }

    // O perfil financeiro não recebe acesso aos projetos.
    if (Number(item.tipo) === 1) {
        return "Nenhum";
    }

    // Confirma que é voluntário, que projetos é uma lista e que ela contém registros.
    if (Number(item.tipo) === 2 && Array.isArray(item.projetos) && item.projetos.length > 0) {
        // Extrai e junta os nomes reais retornados pela API usando vírgula como separador.
        return item.projetos.map((projeto) => projeto.nome).join(", ");
    }

    // Um voluntário sem relacionamentos cadastrados aparece sem projetos permitidos.
    return "Nenhum";
}

// Componente principal responsável por carregar e apresentar os usuários cadastrados.
// A propriedade usuario contém a conta autenticada e apiUrl contém o endereço central da API.
export default function Usuarios({ usuario, apiUrl, onSessaoInvalida, onLogout }) {
    // Cria a função usada para navegar até o formulário de novo usuário.
    const navigate = useNavigate();
    const location = useLocation();
    // Guarda apenas os registros devolvidos pelo endpoint GET /usuarios.
    const [usuarios, setUsuarios] = useState([]);
    // Guarda o texto digitado no campo de busca para filtrar a lista localmente.
    const [busca, setBusca] = useState("");
    // Começa como verdadeiro para mostrar a mensagem enquanto a primeira requisição acontece.
    const [carregando, setCarregando] = useState(true);
    // Guarda uma mensagem amigável caso a requisição falhe.
    const [erro, setErro] = useState("");
    // Guarda as opções reais da tabela PROJETO usadas na edição do voluntário.
    const [projetos, setProjetos] = useState([]);
    // Guarda os campos editáveis do usuário selecionado ou null quando o modal está fechado.
    const [edicao, setEdicao] = useState(null);
    // Controla o card de confirmação exibido antes da exclusão definitiva.
    const [confirmandoExclusao, setConfirmandoExclusao] = useState(false);
    // Controla o estado dos botões enquanto uma edição ou exclusão está sendo enviada.
    const [processando, setProcessando] = useState(false);
    // Guarda uma mensagem de erro exclusiva das ações executadas dentro do modal.
    const [erroModal, setErroModal] = useState("");
    // Mantém no DOM o retorno do backend após editar ou excluir uma conta.
    const [mensagemAcao, setMensagemAcao] = useState(() =>
        location.state?.mensagem
            ? { tipo: "sucesso", texto: location.state.mensagem }
            : null
    );
    // Incrementar este número solicita uma nova leitura dos dados após editar ou excluir.
    const [versaoLista, setVersaoLista] = useState(0);

    // Executa a busca ao montar o componente e novamente apenas se apiUrl mudar.
    useEffect(() => {
        // Cria um controlador para interromper a chamada caso o usuário saia da página.
        const controller = new AbortController();

        // Declara uma função assíncrona porque o callback do useEffect não deve ser async.
        async function carregarUsuarios() {
            // Inicia o tratamento que separa sucesso, erro e finalização.
            try {
                setErro("");

                // A lista de projetos é auxiliar e não deve impedir a exibição dos usuários.
                const requisicaoProjetos = fetch(`${apiUrl}/projetos`, {
                    credentials: "include",
                    signal: controller.signal
                }).catch(() => null);

                const respostaUsuarios = await fetch(`${apiUrl}/usuarios`, {
                    credentials: "include",
                    signal: controller.signal
                });
                const dadosUsuarios = await respostaUsuarios.json().catch(() => ({}));

                // Uma sessão expirada não deve continuar aparecendo como autenticada na interface.
                if (respostaUsuarios.status === 401 || respostaUsuarios.status === 403) {
                    onSessaoInvalida();
                    navigate("/", {
                        replace: true,
                        state: {
                            mensagem: {
                                tipo: "erro",
                                texto: "Sua sessão expirou. Entre novamente para continuar."
                            }
                        }
                    });
                    return;
                }

                // Somente uma falha do endpoint de usuários coloca a listagem em estado de erro.
                if (!respostaUsuarios.ok || !dadosUsuarios.sucesso) {
                    throw new Error(
                        dadosUsuarios.mensagem
                        || dadosUsuarios.erro
                        || "O servidor não informou o motivo do erro."
                    );
                }

                // Uma lista vazia é uma resposta válida e ativa o estado "Sem usuários".
                setUsuarios(Array.isArray(dadosUsuarios.usuarios) ? dadosUsuarios.usuarios : []);

                const respostaProjetos = await requisicaoProjetos;
                if (respostaProjetos?.ok) {
                    const dadosProjetos = await respostaProjetos.json().catch(() => ({}));
                    setProjetos(
                        dadosProjetos.sucesso && Array.isArray(dadosProjetos.projetos)
                            ? dadosProjetos.projetos
                            : []
                    );
                } else {
                    setProjetos([]);
                }
            } catch (error) {
                // Ignora o erro esperado quando a própria página cancela a requisição.
                if (error.name !== "AbortError") {
                    // Escolhe uma mensagem específica para falha de conexão ou erro da aplicação.
                    setErro(
                        // TypeError normalmente indica que o navegador não alcançou o servidor.
                        error instanceof TypeError
                            ? "Não foi possível conectar ao servidor."
                            // Outros erros usam a mensagem amigável criada anteriormente.
                            : error.message
                    );
                }
            } finally {
                // Só altera o estado se o componente ainda estiver presente na tela.
                if (!controller.signal.aborted) {
                    // Encerra o carregamento para liberar a exibição do resultado ou do erro.
                    setCarregando(false);
                }
            }
        }

        // Executa a função definida acima assim que o efeito é iniciado.
        carregarUsuarios();

        // Retorna a limpeza do efeito, cancelando uma chamada ainda pendente ao sair da página.
        return () => controller.abort();
    // A versão permite repetir a leitura depois de salvar ou excluir um usuário.
    }, [apiUrl, navigate, onSessaoInvalida, versaoLista]);

    // Abre o modal preenchendo os campos com os dados da linha que recebeu o clique.
    function abrirEdicao(item) {
        // Converte números em texto para manter os campos select controlados pelo React.
        setEdicao({
            id_usuario: item.id_usuario,
            nome: item.nome,
            email: item.email,
            tipo: String(item.tipo),
            status: String(item.status),
            projetos: Array.isArray(item.projetos)
                ? item.projetos.map((projeto) => projeto.id_projeto)
                : []
        });
        // Remove uma mensagem pertencente a uma abertura anterior do modal.
        setErroModal("");
    }

    // Fecha o modal somente quando nenhuma operação está em andamento.
    function fecharEdicao() {
        if (!processando) {
            setConfirmandoExclusao(false);
            setEdicao(null);
            setErroModal("");
        }
    }

    // Atualiza um campo simples do formulário mantendo os demais valores da edição.
    function atualizarCampo(campo, valor) {
        setEdicao((dadosAtuais) => ({
            ...dadosAtuais,
            [campo]: valor
        }));
    }

    // Adiciona ou remove um projeto da lista de permissões do voluntário.
    function alternarProjeto(idProjeto) {
        setEdicao((dadosAtuais) => ({
            ...dadosAtuais,
            projetos: dadosAtuais.projetos.includes(idProjeto)
                ? dadosAtuais.projetos.filter((id) => id !== idProjeto)
                : [...dadosAtuais.projetos, idProjeto]
        }));
    }

    // Envia ao backend todos os campos editáveis do usuário selecionado.
    async function salvarEdicao(event) {
        event.preventDefault();
        setProcessando(true);
        setErroModal("");
        setMensagemAcao(null);

        // Monta o mesmo formato multipart usado pelo cadastro de usuários.
        const formulario = new FormData();
        formulario.append("nome", edicao.nome);
        formulario.append("email", edicao.email);
        formulario.append("tipo", edicao.tipo);
        formulario.append("status", edicao.status);

        // Só envia projetos quando o perfil editado continuar sendo voluntário.
        if (edicao.tipo === "2") {
            edicao.projetos.forEach((idProjeto) => {
                formulario.append("projetos", idProjeto);
            });
        }

        try {
            const resposta = await fetch(`${apiUrl}/usuarios/${edicao.id_usuario}`, {
                method: "PUT",
                credentials: "include",
                body: formulario
            });
            const dados = await resposta.json().catch(() => ({}));

            if (!resposta.ok || !dados.sucesso) {
                throw new Error(
                    dados.mensagem || dados.erro || "O servidor não informou o motivo do erro."
                );
            }

            // Fecha o modal e solicita à API uma lista já atualizada.
            setEdicao(null);
            setMensagemAcao({ tipo: "sucesso", texto: dados.mensagem });
            setVersaoLista((versaoAtual) => versaoAtual + 1);
        } catch (error) {
            setErroModal(
                error instanceof TypeError
                    ? "Não foi possível conectar ao servidor."
                    : error.message
            );
        } finally {
            setProcessando(false);
        }
    }

    // Realiza a exclusão somente depois da confirmação no card da interface.
    async function excluirUsuario() {
        setProcessando(true);
        setErroModal("");
        setMensagemAcao(null);

        try {
            const resposta = await fetch(`${apiUrl}/usuarios/${edicao.id_usuario}`, {
                method: "DELETE",
                credentials: "include"
            });
            const dados = await resposta.json().catch(() => ({}));

            if (!resposta.ok || !dados.sucesso) {
                throw new Error(
                    dados.mensagem || dados.erro || "O servidor não informou o motivo do erro."
                );
            }

            // Fecha o modal e recarrega a tabela sem manter dados excluídos na interface.
            setConfirmandoExclusao(false);
            setEdicao(null);
            setMensagemAcao({ tipo: "sucesso", texto: dados.mensagem });
            setVersaoLista((versaoAtual) => versaoAtual + 1);
        } catch (error) {
            setErroModal(
                error instanceof TypeError
                    ? "Não foi possível conectar ao servidor."
                    : error.message
            );
        } finally {
            setProcessando(false);
        }
    }

    // Permite fechar o modal pela tecla Escape sem criar eventos permanentes na página.
    useEffect(() => {
        function fecharComEscape(event) {
            if (event.key === "Escape" && confirmandoExclusao && !processando) {
                setConfirmandoExclusao(false);
            } else if (event.key === "Escape") {
                fecharEdicao();
            }
        }

        if (edicao) {
            window.addEventListener("keydown", fecharComEscape);
        }

        return () => window.removeEventListener("keydown", fecharComEscape);
    }, [edicao, processando, confirmandoExclusao]);

    // Remove espaços e ignora diferenças entre letras maiúsculas e minúsculas na pesquisa.
    const termo = busca.trim().toLowerCase();
    // Cria a lista que será exibida sem duplicar os dados originais recebidos da API.
    const usuariosFiltrados = termo
        // Quando existe uma busca, mantém somente nomes ou e-mails que contêm o texto.
        ? usuarios.filter((item) =>
            item.nome.toLowerCase().includes(termo)
            || item.email.toLowerCase().includes(termo)
        )
        // Sem busca, utiliza a lista completa sem realizar um filtro desnecessário.
        : usuarios;

    // Devolve toda a estrutura visual da página de administração dos usuários.
    return (
        // Usa a estrutura geral que posiciona a sidebar ao lado do conteúdo principal.
        <div className="app">

            {/* Renderiza a navegação e mantém Usuários destacado como página atual. */}
            {/* O tipo da conta é enviado para a sidebar controlar os itens permitidos. */}
            <Sidebar paginaAtiva="Usuários" tipoUsuario={usuario.tipo} onLogout={onLogout} />

            {/* Agrupa verticalmente o cabeçalho e o conteúdo localizado ao lado da sidebar. */}
            <div className="main">

                {/* Exibe no topo os dados reais da conta que está autenticada. */}
                <Header usuario={usuario} />

                {/* Define o conteúdo principal da página para semântica e acessibilidade. */}
                <main className="usuarios-content">

                    {/* Organiza o título, a descrição e o botão principal na mesma área. */}
                    <div className="usuarios-page-header">
                        {/* Agrupa os dois textos para que permaneçam alinhados verticalmente. */}
                        <div>
                            {/* Informa de forma direta qual seção administrativa está aberta. */}
                            <h1>Usuários</h1>
                            {/* Explica resumidamente que a página administra contas de acesso. */}
                            <p>Contas de acesso à plataforma Guadalupe Gestões</p>
                        </div>

                        {/* Botão separado do formulário porque apenas navega para outra rota. */}
                        <button
                            // Evita que o botão seja interpretado como envio de formulário.
                            type="button"
                            // Aplica o padrão visual azul das ações principais desta página.
                            className="usuarios-btn-novo"
                            // Abre a rota protegida que contém o cadastro de uma nova conta.
                            onClick={() => navigate("/usuarios/novo")}
                        >
                            {/* Ícone visual que reforça a ação de adicionar um registro. */}
                            <Plus size={15} />
                            {/* Texto visível que identifica a ação mesmo sem depender do ícone. */}
                            Novo usuário
                        </button>
                    </div>

                    {/* Card de resumo cuja quantidade é calculada pela lista real da API. */}
                    <section className="usuarios-resumo">
                        {/* Cria o fundo destacado reservado para o ícone do resumo. */}
                        <div className="usuarios-resumo-icone">
                            {/* Representa visualmente um conjunto de contas cadastradas. */}
                            <UsersRound size={18} />
                        </div>
                        {/* Agrupa o rótulo explicativo e o número total de registros. */}
                        <div>
                            {/* Identifica o significado do número exibido logo abaixo. */}
                            <span>Usuários cadastrados</span>
                            {/* Usa o tamanho atual da lista, sem manter um total fixo no código. */}
                            <strong>{usuarios.length}</strong>
                        </div>
                    </section>

                    {/* Barra de filtros aplicada somente aos dados já carregados no navegador. */}
                    <section className="usuarios-filtros">
                        {/* Título compacto que identifica a finalidade desta barra. */}
                        <div className="usuarios-filtro-label">
                            {/* Ícone decorativo relacionado à filtragem de informações. */}
                            <SlidersHorizontal size={14} />
                            {/* Texto que continua identificando o controle sem depender do ícone. */}
                            Filtros
                        </div>

                        {/* O label envolve o campo para ampliar a área clicável da busca. */}
                        <label className="usuarios-busca">
                            {/* Ícone decorativo que representa uma pesquisa. */}
                            <Search size={14} />
                            {/* Campo controlado pelo estado busca. */}
                            <input
                                // Ativa os recursos próprios de pesquisa fornecidos pelo navegador.
                                type="search"
                                // Mantém o valor visual sempre sincronizado com o estado React.
                                value={busca}
                                // Atualiza o estado a cada caractere digitado pelo usuário.
                                onChange={(event) => setBusca(event.target.value)}
                                // Dá um exemplo do conteúdo que pode ser pesquisado.
                                placeholder="Buscar por nome ou e-mail..."
                                // Fornece um nome acessível mesmo que não exista um texto de label visível.
                                aria-label="Buscar usuários por nome ou e-mail"
                            />
                        </label>
                    </section>

                    {mensagemAcao?.texto && (
                        <p
                            id="mensagem-retorno"
                            data-testid="mensagem-retorno"
                            role="status"
                            className="usuarios-mensagem usuarios-mensagem-sucesso"
                        >
                            {mensagemAcao.texto}
                        </p>
                    )}

                    {/* Card principal que alterna entre os possíveis estados da listagem. */}
                    <section className="usuarios-tabela-card">
                        {/* Enquanto a requisição não terminou, mostra somente o estado de carregamento. */}
                        {carregando ? (
                            <p className="usuarios-estado">Carregando usuários...</p>
                        // Depois do carregamento, prioriza a exibição de uma eventual falha.
                        ) : erro ? (
                            // role alert faz leitores de tela anunciarem a mensagem imediatamente.
                            <p className="usuarios-estado usuarios-estado-erro" role="alert">
                                {/* Exibe a mensagem amigável armazenada no tratamento da requisição. */}
                                {erro}
                            </p>
                        // Sem erro, verifica se a lista completa ou filtrada ficou vazia.
                        ) : usuariosFiltrados.length === 0 ? (
                            <p className="usuarios-estado">
                                {/* Diferencia uma busca sem resultado da ausência total de cadastros. */}
                                {termo
                                    ? "Nenhum usuário encontrado para esta busca."
                                    : "Sem usuários."}
                            </p>
                        // A tabela só é criada quando existem registros disponíveis para exibição.
                        ) : (
                            // O contêiner permite rolagem horizontal em telas menores.
                            <div className="usuarios-tabela-container">
                                {/* Organiza cada usuário em colunas com informações equivalentes. */}
                                <table className="usuarios-tabela">
                                    {/* Define o cabeçalho que identifica o conteúdo de cada coluna. */}
                                    <thead>
                                        <tr>
                                            {/* Coluna destinada ao avatar, nome e e-mail. */}
                                            <th>USUÁRIO</th>
                                            {/* Coluna destinada ao perfil convertido de código para texto. */}
                                            <th>PERFIL</th>
                                            {/* Coluna destinada às permissões calculadas ou vindas da API. */}
                                            <th>PROJETOS PERMITIDOS</th>
                                            {/* Coluna destinada à situação atual da conta. */}
                                            <th>STATUS</th>
                                        </tr>
                                    </thead>
                                    {/* Corpo preenchido dinamicamente com os usuários filtrados. */}
                                    <tbody>
                                        {/* Percorre a lista e cria uma linha para cada registro real do banco. */}
                                        {usuariosFiltrados.map((item) => (
                                            // Usa o ID do banco como chave estável para o React.
                                            <tr
                                                key={item.id_usuario}
                                                className="usuarios-linha-clicavel"
                                                tabIndex={0}
                                                role="button"
                                                aria-label={`Editar usuário ${item.nome}`}
                                                onClick={() => abrirEdicao(item)}
                                                onKeyDown={(event) => {
                                                    if (event.key === "Enter" || event.key === " ") {
                                                        event.preventDefault();
                                                        abrirEdicao(item);
                                                    }
                                                }}
                                            >
                                                {/* Primeira célula: identificação principal da conta. */}
                                                <td>
                                                    {/* Mantém avatar e textos alinhados na mesma linha. */}
                                                    <div className="usuarios-identidade">
                                                        {/* Mostra um avatar textual sem depender de imagem fixa. */}
                                                        <span className="usuarios-avatar">
                                                            {/* Calcula as iniciais usando o nome deste registro. */}
                                                            {obterIniciais(item.nome)}
                                                        </span>
                                                        {/* Agrupa nome completo e e-mail em duas linhas. */}
                                                        <div>
                                                            {/* Nome real devolvido pela API. */}
                                                            <strong>{item.nome}</strong>
                                                            {/* E-mail real devolvido pela API. */}
                                                            <small>{item.email}</small>
                                                        </div>
                                                    </div>
                                                </td>
                                                {/* Segunda célula: perfil de acesso da conta. */}
                                                <td>
                                                    {/* Aplica a aparência visual padrão dos perfis. */}
                                                    <span className="usuarios-perfil">
                                                        {/* Traduz os códigos 0, 1 e 2 para seus nomes. */}
                                                        {formatarPerfil(item.tipo)}
                                                    </span>
                                                </td>
                                                {/* Terceira célula: permissões correspondentes ao perfil. */}
                                                <td className="usuarios-projetos">
                                                    {/* Mostra Todos, Nenhum ou a lista de projetos relacionados. */}
                                                    {formatarProjetosPermitidos(item)}
                                                </td>
                                                {/* Quarta célula: status atual da conta. */}
                                                <td>
                                                    {/* Combina a classe comum com a cor específica do status. */}
                                                    <span
                                                        className={`usuarios-status ${obterClasseStatus(item.status)}`}
                                                    >
                                                        {/* Traduz zero para Ativo e um para Inativo. */}
                                                        {formatarStatus(item.status)}
                                                    </span>
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        )}
                    </section>

                </main>

            </div>

            {/* O modal só é incluído na página quando existe um usuário selecionado. */}
            {edicao && (
                // A camada escura cobre a tela e também permite fechar ao clicar fora do formulário.
                <div
                    className="usuarios-modal-overlay"
                    onMouseDown={(event) => {
                        if (event.target === event.currentTarget) {
                            fecharEdicao();
                        }
                    }}
                >
                    {/* O formulário possui semântica de diálogo para tecnologias assistivas. */}
                    <form
                        className="usuarios-modal"
                        role="dialog"
                        aria-modal="true"
                        aria-labelledby="titulo-editar-usuario"
                        onSubmit={salvarEdicao}
                        noValidate
                    >
                        {/* Cabeçalho do modal com identificação e ação de fechamento. */}
                        <div className="usuarios-modal-header">
                            <div>
                                <h2 id="titulo-editar-usuario">Editar usuário</h2>
                                <p>Atualize os dados da conta selecionada</p>
                            </div>

                            <button
                                type="button"
                                className="usuarios-modal-fechar"
                                onClick={fecharEdicao}
                                disabled={processando}
                                aria-label="Fechar edição"
                            >
                                <X size={18} />
                            </button>
                        </div>

                        {/* Campos de texto preenchidos com nome e e-mail vindos da API. */}
                        <div className="usuarios-modal-campos">
                            <label className="usuarios-modal-field usuarios-modal-field-full">
                                <span>Nome</span>
                                <input
                                    type="text"
                                    value={edicao.nome}
                                    onChange={(event) => atualizarCampo("nome", event.target.value)}
                                    required
                                />
                            </label>

                            <label className="usuarios-modal-field usuarios-modal-field-full">
                                <span>E-mail</span>
                                <input
                                    id="email"
                                    type="email"
                                    value={edicao.email}
                                    onChange={(event) => atualizarCampo("email", event.target.value)}
                                    required
                                />
                            </label>

                            {/* Perfil e status permanecem lado a lado quando houver espaço. */}
                            <label className="usuarios-modal-field">
                                <span>Perfil de acesso</span>
                                <select
                                    value={edicao.tipo}
                                    onChange={(event) => atualizarCampo("tipo", event.target.value)}
                                    required
                                >
                                    <option value="0">Adm geral</option>
                                    <option value="1">Financeiro</option>
                                    <option value="2">Voluntário</option>
                                </select>
                            </label>

                            <label className="usuarios-modal-field">
                                <span>Status</span>
                                <select
                                    value={edicao.status}
                                    onChange={(event) => atualizarCampo("status", event.target.value)}
                                    required
                                >
                                    <option value="0">Ativo</option>
                                    <option value="1">Inativo</option>
                                </select>
                            </label>
                        </div>

                        {/* Exibe as permissões de projeto conforme o perfil escolhido. */}
                        <div className="usuarios-modal-projetos">
                            <h3>Projetos permitidos</h3>

                            {edicao.tipo === "0" && <p>Todos os projetos</p>}
                            {edicao.tipo === "1" && <p>Nenhum projeto</p>}

                            {edicao.tipo === "2" && (
                                <div className="usuarios-modal-checks">
                                    {projetos.map((projeto) => (
                                        <label key={projeto.id_projeto}>
                                            <input
                                                type="checkbox"
                                                checked={edicao.projetos.includes(projeto.id_projeto)}
                                                onChange={() => alternarProjeto(projeto.id_projeto)}
                                            />
                                            <span>{projeto.nome}</span>
                                        </label>
                                    ))}
                                </div>
                            )}
                        </div>

                        {/* Mostra falhas de validação ou comunicação sem fechar o modal. */}
                        {erroModal && (
                            <p
                                id="mensagem-retorno"
                                data-testid="mensagem-retorno"
                                className="usuarios-modal-erro"
                                role="alert"
                                aria-live="assertive"
                            >
                                {erroModal}
                            </p>
                        )}

                        {/* Rodapé separa claramente a ação destrutiva da ação de salvar. */}
                        <div className="usuarios-modal-acoes">
                            <button
                                id="btn-excluir-usuario"
                                data-testid="btn-excluir-usuario"
                                type="button"
                                className="usuarios-btn-excluir"
                                onClick={() => setConfirmandoExclusao(true)}
                                disabled={processando}
                            >
                                <Trash2 size={15} />
                                Excluir usuário
                            </button>

                            <div>
                                <button
                                    id="btn-cancelar-edicao"
                                    data-testid="btn-cancelar-edicao"
                                    type="button"
                                    className="usuarios-btn-cancelar"
                                    onClick={fecharEdicao}
                                    disabled={processando}
                                >
                                    Cancelar
                                </button>
                                <button
                                    id="btn-salvar-usuario"
                                    data-testid="btn-salvar-usuario"
                                    type="submit"
                                    className="usuarios-btn-salvar"
                                    disabled={processando}
                                >
                                    <Save size={15} />
                                    {processando ? "Salvando..." : "Salvar alterações"}
                                </button>
                            </div>
                        </div>
                    </form>
                </div>
            )}

            {edicao && confirmandoExclusao && (
                <div
                    className="usuarios-confirmacao-overlay"
                    onMouseDown={(event) => {
                        if (event.target === event.currentTarget && !processando) {
                            setConfirmandoExclusao(false);
                        }
                    }}
                >
                    <section
                        className="usuarios-confirmacao-card"
                        role="alertdialog"
                        aria-modal="true"
                        aria-labelledby="titulo-confirmar-exclusao"
                        aria-describedby="texto-confirmar-exclusao"
                    >
                        <span className="usuarios-confirmacao-icone" aria-hidden="true">
                            <AlertTriangle size={22} />
                        </span>
                        <h2 id="titulo-confirmar-exclusao">Excluir usuário?</h2>
                        <p id="texto-confirmar-exclusao">
                            Deseja realmente excluir o usuário <strong>{edicao.nome}</strong>?
                            Esta ação não poderá ser desfeita.
                        </p>
                        <div className="usuarios-confirmacao-acoes">
                            <button
                                type="button"
                                className="usuarios-btn-cancelar"
                                onClick={() => setConfirmandoExclusao(false)}
                                disabled={processando}
                            >
                                Cancelar
                            </button>
                            <button
                                type="button"
                                className="usuarios-confirmacao-excluir"
                                onClick={excluirUsuario}
                                disabled={processando}
                                autoFocus
                            >
                                <Trash2 size={15} />
                                {processando ? "Excluindo..." : "Excluir usuário"}
                            </button>
                        </div>
                    </section>
                </div>
            )}

        </div>
    );
}
