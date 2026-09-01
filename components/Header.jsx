// Importa o ícone usado para indicar um futuro menu da conta.
import {
    ChevronDown
} from "lucide-react";
import { useNavigate } from "react-router-dom";

// Importa os estilos do cabeçalho.
import "./Header.css";

// Gera até duas iniciais a partir do nome real do usuário.
function obterIniciais(nome = "") {
    // Remove espaços extras do início e do final.
    return nome
        .trim()
        // Divide o nome sempre que houver um ou mais espaços.
        .split(/\s+/)
        // Considera no máximo os dois primeiros nomes.
        .slice(0, 2)
        // Extrai a primeira letra de cada parte selecionada.
        .map((parte) => parte[0])
        // Une as letras em uma única sigla.
        .join("")
        // Padroniza as iniciais em letras maiúsculas.
        .toUpperCase() || "--";
}

// Exibe as informações do usuário autenticado no topo da página.
export default function Header({ usuario }) {
    const navigate = useNavigate();
    // Obtém o nome recebido da resposta do login, sem valor pessoal fixo.
    const nome = usuario.nome;

    // Renderiza o cabeçalho alinhado à direita.
    return (
        <header className="header">
            {/* Agrupa todos os controles do lado direito. */}
            <div className="header-right">
                {/* Agrupa saudação, avatar e indicação de menu. */}
                <button type="button" className="usuario" onClick={() => navigate("/configuracoes")} aria-label="Abrir configurações da conta">

                    {/* Exibe o nome dinâmico do usuário. */}
                    <span>
                        Olá, {nome}
                    </span>

                    {/* Cria o avatar textual com as iniciais calculadas. */}
                    <div className="avatar">
                        {obterIniciais(nome)}
                    </div>

                    {/* Indica visualmente que a conta poderá abrir um menu. */}
                    <ChevronDown size={12} />

                </button>

            </div>

        </header>
    );
}
