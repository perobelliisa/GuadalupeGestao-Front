import { useEffect, useState } from 'react';
import { History, RefreshCw, Search } from 'lucide-react';
import Sidebar from '../../components/Sidebar.jsx';
import Header from '../../components/Header.jsx';
import { API_URL } from '../config/api.js';
import './Dashboard.css';
import './Logs.css';

const ACOES = { INSERT: 'Inclusão', UPDATE: 'Alteração', DELETE: 'Exclusão' };
const INICIAL = { inicio: '', fim: '', usuario: '', tabela: '', acao: '', registro: '' };

function quando(valor) {
    // O Firebird armazena hora civil sem fuso. Não converter para UTC no navegador.
    if (!valor) return 'Data não informada';
    const [data, hora = ''] = valor.split('T');
    return `${data.split('-').reverse().join('/')} às ${hora.slice(0, 8)}`;
}

export default function Logs({ usuario, onLogout }) {
    const [formulario, setFormulario] = useState(INICIAL);
    const [consulta, setConsulta] = useState({ filtros: INICIAL, pagina: 1, versao: 0 });
    const [dados, setDados] = useState(null);
    const [carregando, setCarregando] = useState(true);
    const [erro, setErro] = useState('');
    const [aberto, setAberto] = useState(null);

    useEffect(() => {
        const controller = new AbortController();
        async function carregar() {
            setCarregando(true);
            setErro('');
            setAberto(null);
            try {
                const params = new URLSearchParams({ ...consulta.filtros, pagina: String(consulta.pagina), tamanho: '25' });
                const resposta = await fetch(`${API_URL}/logs?${params}`, { credentials: 'include', signal: controller.signal });
                const retorno = await resposta.json().catch(() => ({}));
                if (!resposta.ok || !retorno.sucesso) throw new Error(retorno.mensagem || 'Não foi possível carregar o histórico.');
                setDados(retorno);
            } catch (e) {
                if (e.name !== 'AbortError') { setDados(null); setErro(e.message); }
            } finally {
                if (!controller.signal.aborted) setCarregando(false);
            }
        }
        carregar();
        return () => controller.abort();
    }, [consulta]);

    function filtrar(event) {
        event.preventDefault();
        setConsulta({ filtros: { ...formulario }, pagina: 1, versao: consulta.versao + 1 });
    }

    function campo(nome, valor) { setFormulario(atual => ({ ...atual, [nome]: valor })); }

    return <div className="app">
        <Sidebar paginaAtiva="Logs" tipoUsuario={usuario.tipo} onLogout={onLogout} />
        <div className="main">
            <Header usuario={usuario} />
            <main className="content logs-content">
                <div className="page-header logs-heading">
                    <div><span className="logs-eyebrow"><History size={15} aria-hidden="true" /> HISTÓRICO DA MISSÃO</span>
                        <h1>Logs de alterações</h1><p>Acompanhe o que mudou, quando e quem realizou cada ação.</p></div>
                    <button className="logs-button" disabled={carregando} onClick={() => setConsulta(atual => ({ ...atual, versao: atual.versao + 1 }))}>
                        <RefreshCw size={16} aria-hidden="true" /> Atualizar</button>
                </div>
                <form className="logs-filters" onSubmit={filtrar}>
                    <label>De<input type="date" value={formulario.inicio} onChange={e => campo('inicio', e.target.value)} /></label>
                    <label>Até<input type="date" min={formulario.inicio || undefined} value={formulario.fim} onChange={e => campo('fim', e.target.value)} /></label>
                    <label className="logs-user-filter">Usuário<input type="search" placeholder="Nome ou e-mail" maxLength={254} value={formulario.usuario} onChange={e => campo('usuario', e.target.value)} /></label>
                    <label>Tabela<select value={formulario.tabela} onChange={e => campo('tabela', e.target.value)}><option value="">Todas as tabelas</option>{(dados?.tabelas || []).map(tabela => <option key={tabela} value={tabela}>{tabela}</option>)}</select></label>
                    <label>Ação<select value={formulario.acao} onChange={e => campo('acao', e.target.value)}><option value="">Todas as ações</option>{Object.entries(ACOES).map(([valor, nome]) => <option key={valor} value={valor}>{nome}</option>)}</select></label>
                    <label>Registro<input placeholder="ID do registro" maxLength={254} value={formulario.registro} onChange={e => campo('registro', e.target.value)} /></label>
                    <div className="logs-filter-actions"><button className="logs-button logs-primary" type="submit" disabled={carregando}><Search size={16} aria-hidden="true" /> Filtrar</button>
                        <button className="logs-clear" type="button" onClick={() => { setFormulario(INICIAL); setConsulta({ filtros: INICIAL, pagina: 1, versao: consulta.versao + 1 }); }}>Limpar filtros</button></div>
                </form>
                <div className="logs-caption"><span>{carregando ? 'Consultando histórico…' : dados ? `${dados.total} ${dados.total === 1 ? 'registro encontrado' : 'registros encontrados'}` : 'Histórico indisponível'}</span><span>Mais recentes primeiro · Horário do servidor</span></div>
                {erro && <div className="logs-error" role="alert">{erro}<button className="logs-clear" onClick={() => setConsulta(atual => ({ ...atual, versao: atual.versao + 1 }))}>Tentar novamente</button></div>}
                {carregando ? <div className="logs-empty" role="status">Carregando alterações…</div> : !erro && <>
                    {dados?.logs.length === 0 ? <div className="logs-empty"><History size={32} aria-hidden="true" /><h2>Nenhuma alteração encontrada</h2><p>Experimente outro período ou limpe os filtros.</p></div> : <div className="logs-list">{dados?.logs.map(item => <article className="logs-item" key={item.id}>
                        <div className="logs-item-top"><div className="logs-actor"><div className="logs-avatar" aria-hidden="true">{item.nome_usuario[0]}</div><div><strong>{item.nome_usuario}</strong><span>{item.email && item.email !== 'NAO IDENTIFICADO' ? item.email : item.identificacao_legada ? 'Nome definido para o histórico antigo' : 'Sem sessão de usuário'}</span></div></div><time dateTime={item.data_hora}>{quando(item.data_hora)}</time></div>
                        <div className="logs-item-bottom"><div className="logs-item-meta"><span className={`logs-badge logs-${item.acao.toLowerCase()}`}>{ACOES[item.acao] || item.acao}</span><strong>{item.tabela.replaceAll('_', ' ')}</strong>{item.registro_id && <span>Registro #{item.registro_id}</span>}<span className="logs-event-id">Evento #{item.id}</span></div><button className="logs-detail-button" aria-expanded={aberto === item.id} aria-controls={`log-${item.id}`} onClick={() => setAberto(aberto === item.id ? null : item.id)}>{aberto === item.id ? 'Fechar detalhes' : 'Ver alteração'}</button></div>
                        {aberto === item.id && <div className="logs-details" id={`log-${item.id}`}>
                            <div className="logs-fields"><strong>Campos registrados</strong><p>{item.campos}</p></div>
                            <div className="logs-comparison"><section><h3>Antes</h3><pre>{item.acao === 'INSERT' ? 'O registro ainda não existia.' : item.antes || 'Sem valor registrado.'}</pre></section><section><h3>Depois</h3><pre>{item.acao === 'DELETE' ? 'O registro foi excluído.' : item.depois || 'Sem valor registrado.'}</pre></section></div>
                            <p className="logs-device">Origem: {item.dispositivo || 'Não informada'}{item.id_usuario != null && ` · Usuário #${item.id_usuario}`}</p>
                            {item.identificacao_legada && <p className="logs-legacy">Rodrigo foi definido como nome de exibição para este registro antigo, que não tinha autoria salva.</p>}
                        </div>}
                    </article>)}</div>}
                    {dados && dados.total > 0 && <nav className="logs-pagination" aria-label="Paginação do histórico"><span>Página {dados.pagina} de {dados.paginas}</span><div><button className="logs-button" disabled={dados.pagina <= 1} onClick={() => setConsulta(atual => ({ ...atual, pagina: atual.pagina - 1 }))}>Anterior</button><button className="logs-button" disabled={dados.pagina >= dados.paginas} onClick={() => setConsulta(atual => ({ ...atual, pagina: atual.pagina + 1 }))}>Próxima</button></div></nav>}
                </>}
            </main>
        </div>
    </div>;
}
