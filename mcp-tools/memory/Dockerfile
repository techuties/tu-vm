FROM node:22-alpine

RUN npm install -g @modelcontextprotocol/server-memory@latest supergateway@latest

RUN mkdir -p /data

ENV MEMORY_FILE_PATH=/data/memory.json

EXPOSE 3003

CMD ["npx", "supergateway", \
     "--stdio", "npx @modelcontextprotocol/server-memory", \
     "--port", "3003"]
