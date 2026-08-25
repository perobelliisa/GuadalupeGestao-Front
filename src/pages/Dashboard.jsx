
// Importa os componentes que formam cada região da dashboard.
import Sidebar from "../../components/Sidebar.jsx";
import Header from "../../components/Header.jsx";
import Cards from "../../components/Card.jsx";
import Grafico from "../../components/Grafico.jsx";
import Projetos from "../../components/Tabela.jsx";
import { useLocation } from "react-router-dom";
// Importa os estilos exclusivos da estrutura da página.
import "./Dashboard.css";

// Recebe o usuário autenticado e os dados que futuramente virão da API.
export default function Dashboard({ usuario, dados, onLogout }) {
    const location = useLocation();
    const mensagem = location.state?.mensagem;

    // Monta a estrutura visual da dashboard.
    return (
        // Contêiner principal que posiciona sidebar e conteúdo lado a lado.
        <div className="app">

            {/* Menu lateral da aplicação. */}
            <Sidebar tipoUsuario={usuario.tipo} onLogout={onLogout} />

            {/* Área principal que contém cabeçalho e conteúdo. */}
            <div className="main">

                {/* Cabeçalho recebe o usuário real obtido no login. */}
                <Header usuario={usuario} />

                {/* Conteúdo central da visão geral. */}
                <main className="content">

                    {mensagem && (
                        <p
                            id="mensagem-retorno"
                            data-testid="mensagem-retorno"
                            className="mensagem-retorno mensagem-retorno-sucesso"
                            role="status"
                        >
                            {mensagem}
                        </p>
                    )}

                    {/* Título e descrição da página atual. */}
                    <div className="page-header">

                        <div>
                            <h1>Visão geral da Missão</h1>

                            <p>
                                Acompanhe as finanças, pendências e
                                projetos da instituição
                            </p>
                        </div>

                    </div>

                    {/* Indicadores financeiros; ficam vazios enquanto não houver API. */}
                    <Cards
                        saldoGeral={dados?.saldoGeral}
                        entradasMes={dados?.entradasMes}
                        despesasMes={dados?.despesasMes}
                        doacoesRecebidas={dados?.doacoesRecebidas}
                    />

                    {/* Limita o gráfico à largura definida no layout de referência. */}
                    <div className="chart-column">
                        {/* Usa lista vazia quando o backend ainda não enviou o fluxo. */}
                        <Grafico dados={dados?.fluxo ?? []} />
                    </div>

                    {/* Usa lista vazia quando ainda não existem projetos retornados. */}
                    <Projetos dados={dados?.projetos ?? []} />

                </main>

            </div>

        </div>
    );
}

