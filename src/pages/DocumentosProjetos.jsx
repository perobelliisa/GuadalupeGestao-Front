import { useEffect, useMemo, useRef, useState } from "react";
import {
    FileImage,
    FileText,
    Folder,
    Grid3X3,
    List,
    Search,
    Upload,
    UploadCloud,
    Trash2,
    X
} from "lucide-react";
import Sidebar from "../../components/Sidebar.jsx";
import Header from "../../components/Header.jsx";
import "./DocumentosProjetos.css";

function normalizarDocumento(documento, indice) {
    const caminho = documento.caminho || documento.url || documento.arquivo || documento.anexo || "";
    const nomeDoCaminho = String(caminho).split("/").pop();
    return {
        ...documento,
        id: documento.id_documento ?? documento.id ?? `${nomeDoCaminho}-${indice}`,
        nome: documento.nome || documento.nome_arquivo || nomeDoCaminho || "Documento sem nome",
        caminho,
        data: documento.data || documento.criado_em || documento.created_at || "",
        projetos: documento.projetos || (documento.id_projeto ? [documento.id_projeto] : [])
    };
}

function formatarData(valor) {
    if (!valor) return "";
    const data = new Date(String(valor).length === 10 ? `${valor}T12:00:00` : valor);
    return Number.isNaN(data.getTime()) ? "" : new Intl.DateTimeFormat("pt-BR").format(data);
}

function eImagem(nome = "") {
    return /\.(jpe?g|png|gif|webp)$/i.test(nome);
}

export default function DocumentosProjetos({ usuario, apiUrl, projetos = [], onLogout }) {
    const [documentos, setDocumentos] = useState([]);
    const [busca, setBusca] = useState("");
    const [projetoAtivo, setProjetoAtivo] = useState("");
    const [visualizacao, setVisualizacao] = useState("grade");
    const [modalAberto, setModalAberto] = useState(false);
    const [arquivo, setArquivo] = useState(null);
    const [titulo, setTitulo] = useState("");
    const [projetosSelecionados, setProjetosSelecionados] = useState([]);
    const [enviando, setEnviando] = useState(false);
    const [excluindo, setExcluindo] = useState(null);
    const [documentoParaExcluir, setDocumentoParaExcluir] = useState(null);
    const [mensagem, setMensagem] = useState(null);
    const inputArquivo = useRef(null);

    useEffect(() => {
        const controller = new AbortController();
        async function carregar() {
            try {
                const resposta = await fetch(`${apiUrl}/documentos`, {
                    credentials: "include",
                    signal: controller.signal
                });
                const dados = await resposta.json().catch(() => ({}));
                const lista = Array.isArray(dados) ? dados : dados.documentos;
                if (resposta.ok && Array.isArray(lista)) {
                    setDocumentos(lista.map(normalizarDocumento));
                }
            } catch (erro) {
                if (erro.name !== "AbortError") setMensagem({ tipo: "erro", texto: "Não foi possível carregar os documentos." });
            }
        }
        carregar();
        return () => controller.abort();
    }, [apiUrl]);

    const documentosFiltrados = useMemo(() => documentos.filter((documento) => {
        const termo = busca.trim().toLocaleLowerCase("pt-BR");
        const ids = Array.isArray(documento.projetos) ? documento.projetos : [documento.projetos];
        const correspondeProjeto = !projetoAtivo || ids.some((id) => String(id?.id_projeto ?? id) === String(projetoAtivo));
        return correspondeProjeto && (!termo || documento.nome.toLocaleLowerCase("pt-BR").includes(termo));
    }), [busca, documentos, projetoAtivo]);

    function alternarProjeto(id) {
        setProjetosSelecionados((atuais) => atuais.includes(String(id))
            ? atuais.filter((item) => item !== String(id))
            : [...atuais, String(id)]);
    }

    function fecharModal() {
        if (enviando) return;
        setModalAberto(false);
        setArquivo(null);
        setTitulo("");
        setProjetosSelecionados([]);
    }

    async function enviarDocumento(event) {
        event.preventDefault();
        if (!titulo.trim() || !arquivo || projetosSelecionados.length === 0) {
            setMensagem({ tipo: "erro", texto: "Informe o título, escolha um arquivo e marque ao menos um projeto." });
            return;
        }
        setEnviando(true);
        setMensagem(null);
        try {
            const formulario = new FormData();
            formulario.append("arquivo", arquivo);
            formulario.append("titulo", titulo.trim());
            projetosSelecionados.forEach((id) => formulario.append("projetos", id));
            if (projetosSelecionados.length === 1) formulario.append("id_projeto", projetosSelecionados[0]);
            const resposta = await fetch(`${apiUrl}/documentos`, {
                method: "POST",
                credentials: "include",
                body: formulario
            });
            const dados = await resposta.json().catch(() => ({}));
            if (!resposta.ok || dados.sucesso === false) {
                throw new Error(dados.mensagem || dados.erro || `Não foi possível enviar o documento (erro ${resposta.status}).`);
            }
            const salvo = dados.documento || {
                id_documento: dados.id_documento,
                nome: titulo.trim(),
                caminho: dados.caminho || dados.url || dados.arquivo || dados.anexo,
                data: new Date().toISOString(),
                projetos: projetosSelecionados
            };
            setDocumentos((atuais) => [normalizarDocumento(salvo, atuais.length), ...atuais]);
            setModalAberto(false);
            setArquivo(null);
            setTitulo("");
            setProjetosSelecionados([]);
            setMensagem({ tipo: "sucesso", texto: "Documento enviado com sucesso." });
        } catch (erro) {
            setMensagem({ tipo: "erro", texto: erro.message });
        } finally {
            setEnviando(false);
        }
    }

    async function baixarDocumento(documento) {
        if (!documento.caminho) {
            setMensagem({ tipo: "erro", texto: "O arquivo deste documento não está disponível para download." });
            return;
        }
        try {
            const url = /^https?:|^blob:|^data:/i.test(documento.caminho)
                ? documento.caminho
                : `${apiUrl}${documento.caminho.startsWith("/") ? "" : "/"}${documento.caminho}`;
            const resposta = await fetch(url, { credentials: "include" });
            if (!resposta.ok) throw new Error();
            const blob = await resposta.blob();
            const endereco = URL.createObjectURL(blob);
            const link = document.createElement("a");
            link.href = endereco;
            const extensao = String(documento.caminho).match(/\.[a-z0-9]+(?:\?|$)/i)?.[0]?.replace("?", "") || "";
            link.download = /\.[a-z0-9]+$/i.test(documento.nome) ? documento.nome : `${documento.nome}${extensao}`;
            document.body.appendChild(link);
            link.click();
            link.remove();
            URL.revokeObjectURL(endereco);
        } catch {
            setMensagem({ tipo: "erro", texto: "Não foi possível baixar o arquivo." });
        }
    }

    async function excluirDocumento(documento) {
        setExcluindo(documento.id);
        setMensagem(null);
        try {
            const resposta = await fetch(`${apiUrl}/documentos/${documento.id}`, {
                method: "DELETE",
                credentials: "include"
            });
            const dados = await resposta.json().catch(() => ({}));
            if (!resposta.ok || dados.sucesso === false) {
                throw new Error(dados.mensagem || dados.erro || `Não foi possível excluir o documento (erro ${resposta.status}).`);
            }
            setDocumentos((atuais) => atuais.filter((item) => item.id !== documento.id));
            setDocumentoParaExcluir(null);
            setMensagem({ tipo: "sucesso", texto: "Documento excluído com sucesso." });
        } catch (erro) {
            setMensagem({ tipo: "erro", texto: erro.message });
        } finally {
            setExcluindo(null);
        }
    }

    return (
        <div className="app">
            <Sidebar paginaAtiva="Documentos dos Projetos" tipoUsuario={usuario.tipo} onLogout={onLogout} />
            <div className="main">
                <Header usuario={usuario} />
                <main className="documentos-content">
                    <div className="documentos-titlebar">
                        <div><h1>Documentos dos Projetos</h1><p>Biblioteca central de comprovantes, relatórios e arquivos institucionais</p></div>
                        <button type="button" onClick={() => { setMensagem(null); setModalAberto(true); }}><Upload size={16} /> Enviar documento</button>
                    </div>

                    {mensagem && <div className={`documentos-message ${mensagem.tipo}`}>{mensagem.texto}</div>}

                    <div className="documentos-projetos" aria-label="Filtrar por projeto">
                        <button className={!projetoAtivo ? "ativo" : ""} onClick={() => setProjetoAtivo("")}><Folder size={15} /> Todos <small>{documentos.length}</small></button>
                        {projetos.map((projeto) => {
                            const quantidade = documentos.filter((documento) => (Array.isArray(documento.projetos) ? documento.projetos : [documento.projetos]).some((id) => String(id?.id_projeto ?? id) === String(projeto.id_projeto))).length;
                            return <button className={String(projetoAtivo) === String(projeto.id_projeto) ? "ativo" : ""} key={projeto.id_projeto} onClick={() => setProjetoAtivo(projeto.id_projeto)}><Folder size={15} /> {projeto.nome} <small>{quantidade}</small></button>;
                        })}
                    </div>

                    <section className="documentos-toolbar">
                        <label><Search size={16} /><input type="search" placeholder="Buscar documento..." value={busca} onChange={(event) => setBusca(event.target.value)} /></label>
                        <div className="documentos-view">
                            <button className={visualizacao === "grade" ? "ativo" : ""} onClick={() => setVisualizacao("grade")} aria-label="Visualização em grade"><Grid3X3 size={16} /></button>
                            <button className={visualizacao === "lista" ? "ativo" : ""} onClick={() => setVisualizacao("lista")} aria-label="Visualização em lista"><List size={17} /></button>
                        </div>
                    </section>

                    <section className={`documentos-grid ${visualizacao}`}>
                        {documentosFiltrados.length ? documentosFiltrados.map((documento) => (
                            <article className="documento-card" key={documento.id}>
                                <button type="button" className="documento-download" onClick={() => baixarDocumento(documento)} title={`Baixar ${documento.nome}`}>
                                    <span className="documento-icon">{eImagem(documento.nome) ? <FileImage size={19} /> : <FileText size={19} />}</span>
                                    <strong>{documento.nome}</strong>
                                    <time>{formatarData(documento.data)}</time>
                                </button>
                                <button type="button" className="documento-delete" onClick={() => setDocumentoParaExcluir(documento)} disabled={excluindo === documento.id} aria-label={`Excluir ${documento.nome}`} title="Excluir documento">
                                    <Trash2 size={16} />
                                </button>
                            </article>
                        )) : <div className="documentos-empty"><FileText size={30} /><strong>Nenhum documento encontrado</strong><span>Envie um arquivo ou altere os filtros.</span></div>}
                    </section>
                </main>
            </div>

            {modalAberto && (
                <div className="documentos-modal-overlay" onMouseDown={(event) => event.target === event.currentTarget && fecharModal()}>
                    <form className="documentos-modal" onSubmit={enviarDocumento}>
                        <header><div><h2>Enviar documento</h2><p>Adicione o arquivo e indique a quais projetos ele pertence.</p></div><button type="button" onClick={fecharModal} aria-label="Fechar"><X size={20} /></button></header>
                        <div className="documentos-modal-body">
                            <label className="documentos-title-field">
                                <span>Título do documento <b>*</b></span>
                                <input type="text" maxLength="255" value={titulo} onChange={(event) => setTitulo(event.target.value)} placeholder="Ex.: Relatório mensal — julho 2026" autoFocus />
                                <small>Este será o nome exibido no card do documento.</small>
                            </label>
                            <label className="documentos-upload">
                                <UploadCloud size={31} />
                                <strong>{arquivo?.name || "Nenhum arquivo selecionado"}</strong>
                                <span>PDF, JPG ou PNG</span>
                                <span className="documentos-upload-button">Escolher arquivo</span>
                                <input ref={inputArquivo} type="file" accept=".pdf,.jpg,.jpeg,.png" onChange={(event) => setArquivo(event.target.files[0] || null)} />
                            </label>
                            <fieldset><legend>Vincular aos projetos <b>*</b></legend><p>Marque pelo menos um projeto relacionado ao documento.</p><div className="documentos-checklist">
                                {projetos.map((projeto) => <label key={projeto.id_projeto}><input type="checkbox" checked={projetosSelecionados.includes(String(projeto.id_projeto))} onChange={() => alternarProjeto(projeto.id_projeto)} /><span>{projeto.nome}</span></label>)}
                            </div></fieldset>
                        </div>
                        <footer><button type="button" className="documentos-cancel" onClick={fecharModal}>Cancelar</button><button type="submit" className="documentos-submit" disabled={enviando}>{enviando ? "Enviando..." : "Enviar documento"}</button></footer>
                    </form>
                </div>
            )}

            {documentoParaExcluir && (
                <div className="documentos-confirm-overlay" onMouseDown={(event) => event.target === event.currentTarget && !excluindo && setDocumentoParaExcluir(null)}>
                    <section className="documentos-confirm" role="dialog" aria-modal="true" aria-labelledby="titulo-excluir-documento">
                        <span className="documentos-confirm-icon"><Trash2 size={24} /></span>
                        <h2 id="titulo-excluir-documento">Excluir documento?</h2>
                        <p>O arquivo <strong>{documentoParaExcluir.nome}</strong> será excluído definitivamente.</p>
                        <div>
                            <button type="button" className="documentos-cancel" onClick={() => setDocumentoParaExcluir(null)} disabled={Boolean(excluindo)}>Cancelar</button>
                            <button type="button" className="documentos-confirm-delete" onClick={() => excluirDocumento(documentoParaExcluir)} disabled={Boolean(excluindo)}>
                                <Trash2 size={15} /> {excluindo ? "Excluindo..." : "Excluir documento"}
                            </button>
                        </div>
                    </section>
                </div>
            )}
        </div>
    );
}
