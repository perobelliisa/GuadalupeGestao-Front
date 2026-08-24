// Importa os ícones usados para identificar cada indicador financeiro.
import {
    Wallet,
    ArrowDownCircle,
    ArrowUpCircle,
    Heart
} from "lucide-react";

// Importa os estilos dos cards.
import "./Card.css";

// Componente reutilizável que representa um único indicador.
function Card({
                  titulo,
                  valor,
                  icone,
                  tipo
              }) {
    // Renderiza o ícone, o título e o valor recebidos por propriedades.
    return (
        // Contêiner visual de um indicador.
        <div className="card">

            {/* Aplica uma cor diferente conforme o tipo do indicador. */}
            <div className={`card-icon ${tipo}`}>
                {icone}
            </div>

            {/* Agrupa o nome e o valor do indicador. */}
            <div className="card-content">

                {/* Exibe o título fixo da categoria, não um dado financeiro. */}
                <span>
                    {titulo}
                </span>

                {/* Exibe o valor da API ou um traço enquanto ele não existe. */}
                <strong>
                    {valor ?? "—"}
                </strong>

            </div>

        </div>
    );
}

// Organiza os quatro indicadores recebidos pela dashboard.
export default function Cards({
                                  saldoGeral,
                                  entradasMes,
                                  despesasMes,
                                  doacoesRecebidas
                              }) {

    // Renderiza a grade de indicadores financeiros.
    return (
        // Seção semântica que agrupa todos os cards.
        <section className="cards">

            {/* Card do saldo geral. */}
            <Card
                titulo="Saldo geral"
                valor={saldoGeral}
                tipo="blue"
                icone={<Wallet size={17} />}
            />

            {/* Card das entradas do mês. */}
            <Card
                titulo="Entradas do mês"
                valor={entradasMes}
                tipo="green"
                icone={<ArrowDownCircle size={17} />}
            />

            {/* Card das despesas do mês. */}
            <Card
                titulo="Despesas do mês"
                valor={despesasMes}
                tipo="red"
                icone={<ArrowUpCircle size={17} />}
            />

            {/* Card das doações recebidas. */}
            <Card
                titulo="Doações recebidas"
                valor={doacoesRecebidas}
                tipo="yellow"
                icone={<Heart size={17} />}
            />

        </section>
    );
}
