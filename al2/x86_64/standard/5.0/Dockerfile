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

FROM public.ecr.aws/amazonlinux/amazonlinux:2023 AS core

# Install git, SSH, and other utilities
RUN set -ex \
    && yum install -y -q openssh-clients \
    && mkdir ~/.ssh \
    && mkdir -p /opt/tools \
    && mkdir -p /codebuild/image/config \
    && touch ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa,ed25519,ecdsa -H github.com >> ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa,ed25519,ecdsa -H bitbucket.org >> ~/.ssh/known_hosts \
    && chmod 600 ~/.ssh/known_hosts \
    && rpm --import https://download.mono-project.com/repo/xamarin.gpg \
    && curl https://download.mono-project.com/repo/centos7-stable.repo | tee /etc/yum.repos.d/mono-centos7-stable.repo \
    && yum groupinstall -y -q "Development tools" \
    && yum install -y -q \
           ImageMagick asciidoc bzip2-devel cvs cvsps \
           docbook-dtds docbook-style-xsl e2fsprogs expat-devel expect fakeroot \
           glib2-devel groff gzip icu iptables jq krb5-server libargon2-devel \
           libcurl-devel libdb-devel libedit-devel libevent-devel libffi-devel \
           libicu-devel libjpeg-devel libpng-devel libserf sqlite-devel \
           libtidy-devel libunwind libwebp-devel libxml2-devel libxslt libxslt-devel \
           libyaml-devel libzip-devel mariadb105-devel mercurial mlocate \
           ncurses-devel oniguruma-devel openssl openssl-devel perl-DBD-SQLite \
           perl-DBI perl-HTTP-Date perl-TimeDate perl-YAML-LibYAML \
           postgresql-devel procps-ng python-configobj readline-devel rsync sgml-common \
           subversion-perl tar tcl tk vim wget which xfsprogs xmlto xorg-x11-server-Xvfb xz-devel \
           amazon-ecr-credential-helper \
    && rm /etc/yum.repos.d/mono-centos7-stable.repo

RUN useradd codebuild-user

#=======================End of layer: core  =================

FROM core AS tools

# Install Git
RUN set -ex \
   && GIT_VERSION=2.40.0 \
   && GIT_TAR_FILE=git-$GIT_VERSION.tar.gz \
   && GIT_SRC=https://github.com/git/git/archive/v${GIT_VERSION}.tar.gz  \
   && curl -L -o $GIT_TAR_FILE $GIT_SRC \
   && tar zxf $GIT_TAR_FILE \
   && cd git-$GIT_VERSION \
   && make -j4 prefix=/usr \
   && make install prefix=/usr \
   && cd .. && rm -rf git-$GIT_VERSION \
   && rm -rf $GIT_TAR_FILE /tmp/*

# Install stunnel
RUN set -ex \
   && STUNNEL_VERSION=5.69 \
   && STUNNEL_TAR=stunnel-$STUNNEL_VERSION.tar.gz \
   && STUNNEL_SHA256="1ff7d9f30884c75b98c8a0a4e1534fa79adcada2322635e6787337b4e38fdb81" \
   && curl -o $STUNNEL_TAR https://www.usenix.org.uk/mirrors/stunnel/archive/5.x/$STUNNEL_TAR && echo "$STUNNEL_SHA256 $STUNNEL_TAR" | sha256sum --check && tar xfz $STUNNEL_TAR \
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
RUN curl -sS -o /usr/local/bin/aws-iam-authenticator https://s3.us-west-2.amazonaws.com/amazon-eks/1.26.2/2023-03-17/bin/linux/amd64/aws-iam-authenticator \
    && curl -sS -o /usr/local/bin/kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.26.2/2023-03-17/bin/linux/amd64/kubectl \
    && curl -sS -o /usr/local/bin/ecs-cli https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest \
    && curl -sS -L https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz | tar xz -C /usr/local/bin \
    && chmod +x /usr/local/bin/kubectl /usr/local/bin/aws-iam-authenticator /usr/local/bin/ecs-cli /usr/local/bin/eksctl

# Configure SSM
RUN set -ex \
    && yum install -y -q https://s3.amazonaws.com/amazon-ssm-us-east-1/latest/linux_amd64/amazon-ssm-agent.rpm

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
RUN curl https://pyenv.run | bash
ENV PATH="/root/.pyenv/shims:/root/.pyenv/bin:$PATH"

##php
RUN curl -L https://raw.githubusercontent.com/phpenv/phpenv-installer/master/bin/phpenv-installer | bash
ENV PATH="/root/.phpenv/shims:/root/.phpenv/bin:$PATH"

##go
RUN git clone https://github.com/syndbg/goenv.git $HOME/.goenv
ENV PATH="/root/.goenv/shims:/root/.goenv/bin:/go/bin:$PATH"
ENV GOENV_DISABLE_GOPATH=1
ENV GOPATH="/go"

#=======================End of layer: tools  =================

FROM tools AS runtimes_1

#****************      JAVA     ****************************************************

ENV JAVA_17_HOME="/usr/lib/jvm/java-17-amazon-corretto.x86_64" \
    JDK_17_HOME="/usr/lib/jvm/java-17-amazon-corretto.x86_64" \
    JRE_17_HOME="/usr/lib/jvm/java-17-amazon-corretto.x86_64" \
    ANT_VERSION=1.10.13 \
    MAVEN_HOME="/opt/maven" \
    MAVEN_VERSION=3.9.1 \
    GRADLE_VERSION=8.1.1 \
    SBT_VERSION=1.8.2 \
    GRADLE_PATH="$SRC_DIR/gradle" \
    ANT_DOWNLOAD_SHA512="de4ac604629e39a86a306f0541adb3775596909ad92feb8b7de759b1b286417db24f557228737c8b902d6abf722d2ce5bb0c3baa3640cbeec3481e15ab1958c9" \
    MAVEN_DOWNLOAD_SHA512="d3be5956712d1c2cf7a6e4c3a2db1841aa971c6097c7a67f59493a5873ccf8c8b889cf988e4e9801390a2b1ae5a0669de07673acb090a083232dbd3faf82f3e3" \
    GRADLE_DOWNLOADS_SHA256="5625a0ae20fe000d9225d000b36909c7a0e0e8dda61c19b12da769add847c975 8.1.1" \
    SBT_DOWNLOAD_SHA256="1f65344da074dbd66dfefa93c0eff8d319d772e5cad47fcbeb6ae178bbdf4686"

ARG MAVEN_CONFIG_HOME="/root/.m2"
ENV JAVA_HOME="$JAVA_17_HOME" \
    JDK_HOME="$JDK_17_HOME" \
    JRE_HOME="$JRE_17_HOME"

RUN set -x \
    # Install Amazon Corretto 17
    && rpm --import https://yum.corretto.aws/corretto.key \
    && curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo \
    && yum install -y -q java-17-amazon-corretto java-17-amazon-corretto-devel \
    && update-ca-trust \
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
    && tar xzf /var/tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz -C $MAVEN_HOME --strip-components=1 \
    && rm /var/tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    && update-alternatives --install /usr/bin/mvn mvn /opt/maven/bin/mvn 10000 \
    && mkdir -p $MAVEN_CONFIG_HOME \
    # Install Gradle
    && mkdir -p $GRADLE_PATH \
    && wget -q "https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-all.zip" -O "$GRADLE_PATH/gradle-$GRADLE_VERSION-all.zip" \
    && unzip -q "$GRADLE_PATH/gradle-$GRADLE_VERSION-all.zip" -d /usr/local \
    && echo -e "$GRADLE_DOWNLOADS_SHA256" | grep "$GRADLE_VERSION" | sed "s|$GRADLE_VERSION|$GRADLE_PATH/gradle-$GRADLE_VERSION-all.zip|" | sha256sum -c - \
    && rm "$GRADLE_PATH/gradle-$GRADLE_VERSION-all.zip" \
    && mkdir "/tmp/gradle-$GRADLE_VERSION" \
    && "/usr/local/gradle-$GRADLE_VERSION/bin/gradle" -p "/tmp/gradle-$GRADLE_VERSION" init \
    && "/usr/local/gradle-$GRADLE_VERSION/bin/gradle" -p "/tmp/gradle-$GRADLE_VERSION" wrapper \
    # Android Studio uses the "-all" distribution for it's wrapper script.
    && perl -pi -e "s/gradle-$GRADLE_VERSION-bin.zip/gradle-$GRADLE_VERSION-all.zip/" "/tmp/gradle-$GRADLE_VERSION/gradle/wrapper/gradle-wrapper.properties" \
    && "/tmp/gradle-$GRADLE_VERSION/gradlew" -p "/tmp/gradle-$GRADLE_VERSION" init \
    && rm -rf "/tmp/gradle-$GRADLE_VERSION" \
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
RUN rm -fr /tmp/* /var/tmp/*
#****************     END JAVA     ****************************************************


#****************     PowerShell     *******************************************************

# Install Powershell Core
# See instructions at https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-powershell-core-on-linux
ENV POWERSHELL_VERSION 7.3.4
ENV POWERSHELL_DOWNLOAD_URL https://github.com/PowerShell/PowerShell/releases/download/v$POWERSHELL_VERSION/powershell-$POWERSHELL_VERSION-linux-x64.tar.gz
ENV POWERSHELL_DOWNLOAD_SHA E85D5544E13A924F8B2C4A5DC2D43ABE46E46633F89E8D138D39C0AAEACB9976

RUN set -ex \
    && curl -SL $POWERSHELL_DOWNLOAD_URL --output powershell.tar.gz \
    && echo "$POWERSHELL_DOWNLOAD_SHA powershell.tar.gz" | sha256sum -c - \
    && mkdir -p /opt/microsoft/powershell/$POWERSHELL_VERSION \
    && tar zxf powershell.tar.gz -C /opt/microsoft/powershell/$POWERSHELL_VERSION \
    && rm powershell.tar.gz \
    && ln -s /opt/microsoft/powershell/$POWERSHELL_VERSION/pwsh /usr/bin/pwsh

# Install AWS CLI v2
# https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html
RUN curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /opt \
    && /opt/aws/install --update -i /usr/local/aws-cli -b /usr/local/bin \
    && rm /tmp/awscliv2.zip \
    && rm -rf /opt/aws \
    && aws --version

#DotNet 6.0
ENV DOTNET_60_SDK_VERSION="6.0.408"
ENV DOTNET_ROOT="/root/.dotnet"

# Add .NET Core 6.0 Global Tools install folder to PATH
RUN /usr/local/bin/dotnet-install.sh -v $DOTNET_60_SDK_VERSION \
    && dotnet --list-sdks \
    && rm -rf /tmp/*

## Trigger the population of the local package cache
ENV NUGET_XMLDOC_MODE skip
RUN set -ex \
    && mkdir warmup \
    && cd warmup \
    && dotnet new \
    && cd .. \
    && rm -rf warmup \
    && rm -rf /tmp/NuGetScratch
#****************     END Powershell     *******************************************************


#****************      NODEJS     ****************************************************

ENV NODE_18_VERSION="18.16.0"

RUN  n $NODE_18_VERSION && npm install --save-dev -g -f grunt && npm install --save-dev -g -f grunt-cli && npm install --save-dev -g -f webpack \
     && cd / && rm -rf $N_SRC_DIR && rm -rf /tmp/*

#****************      END NODEJS     ****************************************************

#**************** RUBY *********************************************************

ENV RUBY_32_VERSION="3.2.2"

RUN rbenv install $RUBY_32_VERSION && rm -rf /tmp/* && rbenv global $RUBY_32_VERSION && ruby -v

#**************** END RUBY *****************************************************

#**************** PYTHON *****************************************************
#Python 3.11
ENV PYTHON_311_VERSION="3.11.2"
ENV PYTHON_PIP_VERSION=23.1.1
ENV PYYAML_VERSION=6.0

COPY tools/runtime_configs/python/$PYTHON_311_VERSION /root/.pyenv/plugins/python-build/share/python-build/$PYTHON_311_VERSION
RUN   env PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install $PYTHON_311_VERSION && rm -rf /tmp/*
RUN   pyenv global  $PYTHON_311_VERSION
RUN set -ex \
    && pip3 install --no-cache-dir --upgrade --force-reinstall "pip==$PYTHON_PIP_VERSION" \
    && pip3 install --no-cache-dir --upgrade 'setuptools==67.7.2' wheel aws-sam-cli boto3 pipenv virtualenv \
    && pip3 install --no-cache-dir --upgrade "PyYAML==$PYYAML_VERSION"

#**************** END PYTHON *****************************************************

#****************      PHP     ****************************************************
ENV PHP_82_VERSION="8.2.5"

COPY tools/runtime_configs/php/$PHP_82_VERSION /root/.phpenv/plugins/php-build/share/php-build/definitions/$PHP_82_VERSION
RUN phpenv install $PHP_82_VERSION && rm -rf /tmp/* && phpenv global $PHP_82_VERSION
RUN echo "memory_limit = 1G;" >> "/root/.phpenv/versions/$PHP_82_VERSION/etc/conf.d/memory.ini"

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer
#****************      END PHP     ****************************************************

#****************     GOLANG     ****************************************************
ENV GOLANG_20_VERSION="1.20.3"
ENV GOENV_DISABLE_GOPATH=1
ENV GOPATH="/go"

RUN goenv install $GOLANG_20_VERSION && rm -rf /tmp/* && \
    goenv global $GOLANG_20_VERSION && \
    go env -w GO111MODULE=auto

RUN go get -u github.com/golang/dep/cmd/dep
#****************      END GOLANG     ****************************************************

#=======================End of layer: runtimes_1  =================
FROM runtimes_1 AS runtimes_2

#Docker 23
ENV DOCKER_BUCKET="download.docker.com" \
    DOCKER_CHANNEL="stable" \
    DIND_COMMIT="3b5fac462d21ca164b3778647420016315289034" \
    DOCKER_COMPOSE_VERSION="2.17.3" \
    DOCKER_BUILDX_VERSION="0.10.4"

ENV DOCKER_SHA256="81BD643A32B3428F6D9EAFBD9331D0DA1577C958C1C2702DB1EFF7AFA1CDF3CD"
ENV DOCKER_VERSION="23.0.4"

VOLUME /var/lib/docker

RUN set -ex \
    && curl -fSL "https://${DOCKER_BUCKET}/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz" -o docker.tgz \
    && echo "${DOCKER_SHA256} *docker.tgz" | sha256sum -c - \
    && tar --extract --file docker.tgz --strip-components 1  --directory /usr/local/bin/ \
    && rm docker.tgz \
    && docker -v \
    # set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
    && groupadd dockremap \
    && useradd -g dockremap dockremap \
    && echo 'dockremap:165536:65536' >> /etc/subuid \
    && echo 'dockremap:165536:65536' >> /etc/subgid \
    && wget -q "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind" -O /usr/local/bin/dind \
    # Install docker compose as docker plugin and maintain docker-compose usage
    && mkdir -p /usr/local/lib/docker/cli-plugins \
    && curl -L https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-Linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose \
    && chmod +x /usr/local/lib/docker/cli-plugins/docker-compose \
    && ln -s /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose \
    # Ensure docker-compose and docker compose work
    && docker-compose version \
    && docker compose version \
    # Add docker buildx tool
    && curl -L https://github.com/docker/buildx/releases/download/v${DOCKER_BUILDX_VERSION}/buildx-v${DOCKER_BUILDX_VERSION}.linux-amd64 -o /usr/local/bin/docker-buildx \
    && chmod +x /usr/local/bin/dind /usr/local/bin/docker-buildx \
    # Ensure docker-buildx works
    && docker-buildx version

#=======================End of layer: runtimes_2  =================
FROM runtimes_2 AS runtimes_3

# Install GitVersion
ENV GITVERSION_VERSION="5.12.0"
RUN set -ex \
    && dotnet tool install --global GitVersion.Tool --version $GITVERSION_VERSION \
    && ln -s ~/.dotnet/tools/dotnet-gitversion /usr/local/bin/gitversion

#===================END of runtimes_3 ==============
FROM runtimes_3 AS al2_v5

# Configure SSH
COPY ssh_config /root/.ssh/config
COPY runtimes.yml /codebuild/image/config/runtimes.yml
COPY dockerd-entrypoint.sh /usr/local/bin/dockerd-entrypoint.sh
COPY legal/THIRD_PARTY_LICENSES.txt /usr/share/doc/THIRD_PARTY_LICENSES.txt
COPY legal/bill_of_material.txt /usr/share/doc/bill_of_material.txt
COPY amazon-ssm-agent.json /etc/amazon/ssm/amazon-ssm-agent.json

ENTRYPOINT ["/usr/local/bin/dockerd-entrypoint.sh"]


#=======================End of layer: al2_v5  =================
