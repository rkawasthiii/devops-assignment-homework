FROM node:22-bookworm-slim
WORKDIR /app
COPY app/ ./app/
COPY tests/ ./tests/
COPY package.json ./
EXPOSE 3000
CMD ["node", "app/server.js"]
