import { useState } from "react";
import "./FormularioMovimentacao.css";

// Compara origens ignorando espaços e diferença entre maiúsculas e minúsculas.
function mesmaOrigem(primeira, segunda) {
    return String(primeira || "").trim().toLocaleLowerCase("pt-BR") === String(segunda || "").trim().toLocaleLowerCase("pt-BR");
}

// Exibe origens já usadas e oferece um campo para cadastrar uma nova.
export default function OrigemMovimentacao({ label, origens = [], defaultValue = "", placeholder }) {
    const origemExiste = origens.some((origem) => mesmaOrigem(origem, defaultValue));
    const [origemSelecionada, setOrigemSelecionada] = useState(defaultValue && origemExiste ? defaultValue : (defaultValue ? "__nova__" : ""));
    const informandoNovaOrigem = origemSelecionada === "__nova__";

    return (
        <label className="entrada-field">
            <span>{label}<b>*</b></span>
            <select name={informandoNovaOrigem ? undefined : "origem"} value={origemSelecionada} onChange={(event) => setOrigemSelecionada(event.target.value)} required>
                <option value="" disabled>Selecione uma origem</option>
                {origens.map((origem) => <option key={origem} value={origem}>{origem}</option>)}
                <option value="__nova__">+ Informar nova origem</option>
            </select>
            {informandoNovaOrigem && <input name="origem" defaultValue={origemExiste ? defaultValue : ""} placeholder={placeholder} required />}
            <small className="entrada-field-hint">Escolha uma origem já usada ou informe uma nova para ela ficar disponível nos próximos lançamentos.</small>
        </label>
    );
}
