// Importa os estilos da tabela de projetos.
import "./Tabela.css";

// Componente pequeno que padroniza a etiqueta visual de status.
function Status({ status, tipo }) {
    // Combina a classe geral com a variação de cor recebida.
    return (
        <span className={`status ${tipo}`}>
            {status}
        </span>
    );
}

// Exibe os projetos retornados futuramente pelo backend.
export default function Projetos({ dados }) {

    // Renderiza o card que contém título, cabeçalho e linhas da tabela.
    return (
        // Seção semântica da situação dos projetos.
        <section className="projetos">

            {/* Título da seção. */}
            <div className="projetos-header">
                <h2>
                    Situação dos projetos
                </h2>
            </div>

            {/* Permite rolagem horizontal da tabela em telas menores. */}
            <div className="tabela-container">

                {/* Estrutura tabular dos projetos. */}
                <table>

                    {/* Cabeçalho que identifica cada campo retornado pela API. */}
                    <thead>
                    <tr>
                        <th>PROJETO</th>
                        <th>RESPONSÁVEL</th>
                        <th>STATUS</th>
                        <th>
                            SALDO /<br />
                            GASTO DO MÊS
                        </th>
                        <th>PENDÊNCIA</th>
                    </tr>
                    </thead>

                    {/* Corpo preenchido dinamicamente ou com estado vazio. */}
                    <tbody>

                    {/* Exibe uma mensagem única enquanto não houver projetos. */}
                    {dados.length === 0 ? (
                        <tr>
                            <td colSpan="5" className="tabela-vazia">
                                Os projetos aparecerão aqui quando estiverem disponíveis.
                            </td>
                        </tr>
                    ) : dados.map((projeto) => (

                        // Cada projeto gera uma linha identificada por seu id.
                        <tr key={projeto.id}>

                            {/* Nome do projeto acompanhado de um marcador de cor. */}
                            <td>
                                <div className="nome-projeto">

                    <span
                        className={`dot ${projeto.cor}`}
                    />

                                    {projeto.nome}

                                </div>
                            </td>

                            {/* Responsável recebido para o projeto atual. */}
                            <td>
                                {projeto.responsavel}
                            </td>

                            {/* Status com estilo correspondente ao tipo recebido. */}
                            <td>

                                <Status
                                    status={projeto.status}
                                    tipo={projeto.tipoStatus}
                                />

                            </td>

                            {/* Saldo ou gasto, destacado quando vier como negativo. */}
                            <td
                                className={
                                    projeto.saldoNegativo
                                        ? "saldo-negativo"
                                        : ""
                                }
                            >
                                {projeto.saldo}
                            </td>

                            {/* Resumo das pendências do projeto. */}
                            <td>
                                {projeto.pendencia}
                            </td>

                        </tr>

                    ))}

                    </tbody>

                </table>

            </div>

        </section>
    );
}
