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


# Install git, SSH, php, and other utilities
RUN set -ex \
    && yum install -yq openssh-clients \
    && mkdir ~/.ssh \
    && touch ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa,ed25519,ecdsa -H github.com >> ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa,ed25519,ecdsa -H bitbucket.org >> ~/.ssh/known_hosts \
    && chmod 600 ~/.ssh/known_hosts \
    && rpm --import https://download.mono-project.com/repo/xamarin.gpg \
    && curl https://download.mono-project.com/repo/centos7-stable.repo | tee /etc/yum.repos.d/mono-centos7-stable.repo \
    && yum groupinstall -yq "Development tools" \
    && yum install -yq \
           ImageMagick asciidoc bzip2 bzip2-devel cvs cvsps \
           docbook-dtds docbook-style-xsl e2fsprogs expat-devel expect fakeroot \
           git glib2-devel groff gzip icu iptables jq krb5-server libargon2-devel \
           libcurl-devel libdb-devel libedit-devel libevent-devel libffi-devel \
           libjpeg-devel libpng-devel libserf \
           libtidy-devel libunwind libwebp-devel libxml2-devel libxslt libxslt-devel \
           libyaml-devel libzip-devel mlocate \
           ncurses-devel oniguruma-devel openssl openssl-devel perl-DBD-SQLite \
           perl-DBI perl-HTTP-Date perl-TimeDate perl-YAML-LibYAML php8.1 \
           postgresql-devel procps-ng python-configobj readline-devel rsync sgml-common \
           patch pkg-config procps python3-configobj llvm rsync sqlite-devel \
           subversion-perl tar tcl tk vim wget which xfsprogs xmlto xorg-x11-server-Xvfb xz-devel \
           amazon-ecr-credential-helper

RUN useradd codebuild-user

#=======================End of layer: core  =================

FROM core AS tools

# Install stunnel
RUN set -ex \
   && STUNNEL_VERSION=5.69 \
   && STUNNEL_TAR=stunnel-$STUNNEL_VERSION.tar.gz \
   && STUNNEL_SHA256="1ff7d9f30884c75b98c8a0a4e1534fa79adcada2322635e6787337b4e38fdb81" \
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
   && cd .. ; rm -rf stunnel-${STUNNEL_VERSION}*

# AWS Tools
# https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html
RUN curl -sS -o /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.25.6/2023-01-30/bin/linux/arm64/aws-iam-authenticator \
    && curl -sS -o /usr/local/bin/kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.25.6/2023-01-30/bin/linux/arm64/kubectl \
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

##awscliv2
RUN curl https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip -o /tmp/awscliv2.zip \
     && unzip /tmp/awscliv2.zip -d /opt \
     && /opt/aws/install --update -i /usr/local/aws-cli -b /usr/local/bin \
     && rm /tmp/awscliv2.zip \
     && rm -rf /opt/aws \
     && aws --version

#=======================End of layer: tools  =================

FROM tools AS runtimes_1

#****************      JAVA     ****************************************************
ENV JAVA_17_HOME="/usr/lib/jvm/java-17-amazon-corretto.aarch64" \
    JDK_17_HOME="/usr/lib/jvm/java-17-amazon-corretto.aarch64" \
    JRE_17_HOME="/usr/lib/jvm/java-17-amazon-corretto.aarch64/jre" \
    ANT_VERSION=1.10.13 \
    MAVEN_HOME="/opt/maven" \
    MAVEN_VERSION=3.9.1 \
    INSTALLED_GRADLE_VERSIONS="8.0.2" \
    GRADLE_VERSION=8.0.2 \
    SBT_VERSION=1.3.13 \
    GRADLE_PATH="$SRC_DIR/gradle" \
    ANT_DOWNLOAD_SHA512="de4ac604629e39a86a306f0541adb3775596909ad92feb8b7de759b1b286417db24f557228737c8b902d6abf722d2ce5bb0c3baa3640cbeec3481e15ab1958c9" \
    MAVEN_DOWNLOAD_SHA512="d3be5956712d1c2cf7a6e4c3a2db1841aa971c6097c7a67f59493a5873ccf8c8b889cf988e4e9801390a2b1ae5a0669de07673acb090a083232dbd3faf82f3e3" \
    GRADLE_DOWNLOADS_SHA256="47a5bfed9ef814f90f8debcbbb315e8e7c654109acd224595ea39fca95c5d4da 8.0.2" \
    SBT_DOWNLOAD_SHA256="854154de27a7d8c13b5a0f9a297cd1f254cc13b44588dae507e5d4fb2741bd22"

ARG MAVEN_CONFIG_HOME="/root/.m2"
ENV JAVA_HOME="$JAVA_17_HOME" \
    JDK_HOME="$JAVA_17_HOME" \
    JRE_HOME="$JAVA_17_HOME"


RUN set -x \
    # Install Amazon Corretto 17
    # Note: We will use update-alternatives to make sure JDK17 has higher priority for all the tools
    && yum install -yq java-17-amazon-corretto \
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
    && wget -q "https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-all.zip" -O "$GRADLE_PATH/gradle-$GRADLE_VERSION-all.zip" \
    && unzip -q "$GRADLE_PATH/gradle-$GRADLE_VERSION-all.zip" -d /usr/local \
    && echo -e "$GRADLE_DOWNLOADS_SHA256" | grep "$GRADLE_VERSION" | sed "s|$GRADLE_VERSION|$GRADLE_PATH/gradle-$GRADLE_VERSION-all.zip|" | sha256sum -c - \
    && rm "$GRADLE_PATH/gradle-$GRADLE_VERSION-all.zip" \
    && mkdir "/tmp/gradle-$GRADLE_VERSION" \
    && "/usr/local/gradle-$GRADLE_VERSION/bin/gradle" -p "/tmp/gradle-$GRADLE_VERSION" init \
    && "/usr/local/gradle-$GRADLE_VERSION/bin/gradle" -p "/tmp/gradle-$GRADLE_VERSION" wrapper \
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
RUN sbt version
# Cleanup
RUN rm -fr /tmp/* /var/tmp/* \
     && yum clean all
#****************     END JAVA     ****************************************************


#****************     PowerShell     *******************************************************

# Install Powershell Core
ENV POWERSHELL_VERSION 7.3.3
ENV POWERSHELL_DOWNLOAD_URL https://github.com/PowerShell/PowerShell/releases/download/v$POWERSHELL_VERSION/powershell-$POWERSHELL_VERSION-linux-arm64.tar.gz
ENV POWERSHELL_DOWNLOAD_SHA 5EFCA750F22BFECB31BCDA57C3A76BB804C68AEF6626F123AAC68C6E3D7E52F7

RUN set -ex \
    && curl -SL $POWERSHELL_DOWNLOAD_URL --output powershell.tar.gz \
    && echo "$POWERSHELL_DOWNLOAD_SHA powershell.tar.gz" | sha256sum -c - \
    && mkdir -p /opt/microsoft/powershell/$POWERSHELL_VERSION \
    && tar zxf powershell.tar.gz -C /opt/microsoft/powershell/$POWERSHELL_VERSION \
    && rm powershell.tar.gz \
    && ln -s /opt/microsoft/powershell/$POWERSHELL_VERSION/pwsh /usr/bin/pwsh
#****************     END Powershell     *******************************************************



#****************      NODEJS     ****************************************************

ENV NODE_18_VERSION="18.15.0"

RUN  n $NODE_18_VERSION && npm install --save-dev -g -f grunt && npm install --save-dev -g -f grunt-cli && npm install --save-dev -g -f webpack \
     && cd / && rm -rf $N_SRC_DIR; rm -rf /tmp/*

#****************      END NODEJS     ****************************************************

#**************** RUBY *********************************************************

ENV RUBY_32_VERSION="3.2.1"

RUN rbenv install $RUBY_32_VERSION && rm -rf /tmp/* \
    && rbenv global $RUBY_32_VERSION && ruby -v

#**************** END RUBY *****************************************************

#**************** PYTHON *****************************************************
ENV PYTHON_311_VERSION="3.11.2"
ENV PYTHON_PIP_VERSION=23.0.1
ENV PYYAML_VERSION=6.0

COPY tools/runtime_configs/python/$PYTHON_311_VERSION /root/.pyenv/plugins/python-build/share/python-build/$PYTHON_311_VERSION
RUN   env PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install $PYTHON_311_VERSION; rm -rf /tmp/*
RUN   pyenv global  $PYTHON_311_VERSION
RUN set -ex \
    && pip3 install --no-cache-dir --upgrade --force-reinstall "pip==$PYTHON_PIP_VERSION" \
    && pip3 install --no-cache-dir --upgrade "PyYAML==$PYYAML_VERSION" \
    && pip3 install --no-cache-dir --upgrade 'setuptools==57.4.0' wheel aws-sam-cli boto3 pipenv virtualenv

#**************** END PYTHON *****************************************************

#****************      PHP     ****************************************************

# Installed in packages
ENV PHP_81_VERSION="8.1.14"
# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer
#****************      END PHP     ****************************************************

#****************     GOLANG     ****************************************************
ENV GOPATH="/go"

ENV GOLANG_20_VERSION="1.20.2"
ENV GOLANG_20_DOWNLOAD_SHA256="78d632915bb75e9a6356a47a42625fd1a785c83a64a643fedd8f61e31b1b3bef"

RUN set -ex \
    && mkdir -p "$GOPATH/src" "$GOPATH/bin" \
    && chmod -R 777 "$GOPATH" \
    && wget -q "https://dl.google.com/go/go$GOLANG_20_VERSION.linux-arm64.tar.gz" -O /tmp/golang.tar.gz \
    && echo "$GOLANG_20_DOWNLOAD_SHA256 /tmp/golang.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/golang.tar.gz -C /tmp \
    && mv /tmp/go /usr/local/go20  \
    && rm -fr /tmp/* /var/tmp/*

RUN ln -s /usr/local/go20 /usr/local/go
ENV PATH="$GOPATH/bin:/usr/local/go/bin:$PATH"

#****************      END GOLANG     ****************************************************


#=======================End of layer: runtimes_1  =================
FROM runtimes_1 AS runtimes_2

#Docker 2.17
ENV DOCKER_BUCKET="download.docker.com" \
    DOCKER_CHANNEL="stable" \
    DIND_COMMIT="3b5fac462d21ca164b3778647420016315289034"

ENV DOCKER_SHA256="3865F837DBD951B19EEB5F7D87AADA2E865B2017E9462FE389F0E5D9A438324D"
ENV DOCKER_VERSION="23.0.1"
ENV DOCKER_COMPOSE_VERSION="2.17.2"

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
    && curl -L https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-Linux-aarch64 > /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/dind /usr/local/bin/docker-compose \
    # Ensure docker-compose works
    && docker-compose version

#=======================End of layer: runtimes_2  =================
FROM runtimes_2 AS runtimes_3

#DotNet 6.0
ENV DOTNET_6_SDK_VERSION="6.0.407"
ENV DOTNET_ROOT="/root/.dotnet"

RUN /usr/local/bin/dotnet-install.sh -v $DOTNET_6_SDK_VERSION \
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
COPY legal/bill_of_material.txt /usr/share/doc
COPY amazon-ssm-agent.json /etc/amazon/ssm/

ENTRYPOINT ["dockerd-entrypoint.sh"]

#=======================End of layer: aarch64_v2  =================


