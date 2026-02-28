FROM node:22-alpine

RUN apk add --no-cache python3 py3-pip && \
    pip install --break-system-packages mcp-server-fetch && \
    npm install -g supergateway@latest

EXPOSE 3002

CMD ["npx", "supergateway", \
     "--stdio", "python3 -m mcp_server_fetch", \
     "--port", "3002"]
