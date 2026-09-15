import "./FormularioMovimentacao.css";
import { useState } from "react";

// Renderiza categorias existentes e permite iniciar o cadastro de uma nova.
export default function CategoriaMovimentacao({ categorias = [], tipo, defaultValue = "" }) {
    const sugestoes = categorias.filter((categoria) => Number(categoria.tipo) === Number(tipo));
    const exemplo = Number(tipo) === 0 ? "Ex.: doação, oferta ou evento" : "Ex.: alimentação, material ou transporte";
    const [categoriaSelecionada, setCategoriaSelecionada] = useState(defaultValue ? String(defaultValue) : "");
    const criandoCategoria = categoriaSelecionada === "__nova__";

    return (
        <label className="entrada-field">
            <span>Categoria<b>*</b></span>
            <select name={criandoCategoria ? undefined : "id_categoria"} value={categoriaSelecionada} onChange={(event) => setCategoriaSelecionada(event.target.value)} required>
                <option value="" disabled>Selecione uma categoria</option>
                {sugestoes.map((categoria) => <option key={categoria.id_categoria ?? categoria.id} value={categoria.id_categoria ?? categoria.id}>{categoria.nome}</option>)}
                <option value="__nova__">+ Criar nova categoria</option>
            </select>
            {criandoCategoria && <input name="categoria" placeholder={exemplo} required />}
            <small className="entrada-field-hint">Escolha uma categoria cadastrada ou crie uma nova para usar nos próximos lançamentos.</small>
        </label>
    );
}
