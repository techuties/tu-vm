FROM node:22-alpine

RUN npm install -g @modelcontextprotocol/server-filesystem@latest supergateway@latest

RUN mkdir -p /shared

EXPOSE 3001

CMD ["npx", "supergateway", \
     "--stdio", "npx @modelcontextprotocol/server-filesystem /shared", \
     "--port", "3001"]
