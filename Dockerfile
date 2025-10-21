FROM node:20-slim

LABEL org.opencontainers.image.authors="Indra Wahjoedi <iw@ijoe.eu.org>"
    
    # ========================
    # ENVIRONMENT
    # ========================
    ENV DEBIAN_FRONTEND=noninteractive \
    NODE_ENV=development \
    CF_USER=cfuser \
    CF_UID=1000 \
    CF_GID=1000 \
    PNPM_HOME="/usr/local/share/pnpm" \
    PATH="$PNPM_HOME:$PATH" \
    CF_API_TOKEN="" \
    GITHUB_TOKEN=""
    
    # ========================
    # SYSTEM + DEV TOOLS + GITHUB CLI
    # ========================
    RUN apt-get update && apt-get install -y --no-install-recommends \
    git vim nano less wget unzip p7zip sudo tini curl gnupg2 ca-certificates \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
    https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y gh \
    && corepack enable && corepack prepare pnpm@latest --activate \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
    
    # ========================
    # USER & WORKSPACE
    # ========================
    RUN groupadd -g ${CF_GID} ${CF_USER} \
    && useradd -u ${CF_UID} -g ${CF_GID} -m -s /bin/bash ${CF_USER} \
    && echo "${CF_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && mkdir -p /workspace /usr/local/share/pnpm \
    && chown -R ${CF_USER}:${CF_USER} /workspace /usr/local/share/pnpm
    
    USER ${CF_USER}
    WORKDIR /workspace
    
    # ========================
    # GLOBAL TOOLS
    # ========================
    ARG WRANGLER_VERSION=3.70.0
    RUN pnpm add -g wrangler@${WRANGLER_VERSION} \
    && git config --global --add safe.directory /workspace
    
    # ========================
    # AUTH HANDLER
    # ========================
    COPY dev-entry.sh /usr/local/bin/dev-entry.sh
    RUN sudo chmod +x /usr/local/bin/dev-entry.sh
    
    EXPOSE 8787
    ENTRYPOINT ["/usr/bin/tini", "--", "dev-entry.sh"]
    CMD ["/bin/bash"]