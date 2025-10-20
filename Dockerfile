FROM debian:bullseye

LABEL org.opencontainers.image.authors="Indra Wahjoedi <iw@ijoe.eu.org>"

# ========================
# ENVIRONMENT VARIABLES
# ========================
ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_ENV=development
ENV CF_USER=cfuser
ENV CF_UID=1000
ENV CF_GID=1000

# Menentukan di mana corepack akan menaruh symlink pnpm/yarn, dll.
ENV PNPM_HOME="/usr/local/share/pnpm"
# Pastikan direktori ini ada di PATH
ENV PATH="$PNPM_HOME:$PATH"

# renovate: datasource=github-releases depName=krallin/tini
ARG TINI_VERSION=0.19.0
ADD https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini /tini
RUN chmod +x /tini

# ========================
# INSTALL SYSTEM DEPS & NODE.JS
# ========================
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    # Deps untuk Node.js
    curl git gnupg2 ca-certificates apt-transport-https software-properties-common sudo procps \
    # Tools Developer
    vim nano less wget unzip p7zip \
    # --- Instal Node.js 20 ---
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    # --- Cleanup ---
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN corepack enable \
    && corepack prepare pnpm@latest --activate \
    && pnpm --version

# ========================
# USER & WORKSPACE SETUP
# ========================
# Buat user non-root
RUN groupadd -g ${CF_GID} ${CF_USER} \
    && useradd -u ${CF_UID} -g ${CF_GID} -m -s /bin/bash ${CF_USER} \
    && echo "${CF_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Siapkan direktori NPM global sebelum beralih user
RUN mkdir -p /usr/local/lib/node_modules \
    && chown -R ${CF_USER}:${CF_USER} /usr/local/lib/node_modules

# Tentukan workspace dan ubah kepemilikan
WORKDIR /workspace
RUN chown ${CF_USER}:${CF_USER} /workspace

# ========================
# INSTALL GLOBAL TOOLS (WRANGLER)
# ========================
USER ${CF_USER}

RUN pnpm install -g wrangler@latest

# Tentukan WORKDIR akhir dan Exposure Port
WORKDIR /workspace
EXPOSE 8787

ENTRYPOINT ["/tini", "--"]
CMD ["/bin/bash"]