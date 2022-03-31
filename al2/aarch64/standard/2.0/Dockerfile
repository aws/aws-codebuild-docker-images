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

FROM public.ecr.aws/amazonlinux/amazonlinux:2 AS core

ENV EPEL_REPO="https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"

# Install git, SSH, and other utilities
RUN set -ex \
    && yum install -yq openssh-clients \
    && mkdir ~/.ssh \
    && touch ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa -H github.com >> ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa -H bitbucket.org >> ~/.ssh/known_hosts \
    && chmod 600 ~/.ssh/known_hosts \
    && yum install -yq $EPEL_REPO \
    && rpm --import https://download.mono-project.com/repo/xamarin.gpg \
    && curl https://download.mono-project.com/repo/centos7-stable.repo | tee /etc/yum.repos.d/mono-centos7-stable.repo \
    && amazon-linux-extras enable corretto8 \
    && amazon-linux-extras enable docker \
    && yum groupinstall -yq "Development tools" \
    && yum install -yq \
           GeoIP-devel ImageMagick asciidoc bzip2-devel bzr bzrtools cvs cvsps \
           docbook-dtds docbook-style-xsl dpkg-dev e2fsprogs expat-devel expect fakeroot \
           glib2-devel groff gzip icu iptables jq krb5-server libargon2-devel \
           libcurl-devel libdb-devel libedit-devel libevent-devel libffi-devel \
           libicu-devel libjpeg-devel libpng-devel libserf libsqlite3x-devel \
           libtidy-devel libunwind libwebp-devel libxml2-devel libxslt libxslt-devel \
           libyaml-devel libzip-devel mariadb-devel mlocate \
           ncurses-devel oniguruma-devel openssl openssl-devel perl-DBD-SQLite \
           perl-DBI perl-HTTP-Date perl-IO-Pty-Easy perl-TimeDate perl-YAML-LibYAML \
           postgresql-devel procps-ng python-configobj readline-devel rsync sgml-common \
           subversion-perl tar tcl tk vim wget which xfsprogs xmlto xorg-x11-server-Xvfb xz-devel \
           amazon-ecr-credential-helper

RUN useradd codebuild-user

#=======================End of layer: core  =================

FROM core AS tools

# Install Git
RUN set -ex \
   && GIT_VERSION=2.27.0 \
   && GIT_TAR_FILE=git-$GIT_VERSION.tar.gz \
   && GIT_SRC=https://github.com/git/git/archive/v${GIT_VERSION}.tar.gz  \
   && curl -L -o $GIT_TAR_FILE $GIT_SRC \
   && tar zxf $GIT_TAR_FILE \
   && cd git-$GIT_VERSION \
   && make -j4 prefix=/usr \
   && make install prefix=/usr \
   && cd .. ; rm -rf git-$GIT_VERSION \
   && rm -rf $GIT_TAR_FILE /tmp/*

# Install stunnel
RUN set -ex \
   && STUNNEL_VERSION=5.56 \
   && STUNNEL_TAR=stunnel-$STUNNEL_VERSION.tar.gz \
   && STUNNEL_SHA256="7384bfb356b9a89ddfee70b5ca494d187605bb516b4fff597e167f97e2236b22" \
   && curl -o $STUNNEL_TAR https://www.usenix.org.uk/mirrors/stunnel/archive/5.x/$STUNNEL_TAR \
   && echo "$STUNNEL_SHA256 $STUNNEL_TAR" | sha256sum -c - \
   && tar xvfz $STUNNEL_TAR \
   && cd stunnel-$STUNNEL_VERSION \
   && ./configure \
   && make -j4 \
   && make install \
   && openssl genrsa -out key.pem 2048 \
   && openssl req -new -x509 -key key.pem -out cert.pem -days 1095 -subj "/C=US/ST=Washington/L=Seattle/O=Amazon/OU=Codebuild/CN=codebuild.amazon.com" \
   && cat key.pem cert.pem >> /usr/local/etc/stunnel/stunnel.pem \
   && cd .. ; rm -rf stunnel-${STUNNEL_VERSION}*

# AWS Tools
# https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html
RUN curl -sS -o /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.16.8/2020-04-16/bin/linux/arm64/aws-iam-authenticator \
    && curl -sS -o /usr/local/bin/kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.16.8/2020-04-16/bin/linux/arm64/kubectl \
    && curl -sS -o /usr/local/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-arm64-latest \
    && chmod +x /usr/local/bin/kubectl /usr/local/bin/aws-iam-authenticator /usr/local/bin/ecs-cli

# Configure SSM
RUN set -ex \
    && yum install -yq https://s3.amazonaws.com/amazon-ssm-us-east-1/3.0.1390.0/linux_arm64/amazon-ssm-agent.rpm

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

#=======================End of layer: tools  =================

FROM tools AS runtimes_1

#****************      JAVA     ****************************************************
ENV JAVA_11_HOME="/usr/lib/jvm/java-11-amazon-corretto.aarch64" \
    JDK_11_HOME="/usr/lib/jvm/java-11-amazon-corretto.aarch64" \
    JRE_11_HOME="/usr/lib/jvm/java-11-amazon-corretto.aarch64" \
    JAVA_8_HOME="/usr/lib/jvm/java-1.8.0-amazon-corretto.aarch64" \
    JDK_8_HOME="/usr/lib/jvm/java-1.8.0-amazon-corretto.aarch64" \
    JRE_8_HOME="/usr/lib/jvm/java-1.8.0-amazon-corretto.aarch64/jre" \
    ANT_VERSION=1.10.8 \
    MAVEN_HOME="/opt/maven" \
    MAVEN_VERSION=3.6.3 \
    INSTALLED_GRADLE_VERSIONS="5.6.4 6.5" \
    GRADLE_VERSION=6.5 \
    SBT_VERSION=1.3.13 \
    GRADLE_PATH="$SRC_DIR/gradle" \
    ANT_DOWNLOAD_SHA512="4d80dc6ba23eeec7769085ddb00261b7480b596b56c6e69aa221391acbfb7338eb5855179c88222c8021095ef1f64f43caf2b4f90e8305d7c3128026d4258d06" \
    MAVEN_DOWNLOAD_SHA512="c35a1803a6e70a126e80b2b3ae33eed961f83ed74d18fcd16909b2d44d7dada3203f1ffe726c17ef8dcca2dcaa9fca676987befeadc9b9f759967a8cb77181c0" \
    GRADLE_DOWNLOADS_SHA256="c9910513d0eed63cd8f5c7fec4cb4a05731144770104a0871234a4edc3ba3cef 6.5\nabc10bcedb58806e8654210f96031db541bcd2d6fc3161e81cb0572d6a15e821 5.6.4" \
    SBT_DOWNLOAD_SHA256="854154de27a7d8c13b5a0f9a297cd1f254cc13b44588dae507e5d4fb2741bd22"

ARG MAVEN_CONFIG_HOME="/root/.m2"
ENV JAVA_HOME="$JAVA_11_HOME" \
    JDK_HOME="$JDK_11_HOME" \
    JRE_HOME="$JRE_11_HOME"

RUN set -ex \
    # Install Amazon Corretto 8
    && yum install -yq java-1.8.0-amazon-corretto-devel \
    # Ensure Java cacerts symlink points to valid location
    && update-ca-trust

RUN set -x \
    # Install Amazon Corretto 11
    # Note: We will use update-alternatives to make sure JDK11 has higher priority for all the tools
    && yum install -yq java-11-amazon-corretto \
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
    && curl -LSso /var/tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz https://apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz \
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
       && "/usr/local/gradle-$version/bin/gradle" -p "/tmp/gradle-$version" wrapper \
       && perl -pi -e "s/gradle-$version-bin.zip/gradle-$version-all.zip/" "/tmp/gradle-$version/gradle/wrapper/gradle-wrapper.properties" \
       && "/tmp/gradle-$version/gradlew" -p "/tmp/gradle-$version" init \
       && rm -rf "/tmp/gradle-$version" \
       && if [ "$version" != "$GRADLE_VERSION" ]; then rm -rf "/usr/local/gradle-$version"; fi; \
     }; done \
    # Install default GRADLE_VERSION to path
    && ln -s /usr/local/gradle-$GRADLE_VERSION/bin/gradle /usr/bin/gradle \
    && rm -rf $GRADLE_PATH \
    # Install SBT
    && curl -fSL "https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.tgz" -o sbt.tgz \
    && echo "${SBT_DOWNLOAD_SHA256} *sbt.tgz" | sha256sum -c - \
    && tar xzf sbt.tgz -C /usr/local/bin/ \
    && rm sbt.tgz
ENV PATH "/usr/local/bin/sbt/bin:$PATH"
RUN sbt version
# Cleanup
RUN rm -fr /tmp/* /var/tmp/* \
    && yum clean all
#****************     END JAVA     ****************************************************


#****************     PowerShell     *******************************************************

# Install Powershell Core
ENV POWERSHELL_VERSION 7.0.2
ENV POWERSHELL_DOWNLOAD_URL https://github.com/PowerShell/PowerShell/releases/download/v$POWERSHELL_VERSION/powershell-$POWERSHELL_VERSION-linux-arm64.tar.gz
ENV POWERSHELL_DOWNLOAD_SHA 8677301996b5335b872d267d41f588c145eeffa6b9736962530480b4d15cc295

RUN set -ex \
    && curl -SL $POWERSHELL_DOWNLOAD_URL --output powershell.tar.gz \
    && echo "$POWERSHELL_DOWNLOAD_SHA powershell.tar.gz" | sha256sum -c - \
    && mkdir -p /opt/microsoft/powershell/$POWERSHELL_VERSION \
    && tar zxf powershell.tar.gz -C /opt/microsoft/powershell/$POWERSHELL_VERSION \
    && rm powershell.tar.gz \
    && ln -s /opt/microsoft/powershell/$POWERSHELL_VERSION/pwsh /usr/bin/pwsh
#****************     END Powershell     *******************************************************



#****************      NODEJS     ****************************************************

ENV NODE_10_VERSION="10.24.1"

RUN  n $NODE_10_VERSION && npm install --save-dev -g -f grunt && npm install --save-dev -g -f grunt-cli && npm install --save-dev -g -f webpack \
     && curl -sSL https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo \
     && rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg \
     && yum install -yq yarn \
     && yarn --version \
     && cd / && rm -rf $N_SRC_DIR; rm -rf /tmp/*

#****************      END NODEJS     ****************************************************

#**************** RUBY *********************************************************

ENV RUBY_26_VERSION="2.6.6"

RUN rbenv install $RUBY_26_VERSION; rm -rf /tmp/*; rbenv global $RUBY_26_VERSION;ruby -v

#**************** END RUBY *****************************************************

#**************** PYTHON *****************************************************
ENV PYTHON_37_VERSION="3.7.10"
ENV PYTHON_PIP_VERSION=21.1.2
ENV PYYAML_VERSION=5.4.1
ENV DOCKER_COMPOSE_VERSION="1.26.0"

COPY tools/runtime_configs/python/$PYTHON_37_VERSION /root/.pyenv/plugins/python-build/share/python-build/$PYTHON_37_VERSION
RUN   env PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install $PYTHON_37_VERSION; rm -rf /tmp/*
RUN   pyenv global  $PYTHON_37_VERSION
RUN set -ex \
    && pip3 install --no-cache-dir --upgrade --force-reinstall "pip==$PYTHON_PIP_VERSION" \
    && pip3 install --no-cache-dir --upgrade "PyYAML==$PYYAML_VERSION" \
    && pip3 install --no-cache-dir --upgrade 'setuptools==57.4.0' wheel aws-sam-cli awscli boto3 pipenv virtualenv \
    && pip3 install --no-cache-dir "docker-compose==$DOCKER_COMPOSE_VERSION" \
    && docker-compose version

#**************** END PYTHON *****************************************************

#****************      PHP     ****************************************************
ENV PHP_73_VERSION="7.3.19"

COPY tools/runtime_configs/php/$PHP_73_VERSION /root/.phpenv/plugins/php-build/share/php-build/definitions/$PHP_73_VERSION
RUN phpenv install $PHP_73_VERSION; rm -rf /tmp/*; phpenv global $PHP_73_VERSION
RUN echo "memory_limit = 1G;" >> "/root/.phpenv/versions/$PHP_73_VERSION/etc/conf.d/memory.ini"

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer
#****************      END PHP     ****************************************************

#****************     GOLANG     ****************************************************
ENV GOPATH="/go" \
    DEP_VERSION="0.5.4" \
    DEP_BINARY="dep-linux-arm64"

ENV GOLANG_14_VERSION="1.14.7"
ENV GOLANG_14_DOWNLOAD_SHA256="fe5b6f6e441f3cb7b53ebf1a010bbebcb720ac98124984cfe2e51d72b8a58c71"

RUN set -ex \
    && mkdir -p "$GOPATH/src" "$GOPATH/bin" \
    && chmod -R 777 "$GOPATH" \
    && wget -q "https://dl.google.com/go/go$GOLANG_14_VERSION.linux-arm64.tar.gz" -O /tmp/golang.tar.gz \
    && echo "$GOLANG_14_DOWNLOAD_SHA256 /tmp/golang.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/golang.tar.gz -C /tmp \
    && mv /tmp/go /usr/local/go14  \
    && rm -fr /tmp/* /var/tmp/* \
    && wget -q "https://github.com/golang/dep/releases/download/v$DEP_VERSION/$DEP_BINARY" -O "$GOPATH/bin/dep" \
    && chmod +x "$GOPATH/bin/dep"

RUN ln -s /usr/local/go14 /usr/local/go
ENV PATH="$GOPATH/bin:/usr/local/go/bin:$PATH"

#****************     GO 1.13   **********************************************************

ENV GOLANG_13_VERSION="1.13.15"
ENV GOLANG_13_DOWNLOAD_SHA256="a5c59e3f0aeaf6e939790152a8bfabb91d70c9787afb7aee06aef9bd4411c551"

RUN set -ex \
    && wget -q "https://dl.google.com/go/go$GOLANG_13_VERSION.linux-arm64.tar.gz" -O /tmp/golang.tar.gz \
    && echo "$GOLANG_13_DOWNLOAD_SHA256 /tmp/golang.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/golang.tar.gz -C /tmp \
    && mv /tmp/go /usr/local/go13  \
    && rm -fr /tmp/* /var/tmp/*

#***************    GO 1.12   *************************************************

ENV GOLANG_12_VERSION="1.12.17"
ENV GOLANG_12_DOWNLOAD_SHA256="9d0819cce1451abdb090071880fe8771f16a3bcee71d6f6906023d17799574e2"

RUN set -ex \
    && wget -q "https://dl.google.com/go/go$GOLANG_12_VERSION.linux-arm64.tar.gz" -O /tmp/golang.tar.gz \
    && echo "$GOLANG_12_DOWNLOAD_SHA256 /tmp/golang.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/golang.tar.gz -C /tmp \
    && mv /tmp/go /usr/local/go12  \
    && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

#****************      END GOLANG     ****************************************************


#=======================End of layer: runtimes_1  =================
FROM runtimes_1 AS runtimes_2

#Docker 19
ENV DOCKER_BUCKET="download.docker.com" \
    DOCKER_CHANNEL="stable" \
    DIND_COMMIT="3b5fac462d21ca164b3778647420016315289034"

ENV DOCKER_SHA256="0259f8b6572f02cf0dafd7388ca0e4adfdbbfaba81cfb1b7443e89fccbed22c7"
ENV DOCKER_VERSION="20.10.9"

VOLUME /var/lib/docker

# Install Docker
RUN set -ex \
    && curl -fSL "https://${DOCKER_BUCKET}/linux/static/${DOCKER_CHANNEL}/aarch64/docker-${DOCKER_VERSION}.tgz" -o docker.tgz \
    && echo "${DOCKER_SHA256} *docker.tgz" | sha256sum -c - \
    && tar --extract --file docker.tgz --strip-components 1  --directory /usr/local/bin \
    && rm docker.tgz \
    && docker -v \
    # set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
    && groupadd dockremap \
    && useradd -g dockremap dockremap \
    && echo 'dockremap:165536:65536' >> /etc/subuid \
    && echo 'dockremap:165536:65536' >> /etc/subgid \
    && wget -q "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind" -O /usr/local/bin/dind \
    && chmod +x /usr/local/bin/dind

#Python 3.8
ENV PYTHON_38_VERSION="3.8.10"

COPY tools/runtime_configs/python/$PYTHON_38_VERSION /root/.pyenv/plugins/python-build/share/python-build/$PYTHON_38_VERSION
RUN   env PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install $PYTHON_38_VERSION; rm -rf /tmp/*
RUN   pyenv global  $PYTHON_38_VERSION
RUN set -ex \
    && pip3 install --no-cache-dir --upgrade --force-reinstall "pip==$PYTHON_PIP_VERSION" \
    && pip3 install --no-cache-dir --upgrade "PyYAML==$PYYAML_VERSION" \
    && pip3 install --no-cache-dir --upgrade 'setuptools==57.4.0' wheel aws-sam-cli awscli boto3 pipenv virtualenv \
    && pip3 install --no-cache-dir "docker-compose==$DOCKER_COMPOSE_VERSION" \
    && docker-compose version

#Python 3.9
ENV PYTHON_39_VERSION="3.9.5"

COPY tools/runtime_configs/python/$PYTHON_39_VERSION /root/.pyenv/plugins/python-build/share/python-build/$PYTHON_39_VERSION
RUN   env PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install $PYTHON_39_VERSION; rm -rf /tmp/*
RUN   pyenv global  $PYTHON_39_VERSION
RUN set -ex \
    && pip3 install --no-cache-dir --upgrade --force-reinstall "pip==$PYTHON_PIP_VERSION" \
    && pip3 install --no-cache-dir --upgrade "PyYAML==$PYYAML_VERSION" \
    && pip3 install --no-cache-dir --upgrade 'setuptools==57.4.0' wheel aws-sam-cli awscli boto3 pipenv virtualenv \
    && pip3 install --no-cache-dir "docker-compose==$DOCKER_COMPOSE_VERSION" \
    && docker-compose version

# Node 12
ENV NODE_12_VERSION="12.22.2"

RUN  n $NODE_12_VERSION && npm install --save-dev -g -f grunt && npm install --save-dev -g -f grunt-cli && npm install --save-dev -g -f webpack \
     && rm -rf /tmp/*

#=======================End of layer: runtimes_2  =================
FROM runtimes_2 AS runtimes_3

#DotNet 3.1
ENV DOTNET_31_SDK_VERSION="3.1.301"
ENV DOTNET_ROOT="/root/.dotnet"

RUN /usr/local/bin/dotnet-install.sh -v $DOTNET_31_SDK_VERSION \
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

#Ruby 2.7
ENV RUBY_27_VERSION="2.7.1"
RUN rbenv install $RUBY_27_VERSION; rm -rf /tmp/*; rbenv global $RUBY_27_VERSION;ruby -v

#Php 7.4
ENV PHP_74_VERSION="7.4.7"
COPY tools/runtime_configs/php/$PHP_74_VERSION /root/.phpenv/plugins/php-build/share/php-build/definitions/$PHP_74_VERSION
RUN phpenv install $PHP_74_VERSION; rm -rf /tmp/*; phpenv global $PHP_74_VERSION
RUN echo "memory_limit = 1G;" >> "/root/.phpenv/versions/$PHP_74_VERSION/etc/conf.d/memory.ini"

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer
#****************      END PHP     ****************************************************

#===================END of runtimes_3 ==============
FROM runtimes_3 AS aarch64_v2

# Configure SSH
COPY ssh_config /root/.ssh/config
COPY runtimes.yml /codebuild/image/config/runtimes.yml
COPY dockerd-entrypoint.sh /usr/local/bin/
COPY legal/THIRD_PARTY_LICENSES.txt /usr/share/doc
COPY legal/bill_of_material.txt     /usr/share/doc
COPY amazon-ssm-agent.json          /etc/amazon/ssm/

ENTRYPOINT ["dockerd-entrypoint.sh"]

#=======================End of layer: aarch64_v2  =================

