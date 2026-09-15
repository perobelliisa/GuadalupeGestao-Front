import "./FormularioMovimentacao.css";

export default function CampoMovimentacao({ label, name, opcoes = [], required = false, inputType = "text", placeholder }) {
    return (
        <label className="entrada-field">
            <span>{label}{required && <b>*</b>}</span>
            {opcoes.length ? (
                <select name={name} required={required} defaultValue="">
                    <option value="" disabled>Selecione</option>
                    {opcoes.map((opcao) => (
                        <option key={opcao.id ?? opcao.valor} value={opcao.valor ?? opcao.id}>
                            {opcao.nome ?? opcao.label}
                        </option>
                    ))}
                </select>
            ) : (
                <input name={name} type={inputType} required={required} placeholder={placeholder || `Informe ${label.toLocaleLowerCase("pt-BR")}`} />
            )}
        </label>
    );
}
