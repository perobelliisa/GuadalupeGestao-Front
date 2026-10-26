FROM node:22-bookworm AS build
WORKDIR /app
COPY . .
RUN npm ci --include=optional && npm install --no-save --no-package-lock @rolldown/binding-linux-x64-gnu@1.2.4
RUN npm run build

FROM caddy:2-alpine
COPY --from=build /app/dist /usr/share/caddy
RUN printf '%s\n' ':80 {' 'handle_path /api/* {' 'reverse_proxy ponsyx_guadalupe-back:5000' '}' 'handle {' 'root * /usr/share/caddy' 'try_files {path} /index.html' 'file_server' '}' '}' > /etc/caddy/Caddyfile
EXPOSE 80

