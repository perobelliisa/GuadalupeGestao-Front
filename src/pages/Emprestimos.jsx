// Importa o menu lateral da aplicação.
import Sidebar from "../../components/Sidebar.jsx";
// Importa o cabeçalho que mostra o usuário logado.
import Header from "../../components/Header.jsx";
// Importa o hook usado para controlar estados locais do React.
import { useState } from "react";
// Importa o hook usado para navegar entre páginas sem recarregar o site.
import { useNavigate } from "react-router-dom";
// Importa os estilos gerais usados pelo layout.
import "./Dashboard.css";
// Importa estilos compartilhados pelas páginas de movimentações.
import "../../components/Movimentacoes.css";
// Importa os estilos específicos dos empréstimos.
import "./Emprestimos.css";

// Recebe um valor e devolve o texto correspondente em reais.
function dinheiro(valor) {
    // Converte o valor recebido para número.
    const numero = Number(valor || 0);
    // Mantém duas casas decimais e troca o ponto por vírgula.
    return "R$ " + numero.toFixed(2).replace(".", ",");
}

// Recebe uma data ISO e devolve a data no padrão brasileiro.
function dataBrasileira(data) {
    // Mostra um traço quando a data não foi informada.
    if (!data) return "-";
    // Divide a data em ano, mês e dia.
    const partes = data.split("-");
    // Reorganiza as partes para dia/mês/ano.
    return partes[2] + "/" + partes[1] + "/" + partes[0];
}

// Calcula a devolução usando a data inicial e a quantidade de parcelas.
function adicionarMeses(data, quantidade) {
    // Retorna vazio se ainda não houver dados suficientes para calcular.
    if (!data || !quantidade) return "";
    // Separa a data em números.
    const [ano, mes, dia] = data.split("-").map(Number);
    // Cria uma data adicionando a quantidade de meses informada.
    const resultado = new Date(ano, mes - 1 + Number(quantidade), 1);
    // Descobre o último dia do mês calculado.
    const ultimoDia = new Date(resultado.getFullYear(), resultado.getMonth() + 1, 0).getDate();
    // Evita datas inválidas em meses com menos dias.
    resultado.setDate(Math.min(dia, ultimoDia));
    // Retorna a data novamente no formato usado pelo input date.
    return `${resultado.getFullYear()}-${String(resultado.getMonth() + 1).padStart(2, "0")}-${String(resultado.getDate()).padStart(2, "0")}`;
}

// Define o texto do status com base nas parcelas pagas e no total de parcelas.
function statusPagamento(emprestimo) {
    // Lê quantas parcelas foram pagas; se não existir, considera zero.
    const pagas = Number(emprestimo.parcelas_pagas || 0);
    // Lê o total de parcelas; se não existir, considera uma parcela.
    const parcelas = Number(emprestimo.parcelas || 1);
    // Considera quitado quando todas as parcelas foram pagas.
    if (pagas >= parcelas) return "Pago";
    // Considera parcial quando pelo menos uma parcela foi paga.
    if (pagas > 0) return "Parcial";
    // Caso contrário, o pagamento continua pendente.
    return "Pendente";
}

// Modal responsável por editar um empréstimo e registrar seus pagamentos.
function EditorEmprestimo({ item, projetos, onFechar, onSalvar }) {
    // Guarda a quantidade de parcelas já pagas pelo empréstimo.
    const [parcelasPagas, setParcelasPagas] = useState(Number(item.parcelas_pagas || 0));
    // Guarda a quantidade total de parcelas que está sendo editada.
    const [parcelas, setParcelas] = useState(Number(item.parcelas || 1));
    // Guarda o valor editável do empréstimo.
    const [valor, setValor] = useState(Number(item.valor || 0));
    // Guarda a data inicial editável.
    const [data, setData] = useState(item.dia || "");
    // Informa se alguma operação está sendo salva.
    const [processando, setProcessando] = useState(false);
    // Guarda uma mensagem de erro para mostrar no modal.
    const [erro, setErro] = useState("");

    // Salva imediatamente a nova quantidade de parcelas pagas.
    async function salvarPagamento(novaQuantidade) {
        // Limpa uma mensagem de erro anterior.
        setErro("");
        // Desabilita os botões enquanto a API trabalha.
        setProcessando(true);
        try {
            // Envia somente o campo de pagamento para o endpoint de edição.
            await onSalvar(item.id_emprestimo, { parcelas_pagas: novaQuantidade });
            // Atualiza o contador visual depois da confirmação da API.
            setParcelasPagas(novaQuantidade);
        } catch (error) {
            // Mostra o erro retornado pelo backend.
            setErro(error.message);
        } finally {
            // Libera os botões novamente.
            setProcessando(false);
        }
    }

    // Salva os campos cadastrais alterados do empréstimo.
    async function salvarDados(event) {
        // Impede o navegador de recarregar a página.
        event.preventDefault();
        // Lê todos os campos preenchidos dentro do formulário.
        const dados = Object.fromEntries(new FormData(event.currentTarget).entries());
        // Converte o valor para número antes de enviar ao backend.
        dados.valor = Number(String(dados.valor).replace(",", "."));
        // Converte a quantidade de parcelas para número.
        dados.parcelas = Number(dados.parcelas);
        // Recalcula a data de devolução com base na nova quantidade de parcelas.
        dados.devolucao = adicionarMeses(dados.dia, dados.parcelas);
        // Mantém o campo de validade compatível com o banco atual.
        dados.validade = dados.devolucao;
        // Envia também o progresso atual do pagamento.
        dados.parcelas_pagas = parcelasPagas;
        // Limpa uma mensagem de erro anterior.
        setErro("");
        // Desabilita o formulário enquanto salva.
        setProcessando(true);
        try {
            // Envia os dados editados para o componente App.
            await onSalvar(item.id_emprestimo, dados);
            // Fecha o modal após o salvamento concluído.
            onFechar();
        } catch (error) {
            // Mostra o erro sem perder o conteúdo digitado.
            setErro(error.message);
        } finally {
            // Libera o formulário novamente.
            setProcessando(false);
        }
    }

    // Garante que o total de parcelas nunca fique abaixo de uma.
    const quantidadeParcelas = Math.max(Number(parcelas || 1), 1);
    // Calcula o valor aproximado de cada parcela.
    const valorParcela = Number(valor || 0) / quantidadeParcelas;
    // Calcula novamente a data de devolução exibida no formulário.
    const devolucaoCalculada = adicionarMeses(data, quantidadeParcelas);
    // Converte o progresso em percentual para preencher a barra.
    const percentualPago = Math.min((parcelasPagas / quantidadeParcelas) * 100, 100);

    // Renderiza a camada escura e a janela de edição.
    return (
        // Fecha o modal quando o usuário clica fora da janela.
        <div
            className="emprestimo-editor-overlay"
            onMouseDown={(event) => event.target === event.currentTarget && onFechar()}
        >
            {/* Formulário que reúne edição e pagamento. */}
            <form
                className="emprestimo-editor"
                onSubmit={salvarDados}
                role="dialog"
                aria-modal="true"
            >
                {/* Cabeçalho do modal e botão de fechar. */}
                <header>
                    <div>
                        <h2>Editar empréstimo</h2>
                        <p>Atualize os dados e acompanhe o pagamento.</p>
                    </div>
                    <button
                        type="button"
                        onClick={onFechar}
                        aria-label="Fechar"
                    >
                        ×
                    </button>
                </header>

                {/* Campos principais que podem ser editados. */}
                <div className="emprestimo-editor-grid">
                    {/* Campo que identifica de onde veio o empréstimo. */}
                    <label>
                        <span>Origem *</span>
                        <input
                            name="origem"
                            defaultValue={item.origem || ""}
                            required
                        />
                    </label>

                    {/* Campo do valor total emprestado. */}
                    <label>
                        <span>Valor *</span>
                        <input
                            name="valor"
                            type="number"
                            min="0.01"
                            step="0.01"
                            value={valor}
                            onChange={(event) => setValor(event.target.value)}
                            required
                        />
                    </label>

                    {/* Campo da data em que o empréstimo foi registrado. */}
                    <label>
                        <span>Data *</span>
                        <input
                            name="dia"
                            type="date"
                            max={new Date().toISOString().slice(0, 10)}
                            defaultValue={item.dia || ""}
                            onChange={(event) => setData(event.target.value)}
                            required
                        />
                    </label>

                    {/* Seleção do projeto relacionado ao empréstimo. */}
                    <label>
                        <span>Projeto *</span>
                        <select
                            name="id_projeto"
                            defaultValue={item.id_projeto || ""}
                            required
                        >
                            <option value="" disabled>Selecione</option>
                            {projetos.map((projeto) => (
                                <option
                                    key={projeto.id_projeto}
                                    value={projeto.id_projeto}
                                >
                                    {projeto.nome}
                                </option>
                            ))}
                        </select>
                    </label>

                    {/* Campo que explica a finalidade do empréstimo. */}
                    <label className="full">
                        <span>Finalidade *</span>
                        <input
                            name="finalidade"
                            defaultValue={item.finalidade || ""}
                            required
                        />
                    </label>

                    {/* Campo que permite ajustar o número de parcelas. */}
                    <label>
                        <span>Parcelas *</span>
                        <input
                            name="parcelas"
                            type="number"
                            min={Math.max(parcelasPagas, 1)}
                            step="1"
                            value={parcelas}
                            onChange={(event) => setParcelas(event.target.value)}
                            required
                        />
                    </label>

                    {/* Data calculada automaticamente; não pode ser digitada. */}
                    <label>
                        <span>Devolução prevista</span>
                        <input
                            type="text"
                            value={dataBrasileira(devolucaoCalculada) || "Será calculada automaticamente"}
                            readOnly
                        />
                    </label>
                </div>

                {/* Área específica para marcar parcelas pagas. */}
                <section className="emprestimo-pagamento">
                    {/* Mostra a descrição e o contador do pagamento. */}
                    <div className="emprestimo-pagamento-header">
                        <div>
                            <h3>Pagamento</h3>
                            <p>Marque as parcelas conforme forem devolvidas.</p>
                        </div>
                        <strong>
                            {parcelasPagas}/{quantidadeParcelas} pagas
                        </strong>
                    </div>

                    {/* Barra visual que representa o percentual pago. */}
                    <div className="emprestimo-pagamento-barra">
                        <span style={{ width: `${percentualPago}%` }} />
                    </div>

                    {/* Mostra quanto já foi pago e quanto falta do total. */}
                    <p className="emprestimo-pagamento-valor">
                        Pago: <strong>{dinheiro(valorParcela * parcelasPagas)}</strong>
                        {" de "}
                        {dinheiro(valor)}
                    </p>

                    {/* Botões que alteram o contador salvo no banco. */}
                    <div className="emprestimo-pagamento-acoes">
                        <button
                            type="button"
                            onClick={() => salvarPagamento(Math.min(parcelasPagas + 1, quantidadeParcelas))}
                            disabled={processando || parcelasPagas >= quantidadeParcelas}
                        >
                            Marcar próxima como paga
                        </button>
                        <button
                            type="button"
                            onClick={() => salvarPagamento(quantidadeParcelas)}
                            disabled={processando || parcelasPagas >= quantidadeParcelas}
                        >
                            Marcar tudo como pago
                        </button>
                        <button
                            type="button"
                            className="secundario"
                            onClick={() => salvarPagamento(Math.max(parcelasPagas - 1, 0))}
                            disabled={processando || parcelasPagas === 0}
                        >
                            Reverter última
                        </button>
                    </div>
                </section>

                {/* Exibe erros retornados pela API. */}
                {erro && (
                    <p className="mov-modal-error" role="alert">
                        {erro}
                    </p>
                )}

                {/* Ações finais do formulário. */}
                <footer>
                    <button
                        type="button"
                        onClick={onFechar}
                        disabled={processando}
                    >
                        Cancelar
                    </button>
                    <button type="submit" disabled={processando}>
                        {processando ? "Salvando..." : "Salvar alterações"}
                    </button>
                </footer>
            </form>
        </div>
    );
}

// Exibe a lista de empréstimos e seus indicadores.
export default function Emprestimos({
    usuario,
    emprestimos = [],
    projetos = [],
    onAtualizar,
    onLogout
}) {
    // Cria a função usada pelo botão de novo empréstimo.
    const navigate = useNavigate();
    // Guarda o empréstimo escolhido para edição.
    const [selecionado, setSelecionado] = useState(null);
    // Inicializa o total emprestado.
    let total = 0;
    // Inicializa a quantidade de empréstimos parcelados.
    let comParcelas = 0;
    // Inicializa a quantidade de devoluções futuras.
    let devolucoesFuturas = 0;
    // Guarda o instante atual para comparar as datas de devolução.
    const hoje = new Date();
    // Guarda as linhas que serão mostradas na tabela.
    const linhasDaTabela = [];

    // Percorre todos os empréstimos recebidos do App.
    for (let posicao = 0; posicao < emprestimos.length; posicao += 1) {
        // Seleciona o empréstimo da posição atual.
        const emprestimo = emprestimos[posicao];
        // Soma o valor do empréstimo ao total da página.
        total += Number(emprestimo.valor || 0);
        // Conta os empréstimos que possuem mais de uma parcela.
        if (Number(emprestimo.parcelas) > 1) comParcelas += 1;

        // Só compara a devolução quando ela foi cadastrada.
        if (emprestimo.devolucao) {
            // Cria uma data local para evitar comparação apenas de texto.
            const dataDevolucao = new Date(emprestimo.devolucao + "T23:59:59");
            // Conta a devolução se ela ainda não passou.
            if (dataDevolucao >= hoje) devolucoesFuturas += 1;
        }

        // Calcula o status textual do pagamento atual.
        const status = statusPagamento(emprestimo);

        // Adiciona uma linha com os dados do empréstimo.
        linhasDaTabela.push(
            <tr key={emprestimo.id_emprestimo}>
                {/* Mostra a origem do empréstimo. */}
                <td><strong>{emprestimo.origem || "-"}</strong></td>
                {/* Mostra o valor total emprestado. */}
                <td>{dinheiro(emprestimo.valor)}</td>
                {/* Mostra a data do registro. */}
                <td>{dataBrasileira(emprestimo.dia)}</td>
                {/* Mostra o nome do projeto relacionado. */}
                <td>{emprestimo.projeto_nome || emprestimo.id_projeto || "-"}</td>
                {/* Mostra o total de parcelas. */}
                <td>{emprestimo.parcelas || "-"}</td>
                {/* Mostra quantas parcelas foram pagas e o status. */}
                <td>
                    <span className={`emprestimo-status ${status.toLocaleLowerCase("pt-BR")}`}>
                        {Number(emprestimo.parcelas_pagas || 0)}/{Number(emprestimo.parcelas || 1)} {status.toLocaleLowerCase("pt-BR")}
                    </span>
                </td>
                {/* Mostra a data prevista para terminar a devolução. */}
                <td>{dataBrasileira(emprestimo.devolucao)}</td>
                {/* Mostra a finalidade cadastrada. */}
                <td>{emprestimo.finalidade || "-"}</td>
                {/* Abre o modal de edição da linha selecionada. */}
                <td>
                    <button
                        type="button"
                        className="emprestimo-editar"
                        onClick={() => setSelecionado(emprestimo)}
                    >
                        Editar
                    </button>
                </td>
            </tr>
        );
    }

    // Renderiza o layout completo da página.
    return (
        <div className="app">
            {/* Menu lateral com Empréstimos como página ativa. */}
            <Sidebar
                paginaAtiva="Empréstimos"
                tipoUsuario={usuario.tipo}
                onLogout={onLogout}
            />

            {/* Área principal que fica ao lado do menu. */}
            <div className="main">
                {/* Cabeçalho com o usuário autenticado. */}
                <Header usuario={usuario} />

                {/* Conteúdo principal da página. */}
                <main className="entradas-content">
                    {/* Título, descrição e botão para novo registro. */}
                    <div className="entradas-titlebar">
                        <div>
                            <h1>Empréstimos</h1>
                            <p>Empréstimos recebidos para financiar as atividades da Missão</p>
                        </div>
                        <button
                            className="entradas-primary"
                            type="button"
                            onClick={() => navigate("/emprestimos/novo")}
                        >
                            + Novo empréstimo
                        </button>
                    </div>

                    {/* Cards com os totais principais da página. */}
                    <section className="entradas-summary">
                        {/* Card que mostra a soma dos empréstimos. */}
                        <article>
                            <span className="summary-icon blue">R$</span>
                            <div>
                                <small>Total emprestado</small>
                                <strong>{dinheiro(total)}</strong>
                            </div>
                        </article>
                        {/* Card que mostra quantos empréstimos são parcelados. */}
                        <article>
                            <span className="summary-icon teal">#</span>
                            <div>
                                <small>Com parcelas informadas</small>
                                <strong>{comParcelas}</strong>
                            </div>
                        </article>
                        {/* Card que mostra devoluções ainda futuras. */}
                        <article>
                            <span className="summary-icon loan">✓</span>
                            <div>
                                <small>Devoluções futuras</small>
                                <strong>{devolucoesFuturas}</strong>
                            </div>
                        </article>
                    </section>

                    {/* Tabela ou mensagem quando não existem empréstimos. */}
                    <section className="emprestimos-table-card">
                        {emprestimos.length === 0 ? (
                            <div className="entradas-empty">
                                <strong>Nenhum empréstimo registrado</strong>
                                <span>Os empréstimos cadastrados aparecerão aqui.</span>
                            </div>
                        ) : (
                            <div className="entradas-table-scroll">
                                <table>
                                    {/* Cabeçalho da tabela. */}
                                    <thead>
                                        <tr>
                                            <th>ORIGEM</th>
                                            <th>VALOR</th>
                                            <th>DATA</th>
                                            <th>PROJETO</th>
                                            <th>PARCELAS</th>
                                            <th>PAGAMENTO</th>
                                            <th>DEVOLUÇÃO PREVISTA</th>
                                            <th>FINALIDADE</th>
                                            <th>AÇÃO</th>
                                        </tr>
                                    </thead>
                                    {/* Corpo preenchido com as linhas montadas acima. */}
                                    <tbody>{linhasDaTabela}</tbody>
                                </table>
                            </div>
                        )}
                    </section>
                </main>
            </div>

            {/* Mostra o editor somente quando uma linha foi selecionada. */}
            {selecionado && (
                <EditorEmprestimo
                    item={selecionado}
                    projetos={projetos}
                    onFechar={() => setSelecionado(null)}
                    onSalvar={onAtualizar}
                />
            )}
        </div>
    );
}
