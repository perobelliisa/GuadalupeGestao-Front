# Guadalupe Gestão — Frontend

Interface React com Vite. A autenticação depende do backend Flask e do banco de dados dele.

## Executar localmente

1. Inicie o projeto `GuadalupeGestao-Back` e confirme que ele está ouvindo na porta 5000.
2. Instale as dependências com `npm install`.
3. Execute `npm run dev` e abra o endereço exibido pelo Vite.

No PowerShell, use `npm.cmd` se a política de execução bloquear `npm.ps1`.

## Endereço do backend

O frontend envia as chamadas para `/api`. O proxy do Vite encaminha essas chamadas para `http://127.0.0.1:5000` por padrão, removendo o prefixo `/api` e preservando os cookies de autenticação.

As páginas e os componentes importam a variável `API_URL` de `src/config/api.js` para montar as chamadas, por exemplo: ``fetch(`${API_URL}/login`, opcoes)``. O endereço do backend continua configurado no proxy do Vite.

Para usar um backend em outra máquina, copie `.env.example` para `.env.local` e ajuste:

```dotenv
API_TARGET=http://ENDERECO_DO_BACKEND:5000
```

Reinicie o Vite após a alteração. Use uma conta cadastrada no banco do backend escolhido: servidores diferentes podem ter usuários e senhas diferentes.

## Verificações

```sh
npm run build
npm run lint
node --test --test-isolation=none src/utils/filtrarPendencias.test.js
```

## Publicação

O build gera os arquivos estáticos em `dist`. Ao hospedá-los, configure o servidor para encaminhar `/api/*` ao backend, removendo `/api`, e servir `index.html` nas rotas da aplicação. A configuração de proxy do Vite não é incluída nos arquivos estáticos.
