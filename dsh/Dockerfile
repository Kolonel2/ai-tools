FROM node:22-slim

# Install system dependencies required for native modules and basic shell tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    build-essential \
    git \
    curl \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# Install DeepSeek Harness globally
RUN npm install -g @deepseek-ai/dsh

WORKDIR /workspace

# Set default port
ENV PORT=3080
EXPOSE 3080

# Run the web surface bound to loopback/all interfaces
CMD ["dsh", "web"]
