import { UploadCloud } from "lucide-react";
import "./FormularioMovimentacao.css";

export default function AnexoMovimentacao({ arquivo, onChange }) {
    return (
        <label className="entrada-upload">
            <UploadCloud size={22} />
            <strong>{arquivo || "Arraste arquivos ou clique para enviar"}</strong>
            <span>PDF, JPG ou PNG</span>
            <input name="anexo" type="file" accept=".pdf,.jpg,.jpeg,.png" onChange={onChange} />
        </label>
    );
}
