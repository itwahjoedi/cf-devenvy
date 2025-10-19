# Dockerfile

FROM debian:bullseye

LABEL org.opencontainers.image.authors="Indra Wahjoedi <iw@ijoe.eu.org>"

ENV DEBIAN_FRONTEND=noninteractive

# renovate: datasource=github-releases depName=krallin/tini
ARG TINI_VERSION=0.19.0

ADD https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini /tini
RUN chmod +x /tini

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_ENV=development
ENV PORT=8787
ENV CF_USER=cfuser
ENV CF_UID=1000
ENV CF_GID=1000
ENV XAUTHORITY=/tmp/.Xauthority

# Update sistem dan install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    vim \
    nano \
    less \
    wget \
    gnupg2 \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    sudo \
    unzip \
    p7zip \
    curl \
    winbind \
    libvulkan1 \
    openssh-server \
    supervisor \
    procps \
    psmisc \
    && rm -rf /var/lib/apt/lists/*

# Buat user non-root
RUN groupadd -g ${CF_GID} ${CF_USER} \
    && useradd -u ${CF_UID} -g ${CF_GID} -m -s /bin/bash ${CF_USER} \
    && echo "${CF_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Instalasi Node.js (versi 20)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
&& apt-get install -y nodejs \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*

# Instalasi Cloudflare Wrangler CLI secara global untuk non-root user
# Mengubah kepemilikan direktori NPM global agar non-root user bisa menginstal
ENV NPM_CONFIG_PREFIX=/home/${CF_USER}/.npm-global
ENV PATH=$PATH:$NPM_CONFIG_PREFIX/bin

# Membuat direktori dan mengubah kepemilikan
RUN mkdir -p /home/${CF_USER}/.npm-global \
&& chown -R ${CF_USER}:${CF_USER} /home/${CF_USER}

# Beralih ke pengguna non-root untuk instalasi Wrangler
USER ${CF_USER}
RUN npm install -g wrangler@latest

# Kembali ke root (sementara) untuk menyiapkan direktori kerja
USER root

# Create workspace
WORKDIR /workspace
RUN chown ${CF_USER}:${CF_USER} /workspace

# Switch ke user non-root
USER ${CF_USER}
WORKDIR /home/${CF_USER}
EXPOSE 8787

ENTRYPOINT ["/tini", "--"]
CMD ["/bin/bash"]