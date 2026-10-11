FROM caddy:2 AS caddy

FROM node:22-slim

# Install system dependencies required for native modules, basic shell tools,
# and the bubblewrap sandbox that dsh prefers on Linux
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    build-essential \
    git \
    curl \
    iputils-ping \
    bubblewrap \
    && rm -rf /var/lib/apt/lists/*

# Install DeepSeek Harness globally
RUN npm install -g @deepseek-ai/dsh

# dsh web only binds to loopback by design (the UI can run shell commands),
# so Caddy holds the public port with basic auth and proxies to it.
COPY --from=caddy /usr/bin/caddy /usr/bin/caddy
COPY Caddyfile /etc/caddy/Caddyfile
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Agent workspace and harness home live under the shared /workspace mount
ENV DSH_WORKSPACE=/workspace/jerod
ENV DSH_HOME=/workspace/jerod/.dsh

WORKDIR /workspace
EXPOSE 3080

# Requires DSH_UI_USERNAME and DSH_UI_USERPASS at runtime
CMD ["/usr/local/bin/entrypoint.sh"]
