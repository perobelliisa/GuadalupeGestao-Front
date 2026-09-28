// Importa o ícone do ambiente atual.
import { LogOut, Menu, ShieldCheck, X } from "lucide-react";
import { useEffect, useId, useRef, useState } from "react";
// Importa a navegação usada pelos itens que já possuem página.
import { useNavigate } from "react-router-dom";
// Importa o módulo CSS e disponibiliza suas classes como propriedades.
import css from "./Sidebar.module.css";

// Exibe o menu lateral e comunica cliques ao componente que controlar a navegação.
export default function Sidebar({
                                    // Define a visão geral como item selecionado inicialmente.
                                    paginaAtiva = "Visão Geral",
                                    // Recebe o tipo real do usuário autenticado.
                                    tipoUsuario,
                                    // Encerra a sessão quando o botão de saída for acionado.
                                    onLogout,
                                    // Callback opcional chamado quando o usuário escolhe um item.
                                    onNavigate
                                }) {

    // Cria a função de troca de rota sem recarregar o navegador.
    const navigate = useNavigate();
    const [menuAberto, setMenuAberto] = useState(false);
    const menuId = useId();
    const menuRef = useRef(null);
    const botaoRef = useRef(null);

    useEffect(() => {
        if (!menuAberto) return;

        const painel = menuRef.current;
        const botao = botaoRef.current;
        const overflowAnterior = document.body.style.overflow;
        document.body.style.overflow = "hidden";
        painel.querySelector("button")?.focus();

        function controlarTeclado(event) {
            if (event.key === "Escape") setMenuAberto(false);
            if (event.key !== "Tab") return;
            const botoes = painel.querySelectorAll("button");
            const primeiro = botoes[0];
            const ultimo = botoes[botoes.length - 1];
            if (event.shiftKey && document.activeElement === primeiro) {
                event.preventDefault();
                ultimo.focus();
            } else if (!event.shiftKey && document.activeElement === ultimo) {
                event.preventDefault();
                primeiro.focus();
            }
        }

        const media = window.matchMedia("(max-width: 700px)");
        function fecharNoDesktop(event) {
            if (!event.matches) setMenuAberto(false);
        }
        document.addEventListener("keydown", controlarTeclado);
        media.addEventListener("change", fecharNoDesktop);
        return () => {
            document.body.style.overflow = overflowAnterior;
            document.removeEventListener("keydown", controlarTeclado);
            media.removeEventListener("change", fecharNoDesktop);
            if (botao?.isConnected && media.matches) botao.focus();
        };
    }, [menuAberto]);
    // Define se o item administrativo de usuários pode ser exibido.
    const podeGerenciarUsuarios = Number(tipoUsuario) === 0;

    // Organiza os itens em seções para evitar repetir a estrutura visual do menu.
    const menu = [
        // Primeira seção com as páginas mais acessadas.
        {
            titulo: "PRINCIPAL",
            itens: [
                // Acesso à página atual de visão geral.
                {
                    id: "visao-geral",
                    nome: "Visão Geral",
                    icone: "/visaogeral.png",
                    rota: "/dashboard"
                },
                // Acesso às pendências financeiras.
                {
                    id: "pendencias",
                    nome: "Pendências",
                    icone: "/pendencias.png",
                    rota: "/pendencias"
                }
            ]
        },

        // Seção reservada às funcionalidades financeiras.
        {
            titulo: "FINANCEIRO",
            itens: [
                // Acesso ao livro-caixa.
                {
                    id: "livro-caixa",
                    nome: "Livro-caixa",
                    icone: "/livrocaixa.png",
                    rota: "/livro-caixa"
                },
                // Acesso aos registros de entrada.
                {
                    id: "entradas",
                    nome: "Entradas",
                    icone: "/entrada.png",
                    rota: "/entradas"
                },
                // Acesso aos registros de despesa.
                {
                    id: "despesas",
                    nome: "Despesas",
                    icone: "/despesa.png",
                    rota: "/despesas"
                },
                // Acesso aos registros de doações.
                {
                    id: "doacoes",
                    nome: "Doações",
                    icone: "/doacoes.png",
                    rota: "/doacoes"
                },
                // Acesso aos registros de empréstimos.
                {
                    id: "emprestimos",
                    nome: "Empréstimos",
                    icone: "/emprestimos.png",
                    rota: "/emprestimos"
                }
            ]
        },

        // Seção das funcionalidades relacionadas aos projetos sociais.
        {
            titulo: "GESTÃO DOS PROJETOS",
            itens: [
                // Acesso à central que reúne os projetos.
                {
                    id: "central-projetos",
                    nome: "Central de Projetos",
                    icone: "/centralprojetos.png",
                    rota: "/projetos"
                },

                // Acesso aos documentos associados aos projetos.
                {
                    id: "documentos",
                    nome: "Documentos dos Projetos",
                    icone: "/documentos.png",
                    rota: "/documentos"
                }
            ]
        },

        // Seção destinada às ferramentas administrativas.
        {
            titulo: "ADMINISTRAÇÃO",
            itens: [
                // Acesso aos relatórios da instituição.
                {
                    id: "relatorios",
                    nome: "Relatórios",
                    icone: "/relatorios.png",
                    rota: "/relatorios"
                },
                // Acesso ao gerenciamento de usuários.
                {
                    id: "usuarios",
                    nome: "Usuários",
                    icone: "/usuarios.png",
                    rota: "/usuarios"
                },
                // Acesso às configurações gerais.
                {
                    id: "configuracoes",
                    nome: "Configurações",
                    icone: "/configuracoes.png",
                    rota: "/configuracoes"
                }
            ]
        }
    ];


    // Trata a seleção de qualquer item do menu.
    function navegar(item) {
        setMenuAberto(false);

        // Abre a rota quando o item já possui uma página implementada.
        if (item.rota) {
            navigate(item.rota);
        }

        // Também avisa o componente pai quando ele fornecer um callback.
        if (onNavigate) {
            // Envia o objeto completo para o futuro controlador de rotas.
            onNavigate(item);
        }

    }

    // Encerra a sessão e abre o login sem apresentar erro de acesso protegido.
    function sair() {
        if (onLogout) {
            onLogout();
        }

        navigate("/", {
            replace: true,
            state: {
                mensagem: {
                    tipo: "sucesso",
                    texto: "Sessão encerrada com sucesso."
                }
            }
        });
    }


    // Renderiza logo, ambiente atual e todas as seções do menu.
    return (

        // Elemento semântico que identifica a navegação lateral.
        <>
        <button
            ref={botaoRef}
            type="button"
            className={css.menuToggle}
            aria-label="Abrir menu de navegação"
            aria-expanded={menuAberto}
            aria-controls={menuId}
            onClick={() => setMenuAberto(true)}
        >
            <Menu size={24} aria-hidden="true" />
        </button>
        {menuAberto && <div className={css.overlay} onClick={() => setMenuAberto(false)} aria-hidden="true" />}
        <aside
            id={menuId}
            ref={menuRef}
            className={`${css.sidebar} ${menuAberto ? css.sidebarAberta : ""}`}
            role={menuAberto ? "dialog" : undefined}
            aria-modal={menuAberto ? true : undefined}
            aria-label="Menu de navegação"
        >
            <button type="button" className={css.fecharMenu} aria-label="Fechar menu de navegação" onClick={() => setMenuAberto(false)}>
                <X size={24} aria-hidden="true" />
            </button>

            {/* LOGO */}

            <div className={css.logoArea}>

                {/* Imagem decorativa com o símbolo da instituição. */}
                <img
                    src="/Guadalupe Gestões (1).png"
                    alt=""
                    className={css.logoIcone}
                />

                {/* Imagem textual que completa a marca Guadalupe Gestões. */}
                <img
                    src="/Container.png"
                    alt="Guadalupe Gestões"
                    className={css.logoTexto}
                />

            </div>


            {/* AMBIENTE ATUAL */}

            <div className={css.ambienteArea}>

                {/* Rótulo que explica o card apresentado logo abaixo. */}
                <span className={css.ambienteTitulo}>
                    AMBIENTE ATUAL
                </span>


                <div className={css.ambienteCard}>

                    {/* Ícone visual do ambiente de gestão selecionado. */}
                    <div className={css.ambienteIcone}>
                        <ShieldCheck size={15} />
                    </div>

                    {/* Nome do ambiente atual. */}
                    <strong>
                        Gestão da Missão
                    </strong>

                </div>

            </div>


            {/* MENU */}

            <nav className={css.menu}>

                {/* Percorre as seções declaradas no array de configuração. */}
                {menu.map(function (secao) {

                    // Retorna um grupo visual para a seção atual.
                    return (

                        <div
                            className={css.menuSecao}
                            key={secao.titulo}
                        >

                            {/* Exibe o título da seção. */}
                            <span className={css.menuTitulo}>
                                {secao.titulo}
                            </span>


                            <div className={css.menuItens}>

                                {/* Converte cada configuração em um botão navegável. */}
                                {secao.itens
                                    .filter(function (item) {
                                        return item.id !== "usuarios" || podeGerenciarUsuarios;
                                    })
                                    .map(function (item) {

                                    // Compara o nome do item com a página selecionada.
                                    const ativo =
                                        paginaAtiva === item.nome;


                                    // Renderiza o botão do item atual.
                                    // O clique encaminha o item e a classe muda conforme o estado ativo.
                                    return (

                                        <button
                                            key={item.id}
                                            type="button"
                                            onClick={function () {
                                                navegar(item);
                                            }}
                                            className={
                                                ativo
                                                    ? `${css.menuItem} ${css.menuItemAtivo}`
                                                    : css.menuItem
                                            }
                                        >

                                            {/* Reserva uma área consistente para todos os ícones. */}
                                            <span className={css.menuIcone}>
                                                {/* Usa imagem quando há caminho; mantém compatibilidade com texto. */}
                                                {item.icone.startsWith("/") ? (
                                                    <img
                                                        src={item.icone}
                                                        alt=""
                                                        className={css.menuIconeImagem}
                                                    />
                                                ) : item.icone}
                                            </span>

                                            {/* Exibe o nome legível da página. */}
                                            <span>
                                                {item.nome}
                                            </span>

                                        </button>

                                    );

                                    })}

                            </div>

                        </div>

                    );

                })}

            </nav>

            {/* Mantém a saída separada das opções de navegação. */}
            <div className={css.logoutArea}>
                <button
                    type="button"
                    className={css.logoutButton}
                    onClick={sair}
                >
                    <LogOut size={17} aria-hidden="true" />
                    <span>Sair</span>
                </button>
            </div>

        </aside>
        </>

    );
}
