
// Importa somente os elementos necessários para construir o gráfico de linhas.
import {
    ResponsiveContainer,
    LineChart,
    Line,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip
} from "recharts";

// Importa os estilos do gráfico e do estado vazio.
import "./Grafico.css";

// Formata os valores do gráfico com duas casas decimais no padrão brasileiro.
function formatarValor(valor) {
    const numero = Number(valor) || 0;
    return `R$ ${numero.toFixed(2).replace(".", ",")}`;
}

// Apresenta nomes legíveis para as séries exibidas no tooltip.
function nomeDaSerie(nome) {
    return nome === "despesas" ? "Despesas" : "Entradas";
}

// Exibe o fluxo financeiro recebido futuramente da API.
export default function Grafico({ dados }) {
    // Evita criar eixos ou linhas quando ainda não existem registros.
    const possuiDados = dados.length > 0;

    // Renderiza o card do gráfico.
    return (
        // Contêiner visual do fluxo financeiro.
        <section className="grafico-container">

            {/* Cabeçalho textual do gráfico. */}
            <div className="grafico-header">
                <h2>
                    Fluxo financeiro da Missão
                </h2>
            </div>

            {/* Alterna entre gráfico real e mensagem de estado vazio. */}
            {possuiDados ? (
                // Fragmento agrupa gráfico e legenda sem criar elemento extra.
                <>
                    {/* Área com altura reservada para o gráfico responsivo. */}
                    <div className="grafico">

                        {/* Faz o gráfico acompanhar largura e altura do contêiner. */}
                        <ResponsiveContainer
                            width="100%"
                            height="100%"
                        >

                            {/* Associa o conjunto recebido às linhas do gráfico. */}
                            <LineChart data={dados}>

                                {/* Desenha somente linhas horizontais tracejadas de apoio. */}
                                <CartesianGrid
                                    strokeDasharray="3 3"
                                    vertical={false}
                                />

                                {/* Usa o campo "mes" como rótulo do eixo horizontal. */}
                                <XAxis
                                    dataKey="mes"
                                    axisLine={false}
                                    tickLine={false}
                                />

                                {/* Exibe a escala numérica no eixo vertical. */}
                                <YAxis
                                    axisLine={false}
                                    tickLine={false}
                                />

                                {/* Mostra os valores ao posicionar o cursor sobre o gráfico. */}
                                <Tooltip
                                    formatter={(valor, nome) => [
                                        formatarValor(valor),
                                        nomeDaSerie(nome)
                                    ]}
                                />

                                {/* Representa a série de entradas retornada pela API. */}
                                <Line
                                    type="monotone"
                                    dataKey="entradas"
                                    stroke="var(--cor-acento)"
                                    strokeWidth={2}
                                    dot={false}
                                />

                                {/* Representa a série de despesas retornada pela API. */}
                                <Line
                                    type="monotone"
                                    dataKey="despesas"
                                    stroke="var(--cor-perigo)"
                                    strokeWidth={2}
                                    dot={false}
                                />

                            </LineChart>

                        </ResponsiveContainer>

                    </div>

                    {/* Explica as cores das duas linhas. */}
                    <div className="legenda">

                        {/* Legenda da série de entradas. */}
                        <span>
                            <i className="entrada" />
                            Entradas
                        </span>

                        {/* Legenda da série de despesas. */}
                        <span>
                            <i className="despesa" />
                            Despesas
                        </span>

                    </div>
                </>
            ) : (
                // Informa por que o gráfico está vazio, sem criar dados fictícios.
                <div className="grafico-vazio">
                    Os dados financeiros aparecerão aqui quando estiverem disponíveis.
                </div>
            )}

        </section>
    );
}
