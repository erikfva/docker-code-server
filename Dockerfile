FROM ghcr.io/linuxserver/baseimage-ubuntu:jammy

# set version label
ARG BUILD_DATE
ARG VERSION
ARG CODE_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV HOME="/config"
ENV S3_ACCESS_KEY_ID=
ENV S3_SECRET_ACCESS_KEY=
ENV S3_BUCKET=
ENV S3_ENDPOINT=

RUN \
  echo "**** install runtime dependencies ****" && \
  apt-get update && \
  apt-get install -y \
    git \
    openssh-client \
    jq \
    libatomic1 \
    nano \
    net-tools \
    netcat \
    sudo && \
  echo "**** install code-server ****" && \
  if [ -z ${CODE_RELEASE+x} ]; then \
    CODE_RELEASE=$(curl -sX GET https://api.github.com/repos/coder/code-server/releases/latest \
      | awk '/tag_name/{print $4;exit}' FS='[""]' | sed 's|^v||'); \
  fi && \
  mkdir -p /app/code-server && \
  curl -o \
    /tmp/code-server.tar.gz -L \
    "https://github.com/coder/code-server/releases/download/v${CODE_RELEASE}/code-server-${CODE_RELEASE}-linux-amd64.tar.gz" && \
  tar xf /tmp/code-server.tar.gz -C \
    /app/code-server --strip-components=1 && \
  echo "**** clean up ****" && \
  apt-get clean && \
  rm -rf \
    /config/* \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

RUN apt-get update
RUN apt-get install -y ca-certificates curl gnupg
RUN install -m 0755 -d /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN chmod a+r /etc/apt/keyrings/docker.gpg
RUN echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update
RUN apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Cypress Prerequisites
RUN apt-get install -y libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libnss3 libxss1 libasound2 libxtst6 xauth xvfb

# install nodejs latest version
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
RUN apt-get install -y nodejs
RUN node --version
RUN npm --version
RUN npm install --yes --global yarn

# add local files
COPY /root /

RUN sudo apt install -y s3fs

# install extensions
RUN mkdir -p /temp/config/extensions
RUN /app/code-server/bin/code-server  --extensions-dir /temp/config/extensions  --install-extension ms-azuretools.vscode-docker
RUN /app/code-server/bin/code-server  --extensions-dir /temp/config/extensions  --install-extension IronGeek.vscode-env
RUN /app/code-server/bin/code-server  --extensions-dir /temp/config/extensions  --install-extension esbenp.prettier-vscode
RUN /app/code-server/bin/code-server  --extensions-dir /temp/config/extensions  --install-extension redhat.vscode-yaml
RUN /app/code-server/bin/code-server  --extensions-dir /temp/config/extensions  --install-extension Vue.volar
RUN /app/code-server/bin/code-server  --extensions-dir /temp/config/extensions  --install-extension johnsoncodehk.vscode-typescript-vue-plugin
RUN /app/code-server/bin/code-server  --extensions-dir /temp/config/extensions  --install-extension nick-rudenko.back-n-forth
RUN /app/code-server/bin/code-server  --extensions-dir /temp/config/extensions  --install-extension humao.rest-client

# install ngrok

RUN curl -o \
    /tmp/ngrok.tgz -L \
    "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz" && \
    tar zxvf tmp/ngrok.tgz -C /app && \
  echo "**** clean up ****" && \
  apt-get clean && \
  rm -rf \
    /tmp/*

# ports and volumes
EXPOSE 8443
