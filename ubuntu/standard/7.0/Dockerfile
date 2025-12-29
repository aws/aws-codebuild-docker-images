# Copyright 2020-2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use this file except in compliance with the License.
# A copy of the License is located at
#
#    http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.
FROM public.ecr.aws/ubuntu/ubuntu:22.04 AS core

ARG DEBIAN_FRONTEND="noninteractive"

# Install SSH, and other utilities
RUN set -ex \
    && echo 'Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/99use-gzip-compression \
    && apt-get update \
    && apt install -y -qq apt-transport-https gnupg ca-certificates sudo \
    && apt-get install software-properties-common -y -qq --no-install-recommends \
    && apt-get install -y -qq --no-install-recommends openssh-client \
    && mkdir ~/.ssh \
    && mkdir -p /codebuild/image/config \
    && touch ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa,ed25519,ecdsa -H github.com >> ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa,ed25519,ecdsa -H bitbucket.org >> ~/.ssh/known_hosts \
    && chmod 600 ~/.ssh/known_hosts \
    && apt-get install -y -qq --no-install-recommends \
        acl apt-utils aria2 asciidoc autoconf automake \
        binutils bison brotli build-essential bzip2 bzr \
        coreutils curl dirmngr dnsutils docbook-xml docbook-xsl dpkg dpkg-dev \
        e2fsprogs expect fakeroot file findutils flex fonts-noto-color-emoji ftp \
        g++ gcc git-lfs gettext gettext-base gnupg2 groff gzip \
        haveged imagemagick iproute2 iptables jq less \
        lib32z1 libapr1 libaprutil1 libargon2-0-dev libbz2-dev \
        libc++-dev libc++abi-dev libc6-dev libcurl4-openssl-dev \
        libdb-dev libdbd-sqlite3-perl libdbi-perl libdpkg-perl \
        libedit-dev liberror-perl libevent-dev libffi-dev  \
        libgeoip-dev libgbm-dev libgconf-2-4 libglib2.0-dev libgsl-dev libgtk-3-0 \
        libhttp-date-perl libio-pty-perl libjpeg-dev libkrb5-dev liblzma-dev \
        libmagic-dev libmagickcore-dev libmagickwand-dev libmysqlclient-dev \
        libncurses5-dev libncursesw5-dev libonig-dev libpq-dev libreadline-dev \
        libsecret-1-dev libserf-1-1 libsodium-dev libsqlite3-dev libssl-dev \
        libsvn1 libsvn-perl libtcl8.6 libtidy-dev libtimedate-perl libtool libunwind8 \
        libwebp-dev libxkbfile-dev libxml2-dev libxml2-utils libxslt1-dev libxss1 \
        libyaml-dev libyaml-perl libzip-dev llvm locales lz4 \
        m4 make mediainfo mercurial mlocate net-tools netbase netcat \
        openssl patch p7zip-full p7zip-rar parallel pass patchelf pigz pkg-config pollinate procps \
        python-is-python3 python3-configobj python3-openssl rpm rsync \
        sgml-base sgml-data shellcheck sphinxsearch sqlite3 ssh sshpass subversion sudo swig systemd-coredump \
        tar tcl tcl8.6 telnet texinfo time tk tk-dev tzdata \
        unzip upx vim wget xfsprogs xml-core xmlto xorriso xsltproc \
        xvfb xz-utils zip zlib1g-dev zsync \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y unattended-upgrades && \
    unattended-upgrade -v --dry-run && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV LC_CTYPE="C.UTF-8"

# Set locale
RUN locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8

RUN useradd codebuild-user

#=======================End of layer: core  =================

FROM core AS tools

# Install Git
RUN set -ex \
    && GIT_VERSION=2.49.0 \
    && GIT_TAR_FILE=git-$GIT_VERSION.tar.gz \
    && GIT_SRC=https://github.com/git/git/archive/v${GIT_VERSION}.tar.gz  \
    && curl -L -o $GIT_TAR_FILE $GIT_SRC \
    && tar zxf $GIT_TAR_FILE \
    && cd git-$GIT_VERSION \
    && make -j4 \
    && make install prefix=/usr \
    && cd .. && rm -rf git-$GIT_VERSION \
    && rm -rf $GIT_TAR_FILE /tmp/* \
    && git --version

# Install AWS SAM CLI
RUN wget -nv https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip -O /tmp/samcli.zip \
    && unzip -q /tmp/samcli.zip -d /opt/samcli \
    && /opt/samcli/install --update -i /usr/local/sam-cli -b /usr/local/bin \
    && rm -rf /opt/samcli /tmp/* \
    && sam --version

# Install AWS CLI v2
# https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html
RUN curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /opt/awscli \
    && /opt/awscli/aws/install --update -i /usr/local/aws-cli -b /usr/local/bin \
    && rm -rf /opt/awscli /tmp/* \
    && aws --version

# Install stunnel
RUN set -ex \
    && STUNNEL_VERSION=5.75 \
    && STUNNEL_TAR=stunnel-$STUNNEL_VERSION.tar.gz \
    && STUNNEL_SHA256="0c1ef0ed85240974dccb94fe74fb92d6383474c7c0d10e8796d1f781a3ba5683" \
    && curl -o $STUNNEL_TAR https://www.stunnel.org/archive/5.x/$STUNNEL_TAR && echo "$STUNNEL_SHA256 $STUNNEL_TAR" | sha256sum --check && tar xfz $STUNNEL_TAR \
    && cd stunnel-$STUNNEL_VERSION \
    && ./configure \
    && make -j4 \
    && make install \
    && openssl genrsa -out key.pem 2048 \
    && openssl req -new -x509 -key key.pem -out cert.pem -days 1095 -subj "/C=US/ST=Washington/L=Seattle/O=Amazon/OU=Codebuild/CN=codebuild.amazon.com" \
    && cat key.pem cert.pem >> /usr/local/etc/stunnel/stunnel.pem \
    && cd .. && rm -rf stunnel-${STUNNEL_VERSION}* \
    && stunnel -version

# AWS Tools
# aws-iam-authenticator: https://github.com/kubernetes-sigs/aws-iam-authenticator/releases
# kubectl: https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html
# eksctl: https://eksctl.io/installation/
# ecs-cli: https://github.com/aws/amazon-ecs-cli?tab=readme-ov-file#installing
RUN set -ex \
    && KUBERNETES_VERSION=1.33.0 \
    && AMAZON_EKS_S3_PATH=2025-05-01 \
    && curl -sS -o /usr/local/bin/aws-iam-authenticator https://s3.us-west-2.amazonaws.com/amazon-eks/$KUBERNETES_VERSION/$AMAZON_EKS_S3_PATH/bin/linux/amd64/aws-iam-authenticator \
    && chmod +x /usr/local/bin/aws-iam-authenticator \
    && aws-iam-authenticator version \
    && curl -sS -o /usr/local/bin/kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/$KUBERNETES_VERSION/$AMAZON_EKS_S3_PATH/bin/linux/amd64/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && kubectl version --client \
    && curl -sS -L https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz | tar xz -C /usr/local/bin \
    && chmod +x /usr/local/bin/eksctl \
    && eksctl version \
    && curl -sS -o /usr/local/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest \
    && chmod +x /usr/local/bin/ecs-cli \
    && ecs-cli --version

# Install amazon-ecr-credential-helper
# To configure: https://github.com/awslabs/amazon-ecr-credential-helper?tab=readme-ov-file#configuration
# ecr-login is not configured because it conflicts with docker login commands https://github.com/awslabs/amazon-ecr-credential-helper/issues/102
RUN set -ex \
    && apt-get update \
    && apt-get install -y -qq amazon-ecr-credential-helper \
    && docker-credential-ecr-login -v

# Configure SSM
RUN set -ex \
    && mkdir /tmp/ssm \
    && cd /tmp/ssm \
    && wget -q https://s3.amazonaws.com/amazon-ssm-us-east-1/latest/debian_amd64/amazon-ssm-agent.deb \
    && dpkg -i amazon-ssm-agent.deb

# Install Pack
RUN set -ex \
    && PACK_VERSION=0.38.0 \
    && (curl -sSL "https://github.com/buildpacks/pack/releases/download/v${PACK_VERSION}/pack-v${PACK_VERSION}-linux.tgz" | tar -C /usr/local/bin/ --no-same-owner -xzv pack) \
    && pack --version

#****************        DOCKER    *********************************************
ARG DOCKER_BUCKET="download.docker.com"
ARG DOCKER_CHANNEL="stable"
ARG DIND_COMMIT="3b5fac462d21ca164b3778647420016315289034"
ARG DOCKER_COMPOSE_VERSION="2.37.1"
ARG DOCKER_BUILDX_VERSION="0.24.0"
ARG SRC_DIR="/usr/src"

ARG DOCKER_SHA256="4f798b3ee1e0140eab5bf30b0edc4e84f4cdb53255a429dc3bbae9524845d640"
ARG DOCKER_VERSION="27.5.1"

# Install Docker
RUN set -ex \
    && curl -fSL "https://${DOCKER_BUCKET}/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz" -o docker.tgz \
    && echo "${DOCKER_SHA256} *docker.tgz" | sha256sum -c - \
    && tar --extract --file docker.tgz --strip-components 1  --directory /usr/local/bin/ \
    && rm docker.tgz \
    && docker -v \
    # Check runc version
    && runc -v \
    # set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
    && addgroup dockremap \
    && useradd -g dockremap dockremap \
    && echo 'dockremap:165536:65536' >> /etc/subuid \
    && echo 'dockremap:165536:65536' >> /etc/subgid \
    && wget -q "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind" -O /usr/local/bin/dind \
    # Install docker compose as docker plugin and maintain docker-compose usage
    && mkdir -p /usr/local/lib/docker/cli-plugins \
    && curl -L https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-Linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose \
    && chmod +x /usr/local/bin/dind /usr/local/lib/docker/cli-plugins/docker-compose \
    && ln -s /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose \
    # Ensure docker-compose and docker compose work
    && docker-compose version \
    && docker compose version \
    # Add docker buildx tool
    && curl -L https://github.com/docker/buildx/releases/download/v${DOCKER_BUILDX_VERSION}/buildx-v${DOCKER_BUILDX_VERSION}.linux-amd64 -o /usr/local/lib/docker/cli-plugins/docker-buildx \
    && chmod +x /usr/local/lib/docker/cli-plugins/docker-buildx \
    && ln -s /usr/local/lib/docker/cli-plugins/docker-buildx /usr/local/bin/docker-buildx \
    # Ensure docker-buildx works
    && docker-buildx version \
    && docker buildx version

VOLUME /var/lib/docker
#*********************** END  DOCKER  ****************************

# Install gh
# Instruction: https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian-ubuntu-linux-raspberry-pi-os-apt
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt update \
    && apt install gh -y

# Install Chrome
RUN set -ex \
    && curl -L https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb --output /tmp/google-chrome-stable_current_amd64.deb \
    && dpkg -i /tmp/google-chrome-stable_current_amd64.deb || apt-get install -f -y \
    && rm -rf /tmp/* \
    && google-chrome --version

# Install ChromeDriver
# https://googlechromelabs.github.io/chrome-for-testing/
# https://github.com/GoogleChromeLabs/chrome-for-testing#json-api-endpoints
RUN set -ex \
    && CHROME_DRIVER_DOWNLOAD_URL=$(curl -sL https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json | jq -r '.channels.Stable.downloads.chromedriver[] | select(.platform == "linux64") | .url') \
    && curl -L $CHROME_DRIVER_DOWNLOAD_URL --output /tmp/chromedriver-linux64.zip \
    && unzip -q /tmp/chromedriver-linux64.zip -d /opt/chromedriver \
    && ln -s /opt/chromedriver/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver \
    && rm -rf /tmp/* \
    && chromedriver --version

# Install Chromium
# See instruction: https://www.chromium.org/getting-involved/download-chromium/
RUN set -ex \
    && CHROMIUM_VERSION=$(curl -sL https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Linux_x64%2FLAST_CHANGE?alt=media) \
    && CHROMIUM_DOWNLOAD_URL=https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Linux_x64%2F$CHROMIUM_VERSION%2Fchrome-linux.zip?alt=media \
    && curl -L $CHROMIUM_DOWNLOAD_URL --output /tmp/chromium-linux.zip \
    && unzip -q /tmp/chromium-linux.zip -d /opt/chromium \
    && ln -s /opt/chromium/chrome-linux/chrome /usr/local/bin/chromium \
    && ln -s /opt/chromium/chrome-linux/chrome /usr/local/bin/chromium-browser \
    && rm -rf /tmp/* \
    && chromium --version \
    && chromium-browser --version

# Install Mozilla Firefox
RUN set -ex \
    && add-apt-repository ppa:mozillateam/ppa \
    && printf "Package: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n" > /etc/apt/preferences.d/mozilla \
    && apt install -y -qq --no-install-recommends firefox \
    && firefox --version

# Install Geckodriver
RUN set -ex \
    && apt install -y -qq firefox-geckodriver \
    && geckodriver --version

# Install Selenium server
RUN set -ex \
    && SELENIUM_DOWNLOAD_URL=$(curl -sL https://api.github.com/repos/SeleniumHQ/selenium/releases/latest | jq -r ' .assets[] | select(.browser_download_url | contains("selenium-server") and endswith(".jar")) | .browser_download_url') \
    && wget -q -P /usr/share/java $SELENIUM_DOWNLOAD_URL

#=======================End of stage: tools  =================
FROM tools AS runtimes

#****************     .NET-CORE     *******************************************************

# Dotnet
ENV PATH="/root/.dotnet/:/root/.dotnet/tools/:$PATH"
RUN set -ex  \
    && wget -qO /usr/local/bin/dotnet-install.sh https://dot.net/v1/dotnet-install.sh \
    && chmod +x /usr/local/bin/dotnet-install.sh

ENV DOTNET_8_SDK_VERSION="8.0.411" \
    DOTNET_6_SDK_VERSION="6.0.428" \
    DOTNET_6_GLOBAL_JSON_SDK_VERSION="6.0.0" \
    DOTNET_8_GLOBAL_JSON_SDK_VERSION="8.0.0"
ENV DOTNET_ROOT="/root/.dotnet"

# Add .NET Core 8 Global Tools install folder to PATH
RUN  /usr/local/bin/dotnet-install.sh -v $DOTNET_8_SDK_VERSION \
     && dotnet --list-sdks \
     && rm -rf /tmp/*

# Add .NET Core 6 Global Tools install folder to PATH
RUN  /usr/local/bin/dotnet-install.sh -v $DOTNET_6_SDK_VERSION \
     && dotnet --list-sdks \
     && rm -rf /tmp/* \
     && cd /codebuild && dotnet new globaljson --force --sdk-version $DOTNET_6_GLOBAL_JSON_SDK_VERSION --roll-forward latestFeature

# Trigger the population of the local package cache
ENV NUGET_XMLDOC_MODE skip
RUN set -ex \
    && mkdir warmup \
    && cd warmup \
    && dotnet new \
    && cd .. \
    && rm -rf warmup \
    && rm -rf /tmp/NuGetScratch

# Install Powershell Core
# See instructions at https://learn.microsoft.com/en-us/powershell/scripting/install/install-other-linux?view=powershell-7.4#installation-using-a-binary-archive-file
ARG POWERSHELL_VERSION=7.4.10
ARG POWERSHELL_DOWNLOAD_URL=https://github.com/PowerShell/PowerShell/releases/download/v$POWERSHELL_VERSION/powershell-$POWERSHELL_VERSION-linux-x64.tar.gz
ARG POWERSHELL_DOWNLOAD_SHA=d91b9172668f4b6aef4abce8c780cd298872c7a0f4487cc47444d26877ba49f6

RUN set -ex \
    && curl -SL $POWERSHELL_DOWNLOAD_URL --output powershell.tar.gz \
    && echo "$POWERSHELL_DOWNLOAD_SHA powershell.tar.gz" | sha256sum -c - \
    && mkdir -p /opt/microsoft/powershell/$POWERSHELL_VERSION \
    && tar zxf powershell.tar.gz -C /opt/microsoft/powershell/$POWERSHELL_VERSION \
    && rm powershell.tar.gz \
    && chmod +x /opt/microsoft/powershell/$POWERSHELL_VERSION/pwsh \
    && ln -s /opt/microsoft/powershell/$POWERSHELL_VERSION/pwsh /usr/bin/pwsh \
    && pwsh --version
#****************     END .NET-CORE     *******************************************************


#****************      NODEJS     ****************************************************

#nodejs
ARG SRC_DIR="/usr/src"
ARG N_SRC_DIR="$SRC_DIR/n"

ENV NODE_18_VERSION="18.20.8" \
    NODE_20_VERSION="20.19.2" \
    NODE_22_VERSION="22.16.0" \
    NODE_24_VERSION="24.2.0"

RUN git clone https://github.com/tj/n $N_SRC_DIR \
    && cd $N_SRC_DIR && make install

RUN n $NODE_18_VERSION && npm install --save-dev -g -f grunt \
    && npm install --save-dev -g -f grunt-cli \
    && npm install --save-dev -g -f webpack \
    && npm install --save-dev -g -f yarn \
    && n $NODE_20_VERSION && npm install --save-dev -g -f grunt \
    && npm install --save-dev -g -f grunt-cli \
    && npm install --save-dev -g -f webpack \
    && npm install --save-dev -g -f yarn \
    && n $NODE_22_VERSION && npm install --save-dev -g -f grunt \
    && npm install --save-dev -g -f grunt-cli \
    && npm install --save-dev -g -f webpack \
    && npm install --save-dev -g -f yarn \
    && n $NODE_24_VERSION && npm install --save-dev -g -f grunt \
    && npm install --save-dev -g -f grunt-cli \
    && npm install --save-dev -g -f webpack \
    && npm install --save-dev -g -f yarn \
    && cd / && rm -rf $N_SRC_DIR && rm -rf /tmp/*

RUN npm install -g npm@11.4.2

# Preserve latest npm version
ENV N_PRESERVE_NPM=1 \
    N_PRESERVE_COREPACK=1
#****************      END NODEJS     ****************************************************

#**************** RUBY *********************************************************

#rubyenv
ENV RBENV_SRC_DIR="/usr/local/rbenv"

ENV PATH="/root/.rbenv/shims:$RBENV_SRC_DIR/bin:$RBENV_SRC_DIR/shims:$PATH" \
    RUBY_BUILD_SRC_DIR="$RBENV_SRC_DIR/plugins/ruby-build"

RUN set -ex \
    && git clone https://github.com/rbenv/rbenv.git $RBENV_SRC_DIR \
    && mkdir -p $RBENV_SRC_DIR/plugins \
    && git clone https://github.com/rbenv/ruby-build.git $RUBY_BUILD_SRC_DIR \
    && sh $RUBY_BUILD_SRC_DIR/install.sh

ENV RUBY_34_VERSION="3.4.2" \
    RUBY_33_VERSION="3.3.7" \
    RUBY_32_VERSION="3.2.7" \
    RUBY_31_VERSION="3.1.6"

RUN rbenv install $RUBY_34_VERSION \
    && rbenv install $RUBY_33_VERSION \
    && rbenv install $RUBY_32_VERSION \
    && rbenv install $RUBY_31_VERSION \
    && rbenv global $RUBY_32_VERSION && ruby -v \
    && rm -rf /tmp/*
#**************** END RUBY *****************************************************

#**************** PYTHON *****************************************************

#Install pyenv
RUN curl -s -S -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash
ENV PATH="/root/.pyenv/shims:/root/.pyenv/bin:$PATH"

ENV PYTHON_313_VERSION="3.13.5" \
    PYTHON_312_VERSION="3.12.11" \
    PYTHON_311_VERSION="3.11.13" \
    PYTHON_310_VERSION="3.10.18" \
    PYTHON_39_VERSION="3.9.23" \
    PYTHON_PIP_VERSION="25.1.1" \
    PYYAML_VERSION="6.0.2" \
    PYTHON_SETUPTOOLS_VERSION="80.9.0" \
    PYTHON_CONFIGURE_OPTS="--enable-shared --enable-loadable-sqlite-extensions"

# Python313
RUN set -ex \
    && pyenv install $PYTHON_313_VERSION \
    && pyenv global $PYTHON_313_VERSION \
    && pip3 install --no-cache-dir --upgrade --force-reinstall "pip==$PYTHON_PIP_VERSION" \
    && pip3 install wheel \
    && pip3 install --no-cache-dir --upgrade "setuptools==$PYTHON_SETUPTOOLS_VERSION" boto3 pipenv virtualenv \
    && pip3 install --no-build-isolation "Cython<3" "PyYAML==$PYYAML_VERSION" \
    && pip3 uninstall cython --yes

#Python312
RUN set -ex \
    && pyenv install $PYTHON_312_VERSION \
    && pyenv global $PYTHON_312_VERSION \
    && pip3 install --no-cache-dir --upgrade --force-reinstall "pip==$PYTHON_PIP_VERSION" \
    && pip3 install wheel \
    && pip3 install --no-cache-dir --upgrade "setuptools==$PYTHON_SETUPTOOLS_VERSION" boto3 pipenv virtualenv \
    && pip3 install --no-build-isolation "Cython<3" "PyYAML==$PYYAML_VERSION" \
    && pip3 uninstall cython --yes

# Python311
RUN set -ex \
    && pyenv install $PYTHON_311_VERSION \
    && pyenv global $PYTHON_311_VERSION \
    && pip3 install --no-cache-dir --upgrade --force-reinstall "pip==$PYTHON_PIP_VERSION" \
    && pip3 install wheel \
    && pip3 install --no-cache-dir --upgrade "setuptools==$PYTHON_SETUPTOOLS_VERSION" boto3 pipenv virtualenv \
    && pip3 install --no-build-isolation "Cython<3" "PyYAML==$PYYAML_VERSION" \
    && pip3 uninstall cython --yes

# Python310
RUN set -ex \
    && pyenv install $PYTHON_310_VERSION \
    && pyenv global $PYTHON_310_VERSION \
    && pip3 install --no-cache-dir --upgrade --force-reinstall "pip==$PYTHON_PIP_VERSION" \
    && pip3 install wheel \
    && pip3 install --no-cache-dir --upgrade "setuptools==$PYTHON_SETUPTOOLS_VERSION" boto3 pipenv virtualenv \
    && pip3 install --no-build-isolation "Cython<3" "PyYAML==$PYYAML_VERSION" \
    && pip3 uninstall cython --yes

# Python39
RUN set -ex \
    && pyenv install $PYTHON_39_VERSION \
    && pyenv global $PYTHON_39_VERSION \
    && pip3 install --no-cache-dir --upgrade --force-reinstall "pip==$PYTHON_PIP_VERSION" \
    && pip3 install wheel \
    && pip3 install --no-cache-dir --upgrade "setuptools==$PYTHON_SETUPTOOLS_VERSION" boto3 pipenv virtualenv \
    && pip3 install --no-build-isolation "Cython<3" "PyYAML==$PYYAML_VERSION" \
    && pip3 uninstall cython --yes \
    && rm -rf /tmp/*
#**************** END PYTHON *****************************************************

#****************      PHP     ****************************************************

#phpenv
RUN curl -L https://raw.githubusercontent.com/phpenv/phpenv-installer/master/bin/phpenv-installer | bash
ENV PATH="/root/.phpenv/shims:/root/.phpenv/bin:$PATH"

ENV PHP_83_VERSION="8.3.22" \
    PHP_82_VERSION="8.2.28"
# Set environment variables for PHP configure options
ENV PHP_BUILD_CONFIGURE_OPTS="--with-curl --with-password-argon2 --with-pdo-pgsql --with-libedit"
# Set make arguments to use 4 parallel jobs.
ENV PHP_BUILD_EXTRA_MAKE_ARGUMENTS="-j4"

RUN phpenv update \
    && phpenv install $PHP_83_VERSION \
    && phpenv install $PHP_82_VERSION \
    && phpenv global $PHP_82_VERSION \
    && php -v \
    && echo "memory_limit = 1G;" >> "/root/.phpenv/versions/$PHP_83_VERSION/etc/conf.d/memory.ini" \
    && echo "memory_limit = 1G;" >> "/root/.phpenv/versions/$PHP_82_VERSION/etc/conf.d/memory.ini" \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
    && rm -rf /tmp/*
#****************      END PHP     ****************************************************

#****************     GOLANG     ****************************************************

#goenv
RUN git clone https://github.com/syndbg/goenv.git $HOME/.goenv
ENV PATH="/root/.goenv/shims:/root/.goenv/bin:/go/bin:$PATH"

ENV GOLANG_24_VERSION="1.24.4" \
    GOLANG_23_VERSION="1.23.10" \
    GOLANG_22_VERSION="1.22.12" \
    GOLANG_21_VERSION="1.21.13" \
    GOLANG_20_VERSION="1.20.14"
ENV GOENV_DISABLE_GOPATH=1 \
    GOPATH="/go"

RUN goenv install $GOLANG_24_VERSION \
    && goenv install $GOLANG_23_VERSION \
    && goenv install $GOLANG_22_VERSION \
    && goenv install $GOLANG_21_VERSION \
    && goenv install $GOLANG_20_VERSION \
    && goenv global $GOLANG_20_VERSION \
    && go env -w GO111MODULE=auto \
    && go get -u github.com/golang/dep/cmd/dep \
    && rm -rf /tmp/*
#****************      END GOLANG     *******************************

#****************      JAVA     ****************************************************
ENV JAVA_21_HOME="/usr/lib/jvm/java-21-amazon-corretto" \
    JDK_21_HOME="/usr/lib/jvm/java-21-amazon-corretto" \
    JRE_21_HOME="/usr/lib/jvm/java-21-amazon-corretto" \
    JAVA_17_HOME="/usr/lib/jvm/java-17-amazon-corretto" \
    JDK_17_HOME="/usr/lib/jvm/java-17-amazon-corretto" \
    JRE_17_HOME="/usr/lib/jvm/java-17-amazon-corretto" \
    JAVA_11_HOME="/usr/lib/jvm/java-11-amazon-corretto" \
    JDK_11_HOME="/usr/lib/jvm/java-11-amazon-corretto" \
    JRE_11_HOME="/usr/lib/jvm/java-11-amazon-corretto" \
    JAVA_8_HOME="/usr/lib/jvm/java-1.8.0-amazon-corretto" \
    JDK_8_HOME="/usr/lib/jvm/java-1.8.0-amazon-corretto" \
    JRE_8_HOME="/usr/lib/jvm/java-1.8.0-amazon-corretto"
ARG ANT_VERSION=1.10.15
ARG MAVEN_HOME="/opt/maven"
ARG MAVEN_VERSION=3.9.10
ARG GRADLE_VERSION=8.14.2
ARG SBT_VERSION=1.11.2
ARG GRADLE_PATH="$SRC_DIR/gradle"
ARG ANT_DOWNLOAD_SHA512="d78427aff207592c024ff1552dc04f7b57065a195c42d398fcffe7a0145e8d00cd46786f5aa52e77ab0fdf81334f065eb8011eecd2b48f7228e97ff4cb20d16c"
ARG MAVEN_DOWNLOAD_SHA512="4ef617e421695192a3e9a53b3530d803baf31f4269b26f9ab6863452d833da5530a4d04ed08c36490ad0f141b55304bceed58dbf44821153d94ae9abf34d0e1b"
ARG GRADLE_DOWNLOADS_SHA256="443c9c8ee2ac1ee0e11881a40f2376d79c66386264a44b24a9f8ca67e633375f 8.14.2"
ARG SBT_DOWNLOAD_SHA256="84c7b9d8e20c5dc8356154a5b7146c0a8b86aba97268ce9fe1a585d2c8908f4f"

ARG MAVEN_CONFIG_HOME="/root/.m2"

ENV JAVA_HOME="$JAVA_17_HOME" \
    JDK_HOME="$JDK_17_HOME" \
    JRE_HOME="$JRE_17_HOME"

ENV PATH="${PATH}:/opt/tools"

RUN set -ex \
    && apt-get update \
    && apt-get install -y -qq software-properties-common apt-utils \
    && wget -O - https://apt.corretto.aws/corretto.key | sudo gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" | sudo tee /etc/apt/sources.list.d/corretto.list \
    && apt-get update \
    && apt-get install -y -qq java-21-amazon-corretto-jdk \
    && apt-get install -y -qq java-17-amazon-corretto-jdk \
    && apt-get install -y -qq java-11-amazon-corretto-jdk \
    && apt-get install -y -qq java-1.8.0-amazon-corretto-jdk \
    && apt-get install -y -qq --no-install-recommends ca-certificates-java \
    # Ensure Java cacerts symlink points to valid location
    && update-ca-certificates -f \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && for tool_path in $JAVA_HOME/bin/*; do \
          tool=`basename $tool_path`; \
          update-alternatives --install /usr/bin/$tool $tool $tool_path 10000; \
          update-alternatives --set $tool $tool_path; \
        done \
     && rm $JAVA_HOME/lib/security/cacerts && ln -s /etc/ssl/certs/java/cacerts $JAVA_HOME/lib/security/cacerts \
    # Install Ant
    && curl -LSso /var/tmp/apache-ant-$ANT_VERSION-bin.tar.gz https://archive.apache.org/dist/ant/binaries/apache-ant-$ANT_VERSION-bin.tar.gz  \
    && echo "$ANT_DOWNLOAD_SHA512 /var/tmp/apache-ant-$ANT_VERSION-bin.tar.gz" | sha512sum -c - \
    && tar -xzf /var/tmp/apache-ant-$ANT_VERSION-bin.tar.gz -C /opt \
    && rm /var/tmp/apache-ant-$ANT_VERSION-bin.tar.gz \
    && update-alternatives --install /usr/bin/ant ant /opt/apache-ant-$ANT_VERSION/bin/ant 10000

RUN set -ex \
    # Install Maven
    && mkdir -p $MAVEN_HOME \
    && curl -LSso /var/tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz https://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    && echo "$MAVEN_DOWNLOAD_SHA512 /var/tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz" | sha512sum -c - \
    && tar xzf /var/tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz -C $MAVEN_HOME --strip-components=1 \
    && rm /var/tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    && update-alternatives --install /usr/bin/mvn mvn /opt/maven/bin/mvn 10000 \
    && mkdir -p $MAVEN_CONFIG_HOME \
    # Install Gradle
    && mkdir -p $GRADLE_PATH \
    && wget -q "https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-all.zip" -O "$GRADLE_PATH/gradle-$GRADLE_VERSION-all.zip" \
    && unzip -q "$GRADLE_PATH/gradle-$GRADLE_VERSION-all.zip" -d /usr/local \
    && echo "$GRADLE_DOWNLOADS_SHA256" | grep "$GRADLE_VERSION" | sed "s|$GRADLE_VERSION|$GRADLE_PATH/gradle-$GRADLE_VERSION-all.zip|" | sha256sum -c - \
    && rm "$GRADLE_PATH/gradle-$GRADLE_VERSION-all.zip" \
    && mkdir -p "/tmp/gradle-$GRADLE_VERSION" \
    && "/usr/local/gradle-$GRADLE_VERSION/bin/gradle" -p "/tmp/gradle-$GRADLE_VERSION" init --overwrite \
    && "/usr/local/gradle-$GRADLE_VERSION/bin/gradle" -p "/tmp/gradle-$GRADLE_VERSION" wrapper \
    # Android Studio uses the "-all" distribution for it's wrapper script.
    && perl -pi -e "s/gradle-$GRADLE_VERSION-bin.zip/gradle-$GRADLE_VERSION-all.zip/" "/tmp/gradle-$GRADLE_VERSION/gradle/wrapper/gradle-wrapper.properties" \
    && "/tmp/gradle-$GRADLE_VERSION/gradlew" -p "/tmp/gradle-$GRADLE_VERSION" init --overwrite \
    && rm -rf "/tmp/gradle-$GRADLE_VERSION"  \
    # Install default GRADLE_VERSION to path
    && ln -s /usr/local/gradle-$GRADLE_VERSION/bin/gradle /usr/bin/gradle \
    && rm -rf $GRADLE_PATH \
    # Install SBT
    && curl -fSL "https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.tgz" -o sbt.tgz \
    && echo "${SBT_DOWNLOAD_SHA256} *sbt.tgz" | sha256sum -c - \
    && tar xzf sbt.tgz -C /usr/local/bin/ \
    && rm sbt.tgz

ENV PATH="/usr/local/bin/sbt/bin:$PATH"
RUN sbt --allow-empty version -Dsbt.rootdir=true
# Cleanup -- if we do not run apt-get update after apt-get clean, it will remove available corretto versions to install
RUN rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/* && apt-get clean && apt-get update
#****************     END JAVA     ****************************************************

#=======================End of stage: runtimes  =================

FROM runtimes AS std_v7

# Activate runtime versions specific to image version.
RUN n --preserve $NODE_22_VERSION
RUN pyenv global $PYTHON_311_VERSION
RUN phpenv global $PHP_82_VERSION
RUN rbenv global $RUBY_32_VERSION
RUN goenv global $GOLANG_20_VERSION
RUN dotnet new globaljson --force --sdk-version $DOTNET_6_GLOBAL_JSON_SDK_VERSION --roll-forward latestFeature

# Configure SSH
COPY ssh_config /root/.ssh/config
COPY runtimes.yml /codebuild/image/config/runtimes.yml
COPY dockerd-entrypoint.sh /usr/local/bin/dockerd-entrypoint.sh
RUN chmod +x /usr/local/bin/dockerd-entrypoint.sh
COPY legal/bill_of_material.txt /usr/share/doc/bill_of_material.txt
COPY amazon-ssm-agent.json /etc/amazon/ssm/amazon-ssm-agent.json

ENTRYPOINT ["/usr/local/bin/dockerd-entrypoint.sh"]

#=======================END of STD:7.0  =================
