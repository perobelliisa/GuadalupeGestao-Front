// Importa hooks para memorizar funções, executar efeitos, guardar referências e controlar os estados da tela.
import { useCallback, useEffect, useRef, useState } from "react";
// Importa o menu lateral compartilhado pelas páginas.
import Sidebar from "../../components/Sidebar.jsx";
// Importa o cabeçalho que exibe os dados do usuário conectado.
import Header from "../../components/Header.jsx";
// Carrega os estilos do layout geral da aplicação.
import "./Dashboard.css";
// Carrega estilos compartilhados dos cartões, tabelas e botões financeiros.
import "../../components/Movimentacoes.css";
// Carrega os estilos usados pela janela de confirmação de pagamento.
import "../../components/EditorMovimentacao.css";
// Carrega as cores de prioridade e os demais estilos específicos desta página.
import "./Pendencias.css";

// Cria um formatador de reais no padrão brasileiro, como R$ 1.234,50.
const moeda = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" });
// Divide AAAA-MM-DD pelos hífens, inverte as partes e une com barras: DD/MM/AAAA.
const dataBrasileira = (data) => data.split("-").reverse().join("/");
// Escolhe a classe CSS da cor; a prioridade recebida já foi calculada pelo backend.
const classePrioridade = (valor) => `pendencia-prioridade prioridade-${valor === "Alta" ? "alta" : valor === "Média" ? "media" : "baixa"}`;

// Converte a diferença de dias recebida da API em uma descrição legível.
function prazo(dias) {
    // Dias negativos indicam atraso; -dias transforma a quantidade em positiva para exibição.
    if (dias < 0) return `Vencida há ${-dias} dia(s)`;
    // Zero significa que o vencimento acontece hoje.
    if (dias === 0) return "Vence hoje";
    // Para dias positivos, informa quanto falta para vencer.
    return `Vence em ${dias} dia(s)`;
}

// Exporta a página: recebe usuário, URL da API, projetos (lista vazia por padrão) e callbacks de pagamento e saída.
export default function Pendencias({ usuario, apiUrl, projetos = [], onPagamento, onLogout }) {
    // Guarda as ocorrências abertas; setPendencias atualiza a lista e provoca uma nova renderização.
    const [pendencias, setPendencias] = useState([]);
    // Guarda avisos da API, como registros com datas inválidas que precisam ser corrigidos.
    const [avisos, setAvisos] = useState([]);
    // Começa carregando para não mostrar uma falsa lista vazia antes da primeira consulta.
    const [carregando, setCarregando] = useState(true);
    // Guarda a mensagem de erro; a string vazia significa que não há erro para exibir.
    const [erro, setErro] = useState("");
    // Guarda a confirmação de sucesso apresentada após um pagamento.
    const [mensagem, setMensagem] = useState("");
    // Guarda a ocorrência escolhida para pagar; null mantém a janela de confirmação fechada.
    const [selecionada, setSelecionada] = useState(null);
    // Controla a indicação de salvamento e o bloqueio visual dos botões.
    const [salvando, setSalvando] = useState(false);
    // Mantém o controlador da consulta mais recente entre renderizações, sem renderizar ao alterá-lo.
    const requisicao = useRef(null);
    // Mantém uma trava imediata para cliques repetidos, sem esperar a atualização visual do React.
    const pagamentoEmCurso = useRef(false);

    // Memoriza esta função assíncrona enquanto apiUrl não mudar, evitando reconfigurar o efeito a cada renderização.
    const carregar = useCallback(async () => {
        // Cancela a consulta de listagem anterior, se existir; ?. evita chamar abort em uma referência nula.
        requisicao.current?.abort();
        // Cria o controlador que permitirá cancelar esta nova consulta.
        const controller = new AbortController();
        // Salva o controlador para que outras partes do componente possam cancelar a consulta.
        requisicao.current = controller;
        // Ativa a indicação de carregamento enquanto a consulta está em andamento.
        setCarregando(true);
        // Limpa a mensagem de erro da tentativa anterior.
        setErro("");
        // Inicia o bloco protegido para tratar falhas de rede, interpretação da resposta ou validação.
        try {
            // Consulta a lista; credentials envia os cookies de sessão e signal permite cancelar a requisição.
            const resposta = await fetch(`${apiUrl}/pendencias`, { credentials: "include", signal: controller.signal });
            // Aguarda a conversão do corpo JSON da resposta em um objeto JavaScript.
            const dados = await resposta.json();
            // Exige sucesso HTTP, confirmação da API e um array válido de pendências.
            if (!resposta.ok || !dados.sucesso || !Array.isArray(dados.pendencias)) {
                // Interrompe o fluxo com a mensagem da API ou, se ausente, uma mensagem padrão.
                throw new Error(dados.mensagem || "Não foi possível carregar as pendências.");
            }
            // Só aplica a resposta se esta consulta não foi cancelada por uma mais recente ou pela saída da página.
            if (!controller.signal.aborted) {
                // Substitui a lista exibida pelos dados atualizados recebidos do servidor.
                setPendencias(dados.pendencias);
                // Atualiza os avisos e usa uma lista vazia caso a API não envie nenhum.
                setAvisos(dados.avisos || []);
            }
        // Captura uma falha lançada dentro do bloco try.
        } catch (error) {
            // Mostra falhas reais; cancelamentos intencionais não viram mensagens de erro.
            if (!controller.signal.aborted) setErro(error.message || "Não foi possível carregar as pendências.");
        // Executa a finalização tanto após sucesso quanto após falha.
        } finally {
            // Encerra o carregamento somente se a consulta não foi cancelada.
            if (!controller.signal.aborted) setCarregando(false);
        }
    // A dependência apiUrl faz a função ser recriada apenas quando o endereço da API mudar.
    }, [apiUrl]);

    // Configura a consulta inicial e as atualizações automáticas quando a página é montada.
    useEffect(() => {
        // Busca os dados ao executar este efeito.
        carregar();
        // Define a função compartilhada pelo evento de foco e pelo temporizador.
        const atualizar = () => {
            // Evita consultar automaticamente enquanto um pagamento está em andamento.
            if (!pagamentoEmCurso.current) carregar();
        };
        // Atualiza a lista quando a janela do navegador volta a receber foco.
        window.addEventListener("focus", atualizar);
        // Agenda uma atualização a cada 60.000 milissegundos, equivalentes a um minuto.
        const intervalo = window.setInterval(atualizar, 60000);
        // Define a limpeza executada ao sair da página ou antes de reexecutar este efeito.
        return () => {
            // Cancela a consulta de listagem anterior, se existir; ?. evita chamar abort em uma referência nula.
            requisicao.current?.abort();
            // Remove o evento de foco para não deixar uma atualização ligada a uma página fechada.
            window.removeEventListener("focus", atualizar);
            // Interrompe o temporizador criado por este efeito.
            window.clearInterval(intervalo);
        };
    // Refaz o efeito se a função carregar mudar, por exemplo, quando apiUrl mudar.
    }, [carregar]);

    // Registra o pagamento da ocorrência escolhida após a confirmação do usuário.
    async function pagar() {
        // Sai sem enviar nada se não houver seleção ou se outro pagamento já estiver em andamento.
        if (!selecionada || pagamentoEmCurso.current) return;
        // Ativa imediatamente a trava contra envios repetidos, antes da próxima renderização.
        pagamentoEmCurso.current = true;
        // Cancela a consulta de listagem anterior, se existir; ?. evita chamar abort em uma referência nula.
        requisicao.current?.abort();
        // Mostra o estado de salvamento e desabilita os botões envolvidos.
        setSalvando(true);
        // Limpa a mensagem de erro da tentativa anterior.
        setErro("");
        // Remove a confirmação de sucesso anterior antes de começar o novo pagamento.
        setMensagem("");
        // Inicia o bloco protegido para tratar falhas de rede, interpretação da resposta ou validação.
        try {
            // Monta a rota usando o tipo e o identificador da conta ou empréstimo selecionado.
            const resposta = await fetch(`${apiUrl}/pendencias/${selecionada.tipo}/${selecionada.id}/pagar`, {
                // POST solicita a gravação; include envia a sessão e Content-Type informa que o corpo é JSON.
                method: "POST", credentials: "include", headers: { "Content-Type": "application/json" },
                // Envia o vencimento exato; o backend verifica se essa ocorrência ainda está aberta antes de pagar.
                body: JSON.stringify({ vencimento: selecionada.vencimento })
            });
            // Aguarda a conversão do corpo JSON da resposta em um objeto JavaScript.
            const dados = await resposta.json();
            // Só continua se o servidor confirmar sucesso; caso contrário, encaminha a mensagem para catch.
            if (!resposta.ok || !dados.sucesso) throw new Error(dados.mensagem || "Não foi possível salvar o pagamento.");
            // Após confirmação da API, cria uma lista sem a ocorrência paga; a chave distingue cada vencimento.
            setPendencias((atuais) => atuais.filter((item) => item.chave !== selecionada.chave));
            // Limpa a seleção, fazendo a janela de confirmação desaparecer.
            setSelecionada(null);
            // Informa que a ocorrência foi paga, mas os vencimentos futuros continuam sendo acompanhados.
            setMensagem("Pagamento registrado. A ocorrência paga foi removida; os próximos vencimentos continuam sendo acompanhados.");
            // Avisa o App para atualizar os dados financeiros; só chama o callback se ele existir.
            onPagamento?.();
            // Consulta novamente os próximos vencimentos em aberto após a confirmação do pagamento.
            await carregar();
        // Captura uma falha lançada dentro do bloco try.
        } catch (error) {
            // Exibe a falha; sem confirmação da API, a ocorrência não é removida pelo fluxo de sucesso.
            setErro(error.message || "Não foi possível salvar o pagamento. Atualize a lista antes de tentar novamente.");
            // Encerra um indicador de consulta que possa ter ficado ativo após o cancelamento anterior.
            setCarregando(false);
        // Executa a finalização tanto após sucesso quanto após falha.
        } finally {
            // Libera a trava para permitir outra tentativa de pagamento.
            pagamentoEmCurso.current = false;
            // Encerra o salvamento visual e reabilita os botões.
            setSalvando(false);
        }
    }

    // Procura um nome legível para o projeto ou para a conta geral da missão.
    function nomeProjeto(conta) {
        // O identificador zero representa a missão geral, sem projeto específico.
        if (String(conta) === "0") return "Missão Guadalupe";
        // Compara os IDs como texto; retorna o nome encontrado, o próprio ID ou um traço, nessa ordem.
        return projetos.find((projeto) => String(projeto.id_projeto) === String(conta))?.nome || conta || "—";
    }

    // Retorna o JSX que o React transforma na interface da página.
    return (
        // Organiza o menu lateral e a área principal no layout geral.
        <div className="app">
            {/* Marca Pendências como ativa e fornece ao menu o tipo do usuário e a função de saída. */}
            <Sidebar paginaAtiva="Pendências" tipoUsuario={usuario.tipo} onLogout={onLogout} />
            {/* Agrupa o cabeçalho e o conteúdo ao lado do menu. */}
            <div className="main">
                {/* Mostra o cabeçalho compartilhado com os dados do usuário conectado. */}
                <Header usuario={usuario} />
                {/* Identifica o conteúdo principal e aplica os espaçamentos da página. */}
                <main className="entradas-content">
                    {/* Exibe título, descrição e botão Atualizar; bloqueia o botão durante carregamento ou pagamento. */}
                    <div className="entradas-titlebar"><div><h1>Pendências</h1><p>Próximo vencimento em aberto de cada conta recorrente e empréstimo parcelado</p></div><button type="button" className="entradas-primary" disabled={carregando || salvando} onClick={carregar}>Atualizar</button></div>
                    {/* Explica as faixas de prioridade usadas pelo backend. */}
                    <p className="pendencias-legenda">Alta: vencidas ou até 2 dias • Média: de 3 a 13 dias • Baixa: a partir de 14 dias</p>
                    {/* Mostra a confirmação somente quando preenchida; role=status anuncia a atualização a leitores de tela. */}
                    {mensagem && <p role="status">{mensagem}</p>}
                    {/* Exibe o erro quando houver; role=alert destaca a mensagem para leitores de tela. */}
                    {erro && <p className="mov-modal-error" role="alert">{erro}</p>}
                    {/* Percorre os avisos recebidos e cria um parágrafo para cada um; key identifica os elementos para o React. */}
                    {avisos.length > 0 && <div role="alert">{avisos.map((aviso) => <p key={aviso}>{aviso}</p>)}</div>}
                    {/* Agrupa os cartões e dá à seção um nome acessível com aria-label. */}
                    <section className="entradas-summary" aria-label="Prioridades">
                        {/* Cria um cartão por prioridade; filter conta as ocorrências e mostra um traço durante carregamento ou erro. */}
                        {["Alta", "Média", "Baixa"].map((prioridade) => <article key={prioridade}><span className={classePrioridade(prioridade)}>{prioridade}</span><div><small>Pendências</small><strong>{carregando || erro ? "—" : pendencias.filter((item) => item.prioridade === prioridade).length}</strong></div></article>)}
                    </section>
                    {/* Contém a listagem; aria-busy informa que os dados estão sendo carregados. */}
                    <section className="entradas-table-card" aria-label="Pendências financeiras" aria-busy={carregando}>
                        {/* Escolhe entre carregamento, erro, lista vazia e tabela; falhas não são apresentadas como ausência de pendências. */}
                        {carregando ? <div className="entradas-empty" role="status">Carregando pendências...</div> : erro ? <div className="entradas-empty">Atualize a lista para consultar os vencimentos.</div> : pendencias.length === 0 ? (
                            // Mostra o estado vazio apenas após uma consulta bem-sucedida que não trouxe ocorrências.
                            <div className="entradas-empty"><strong>Nenhuma pendência encontrada</strong><span>Não há vencimentos em aberto para as contas recorrentes e os empréstimos parcelados consultados.</span></div>
                        ) : (
                            // Permite rolagem horizontal quando a tabela é mais larga que a tela.
                            <div className="entradas-table-scroll"><table>
                                {/* Define os títulos das seis colunas da tabela. */}
                                <thead><tr><th>PRIORIDADE</th><th>DESCRIÇÃO</th><th>PROJETO / CASA</th><th>VENCIMENTO</th><th>VALOR</th><th>AÇÃO</th></tr></thead>
                                {/* Cria uma linha por ocorrência; item.chave diferencia inclusive os vencimentos de uma mesma conta. */}
                                <tbody>{pendencias.map((item) => <tr key={item.chave}>
                                    {/* Exibe a prioridade com a classe CSS que determina sua cor. */}
                                    <td><span className={classePrioridade(item.prioridade)}>{item.prioridade}</span></td>
                                    {/* Mostra a descrição e identifica a conta recorrente ou o número da parcela do empréstimo. */}
                                    <td><strong>{item.descricao || "—"}</strong><small className="pendencia-detalhe">{item.tipo === "despesa" ? "Conta recorrente" : `Empréstimo — parcela ${item.parcela}/${item.parcelas}`}</small></td>
                                    {/* Preenche projeto, data formatada, prazo em dias e valor em reais da ocorrência. */}
                                    <td>{nomeProjeto(item.conta)}</td><td>{dataBrasileira(item.vencimento)}<small className="pendencia-detalhe">{prazo(item.dias)}</small></td><td>{moeda.format(item.valor)}</td>
                                    {/* O clique seleciona a ocorrência, abre a confirmação e limpa o sucesso anterior; ainda não grava o pagamento. */}
                                    <td><button type="button" className="pendencia-pagar" disabled={salvando} onClick={() => { setSelecionada(item); setMensagem(""); }}>Marcar como paga</button></td>
                                </tr>)}</tbody>
                            </table></div>
                        )}
                    </section>
                </main>
            </div>
            {/* Abre o modal somente com uma seleção; os atributos aria identificam seu tipo e seu título acessível. */}
            {selecionada && <div className="mov-modal-overlay"><section className="mov-modal pendencia-confirmacao" role="dialog" aria-modal="true" aria-labelledby="confirmar-pagamento">
                {/* Define o título; seu id é referenciado por aria-labelledby na janela. */}
                <header><h2 id="confirmar-pagamento">Confirmar pagamento</h2></header>
                {/* Permite conferir a descrição e o valor antes de confirmar o pagamento. */}
                <p>{selecionada.descricao} — {moeda.format(selecionada.valor)}</p>
                {/* Mostra a data exata e acrescenta o número da parcela quando a seleção for um empréstimo. */}
                <p>Vencimento: {dataBrasileira(selecionada.vencimento)}{selecionada.parcela ? ` • Parcela ${selecionada.parcela}/${selecionada.parcelas}` : ""}</p>
                {/* Esclarece que a confirmação paga apenas o vencimento selecionado. */}
                <p>Somente este vencimento será marcado como pago.</p>
                {/* Exibe o erro quando houver; role=alert destaca a mensagem para leitores de tela. */}
                {erro && <p className="mov-modal-error" role="alert">{erro}</p>}
                {/* Cancelar recebe o foco inicial e fecha a janela; Confirmar chama pagar e mostra Salvando durante o envio. */}
                <footer><div><button type="button" autoFocus className="mov-cancel" disabled={salvando} onClick={() => setSelecionada(null)}>Cancelar</button><button type="button" className="mov-save" disabled={salvando} onClick={pagar}>{salvando ? "Salvando..." : "Confirmar pagamento"}</button></div></footer>
            </section></div>}
        </div>
    );
}
