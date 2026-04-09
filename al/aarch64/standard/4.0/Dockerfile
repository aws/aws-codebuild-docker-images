# Copyright 2020-2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use this file except in compliance with the License.
# A copy of the License is located at
#
#    http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

FROM public.ecr.aws/amazonlinux/amazonlinux:2023 AS core

RUN set -ex \
    && yum install -yq openssh-clients \
    && mkdir ~/.ssh \
    && touch ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa,ed25519,ecdsa -H github.com >> ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa,ed25519,ecdsa -H bitbucket.org >> ~/.ssh/known_hosts \
    && chmod 600 ~/.ssh/known_hosts \
    && curl https://download.mono-project.com/repo/centos7-stable.repo | tee /etc/yum.repos.d/mono-centos7-stable.repo \
    && yum groupinstall -yq "Development tools" \
    && yum install -yq --allowerasing \
           ImageMagick asciidoc bzip2 bzip2-devel cvs cvsps automake \
           docbook-dtds docbook-style-xsl e2fsprogs expat-devel expect fakeroot \
           glib2-devel groff gzip icu iptables-legacy jq krb5-server libargon2-devel \
           libcurl-devel libdb-devel libedit-devel libevent-devel libffi-devel \
           libicu-devel libjpeg-devel libpng-devel libserf \
           libtidy libtidy-devel libunwind libwebp-devel libxml2-devel libxslt libxslt-devel \
           libyaml-devel libzip-devel mlocate \
           ncurses-devel oniguruma-devel openssl openssl-devel perl-DBD-SQLite \
           perl-DBI perl-HTTP-Date perl-TimeDate perl-YAML-LibYAML perl perl-FindBin \
           postgresql-devel procps-ng python-configobj readline-devel rsync sgml-common \
           patch pkg-config procps python3-configobj llvm rsync sqlite-devel \
           subversion-perl tar tcl tk telnet texinfo time tzdata vim wget which xfsprogs xmlto xorg-x11-server-Xvfb xz-devel \
           amazon-ecr-credential-helper git-lfs runc acl unzip \
           automake binutils bison brotli file findutils flex gnupg2 libsecret-devel libtool \
           libxkbfile-devel lz4 m4 make mesa-libgbm-devel mariadb105-devel mercurial net-tools pigz pkg-config xorriso xz zip

RUN useradd codebuild-user

#=======================End of layer: core  =================

FROM core AS tools

# Install AWS SAM CLI
RUN wget -nv https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-arm64.zip -O /tmp/samcli.zip \
    && unzip -q /tmp/samcli.zip -d /opt \
    && /opt/install --update -i /usr/local/sam-cli -b /usr/local/bin \
    && rm /tmp/samcli.zip /opt/install \
    && rm -rf /opt/aws-sam-cli-src \
    && sam --version

# Install Git
RUN set -ex \
   && GIT_VERSION=2.53.0 \
   && GIT_TAR_FILE=git-$GIT_VERSION.tar.gz \
   && GIT_SRC=https://github.com/git/git/archive/v${GIT_VERSION}.tar.gz  \
   && curl -L -o $GIT_TAR_FILE $GIT_SRC \
   && tar zxf $GIT_TAR_FILE \
   && cd git-$GIT_VERSION \
   && make -j4 prefix=/usr \
   && make install prefix=/usr \
   && cd .. && rm -rf git-$GIT_VERSION \
   && rm -rf $GIT_TAR_FILE /tmp/* \
   && git --version

# Install stunnel
RUN set -ex \
   && STUNNEL_VERSION=5.77 \
   && STUNNEL_TAR=stunnel-$STUNNEL_VERSION.tar.gz \
   && STUNNEL_SHA256="ec026f4fae4e0d25b940cc7a9451d925e359e7fd59e9edad20baea66ce45f263" \
   && curl -o $STUNNEL_TAR https://www.stunnel.org/archive/5.x/$STUNNEL_TAR \
   && echo "$STUNNEL_SHA256 $STUNNEL_TAR" | sha256sum -c - \
   && tar xvfz $STUNNEL_TAR \
   && cd stunnel-$STUNNEL_VERSION \
   && ./configure \
   && make -j4 \
   && make install \
   && openssl genrsa -out key.pem 2048 \
   && openssl req -new -x509 -key key.pem -out cert.pem -days 1095 -subj "/C=US/ST=Washington/L=Seattle/O=Amazon/OU=Codebuild/CN=codebuild.amazon.com" \
   && cat key.pem cert.pem >> /usr/local/etc/stunnel/stunnel.pem \
   && cd .. ; rm -rf stunnel-${STUNNEL_VERSION}* \
   && stunnel -version

# AWS Tools
# aws-iam-authenticator: https://github.com/kubernetes-sigs/aws-iam-authenticator/releases
# kubectl: https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html
# eksctl: https://eksctl.io/installation/
# ecs-cli: https://github.com/aws/amazon-ecs-cli?tab=readme-ov-file#installing
# Check out the KUBERNETES_VERSION and AMAZON_EKS_S3_PATH from the curl command in:
# https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html#linux_arm64_kubectl
RUN set -ex \
    && KUBERNETES_VERSION=1.35.2 \
    && AMAZON_EKS_S3_PATH=2026-02-27 \
    && curl -sS -o /usr/local/bin/aws-iam-authenticator https://s3.us-west-2.amazonaws.com/amazon-eks/$KUBERNETES_VERSION/$AMAZON_EKS_S3_PATH/bin/linux/arm64/aws-iam-authenticator \
    && chmod +x /usr/local/bin/aws-iam-authenticator \
    && aws-iam-authenticator version \
    && curl -sS -o /usr/local/bin/kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/$KUBERNETES_VERSION/$AMAZON_EKS_S3_PATH/bin/linux/arm64/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && kubectl version --client \
    && curl -sS -L https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_arm64.tar.gz | tar xz -C /usr/local/bin \
    && chmod +x /usr/local/bin/eksctl \
    && eksctl version \
    && curl -sS -o /usr/local/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-arm64-latest \
    && chmod +x /usr/local/bin/ecs-cli \
    && ecs-cli --version

# Install amazon-ecr-credential-helper
# To configure: https://github.com/awslabs/amazon-ecr-credential-helper?tab=readme-ov-file#configuration
# ecr-login is not configured because it conflicts with docker login commands https://github.com/awslabs/amazon-ecr-credential-helper/issues/102
RUN set -ex \
    && yum install -y -q amazon-ecr-credential-helper \
    && docker-credential-ecr-login -v

# Install Pack
RUN set -ex \
    && PACK_VERSION=0.39.1 \
    && (curl -sSL "https://github.com/buildpacks/pack/releases/download/v${PACK_VERSION}/pack-v${PACK_VERSION}-linux-arm64.tgz" | tar -C /usr/local/bin/ --no-same-owner -xzv pack) \
    && pack --version

# Configure SSM
RUN set -ex \
    && yum install -yq https://s3.amazonaws.com/amazon-ssm-us-east-1/latest/linux_arm64/amazon-ssm-agent.rpm

# Install env tools for runtimes
## Dotnet
ENV PATH="/root/.dotnet/:/root/.dotnet/tools/:$PATH"
RUN set -ex  \
    && wget -qO /usr/local/bin/dotnet-install.sh https://dot.net/v1/dotnet-install.sh \
    && chmod +x /usr/local/bin/dotnet-install.sh

##nodejs
ENV N_SRC_DIR="$SRC_DIR/n"
RUN git clone https://github.com/tj/n $N_SRC_DIR \
    && cd $N_SRC_DIR && make install

##ruby
ENV RBENV_SRC_DIR="/usr/local/rbenv"

ENV PATH="/root/.rbenv/shims:$RBENV_SRC_DIR/bin:$RBENV_SRC_DIR/shims:$PATH" \
    RUBY_BUILD_SRC_DIR="$RBENV_SRC_DIR/plugins/ruby-build"

RUN set -ex \
    && git clone https://github.com/rbenv/rbenv.git $RBENV_SRC_DIR \
    && mkdir -p $RBENV_SRC_DIR/plugins \
    && git clone https://github.com/rbenv/ruby-build.git $RUBY_BUILD_SRC_DIR \
    && sh $RUBY_BUILD_SRC_DIR/install.sh

##python
RUN curl -s -S -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash
ENV PATH="/root/.pyenv/shims:/root/.pyenv/bin:$PATH"

##php
RUN curl -L https://raw.githubusercontent.com/phpenv/phpenv-installer/master/bin/phpenv-installer | bash
ENV PATH="/root/.phpenv/shims:/root/.phpenv/bin:$PATH"

##go
RUN git clone https://github.com/syndbg/goenv.git $HOME/.goenv
ENV PATH="/root/.goenv/shims:/root/.goenv/bin:/go/bin:$PATH"
ENV GOENV_DISABLE_GOPATH=1
ENV GOPATH="/go"

##rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain none
ENV PATH="/root/.cargo/bin:$PATH"

##awscliv2
RUN curl https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip -o /tmp/awscliv2.zip \
     && unzip /tmp/awscliv2.zip -d /opt \
     && /opt/aws/install --update -i /usr/local/aws-cli -b /usr/local/bin \
     && rm /tmp/awscliv2.zip \
     && rm -rf /opt/aws \
     && aws --version

## gh
# See instruction: https://github.com/cli/cli/blob/trunk/docs/install_linux.md#fedora-centos-red-hat-enterprise-linux-dnf
RUN yum -y install 'dnf-command(config-manager)' \
    && yum config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo \
    && yum -y install gh --repo gh-cli
#=======================End of layer: tools  =================

FROM tools AS runtimes_1

#****************      JAVA     ****************************************************
ENV JAVA_8_HOME="/usr/lib/jvm/java-1.8.0-amazon-corretto.aarch64" \
    JDK_8_HOME="/usr/lib/jvm/java-1.8.0-amazon-corretto.aarch64" \
    JRE_8_HOME="/usr/lib/jvm/java-1.8.0-amazon-corretto.aarch64" \
    JAVA_11_HOME="/usr/lib/jvm/java-11-amazon-corretto.aarch64" \
    JDK_11_HOME="/usr/lib/jvm/java-11-amazon-corretto.aarch64" \
    JRE_11_HOME="/usr/lib/jvm/java-11-amazon-corretto.aarch64" \
    JAVA_17_HOME="/usr/lib/jvm/java-17-amazon-corretto.aarch64" \
    JDK_17_HOME="/usr/lib/jvm/java-17-amazon-corretto.aarch64" \
    JRE_17_HOME="/usr/lib/jvm/java-17-amazon-corretto.aarch64/jre" \
    JAVA_21_HOME="/usr/lib/jvm/java-21-amazon-corretto.aarch64" \
    JDK_21_HOME="/usr/lib/jvm/java-21-amazon-corretto.aarch64" \
    JRE_21_HOME="/usr/lib/jvm/java-21-amazon-corretto.aarch64" \
    JAVA_25_HOME="/usr/lib/jvm/java-25-amazon-corretto.aarch64" \
    JDK_25_HOME="/usr/lib/jvm/java-25-amazon-corretto.aarch64" \
    JRE_25_HOME="/usr/lib/jvm/java-25-amazon-corretto.aarch64" \
    ANT_VERSION=1.10.15 \
    MAVEN_HOME="/opt/maven" \
    MAVEN_VERSION=3.9.12 \
    INSTALLED_GRADLE_VERSIONS="8.14.4 9.4.0" \
    GRADLE_9_VERSION=9.4.0 \
    GRADLE_8_VERSION=8.14.4 \
    GRADLE_VERSION=9.4.0 \
    SBT_VERSION=1.12.5 \
    GRADLE_PATH="$SRC_DIR/gradle" \
    ANT_DOWNLOAD_SHA512="d78427aff207592c024ff1552dc04f7b57065a195c42d398fcffe7a0145e8d00cd46786f5aa52e77ab0fdf81334f065eb8011eecd2b48f7228e97ff4cb20d16c" \
    MAVEN_DOWNLOAD_SHA512="0a1be79f02466533fc1a80abbef8796e4f737c46c6574ede5658b110899942a94db634477dfd3745501c80aef9aac0d4f841d38574373f7e2d24cce89d694f70" \
    GRADLE_DOWNLOADS_SHA256="e571f9dc2cafeabaf6319756838042bb27c3c1aad307d41c1400cb12dec7b9e0 8.14.4\nb21468753cb43c167738ee04f10c706c46459cf8f8ae6ea132dc9ce589a261f2 9.4.0" \
    SBT_DOWNLOAD_SHA256="f213d84b2efd01cc6b52799a9c92984a0c5d5f072b5ea41722ab8f979f289be0"

ARG MAVEN_CONFIG_HOME="/root/.m2"
ENV JAVA_HOME="$JAVA_25_HOME" \
    JDK_HOME="$JAVA_25_HOME" \
    JRE_HOME="$JAVA_25_HOME"


RUN set -x \
    && rpm --import https://yum.corretto.aws/corretto.key \
    && curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo \
    # Install Amazon Corretto 17
    # Note: We will use update-alternatives to make sure JDK17 has higher priority for all the tools \
    && yum install -y -q java-25-amazon-corretto java-25-amazon-corretto-devel \
    && yum install -y -q java-21-amazon-corretto java-21-amazon-corretto-devel \
    && yum install -y -q java-17-amazon-corretto java-17-amazon-corretto-devel \
    && yum install -y -q java-11-amazon-corretto java-11-amazon-corretto-devel \
    && yum install -y -q java-1.8.0-amazon-corretto java-1.8.0-amazon-corretto-devel \
    && for tool_path in $JAVA_HOME/bin/*; do \
          tool=`basename $tool_path`; \
          update-alternatives --install /usr/bin/$tool $tool $tool_path 10000; \
          update-alternatives --set $tool $tool_path; \
        done \
     && rm $JAVA_HOME/lib/security/cacerts && ln -s /etc/pki/java/cacerts $JAVA_HOME/lib/security/cacerts \
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
    && tar xzvf /var/tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz -C $MAVEN_HOME --strip-components=1 \
    && rm /var/tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    && update-alternatives --install /usr/bin/mvn mvn /opt/maven/bin/mvn 10000 \
    && mkdir -p $MAVEN_CONFIG_HOME \
    # Install Gradle
    && mkdir -p $GRADLE_PATH \
    && for version in $INSTALLED_GRADLE_VERSIONS; do { \
       wget -q "https://services.gradle.org/distributions/gradle-$version-all.zip" -O "$GRADLE_PATH/gradle-$version-all.zip" \
       && unzip -q "$GRADLE_PATH/gradle-$version-all.zip" -d /usr/local \
       && echo -e "$GRADLE_DOWNLOADS_SHA256" | grep "$version" | sed "s|$version|$GRADLE_PATH/gradle-$version-all.zip|" | sha256sum -c - \
       && rm "$GRADLE_PATH/gradle-$version-all.zip" \
       && mkdir "/tmp/gradle-$version" \
       && "/usr/local/gradle-$version/bin/gradle" -p "/tmp/gradle-$version" init --overwrite \
       && "/usr/local/gradle-$version/bin/gradle" -p "/tmp/gradle-$version" wrapper \
       && perl -pi -e "s/gradle-$version-bin.zip/gradle-$version-all.zip/" "/tmp/gradle-$version/gradle/wrapper/gradle-wrapper.properties" \
       && "/tmp/gradle-$version/gradlew" -p "/tmp/gradle-$version" init --overwrite \
       && rm -rf "/tmp/gradle-$version"; \
     }; done \
    && ln -s /usr/local/gradle-$GRADLE_VERSION/bin/gradle /usr/bin/gradle \
    && rm -rf $GRADLE_PATH \
    # Install SBT
    && curl -fSL "https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.tgz" -o sbt.tgz \
    && echo "${SBT_DOWNLOAD_SHA256} *sbt.tgz" | sha256sum -c - \
    && tar xzf sbt.tgz -C /usr/local/bin/ \
    && rm sbt.tgz
ENV PATH="/usr/local/bin/sbt/bin:$PATH"

# Cleanup
RUN rm -fr /tmp/* /var/tmp/* \
     && yum clean all
#****************     END JAVA     ****************************************************

#****************     PowerShell     *******************************************************

# Install Powershell Core
ENV POWERSHELL_VERSION 7.5.4
ENV POWERSHELL_DOWNLOAD_URL https://github.com/PowerShell/PowerShell/releases/download/v$POWERSHELL_VERSION/powershell-$POWERSHELL_VERSION-linux-arm64.tar.gz
ENV POWERSHELL_DOWNLOAD_SHA 4B32D4CB86A43DFB83D5602D0294295BF22FAFBF9E0785D1AAEF81938CDA92F8

RUN set -ex \
    && curl -SL $POWERSHELL_DOWNLOAD_URL --output powershell.tar.gz \
    && echo "$POWERSHELL_DOWNLOAD_SHA powershell.tar.gz" | sha256sum -c - \
    && mkdir -p /opt/microsoft/powershell/$POWERSHELL_VERSION \
    && tar zxf powershell.tar.gz -C /opt/microsoft/powershell/$POWERSHELL_VERSION \
    && rm powershell.tar.gz \
    && ln -s /opt/microsoft/powershell/$POWERSHELL_VERSION/pwsh /usr/bin/pwsh
#****************     END Powershell     *******************************************************

#****************      NODEJS     ****************************************************

ENV NODE_24_VERSION="24.14.0"\
    NODE_22_VERSION="22.22.1"

RUN n $NODE_22_VERSION && npm install --save-dev -g -f grunt \
    && npm install --save-dev -g -f grunt-cli \
    && npm install --save-dev -g -f webpack \
    && npm install --save-dev -g -f yarn \
    && n $NODE_24_VERSION && npm install --save-dev -g -f grunt \
    && npm install --save-dev -g -f grunt-cli \
    && npm install --save-dev -g -f webpack \
    && npm install --save-dev -g -f yarn \
    && cd / && rm -rf $N_SRC_DIR \
    && rm -rf /tmp/* && rm -rf ~/.npm/_logs/

#****************      END NODEJS     ****************************************************

#**************** RUBY *********************************************************

ENV RUBY_VERSIONS="4.0.1 3.4.8 3.3.10 3.2.10" \
    RUBY_40_VERSION="4.0.1" \
    RUBY_34_VERSION="3.4.8" \
    RUBY_33_VERSION="3.3.10"

RUN for version in $RUBY_VERSIONS; do rbenv install $version; done \
    && rbenv global $RUBY_40_VERSION \
    && rm -rf /tmp/*

#**************** END RUBY *****************************************************

#**************** PYTHON *****************************************************
ENV PYTHON_314_VERSION="3.14.3" \
    PYTHON_313_VERSION="3.13.12" \
    PYTHON_312_VERSION="3.12.13" \
    PYTHON_311_VERSION="3.11.15" \
    PYTHON_310_VERSION="3.10.20" \
    PYTHON_PIP_VERSION="26.0.1" \
    PYYAML_VERSION="6.0.3" \
    PYTHON_SETUPTOOLS_VERSION="82.0.0" \
    PYTHON_CONFIGURE_OPTS="--enable-shared --enable-loadable-sqlite-extensions"


RUN set -ex \
    && for version in $PYTHON_314_VERSION $PYTHON_313_VERSION $PYTHON_312_VERSION $PYTHON_311_VERSION $PYTHON_310_VERSION; do \
        pyenv install $version \
        && pyenv global $version \
        && pip3 install --no-cache-dir --upgrade --force-reinstall "pip==$PYTHON_PIP_VERSION" \
        && pip3 install wheel \
        && pip3 install --no-cache-dir --upgrade "setuptools==$PYTHON_SETUPTOOLS_VERSION" boto3 pipenv virtualenv \
        && pip3 install --no-build-isolation "Cython<3" "PyYAML==$PYYAML_VERSION" \
        && pip3 uninstall cython --yes; \
    done \
    && rm -rf /tmp/*

#**************** END PYTHON *****************************************************

#****************      PHP     ****************************************************

# Installed in packages
ENV PHP_VERSIONS="8.5.3 8.4.18 8.3.30 8.2.30" \
    PHP_85_VERSION="8.5.3" \
    PHP_84_VERSION="8.4.18" \
    PHP_83_VERSION="8.3.30" \
    PHP_82_VERSION="8.2.30"

# Set environment variables for PHP configure options
ENV PHP_BUILD_CONFIGURE_OPTS="--with-curl --with-password-argon2 --with-pdo-pgsql --with-libedit"
# Set make arguments to use 4 parallel jobs.
ENV PHP_BUILD_EXTRA_MAKE_ARGUMENTS="-j4"

RUN phpenv update \
    && for version in $PHP_VERSIONS; do phpenv install $version; done \
    && phpenv global $PHP_85_VERSION \
    && for version in $PHP_VERSIONS; do echo "memory_limit = 1G;" >> "/root/.phpenv/versions/$version/etc/conf.d/memory.ini"; done \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
    && rm -rf /tmp/*
#****************      END PHP     ****************************************************

#****************     GOLANG     ****************************************************
ENV GOLANG_VERSIONS="1.24.13 1.25.8 1.26.1" \
    GOLANG_26_VERSION="1.26.1" \
    GOLANG_25_VERSION="1.25.8" \
    GOLANG_24_VERSION="1.24.13"

RUN for version in $GOLANG_VERSIONS; do goenv install $version; done && rm -rf /tmp/*

#****************      END GOLANG     ****************************************************

#****************     RUST     ****************************************************
ENV RUST_94_VERSION="1.94.0"

RUN rustup install $RUST_94_VERSION && rm -rf /tmp/*
RUN rustc --version

#****************      END RUST     ****************************************************

#=======================End of layer: runtimes_1  =================
FROM runtimes_1 AS runtimes_2

#Docker 2.17
ENV DOCKER_BUCKET="download.docker.com" \
    DOCKER_CHANNEL="stable" \
    DIND_COMMIT="3b5fac462d21ca164b3778647420016315289034"

ENV DOCKER_SHA256="9e4f82996ab790724094475ebed33a736434bfe5d45231b676fef22ffb80044d"
ENV DOCKER_VERSION="28.5.2"
ENV DOCKER_COMPOSE_VERSION="5.1.0"
ARG DOCKER_BUILDX_VERSION="0.32.1"

VOLUME /var/lib/docker

# Install Docker
RUN set -ex \
    && curl -fSL "https://${DOCKER_BUCKET}/linux/static/${DOCKER_CHANNEL}/aarch64/docker-${DOCKER_VERSION}.tgz" -o docker.tgz \
    && echo "${DOCKER_SHA256} *docker.tgz" | sha256sum -c - \
    && tar --extract --file docker.tgz --strip-components 1  --directory /usr/local/bin \
    && rm docker.tgz \
    # replace runc package to resolve CVE-2024-21626
    && rm /usr/local/bin/runc \
    && ln -s /usr/sbin/runc /usr/local/bin/runc \
    && runc -v \
    && docker -v \
    # set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
    && groupadd dockremap \
    && useradd -g dockremap dockremap \
    && echo 'dockremap:165536:65536' >> /etc/subuid \
    && echo 'dockremap:165536:65536' >> /etc/subgid \
    && wget -q "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind" -O /usr/local/bin/dind \
    # Install docker compose as docker plugin and maintain docker-compose usage
    && mkdir -p /usr/local/lib/docker/cli-plugins \
    && curl -L https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-Linux-aarch64 -o /usr/local/lib/docker/cli-plugins/docker-compose \
    && chmod +x /usr/local/bin/dind /usr/local/lib/docker/cli-plugins/docker-compose \
    && ln -s /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose \
    # Ensure docker-compose and docker compose work
    && docker-compose version \
    && docker compose version \
    # Add docker buildx tool
    && curl -L https://github.com/docker/buildx/releases/download/v${DOCKER_BUILDX_VERSION}/buildx-v${DOCKER_BUILDX_VERSION}.linux-arm64 -o /usr/local/lib/docker/cli-plugins/docker-buildx \
    && chmod +x /usr/local/lib/docker/cli-plugins/docker-buildx \
    && ln -s /usr/local/lib/docker/cli-plugins/docker-buildx /usr/local/bin/docker-buildx \
    # Ensure docker-buildx works
    && docker-buildx version \
    && docker buildx version

# Install Finch
RUN dnf install -y runfinch-finch \
    && finch --version

#=======================End of layer: runtimes_2  =================
FROM runtimes_2 AS runtimes_3

#DotNet
ENV DOTNET_10_SDK_VERSION="10.0.103" \
    DOTNET_8_SDK_VERSION="8.0.418" \
    DOTNET_8_GLOBAL_JSON_SDK_VERSION="8.0.0" \
    DOTNET_10_GLOBAL_JSON_SDK_VERSION="10.0.0"
ENV DOTNET_ROOT="/root/.dotnet"

# Add .NET Core 10 Global Tools install folder to PATH
RUN /usr/local/bin/dotnet-install.sh -v $DOTNET_10_SDK_VERSION \
    && dotnet --list-sdks \
    && rm -rf /tmp/*

# Add .NET Core 8 Global Tools install folder to PATH
RUN /usr/local/bin/dotnet-install.sh -v $DOTNET_8_SDK_VERSION \
    && dotnet --list-sdks \
    && rm -rf /tmp/*

## Trigger the population of the local package cache
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT true
ENV NUGET_XMLDOC_MODE skip
RUN set -ex \
    && mkdir warmup \
    && cd warmup \
    && dotnet new \
    && cd .. \
    && rm -rf warmup \
    && rm -rf /tmp/NuGetScratch

# Install GitVersion
ENV GITVERSION_VERSION="6.6.0"
RUN set -ex \
    && dotnet tool install --global GitVersion.Tool --version $GITVERSION_VERSION \
    && ln -s ~/.dotnet/tools/dotnet-gitversion /usr/local/bin/gitversion \
    && rm -rf /tmp/*
#****************      END DotNet     ****************************************************

#===================END of runtimes_3 ==============
FROM runtimes_3 AS aarch64_v3

# Activate runtime versions specific to image version.
RUN n --preserve $NODE_24_VERSION
RUN pyenv global $PYTHON_314_VERSION
RUN phpenv global $PHP_85_VERSION
RUN rbenv global $RUBY_40_VERSION
RUN goenv global $GOLANG_26_VERSION
RUN rustup default $RUST_94_VERSION
RUN dotnet new globaljson --force --sdk-version $DOTNET_10_GLOBAL_JSON_SDK_VERSION --roll-forward latestFeature

# Configure SSH
COPY ssh_config /root/.ssh/config
COPY runtimes.yml /codebuild/image/config/runtimes.yml
COPY dockerd-entrypoint.sh /usr/local/bin/
COPY legal/THIRD_PARTY_LICENSES.txt /usr/share/doc
COPY legal/bill_of_material.txt /usr/share/doc
COPY amazon-ssm-agent.json /etc/amazon/ssm/

ENTRYPOINT ["dockerd-entrypoint.sh"]
#=======================End of layer: aarch64_v3  =================