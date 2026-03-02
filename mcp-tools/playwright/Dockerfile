FROM node:22-bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 \
      libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 \
      libxrandr2 libgbm1 libpango-1.0-0 libcairo2 \
      libasound2 libxshmfence1 libglib2.0-0 fonts-liberation \
      ca-certificates && \
    npm install -g @playwright/mcp@latest && \
    npx playwright install chromium && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

EXPOSE 3000

CMD ["npx", "@playwright/mcp", "--headless", "--port", "3000", "--host", "0.0.0.0", "--allowed-hosts", "*"]
