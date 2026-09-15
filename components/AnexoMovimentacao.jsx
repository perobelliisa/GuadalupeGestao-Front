import { UploadCloud } from "lucide-react";
import { useEffect, useState } from "react";
import "./FormularioMovimentacao.css";

export default function AnexoMovimentacao({ arquivo, imagemInicial, onChange }) {
    const [nomeArquivo, setNomeArquivo] = useState("");
    const [imagem, setImagem] = useState(imagemInicial || "");

    useEffect(() => {
        return () => {
            if (imagem) URL.revokeObjectURL(imagem);
        };
    }, [imagem]);

    function selecionarArquivo(event) {
        const arquivoSelecionado = event.target.files[0];
        setNomeArquivo(arquivoSelecionado ? arquivoSelecionado.name : "");
        if (arquivoSelecionado && arquivoSelecionado.type.startsWith("image/")) {
            setImagem(URL.createObjectURL(arquivoSelecionado));
        } else {
            setImagem("");
        }
        if (onChange) onChange(event);
    }

    const nomeExibido = nomeArquivo || arquivo;

    return (
        <label className="entrada-upload">
            {imagem && <img className="entrada-upload-preview" src={imagem} alt="Prévia do anexo" />}
            {!imagem && <UploadCloud size={22} />}
            <strong>{nomeExibido || "Nenhum arquivo selecionado"}</strong>
            <span>PDF, JPG ou PNG</span>
            <span className="entrada-upload-button">Escolher arquivo</span>
            <input name="anexo" type="file" accept=".pdf,.jpg,.jpeg,.png" onChange={selecionarArquivo} />
        </label>
    );
}
