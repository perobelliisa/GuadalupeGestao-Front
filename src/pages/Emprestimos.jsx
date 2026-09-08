// Esta página lista os empréstimos e calcula um resumo simples deles.
// Os comentários explicam blocos de código; cada bloco executa uma tarefa completa.
import Sidebar from "../../components/Sidebar.jsx";
import Header from "../../components/Header.jsx"; // Mostra o cabeçalho com os dados do usuário.
import { useState } from "react"; // Permite guardar a informação do empréstimo selecionado.
import { useNavigate } from "react-router-dom"; // Permite trocar de página ao clicar no botão.
import EditorCadastroFinanceiro from "../../components/EditorCadastroFinanceiro.jsx"; // Janela usada para editar um empréstimo.
import "./Dashboard.css";
import "../../components/Movimentacoes.css";
import "./Emprestimos.css";

// Recebe um valor e devolve um texto como: R$ 10,00.
function dinheiro(valor) {
    const numero = Number(valor || 0); // Converte o valor recebido para número; se estiver vazio, usa zero.
    return "R$ " + numero.toFixed(2).replace(".", ","); // Mantém duas casas decimais e usa vírgula.
}

// Recebe uma data no formato ano-mês-dia e a mostra como dia/mês/ano.
function dataBrasileira(data) {
    if (!data) return "-"; // Se não houver data, mostra um traço na tabela.
    const partes = data.split("-"); // Separa, por exemplo, 2026-09-08 em três pedaços.
    return partes[2] + "/" + partes[1] + "/" + partes[0]; // Junta os pedaços na ordem brasileira.
}

export default function Emprestimos({ usuario, apiUrl, emprestimos = [], onAtualizar, onLogout }) {
    const navigate = useNavigate(); // Cria a função que muda a rota da aplicação.
    const [selecionado, setSelecionado] = useState(null); // Guarda o empréstimo clicado ou null quando nenhum está aberto.
    let total = 0; // Começa a soma de todos os valores em zero.
    let comParcelas = 0; // Conta empréstimos que possuem parcelas.
    let devolucoesFuturas = 0; // Conta devoluções que ainda não passaram.
    const hoje = new Date(); // Guarda a data e hora atuais para fazer a comparação.
    const linhasDaTabela = []; // Aqui serão guardadas as linhas que aparecerão na tabela.

    for (let posicao = 0; posicao < emprestimos.length; posicao += 1) {
        const emprestimo = emprestimos[posicao]; // Pega um empréstimo da lista pela posição atual.
        total += Number(emprestimo.valor || 0); // Acrescenta o valor dele ao total.
        if (Number(emprestimo.parcelas) > 0) comParcelas += 1; // Se possui parcelas, aumenta o contador.

        if (emprestimo.devolucao) {
            const dataDevolucao = new Date(emprestimo.devolucao + "T23:59:59"); // Cria uma data para comparação.
            if (dataDevolucao >= hoje) devolucoesFuturas += 1; // Só conta se a devolução for hoje ou depois.
        }

        // Cria uma linha visual da tabela e a adiciona na lista de linhas.
        // Ao clicar na linha, o empréstimo atual é guardado para abrir a edição.
        linhasDaTabela.push(<tr key={emprestimo.id_emprestimo} className="mov-row-clickable" onClick={() => setSelecionado(emprestimo)}>
            <td><strong>{emprestimo.origem || "-"}</strong></td><td>{dinheiro(emprestimo.valor)}</td><td>{dataBrasileira(emprestimo.dia)}</td>
            <td>{emprestimo.projeto_nome || emprestimo.id_projeto || "-"}</td><td>{emprestimo.parcelas || "-"}</td>
            <td>{dataBrasileira(emprestimo.devolucao)}</td><td>{dataBrasileira(emprestimo.validade)}</td><td>{emprestimo.finalidade || "-"}</td>
        </tr>);
    }

    return <div className="app"><Sidebar paginaAtiva="Empréstimos" tipoUsuario={usuario.tipo} onLogout={onLogout}/><div className="main"><Header usuario={usuario}/><main className="entradas-content">
        <div className="entradas-titlebar"><div><h1>Empréstimos</h1><p>Empréstimos recebidos para financiar as atividades da Missão</p></div><button className="entradas-primary" type="button" onClick={() => navigate("/emprestimos/novo")}>+ Novo empréstimo</button></div>
        <section className="entradas-summary"><article><span className="summary-icon blue">R$</span><div><small>Total emprestado</small><strong>{dinheiro(total)}</strong></div></article><article><span className="summary-icon teal">#</span><div><small>Com parcelas informadas</small><strong>{comParcelas}</strong></div></article><article><span className="summary-icon loan">✓</span><div><small>Devoluções futuras</small><strong>{devolucoesFuturas}</strong></div></article></section>
        <section className="emprestimos-table-card">{emprestimos.length === 0 ? <div className="entradas-empty"><strong>Nenhum empréstimo registrado</strong><span>Os empréstimos cadastrados aparecerão aqui.</span></div> : <div className="entradas-table-scroll"><table><thead><tr><th>ORIGEM</th><th>VALOR</th><th>DATA</th><th>PROJETO</th><th>PARCELAS</th><th>DEVOLUÇÃO</th><th>VALIDADE</th><th>FINALIDADE</th></tr></thead><tbody>{linhasDaTabela}</tbody></table></div>}</section>
        {selecionado && <EditorCadastroFinanceiro item={selecionado} tipo="Empréstimo" apiUrl={apiUrl} onFechar={() => setSelecionado(null)} onSalvar={onAtualizar} />}
    </main></div></div>;
}
