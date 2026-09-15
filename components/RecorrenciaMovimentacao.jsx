import { useState } from "react";
import "./FormularioMovimentacao.css";

export const RECORRENCIAS = [
    { valor: "0", nome: "Não recorrente", dias: 0 },
    { valor: "1", nome: "A cada 15 dias", dias: 15 },
    { valor: "2", nome: "A cada 30 dias", dias: 30 },
    { valor: "3", nome: "Todo dia", dias: 1 },
    { valor: "4", nome: "Semanal", dias: 7 }
];

// Calcula a primeira data de fim permitida para o intervalo escolhido.
function somarDias(dataTexto, dias) {
    if (!dataTexto || !dias) return "";
    const data = new Date(`${dataTexto}T00:00:00`);
    data.setDate(data.getDate() + dias);
    return data.toISOString().slice(0, 10);
}

// Verifica se as datas preenchidas respeitam a recorrência selecionada.
export function validarRecorrencia(dados) {
    const recorrencia = String(dados.recorrencia || "0");
    const inicio = dados.dia_inicio || "";
    const fim = dados.dia_fim || "";
    const opcao = RECORRENCIAS.find((item) => item.valor === recorrencia);

    if (recorrencia !== "0" && (!inicio || !fim)) return "Informe as datas de início e fim para essa recorrência.";
    if ((inicio && !fim) || (!inicio && fim)) return "Informe as duas datas da recorrência.";
    if (!inicio && !fim) return "";

    const diferenca = Math.round((new Date(`${fim}T00:00:00`) - new Date(`${inicio}T00:00:00`)) / 86400000);
    if (diferenca <= 0) return "A data de fim deve ser posterior à data de início.";
    if (opcao?.dias && diferenca < opcao.dias) return `A data de fim deve respeitar pelo menos ${opcao.dias} dias de recorrência.`;
    return "";
}

// Renderiza a recorrência e controla as datas exigidas por ela.
export default function RecorrenciaMovimentacao({ defaultRecorrencia = "", defaultInicio = "", defaultFim = "" }) {
    const [recorrencia, setRecorrencia] = useState(defaultRecorrencia === null || defaultRecorrencia === undefined ? "" : String(defaultRecorrencia));
    const [inicio, setInicio] = useState(defaultInicio || "");
    const opcao = RECORRENCIAS.find((item) => item.valor === recorrencia);
    const exigeDatas = recorrencia !== "" && recorrencia !== "0";
    const menorDataFim = somarDias(inicio, opcao?.dias || (inicio ? 1 : 0));

    return <>
        <label className="entrada-field"><span>Recorrência</span><select name="recorrencia" value={recorrencia} onChange={(event) => setRecorrencia(event.target.value)}><option value="">Selecione</option>{RECORRENCIAS.map((item) => <option key={item.valor} value={item.valor}>{item.nome}</option>)}</select></label>
        <label className="entrada-field"><span>Data de início{exigeDatas && <b>*</b>}</span><input name="dia_inicio" type="date" value={inicio} onChange={(event) => setInicio(event.target.value)} required={exigeDatas} /></label>
        <label className="entrada-field"><span>Data de fim{exigeDatas && <b>*</b>}</span><input name="dia_fim" type="date" min={menorDataFim || undefined} defaultValue={defaultFim || ""} required={exigeDatas} /></label>
        {exigeDatas && <small className="entrada-field-hint full">A data de fim deve ficar pelo menos {opcao?.dias} dias após o início.</small>}
    </>;
}
