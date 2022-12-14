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

FROM public.ecr.aws/amazonlinux/amazonlinux:2 AS core

# Install git, SSH, and other utilities
RUN set -ex \
    && yum install -y -q openssh-clients \
    && mkdir ~/.ssh \
    && mkdir -p /opt/tools \
    && mkdir -p /codebuild/image/config \
    && touch ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa -H github.com >> ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa -H bitbucket.org >> ~/.ssh/known_hosts \
    && chmod 600 ~/.ssh/known_hosts \
    && amazon-linux-extras install epel -y \
    && rpm --import https://download.mono-project.com/repo/xamarin.gpg \
    && curl https://download.mono-project.com/repo/centos7-stable.repo | tee /etc/yum.repos.d/mono-centos7-stable.repo \
    && amazon-linux-extras enable corretto8 \
    && amazon-linux-extras enable docker \
    && yum groupinstall -y -q "Development tools" \
    && yum install -y -q \
           GeoIP-devel ImageMagick asciidoc bzip2-devel bzr bzrtools cvs cvsps \
           docbook-dtds docbook-style-xsl dpkg-dev e2fsprogs expat-devel expect fakeroot \
           glib2-devel groff gzip icu iptables jq krb5-server libargon2-devel \
           libcurl-devel libdb-devel libedit-devel libevent-devel libffi-devel \
           libicu-devel libjpeg-devel libpng-devel libserf libsqlite3x-devel \
           libtidy-devel libunwind libwebp-devel libxml2-devel libxslt libxslt-devel \
           libyaml-devel libzip-devel mariadb-devel mercurial mlocate mono-devel \
           ncurses-devel oniguruma-devel openssl openssl-devel perl-DBD-SQLite \
           perl-DBI perl-HTTP-Date perl-IO-Pty-Easy perl-TimeDate perl-YAML-LibYAML \
           postgresql-devel procps-ng python-configobj readline-devel rsync sgml-common \
           subversion-perl tar tcl tk vim wget which xfsprogs xmlto xorg-x11-server-Xvfb xz-devel \
           amazon-ecr-credential-helper \
    && rm /etc/yum.repos.d/mono-centos7-stable.repo

RUN useradd codebuild-user

#=======================End of layer: core  =================

FROM core AS tools

# Install Git
RUN set -ex \
   && GIT_VERSION=2.36.1 \
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
   && STUNNEL_VERSION=5.64 \
   && STUNNEL_TAR=stunnel-$STUNNEL_VERSION.tar.gz \
   && STUNNEL_SHA256="eebe53ed116ba43b2e786762b0c2b91511e7b74857ad4765824e7199e6faf883" \
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
RUN curl -sS -o /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.22.6/2022-03-09/bin/linux/amd64/aws-iam-authenticator \
    && curl -sS -o /usr/local/bin/kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.22.6/2022-03-09/bin/linux/amd64/kubectl \
    && curl -sS -o /usr/local/bin/ecs-cli https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest \
    && curl -sS -L https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz | tar xz -C /usr/local/bin \
    && chmod +x /usr/local/bin/kubectl /usr/local/bin/aws-iam-authenticator /usr/local/bin/ecs-cli /usr/local/bin/eksctl

# Configure SSM
RUN set -ex \
    && yum install -y -q https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

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


#=======================End of layer: tools  =================

FROM tools AS runtimes_1

#****************      NODEJS     ****************************************************

ENV NODE_16_VERSION="16.15.1"

RUN  n $NODE_16_VERSION && npm install --save-dev -g -f grunt && npm install --save-dev -g -f grunt-cli && npm install --save-dev -g -f webpack \
     && curl -sSL https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo \
     && rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg \
     && yum install -y https://download-ib01.fedoraproject.org/pub/epel/8/Modular/x86_64/Packages/l/libuv-1.43.0-2.module_el8+13804+34326f90.x86_64.rpm \
     && yum install -y -q yarn \
     && yarn --version \
     && cd / && rm -rf $N_SRC_DIR && rm -rf /tmp/*

#****************      END NODEJS     ****************************************************

#**************** RUBY *********************************************************

ENV RUBY_31_VERSION="3.1.2"

RUN rbenv install $RUBY_31_VERSION && rm -rf /tmp/* && rbenv global $RUBY_31_VERSION && ruby -v

#**************** END RUBY *****************************************************

#**************** PYTHON *****************************************************
#Python 3.9
ENV PYTHON_39_VERSION="3.9.12"
ENV PYTHON_PIP_VERSION=21.1.2
ENV PYYAML_VERSION=5.4.1

COPY tools/runtime_configs/python/$PYTHON_39_VERSION /root/.pyenv/plugins/python-build/share/python-build/$PYTHON_39_VERSION
RUN   env PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install $PYTHON_39_VERSION && rm -rf /tmp/*
RUN   pyenv global  $PYTHON_39_VERSION
RUN set -ex \
    && pip3 install --no-cache-dir --upgrade --force-reinstall "pip==$PYTHON_PIP_VERSION" \
    && pip3 install --no-cache-dir --upgrade "PyYAML==$PYYAML_VERSION" \
    && pip3 install --no-cache-dir --upgrade 'setuptools==57.4.0' wheel aws-sam-cli awscli boto3 pipenv virtualenv --use-feature=2020-resolver    

#**************** END PYTHON *****************************************************

RUN wget https://www.sqlite.org/2022/sqlite-autoconf-3400000.tar.gz
RUN tar -xvf sqlite-autoconf-3400000.tar.gz
RUN cd ./sqlite-autoconf-3400000 && CFLAGS="-DSQLITE_ENABLE_COLUMN_METADATA=1" ./configure
RUN cd ./sqlite-autoconf-3400000 && make
RUN cd ./sqlite-autoconf-3400000 && make install

#**************** PROJ *****************************************************

RUN yum install gcc-c++.x86_64 cpp.x86_64 sqlite-devel.x86_64 libtiff.x86_64 cmake3.x86_64 -y
RUN yum install libtiff-devel curl-devel -y
RUN wget https://download.osgeo.org/proj/proj-9.1.1.tar.gz
RUN tar xvf proj-9.1.1.tar.gz
RUN mkdir proj-9.1.1/build
RUN cd ./proj-9.1.1/build && cmake3 -DSQLITE3_INCLUDE_DIR=/usr/local/include -DSQLITE3_LIBRARY=/usr/local/lib/libsqlite3.so ..
RUN cd ./proj-9.1.1/build && cmake3 --build .
RUN cd ./proj-9.1.1/build && cmake3 --build . --target install
RUN ./proj-9.1.1/build/bin/projsync --system-directory --all

#**************** GEOS *****************************************************

RUN wget https://download.osgeo.org/geos/geos-3.11.1.tar.bz2
RUN tar xvf geos-3.11.1.tar.bz2
RUN mkdir geos-3.11.1/_build
RUN cd geos-3.11.1/_build && cmake3 -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local ..
RUN cd geos-3.11.1/_build && make
RUN cd geos-3.11.1/_build && make install
RUN touch /etc/ld.so.conf.d/libgeos_c.so.1.conf
RUN bash -c 'echo "/usr/local/lib64" >> /etc/ld.so.conf.d/libgeos_c.so.1.conf'
RUN ldconfig


#=======================End of layer: runtimes_1  =================
FROM runtimes_1 AS runtimes_2

#Docker 20
ENV DOCKER_BUCKET="download.docker.com" \
    DOCKER_CHANNEL="stable" \
    DIND_COMMIT="3b5fac462d21ca164b3778647420016315289034" \
    DOCKER_COMPOSE_VERSION="1.26.0"

ENV DOCKER_SHA256="9ccfc39305ae1d8882d18c9c431544fca82913d6df717409ac2244ac58c4f070"
ENV DOCKER_VERSION="20.10.15"

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
    && curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-Linux-x86_64 > /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/dind /usr/local/bin/docker-compose \
    && docker-compose version


#=======================End of layer: runtimes_2  =================
FROM runtimes_2 AS runtimes_3



#===================END of runtimes_3 ==============
FROM runtimes_3 AS al2_v3

# Configure SSH
COPY ssh_config /root/.ssh/config
COPY runtimes.yml /codebuild/image/config/runtimes.yml
COPY dockerd-entrypoint.sh /usr/local/bin/dockerd-entrypoint.sh
COPY legal/THIRD_PARTY_LICENSES.txt /usr/share/doc/THIRD_PARTY_LICENSES.txt
COPY legal/bill_of_material.txt /usr/share/doc/bill_of_material.txt
COPY amazon-ssm-agent.json /etc/amazon/ssm/amazon-ssm-agent.json

ENTRYPOINT ["/usr/local/bin/dockerd-entrypoint.sh"]

#=======================End of layer: al2_v4  =================
