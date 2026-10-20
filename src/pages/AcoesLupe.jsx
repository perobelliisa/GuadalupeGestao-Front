export default function AcoesLupe({ acoes, ocupado, onDecidir }) {
    return acoes.filter(acao => ['preparada', 'executando'].includes(acao.estado)).slice(-1).map(acao => <section key={acao.id} className={`lupe-proposta ${acao.destrutiva ? "lupe-proposta-exclusao" : ""}`} aria-label={acao.titulo}>
        <h3>{acao.titulo}</h3>
        {acao.estado === "preparada" ? <>
            {!!acao.descricao && <p>{acao.descricao}</p>}
            <dl>{acao.campos.map((campo, indice) => <div key={indice}><dt>{campo.campo}</dt><dd>{campo.antes ? <><span>{campo.antes}</span> → </> : null}<strong>{campo.depois}</strong></dd></div>)}</dl>
            <div className="lupe-proposta-botoes"><button disabled={ocupado} onClick={() => onDecidir(acao, false)}>Cancelar</button><button className="lupe-proposta-confirmar" disabled={ocupado} onClick={() => onDecidir(acao, true)}>{acao.destrutiva ? "Confirmar exclusão" : "Confirmar"}</button></div>
        </> : <p className="lupe-proposta-estado">Estou concluindo essa ação…</p>}
    </section>);
}
