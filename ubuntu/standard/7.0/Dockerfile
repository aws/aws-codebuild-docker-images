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

# Install git, SSH, and other utilities
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
          apt-utils asciidoc autoconf automake build-essential bzip2 \
          bzr curl dirmngr docbook-xml docbook-xsl dpkg-dev \
          e2fsprogs expect fakeroot file g++ gcc gettext gettext-base \
          groff gzip iptables jq less libapr1 libaprutil1 \
          libargon2-0-dev libbz2-dev libc6-dev libcurl4-openssl-dev \
          libdb-dev libdbd-sqlite3-perl libdbi-perl libdpkg-perl \
          libedit-dev liberror-perl libevent-dev libffi-dev libgeoip-dev \
          libglib2.0-dev libhttp-date-perl libio-pty-perl libjpeg-dev \
          libkrb5-dev liblzma-dev libmagickcore-dev libmagickwand-dev \
          libmysqlclient-dev libncurses5-dev libncursesw5-dev libonig-dev \
          libpq-dev libreadline-dev libserf-1-1 libsodium-dev libsqlite3-dev libssl-dev \
          libsvn1 libsvn-perl libtcl8.6 libtidy-dev libtimedate-perl \
          libtool libwebp-dev libxml2-dev libxml2-utils libxslt1-dev \
          libyaml-dev libyaml-perl llvm locales make mlocate \
          netbase openssl patch pkg-config procps python3-configobj \
          python3-openssl rsync sgml-base sgml-data \
          tar tcl tcl8.6 tk tk-dev unzip wget xfsprogs xml-core xmlto xsltproc \
          libzip-dev vim xvfb xz-utils zip zlib1g-dev git-lfs acl \
    && rm -rf /var/lib/apt/lists/*

ENV LC_CTYPE="C.UTF-8"

RUN useradd codebuild-user

#=======================End of layer: core  =================

FROM core AS tools

# Install Git
RUN set -ex \
   && GIT_VERSION=2.45.2 \
   && GIT_TAR_FILE=git-$GIT_VERSION.tar.gz \
   && GIT_SRC=https://github.com/git/git/archive/v${GIT_VERSION}.tar.gz  \
   && curl -L -o $GIT_TAR_FILE $GIT_SRC \
   && tar zxf $GIT_TAR_FILE \
   && cd git-$GIT_VERSION \
   && make -j4 \
   && make install prefix=/usr \
   && cd .. && rm -rf git-$GIT_VERSION \
   && rm -rf $GIT_TAR_FILE /tmp/*

# Install AWS SAM CLI
RUN wget -nv https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip -O /tmp/samcli.zip \
    && unzip -q /tmp/samcli.zip -d /opt \
    && /opt/install --update -i /usr/local/sam-cli -b /usr/local/bin \
    && rm /tmp/samcli.zip /opt/install \
    && rm -rf /opt/aws-sam-cli-src \
    && sam --version

# Install stunnel
RUN set -ex \
   && STUNNEL_VERSION=5.71 \
   && STUNNEL_TAR=stunnel-$STUNNEL_VERSION.tar.gz \
   && STUNNEL_SHA256="f023aae837c2d32deb920831a5ee1081e11c78a5d57340f8e6f0829f031017f5" \
   && curl -o $STUNNEL_TAR https://www.stunnel.org/archive/5.x/$STUNNEL_TAR && echo "$STUNNEL_SHA256 $STUNNEL_TAR" | sha256sum --check && tar xfz $STUNNEL_TAR \
   && cd stunnel-$STUNNEL_VERSION \
   && ./configure \
   && make -j4 \
   && make install \
   && openssl genrsa -out key.pem 2048 \
   && openssl req -new -x509 -key key.pem -out cert.pem -days 1095 -subj "/C=US/ST=Washington/L=Seattle/O=Amazon/OU=Codebuild/CN=codebuild.amazon.com" \
   && cat key.pem cert.pem >> /usr/local/etc/stunnel/stunnel.pem \
   && cd .. && rm -rf stunnel-${STUNNEL_VERSION}*

# AWS Tools
# https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html
RUN curl -sS -o /usr/local/bin/aws-iam-authenticator https://s3.us-west-2.amazonaws.com/amazon-eks/1.25.6/2023-01-30/bin/linux/amd64/aws-iam-authenticator \
    && curl -sS -o /usr/local/bin/kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.25.6/2023-01-30/bin/linux/amd64/kubectl \
    && curl -sS -o /usr/local/bin/ecs-cli https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest \
    && curl -sS -L https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz | tar xz -C /usr/local/bin \
    && chmod +x /usr/local/bin/kubectl /usr/local/bin/aws-iam-authenticator /usr/local/bin/ecs-cli /usr/local/bin/eksctl

# Configure SSM
RUN set -ex \
    && mkdir /tmp/ssm \
    && cd /tmp/ssm \
    && wget -q https://s3.amazonaws.com/amazon-ssm-us-east-1/latest/debian_amd64/amazon-ssm-agent.deb \
    && dpkg -i amazon-ssm-agent.deb

# Install AWS CLI v2
# https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html
RUN curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /opt \
    && /opt/aws/install --update -i /usr/local/aws-cli -b /usr/local/bin \
    && rm /tmp/awscliv2.zip \
    && rm -rf /opt/aws \
    && aws --version

#****************     Pack CLI     *************************************************
RUN (curl -sSL "https://github.com/buildpacks/pack/releases/download/v0.32.1/pack-v0.32.1-linux.tgz" \
    | tar -C /usr/local/bin/ --no-same-owner -xzv pack)

#****************     END Pack CLI     *********************************************

#****************        DOCKER    *********************************************
ARG DOCKER_BUCKET="download.docker.com"
ARG DOCKER_CHANNEL="stable"
ARG DIND_COMMIT="3b5fac462d21ca164b3778647420016315289034"
ARG DOCKER_COMPOSE_VERSION="2.27.0"
ARG DOCKER_BUILDX_VERSION="0.14.1"
ARG SRC_DIR="/usr/src"

ARG DOCKER_SHA256="a9cede81aa3337f310132c2c920dba2edc8d29b7d97065b63ba41cf47ae1ca4f"
ARG DOCKER_VERSION="26.1.4"

# Install Docker
RUN set -ex \
    && curl -fSL "https://${DOCKER_BUCKET}/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz" -o docker.tgz \
    && echo "${DOCKER_SHA256} *docker.tgz" | sha256sum -c - \
    && tar --extract --file docker.tgz --strip-components 1  --directory /usr/local/bin/ \
    && rm docker.tgz \
    && docker -v \
    # replace runc package to resolve CVE-2024-21626
    && apt-get update && apt-get -y install runc \
    && rm -f /usr/local/bin/runc \
    && ln -s /usr/sbin/runc /usr/local/bin/runc \
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
#=======================End of stage: tools  =================
FROM tools AS runtimes

#****************     .NET-CORE     *******************************************************

# Dotnet
ENV PATH "/root/.dotnet/:/root/.dotnet/tools/:$PATH"
RUN set -ex  \
&& wget -qO /usr/local/bin/dotnet-install.sh https://dot.net/v1/dotnet-install.sh \
&& chmod +x /usr/local/bin/dotnet-install.sh

ENV DOTNET_6_SDK_VERSION="6.0.423"
ENV DOTNET_8_SDK_VERSION="8.0.301"
ENV DOTNET_6_GLOBAL_JSON_SDK_VERSION="6.0.0"
ENV DOTNET_8_GLOBAL_JSON_SDK_VERSION="8.0.0"
ENV DOTNET_ROOT="/root/.dotnet"

# Add .NET Core 8 Global Tools install folder to PATH
RUN  /usr/local/bin/dotnet-install.sh -v $DOTNET_8_SDK_VERSION \
     && dotnet --list-sdks \
     && rm -rf /tmp/*

# Add .NET Core 6 Global Tools install folder to PATH
RUN  /usr/local/bin/dotnet-install.sh -v $DOTNET_6_SDK_VERSION \
     && dotnet --list-sdks \
     && rm -rf /tmp/* \
     && cd /codebuild && dotnet new globaljson --force --sdk-version $DOTNET_6_GLOBAL_JSON_SDK_VERSION --roll-forward feature

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
# See instructions at https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-powershell-core-on-linux
ARG POWERSHELL_VERSION=7.3.11
ARG POWERSHELL_DOWNLOAD_URL=https://github.com/PowerShell/PowerShell/releases/download/v$POWERSHELL_VERSION/powershell-$POWERSHELL_VERSION-linux-x64.tar.gz
ARG POWERSHELL_DOWNLOAD_SHA=674CABD4AC9EAD59C1BBBDCE3FBE07134215128AF1C429A41FE74DDE96928BD4

RUN set -ex \
    && curl -SL $POWERSHELL_DOWNLOAD_URL --output powershell.tar.gz \
    && echo "$POWERSHELL_DOWNLOAD_SHA powershell.tar.gz" | sha256sum -c - \
    && mkdir -p /opt/microsoft/powershell/$POWERSHELL_VERSION \
    && tar zxf powershell.tar.gz -C /opt/microsoft/powershell/$POWERSHELL_VERSION \
    && rm powershell.tar.gz \
    && ln -s /opt/microsoft/powershell/$POWERSHELL_VERSION/pwsh /usr/bin/pwsh
#****************     END .NET-CORE     *******************************************************


#****************      NODEJS     ****************************************************

#nodejs
ARG SRC_DIR="/usr/src"
ARG N_SRC_DIR="$SRC_DIR/n"
RUN git clone https://github.com/tj/n $N_SRC_DIR \
     && cd $N_SRC_DIR && make install

ENV NODE_18_VERSION="18.20.3"
ENV NODE_20_VERSION="20.14.0"
ENV NODE_22_VERSION="22.2.0"

RUN  n $NODE_18_VERSION && npm install --save-dev -g -f grunt \
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
     && cd / && rm -rf $N_SRC_DIR && rm -rf /tmp/*

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

ENV RUBY_33_VERSION="3.3.2"
ENV RUBY_32_VERSION="3.2.4"
ENV RUBY_31_VERSION="3.1.6"

RUN rbenv install $RUBY_33_VERSION \
    && rbenv install $RUBY_32_VERSION \
    && rbenv install $RUBY_31_VERSION \
    && rbenv global $RUBY_32_VERSION && ruby -v \
    && rm -rf /tmp/*

#**************** END RUBY *****************************************************

#**************** PYTHON *****************************************************

#Install pyenv
RUN curl -s -S -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash
ENV PATH="/root/.pyenv/shims:/root/.pyenv/bin:$PATH"

ENV PYTHON_311_VERSION="3.11.9" \
    PYTHON_312_VERSION="3.12.4" \
    PYTHON_310_VERSION="3.10.14" \
    PYTHON_39_VERSION="3.9.19" \
    PYTHON_PIP_VERSION="24.0" \
    PYYAML_VERSION="5.4.1" \
    PYTHON_CONFIGURE_OPTS="--enable-shared --enable-loadable-sqlite-extensions"

#Python312
RUN set -ex \
    && pyenv install $PYTHON_312_VERSION \
    && pyenv global $PYTHON_312_VERSION \
    && pip3 install --no-cache-dir --upgrade --force-reinstall "pip==$PYTHON_PIP_VERSION" \
    && pip3 install wheel \
    && pip3 install --no-cache-dir --upgrade 'setuptools==67.7.2' boto3 pipenv virtualenv \
    && pip3 install --no-build-isolation "Cython<3" "PyYAML==$PYYAML_VERSION" \
    && pip3 uninstall cython --yes

# Python311
RUN set -ex \
    && pyenv install $PYTHON_311_VERSION \
    && pyenv global $PYTHON_311_VERSION \
    && pip3 install --no-cache-dir --upgrade --force-reinstall "pip==$PYTHON_PIP_VERSION" \
    && pip3 install wheel \
    && pip3 install --no-cache-dir --upgrade 'setuptools==67.7.2' boto3 pipenv virtualenv \
    && pip3 install --no-build-isolation "Cython<3" "PyYAML==$PYYAML_VERSION" \
    && pip3 uninstall cython --yes

# Python310
RUN set -ex \
    && pyenv install $PYTHON_310_VERSION \
    && pyenv global $PYTHON_310_VERSION \
    && pip3 install --no-cache-dir --upgrade --force-reinstall "pip==$PYTHON_PIP_VERSION" \
    && pip3 install wheel \
    && pip3 install --no-cache-dir --upgrade 'setuptools==67.7.2' boto3 pipenv virtualenv \
    && pip3 install --no-build-isolation "Cython<3" "PyYAML==$PYYAML_VERSION" \
    && pip3 uninstall cython --yes

# Python39
RUN set -ex \
    && pyenv install $PYTHON_39_VERSION \
    && pyenv global $PYTHON_39_VERSION \
    && pip3 install --no-cache-dir --upgrade --force-reinstall "pip==$PYTHON_PIP_VERSION" \
    && pip3 install wheel \
    && pip3 install --no-cache-dir --upgrade 'setuptools==67.7.2' boto3 pipenv virtualenv \
    && pip3 install --no-build-isolation "Cython<3" "PyYAML==$PYYAML_VERSION" \
    && pip3 uninstall cython --yes \
    && rm -rf /tmp/*

#**************** END PYTHON *****************************************************

#****************      PHP     ****************************************************

#phpenv
RUN curl -L https://raw.githubusercontent.com/phpenv/phpenv-installer/master/bin/phpenv-installer | bash
ENV PATH="/root/.phpenv/shims:/root/.phpenv/bin:$PATH"

ENV PHP_83_VERSION="8.3.8"
ENV PHP_82_VERSION="8.2.20"
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
ENV GOENV_DISABLE_GOPATH=1
ENV GOPATH="/go"

ENV GOLANG_23_VERSION="1.23.2"
ENV GOLANG_22_VERSION="1.22.4"
ENV GOLANG_21_VERSION="1.21.11"
ENV GOLANG_20_VERSION="1.20.14"
ENV GOENV_DISABLE_GOPATH=1
ENV GOPATH="/go"

RUN goenv install $GOLANG_23_VERSION \
    && goenv install $GOLANG_22_VERSION \
    && goenv install $GOLANG_21_VERSION \
    && goenv install $GOLANG_20_VERSION \
    && goenv global $GOLANG_20_VERSION \
    && go env -w GO111MODULE=auto \
    && go get -u github.com/golang/dep/cmd/dep \
    && rm -rf /tmp/*

#****************      END GOLANG     *******************************

#****************      JAVA     ****************************************************
ENV JAVA_17_HOME="/usr/lib/jvm/java-17-amazon-corretto" \
    JDK_17_HOME="/usr/lib/jvm/java-17-amazon-corretto" \
    JRE_17_HOME="/usr/lib/jvm/java-17-amazon-corretto" \
    JAVA_21_HOME="/usr/lib/jvm/java-21-amazon-corretto" \
    JDK_21_HOME="/usr/lib/jvm/java-21-amazon-corretto" \
    JRE_21_HOME="/usr/lib/jvm/java-21-amazon-corretto" \
    JAVA_11_HOME="/usr/lib/jvm/java-11-amazon-corretto" \
    JDK_11_HOME="/usr/lib/jvm/java-11-amazon-corretto" \
    JRE_11_HOME="/usr/lib/jvm/java-11-amazon-corretto" \
    JAVA_8_HOME="/usr/lib/jvm/java-1.8.0-amazon-corretto" \
    JDK_8_HOME="/usr/lib/jvm/java-1.8.0-amazon-corretto" \
    JRE_8_HOME="/usr/lib/jvm/java-1.8.0-amazon-corretto"
ARG ANT_VERSION=1.10.14
ARG MAVEN_HOME="/opt/maven"
ARG MAVEN_VERSION=3.9.5
ARG GRADLE_VERSION=8.3
ARG SBT_VERSION=1.9.6
ARG GRADLE_PATH="$SRC_DIR/gradle"
ARG ANT_DOWNLOAD_SHA512="4e74b382dd8271f9eac9fef69ba94751fb8a8356dbd995c4d642f2dad33de77bd37d4001d6c8f4f0ef6789529754968f0c1b6376668033c8904c6ec84543332a"
ARG MAVEN_DOWNLOAD_SHA512="4810523ba025104106567d8a15a8aa19db35068c8c8be19e30b219a1d7e83bcab96124bf86dc424b1cd3c5edba25d69ec0b31751c136f88975d15406cab3842b"
ARG GRADLE_DOWNLOADS_SHA256="bb09982fdf52718e4c7b25023d10df6d35a5fff969860bdf5a5bd27a3ab27a9e 8.3"
ARG SBT_DOWNLOAD_SHA256="923d7917ccb99a9fd985f4abfd81caacaed42284e67d3f7696cc5239e7c595cb"

ARG MAVEN_CONFIG_HOME="/root/.m2"

ENV JAVA_HOME="$JAVA_17_HOME" \
    JDK_HOME="$JDK_17_HOME" \
    JRE_HOME="$JRE_17_HOME"

ENV PATH="${PATH}:/opt/tools"

RUN set -ex \
    && apt-get update \
    && apt-get install -y -qq software-properties-common apt-utils sudo \
    # Install Corretto 17
    && wget -O - https://apt.corretto.aws/corretto.key | sudo gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" | sudo tee /etc/apt/sources.list.d/corretto.list \
    && apt-get update \
    && apt-get install -y -qq java-17-amazon-corretto-jdk \
    && apt-get install -y -qq java-21-amazon-corretto-jdk \
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
    && mkdir "/tmp/gradle-$GRADLE_VERSION" \
    && "/usr/local/gradle-$GRADLE_VERSION/bin/gradle" -p "/tmp/gradle-$GRADLE_VERSION" init \
    && "/usr/local/gradle-$GRADLE_VERSION/bin/gradle" -p "/tmp/gradle-$GRADLE_VERSION" wrapper \
    # Android Studio uses the "-all" distribution for it's wrapper script.
    && perl -pi -e "s/gradle-$GRADLE_VERSION-bin.zip/gradle-$GRADLE_VERSION-all.zip/" "/tmp/gradle-$GRADLE_VERSION/gradle/wrapper/gradle-wrapper.properties" \
    && "/tmp/gradle-$GRADLE_VERSION/gradlew" -p "/tmp/gradle-$GRADLE_VERSION" init \
    && rm -rf "/tmp/gradle-$GRADLE_VERSION"  \
    # Install default GRADLE_VERSION to path
    && ln -s /usr/local/gradle-$GRADLE_VERSION/bin/gradle /usr/bin/gradle \
    && rm -rf $GRADLE_PATH \
    # Install SBT
    && curl -fSL "https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.tgz" -o sbt.tgz \
    && echo "${SBT_DOWNLOAD_SHA256} *sbt.tgz" | sha256sum -c - \
    && tar xzf sbt.tgz -C /usr/local/bin/ \
    && rm sbt.tgz

ENV PATH "/usr/local/bin/sbt/bin:$PATH"
RUN sbt version -Dsbt.rootdir=true
# Cleanup
RUN rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/* && apt-get clean && apt-get update
#****************     END JAVA     ****************************************************

#=======================End of stage: runtimes  =================

FROM runtimes AS std_v7

# Activate runtime versions specific to image version.
RUN n $NODE_18_VERSION
RUN pyenv global $PYTHON_311_VERSION
RUN phpenv global $PHP_82_VERSION
RUN rbenv global $RUBY_32_VERSION
RUN goenv global $GOLANG_20_VERSION
RUN dotnet new globaljson --force --sdk-version $DOTNET_6_GLOBAL_JSON_SDK_VERSION --roll-forward feature

# Configure SSH
COPY ssh_config /root/.ssh/config
COPY runtimes.yml /codebuild/image/config/runtimes.yml
COPY dockerd-entrypoint.sh /usr/local/bin/dockerd-entrypoint.sh
COPY legal/bill_of_material.txt /usr/share/doc/bill_of_material.txt
COPY amazon-ssm-agent.json /etc/amazon/ssm/amazon-ssm-agent.json



ENTRYPOINT ["/usr/local/bin/dockerd-entrypoint.sh"]

#=======================END of STD:7.0  =================
