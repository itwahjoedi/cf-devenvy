FROM node:20-slim

LABEL org.opencontainers.image.authors="Indra Wahjoedi <iw@ijoe.eu.org>"
    
    # ========================
    # ENVIRONMENT VARIABLES
    # ========================
    ENV DEBIAN_FRONTEND=noninteractive
    ENV NODE_ENV=development
    ENV CF_USER=cfuser
    ENV PNPM_HOME="/usr/local/share/pnpm"
    ENV PATH="$PNPM_HOME:$PATH"
    
    # ========================
    # SYSTEM DEPENDENCIES
    # ========================
    RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git sudo procps ca-certificates gnupg2 apt-transport-https \
    vim nano less wget unzip p7zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
    
    # ========================
    # RENAME DEFAULT USER (node → cfuser)
    # ========================
    RUN existing_user=$(getent passwd 1000 | cut -d: -f1) \
    && usermod -l ${CF_USER} ${existing_user} \
    && usermod -d /home/${CF_USER} -m ${CF_USER} \
    && echo "${CF_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    
    USER ${CF_USER}
    WORKDIR /workspace
    
    # ========================
    # INIT TINI
    # ========================
    ARG TINI_VERSION=0.19.0
    ADD https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini /tini
    RUN sudo chmod +x /tini
    
    # ========================
    # COREPACK, PNPM, WRANGLER, GH
    # ========================
    RUN corepack enable && corepack prepare pnpm@latest --activate \
    && pnpm install -g wrangler@latest gh@latest \
    && pnpm store prune
    
    # ========================
    # PERMISSIONS & SETUP
    # ========================
    RUN sudo mkdir -p /usr/local/share/pnpm /usr/local/lib/node_modules /workspace \
    && sudo chown -R ${CF_USER}:${CF_USER} /usr/local/share/pnpm /usr/local/lib/node_modules /workspace
    
    EXPOSE 8787
    
    ENTRYPOINT ["/tini", "--"]
    CMD ["/bin/bash"]