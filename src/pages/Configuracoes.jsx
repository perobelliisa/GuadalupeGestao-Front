import Sidebar from "../../components/Sidebar.jsx";
import Header from "../../components/Header.jsx";
import { Save, UserRound } from "lucide-react";
import { useEffect, useState } from "react";
import "./Dashboard.css";
import "./Configuracoes.css";

export default function Configuracoes({ usuario, apiUrl, onUsuarioAtualizado, onLogout }) {
    const [dados, setDados] = useState(null);
    const [carregando, setCarregando] = useState(true);
    const [salvando, setSalvando] = useState(false);
    const [mensagem, setMensagem] = useState(null);

    useEffect(() => {
        const controller = new AbortController();
        async function carregarConta() {
            try {
                const resposta = await fetch(`${apiUrl}/minha-conta`, { credentials: "include", signal: controller.signal });
                const retorno = await resposta.json().catch(() => ({}));
                if (!resposta.ok || !retorno.sucesso) throw new Error(retorno.mensagem || retorno.erro || "Não foi possível carregar sua conta.");
                const conta = retorno.usuario;
                if (!conta) throw new Error("A conta autenticada não foi encontrada.");
                setDados({ nome: conta.nome ?? "", email: conta.email ?? "", tipo: String(conta.tipo ?? ""), status: String(conta.status ?? "") });
            } catch (error) {
                if (error.name !== "AbortError") setMensagem({ tipo: "erro", texto: error.message });
            } finally {
                if (!controller.signal.aborted) setCarregando(false);
            }
        }
        carregarConta();
        return () => controller.abort();
    }, [apiUrl, usuario.id]);

    function alterar(campo, valor) {
        setDados((atual) => ({ ...atual, [campo]: valor }));
    }

    async function salvar(event) {
        event.preventDefault();
        setSalvando(true);
        setMensagem(null);
        const formulario = new FormData();
        formulario.append("nome", dados.nome);
        formulario.append("email", dados.email);
        formulario.append("tipo", dados.tipo);
        formulario.append("status", dados.status);

        try {
            const resposta = await fetch(`${apiUrl}/minha-conta`, { method: "PUT", credentials: "include", body: formulario });
            const retorno = await resposta.json().catch(() => ({}));
            if (!resposta.ok || !retorno.sucesso) throw new Error(retorno.mensagem || retorno.erro || "Não foi possível salvar as alterações.");
            onUsuarioAtualizado?.(dados);
            setMensagem({ tipo: "sucesso", texto: retorno.mensagem || "Conta atualizada com sucesso." });
        } catch (error) {
            setMensagem({ tipo: "erro", texto: error.message });
        } finally {
            setSalvando(false);
        }
    }

    return <div className="app"><Sidebar paginaAtiva="Configurações" tipoUsuario={usuario.tipo} onLogout={onLogout}/><div className="main"><Header usuario={usuario}/><main className="configuracoes-content">
        <form onSubmit={salvar}>
            <div className="configuracoes-title"><div><h1>Configurações</h1><p>Gerencie os dados da conta autenticada</p></div><button type="submit" disabled={!dados || salvando}><Save size={16}/>{salvando ? "Salvando..." : "Salvar alterações"}</button></div>
            {mensagem && <p className={`configuracoes-message ${mensagem.tipo}`} role={mensagem.tipo === "erro" ? "alert" : "status"}>{mensagem.texto}</p>}
            <section className="configuracoes-panel">
                <div className="configuracoes-panel-heading"><span><UserRound size={18}/></span><div><h2>Dados da conta</h2><p>Informações cadastradas na tabela de usuários.</p></div></div>
                {carregando ? <p className="configuracoes-state">Carregando dados da conta...</p> : dados ? <div className="configuracoes-grid">
                    <label className="configuracoes-field"><span>Nome</span><input value={dados.nome} onChange={(event) => alterar("nome", event.target.value)} required /></label>
                    <label className="configuracoes-field"><span>E-mail</span><input type="email" value={dados.email} onChange={(event) => alterar("email", event.target.value)} required /></label>
                    <label className="configuracoes-field"><span>Perfil de acesso</span><select value={dados.tipo} onChange={(event) => alterar("tipo", event.target.value)} required><option value="0">Administrador geral</option><option value="1">Financeiro</option><option value="2">Voluntário</option></select></label>
                    <label className="configuracoes-field"><span>Status</span><select value={dados.status} onChange={(event) => alterar("status", event.target.value)} required><option value="0">Ativo</option><option value="1">Inativo</option></select></label>
                </div> : <p className="configuracoes-state">Não foi possível exibir os dados da conta.</p>}
            </section>
        </form>
    </main></div></div>;
}
