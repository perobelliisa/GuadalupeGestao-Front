// Importa as classes visuais exclusivas da página de login.
import css from "./Login.module.css";
// useState controla mensagens e o estado de envio do formulário.
import { useState } from "react";
// useNavigate permite trocar de página depois da autenticação.
import { useNavigate } from "react-router-dom";

// Recebe a URL central da API e o callback que registra o usuário autenticado.
export default function Login({ apiUrl, onLogin }) {
    // Cria a função responsável por navegar entre as rotas.
    const navigate = useNavigate();
    // Guarda a mensagem de erro ou sucesso exibida abaixo do botão.
    const [mensagem, setMensagem] = useState(null);
    // Informa se a requisição está em andamento e evita envios repetidos.
    const [carregando, setCarregando] = useState(false);

    // Processa o formulário, chama a API e redireciona após o sucesso.
    async function entrar(event) {
        // Impede o recarregamento padrão do navegador ao enviar o formulário.
        event.preventDefault();

        // Lê todos os campos diretamente do formulário enviado.
        const formulario = new FormData(event.currentTarget);
        // Obtém o e-mail pelo atributo name do campo correspondente.
        const email = formulario.get("email");
        // Obtém a senha pelo atributo name do campo correspondente.
        const senha = formulario.get("senha");

        // Limpa mensagens antigas antes de uma nova tentativa.
        setMensagem(null);
        // Bloqueia o botão e troca seu texto enquanto aguarda a API.
        setCarregando(true);

        // Inicia o bloco que também captura falhas de conexão e validação.
        try {
            // Envia as credenciais para o endpoint de login do backend.
            const resposta = await fetch(`${apiUrl}/login`, {
                // Usa POST porque as credenciais serão enviadas no corpo.
                method: "POST",
                // Informa ao Flask que o corpo está no formato JSON.
                headers: { "Content-Type": "application/json" },
                // Autoriza receber e enviar o cookie HttpOnly da autenticação.
                credentials: "include",
                // Converte e-mail e senha para texto JSON.
                body: JSON.stringify({ email, senha })
            });

            // Converte a resposta em objeto e usa objeto vazio se ela não vier em JSON.
            const dados = await resposta.json().catch(() => ({}));

            // Trata respostas HTTP que representam falha.
            if (!resposta.ok) {
                // Aproveita mensagens úteis devolvidas pelo backend.
                const mensagemDaApi = dados.mensagem || dados.erro;
                // Esconde detalhes internos quando o servidor falha com erro 500.
                const mensagemAmigavel = resposta.status < 500 && mensagemDaApi
                    ? mensagemDaApi
                    : "Não foi possível entrar agora. Tente novamente em alguns instantes.";

                // Interrompe o fluxo normal e envia o texto ao bloco catch.
                throw new Error(mensagemAmigavel);
            }

            // Confirma também o campo de sucesso definido pelo contrato da API.
            if (!dados.sucesso) {
                throw new Error("Não foi possível confirmar o login. Tente novamente.");
            }

            // Prepara a confirmação visual apresentada ao usuário.
            setMensagem({
                tipo: "sucesso",
                texto: "Login realizado com sucesso! Redirecionando..."
            });

            // Envia os dados públicos do login para o estado central da aplicação.
            onLogin(dados);
            // Mantém a mensagem visível por um curto período antes da troca de página.
            await new Promise((resolve) => setTimeout(resolve, 900));
            // Abre a dashboard e substitui o login no histórico do navegador.
            navigate("/dashboard", { replace: true });
        } catch (error) {
            // Diferencia falha de rede de uma rejeição controlada pela aplicação.
            const texto = error instanceof TypeError
                ? "Não foi possível conectar ao servidor. Verifique se a API está ligada."
                : error.message;

            // Exibe uma mensagem amigável em vez do erro técnico do navegador.
            setMensagem({
                tipo: "erro",
                texto: texto || "Ocorreu um problema ao entrar. Tente novamente."
            });
        } finally {
            // Libera o botão tanto em caso de sucesso quanto em caso de erro.
            setCarregando(false);
        }
    }

    // Renderiza os painéis esquerdo e direito da tela de autenticação.
    return (
        // Elemento principal que ocupa toda a página.
        <main className={css.loginPage}>

            {/* ================================
                LADO ESQUERDO
            ================================= */}

            <section className={css.loginLeft}>

                {/* Limita e alinha o conteúdo do formulário. */}
                <div className={css.loginContent}>

                    {/* Agrupa o símbolo e o nome da marca. */}
                    <div className={css.logoProjetos}>
                        {/* Símbolo visual da Guadalupe Gestões. */}
                        <img
                            src="/Guadalupe Gestões (1).png"
                            alt="Símbolo Guadalupe Gestões"
                            className={css.logoIcone}
                        />

                        {/* Imagem com o nome da plataforma. */}
                        <img
                            src="/Container.png"
                            alt="Guadalupe Gestões"
                            className={css.logoTexto}
                        />
                    </div>


                    <div className={css.loginHeader}>

                        {/* Saudação principal da tela. */}
                        <h1>Bem-vindo de volta</h1>

                        {/* Explica brevemente a finalidade da plataforma. */}
                        <p>
                            Acesse a plataforma para cuidar, organizar e acompanhar
                            cada frente da Missão Guadalupe.
                        </p>

                    </div>


                    {/* Envia os dados pela função entrar sem recarregar a página. */}
                    <form
                        className={css.loginForm}
                        onSubmit={entrar}
                    >

                        {/* Grupo do campo de identificação do usuário. */}
                        <div className={css.formGroup}>

                            {/* Associa o texto ao campo com id "email". */}
                            <label htmlFor="email">
                                E-mail <span>*</span>
                            </label>

                            {/* Campo obrigatório validado como endereço de e-mail. */}
                            <input
                                type="email"
                                id="email"
                                name="email"
                                autoComplete="email"
                                required
                            />

                        </div>


                        {/* Grupo do campo secreto da autenticação. */}
                        <div className={css.formGroup}>

                            {/* Associa o texto ao campo com id "senha". */}
                            <label htmlFor="senha">
                                Senha
                            </label>

                            {/* Campo obrigatório que oculta visualmente a senha digitada. */}
                            <input
                                type="password"
                                id="senha"
                                name="senha"
                                autoComplete="current-password"
                                required
                            />

                        </div>


                        {/* Envia o formulário e permanece bloqueado durante a requisição. */}
                        <button
                            type="submit"
                            className={css.btnEntrar}
                            disabled={carregando}
                        >
                            {carregando ? "Entrando..." : "Entrar"}
                        </button>

                        {/* Mostra retorno acessível somente quando existe uma mensagem. */}
                        {mensagem && (
                            <p
                                role={mensagem.tipo === "erro" ? "alert" : "status"}
                                className={`${css.mensagem} ${
                                    // Seleciona a cor conforme o tipo do retorno.
                                    mensagem.tipo === "erro"
                                        ? css.mensagemErro
                                        : css.mensagemSucesso
                                }`}
                            >
                                {mensagem.texto}
                            </p>
                        )}

                    </form>

                </div>

            </section>


            {/* ================================
                LADO DIREITO
            ================================= */}

            <section className={css.loginRight}>

                {/* Centraliza a composição institucional do painel direito. */}
                <div className={css.rightContent}>


                    {/* PARTE DAS IMAGENS */}

                    <div className={css.visualArea}>


                        {/* COZINHA */}
                        <div
                            className={`${css.photo} ${css.photoCozinha}`}
                        >
                            {/* Fotografia da ação de alimentação solidária. */}
                            <img
                                src="/Voluntárias preparando refeições da Alimentação Solidária (2).png"
                                alt="Voluntárias preparando refeições"
                            />
                        </div>


                        {/* VERDE */}
                        <div
                            className={`${css.shape} ${css.shapeGreen}`}
                        />


                        {/* COSTURA */}
                        <div
                            className={`${css.photo} ${css.photoCostura}`}
                        >
                            {/* Fotografia do projeto Costurando Afeto. */}
                            <img
                                src="/Voluntária da Costurando Afeto costurando.png"
                                alt="Voluntária costurando"
                            />
                        </div>


                        {/* AMARELO */}
                        <div
                            className={`${css.shape} ${css.shapeYellow}`}
                        />


                        {/* AZUL */}
                        <div
                            className={`${css.shape} ${css.shapeBlueSmall}`}
                        />


                        {/* LOGO MISSÃO GUADALUPE */}
                        <div className={css.missionLogoArea}>

                            {/* Marca da Missão Guadalupe no centro da composição. */}
                            <img
                                src="/image 1.png"
                                alt="Missão Guadalupe"
                                className={css.missionLogo}
                            />

                        </div>


                        {/* CUIDADO */}
                        <div
                            className={`${css.photo} ${css.photoCuidado}`}
                        >
                            {/* Fotografia da ação de acolhimento a idosos. */}
                            <img
                                src="/Acolhimento e cuidado com idosos.png"
                                alt="Acolhimento e cuidado com idosos"
                            />
                        </div>


                        {/* ROSA */}
                        <div
                            className={`${css.shape} ${css.shapePink}`}
                        />

                    </div>


                    {/* TEXTO */}

                    <div className={css.rightInfo}>

                        {/* Mensagem institucional principal. */}
                        <h2>
                            Organização e transparência para
                            <br className={css.desktopBreak} />
                            transformar cuidado em impacto.
                        </h2>


                        {/* Lista visual das três áreas de atuação destacadas. */}
                        <div className={css.features}>

                            {/* Destaque para projetos. */}
                            <div className={css.featureCard}>

                                <div
                                    className={`${css.featureIcon} ${css.blue}`}
                                >
                                    ♙
                                </div>

                                <span>Projetos</span>

                            </div>


                            {/* Destaque para doações. */}
                            <div className={css.featureCard}>

                                <div
                                    className={`${css.featureIcon} ${css.yellow}`}
                                >
                                    ♡
                                </div>

                                <span>Doações</span>

                            </div>


                            {/* Destaque para pessoas. */}
                            <div className={css.featureCard}>

                                <div
                                    className={`${css.featureIcon} ${css.green}`}
                                >
                                    ♧
                                </div>

                                <span>Pessoas</span>

                            </div>

                        </div>

                    </div>


                    {/* Forma azul decorativa posicionada no rodapé do painel. */}
                    <div
                        className={`${css.shape} ${css.shapeBlueBottom}`}
                    />

                </div>

            </section>

        </main>
    );
}
