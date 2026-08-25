// Ativa verificações adicionais do React durante o desenvolvimento.
import { StrictMode } from "react";
// Importa a função que cria a raiz de renderização da aplicação no navegador.
import { createRoot } from "react-dom/client";
// Importa o componente principal, responsável pelas rotas e pelo estado global.
import App from "./App.jsx";

// Localiza o elemento HTML com id "root" e cria nele a raiz da aplicação React.
createRoot(document.getElementById("root")).render(
    // Executa verificações extras para encontrar efeitos colaterais e APIs obsoletas.
    <StrictMode>
        <App />
    </StrictMode>
);
