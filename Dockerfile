FROM docker.io/pandoc/core:latest-debian

LABEL maintainer="Ronald Steffen, FU Berlin <r.steffen@fu-berlin.de>"

ENV PANDOC_VERSION=3.14
ENV SAXON_VERSION=HE12-10
ENV LUA_VERSION=5.4
ENV LUAROCKS_VERSION=3.13.0
ENV PATH="/root/.venv/bin:${PATH}"

# Basic packages
ENV SYS_PACKAGES \
    apt-utils \
    wget \
	zip \
    nano \
	curl \
    unzip \
    sudo \
    bash-completion \
    yq

# development packages
ENV DEV_PACKAGES \
    # for pandoc custom writer
    build-essential \
    php \
    php-zip \
    php-xml \
    # for pandoc pdf conversion
    librsvg2-bin

ENV DEV_PACKAGES_2 \
    # for weasyprint
    python3 \
    pip \
    libharfbuzz-subset0 \
    # for Saxon-HE
    default-jre

ENV DEV_PACKAGES_3 \
    # for pagedjs, Mathjax
    nodejs \
    npm 

# tools
ENV TOOLS_PACKAGES \
    # for PDF conversion with Pandoc
    texlive \
    # for xml processing/validation
    libxml2-utils \
    xmlstarlet

ENV TOOLS_PACKAGES_2 \
    # for pandoc custom writer
    liblua${LUA_VERSION}-dev \
    lua5.4 \
    libreadline-dev \
    pipx \ 
    # for pagedjs/chromium/pupeteer
    libxkbcommon-x11-0

# install packages; packages are installed in separate runs due to frequent timeout errors with the Debian server 
RUN set -xe && apt-get update  \
	&& apt-get install -y $SYS_PACKAGES
RUN set -xe && apt-get update  \
	&& apt-get install -y $DEV_PACKAGES
RUN set -xe && apt-get update  \
	&& apt-get install -y $DEV_PACKAGES_2
RUN set -xe && apt-get update  \
	&& apt-get install -y $TOOLS_PACKAGES
RUN set -xe && apt-get update  \
	&& apt-get install -y $TOOLS_PACKAGES_2
    # && pipx install panflute \
    # && pipx ensurepath
RUN set -xe && apt-get update  \
	&& apt-get install -y $DEV_PACKAGES_3

# install required tools not available through the Debian repository
RUN set -xe && cd /root \
    # install nvm
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash \
    && git clone https://github.com/ronste/sspworkflow.git \
    # && mkdir sspworkflow \
    && mkdir sspworkflow/lib \
    && mkdir sspworkflow/work \
    && mkdir sspworkflow/store \
    && mkdir sspworkflow/work/media \
    && mkdir sspworkflow/work/metadata\
    && cd sspworkflow/lib \
    # create python .venv
    && python3 -m venv /root/.venv \
    && . /root/.venv/bin/activate \
    && pip install --upgrade pip \
    && pip install docx weasyprint \
    ## docx2jats
    && git clone https://github.com/Vitaliy-1/docxToJats.git \
    # Install specific Pandoc version
    && arch=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/) \
    && wget https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-linux-${arch}.tar.gz \
    && tar xvzf pandoc-${PANDOC_VERSION}-linux-${arch}.tar.gz --strip-components 1 -C /usr/local/ \
    && rm pandoc-${PANDOC_VERSION}-linux-${arch}.tar.gz \
    # Saxon-HE
    && wget https://github.com/Saxonica/Saxon-HE/releases/download/Saxon${SAXON_VERSION}/Saxon${SAXON_VERSION}J.zip \
    && unzip -d Saxon${SAXON_VERSION}J Saxon${SAXON_VERSION}J.zip \
    && rm Saxon${SAXON_VERSION}J.zip

RUN set -xe && cd /root \
    # install node.js
    && . ~/.bashrc \
    && nvm install 22.14.0 \
    && nvm use 22.14.0 \
    # Setup npm and install global packages
    && node -v \
    && npm install -g npm@10.9.2 \
    && npm install -g \
       html-validate@9.2.0 \
       just-install \
       @vivliostyle/cli \
        #    puppeteer \ # used by pagedjs
        #    pagedjs-cli@latest # still outdated -> find alternative
    # just Bash completion
    && mkdir -p /etc/bash_completion.d \
    && just --completions bash > /etc/bash_completion.d/just

RUN set -xe && cd /root/sspworkflow \
    # Setup npm and install local packages from package.json
    && npm ci --omit=dev --omit=optional \
    # for pandoc custom writer
    # Install luarocks and dependencies
    && cd lib \
    && wget https://luarocks.org/releases/luarocks-${LUAROCKS_VERSION}.tar.gz \
    && tar zxpf luarocks-${LUAROCKS_VERSION}.tar.gz \
    && cd luarocks-${LUAROCKS_VERSION} \
    && ./configure && make && sudo make install \
    && luarocks install xml2lua \
    && eval "$(luarocks path)" \
    && cd .. \
    && rm luarocks-${LUAROCKS_VERSION}.tar.gz

RUN set -xe && cd /root \
    # import pandoc lua filters
    && curl --proto '=https' --tlsv1.3 -sSfL -o /tmp/verstat.tar.xz \
        "https://codeberg.org/pandoc/verstat/archive/main.tar.gz" \
    && tar -xf /tmp/verstat.tar.xz -C /tmp \
    && mv /tmp/verstat/verstat.lua /usr/local/bin/verstat \
    && verstat update /tmp/verstat/packages.json \
    && verstat -v add normalize-metadata metadata-table template-friendly-metadata \
    # Setup runConversionChain command
    && echo '#!/usr/bin/env bash' > /bin/runConversionChain \
    && echo "cd /root/sspworkflow/work" >> /bin/runConversionChain \
    && echo 'just "$@"' >> /bin/runConversionChain \
    && chmod u+x /bin/runConversionChain \
    && echo "alias rcc='runConversionChain'" >> /etc/bash.bashrc

RUN set -xe && cd /root \
    && . ~/.bashrc \
    && runConversionChain reset-example

WORKDIR /root/sspworkflow