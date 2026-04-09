FROM python:3.12-slim

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl nodejs npm \
    && rm -rf /var/lib/apt/lists/*

# Pre-install AFFiNE MCP server to avoid fetching packages at runtime.
RUN npm install -g affine-mcp-server

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY app.py /app/app.py
COPY n8n_node_types.json /app/n8n_node_types.json

ENV PYTHONUNBUFFERED=1
EXPOSE 9002

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "9002"]
