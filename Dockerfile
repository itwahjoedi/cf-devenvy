FROM node:20.5.1-bullseye-slim

LABEL org.opencontainers.image.authors="Indra Wahjoedi <iw@ijoe.eu.org>"
LABEL org.opencontainers.image.source="https://github.com/itwahjoedi/cf-envybox"
LABEL description="Standardized Cloudflare Edge Dev Environment"

# ========================
# ENVIRONMENT VARIABLES
# ========================
ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_ENV=development
ENV CF_USER=cfuser
ENV HOME=/home/cfuser
ENV PNPM_HOME="/usr/local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# ========================
# SYSTEM DEPENDENCIES
# ========================
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git sudo procps ca-certificates gnupg2 apt-transport-https \
    vim nano less wget unzip p7zip zsh htop \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
    
# ========================
# RENAME DEFAULT USER AND GROUP (node → cfuser)
# ========================
RUN existing_user=$(getent passwd 1000 | cut -d: -f1) \
    && usermod -l ${CF_USER} ${existing_user} \
    && usermod -d /home/${CF_USER} -m ${CF_USER} \
    && echo "${CF_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    
RUN existing_group=$(getent group 1000 | cut -d: -f1) \
    && groupmod -n ${CF_USER} ${existing_group}
    
# ========================
# INIT TINI
# ========================
ARG TINI_VERSION=0.19.0
ADD https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini /tini
RUN chmod +x /tini

# ========================
# PERMISSIONS & SETUP
# ========================
RUN mkdir -p /usr/local/share/pnpm /usr/local/lib/node_modules \
    && chown -R ${CF_USER}:${CF_USER} /usr/local/share/pnpm /usr/local/lib/node_modules
    
# ========================
# COREPACK, PNPM, WRANGLER, GH
# ========================
RUN corepack enable && corepack prepare pnpm@latest --activate \
    && pnpm install -g wrangler@latest gh@latest \
    && pnpm store prune

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

#---------------------------------
# DX enhancements
# ---------------------------------------------------------------------
    
# User Config
USER ${CF_USER}
WORKDIR /home/${CF_USER}

RUN echo 'alias wr="wrangler"' >> ~/.zshrc && \
echo 'alias gp="git pull && pnpm install"' >> ~/.zshrc && \
echo 'alias clean="rm -rf ~/.cache/pnpm ~/.npm"' >> ~/.zshrc && \
echo 'export PATH=$HOME/.local/share/pnpm/global/5/bin:$PATH' >> ~/.zshrc

EXPOSE 22 8080
ENTRYPOINT ["/tini", "/usr/local/bin/entrypoint.sh"]
# CMD ["/bin/zsh"]
CMD ["su", "-", "cfuser", "-c", "/bin/zsh"]