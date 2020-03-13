FROM amazonlinux:2

ENV RUBY_VERSION="2.6.5" \
 PYTHON_37_VERSION="3.7.4" \
 PYTHON_VERSION="3.8.0" \
 PHP_VERSION=7.3.10 \
 JAVA_VERSION=11 \ 
 NODE_VERSION="12.13.0" \
 NODE_10_VERSION="10.16.3" \
 NODE_8_VERSION="8.16.0" \
 GOLANG_VERSION="1.13.1" \
 GOLANG_12_VERSION="1.12.9" \
 DOCKER_18_VERSION="18.09.6" \
 DOCKER_VERSION="19.03.1" \
 DOCKER_COMPOSE_VERSION="1.24.0"

ARG CHINA_REGION

#****************        Utilities     ********************************************* 
ENV DOCKER_BUCKET="download.docker.com" \    
    DOCKER_CHANNEL="stable" \
    DOCKER_18_SHA256="c4857639514471e2d1aa6d567880b7fc226437ede462021ed44157d4dcd11dc8" \
    DOCKER_SHA256="44158b9fe44e8b5d3c1226a5d880425850d6f8ec383e4cf053f401e1a8fc269d" \
    DIND_COMMIT="3b5fac462d21ca164b3778647420016315289034" \
    GITVERSION_VERSION="4.0.0" \
    DEBIAN_FRONTEND="noninteractive" \
    SRC_DIR="/usr/src" \
    EPEL_REPO="https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"

# Install git, SSH, and other utilities
RUN set -ex \
    && yum install -y openssh-clients \
    && mkdir ~/.ssh \
    && touch ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa -H github.com >> ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa -H bitbucket.org >> ~/.ssh/known_hosts \
    && chmod 600 ~/.ssh/known_hosts \
    && yum install -y $EPEL_REPO \
    && rpm --import https://download.mono-project.com/repo/xamarin.gpg \
    && curl https://download.mono-project.com/repo/centos7-stable.repo | tee /etc/yum.repos.d/mono-centos7-stable.repo \
    && amazon-linux-extras enable corretto8 \
    && yum groupinstall -y "Development tools" \
    && yum install -y wget fakeroot jq \
       bzr mercurial procps-ng \
       ImageMagick \
       openssl-devel libdb-devel \
       libevent-devel libffi-devel GeoIP-devel glib2-devel \
       libjpeg-devel krb5-server xz-devel \
       mariadb-devel \
       ncurses-devel postgresql-devel readline-devel \
       libsqlite3x-devel libwebp-devel \
       libxml2-devel libxslt-devel libyaml-devel \
       e2fsprogs iptables xfsprogs \
       mono-devel groff \
       asciidoc cvs cvsps docbook-dtds docbook-style-xsl \
       perl-DBD-SQLite perl-DBI perl-HTTP-Date \
       perl-IO-Pty-Easy libserf subversion-perl tcl perl-TimeDate \
       perl-YAML-LibYAML bzrtools python-configobj \
       sgml-common xmlto libxslt \
       tk xorg-x11-server-Xvfb expect parallel rsync \
    && yum clean all

# Install Docker
ENV DOCKER_18_PATH=/usr/local/bin/docker18
ENV DOCKER_PATH=/usr/local/bin/docker19

RUN set -ex \
# for old version (docker 18)
    && mkdir $DOCKER_18_PATH; cd $DOCKER_18_PATH; curl -fSL "https://${DOCKER_BUCKET}/linux/static/${DOCKER_CHANNEL}/aarch64/docker-${DOCKER_18_VERSION}.tgz" -o docker.tgz \
    && echo "${DOCKER_18_SHA256} *docker.tgz" | sha256sum -c - \
    && tar --extract --file docker.tgz --strip-components 1  --directory $DOCKER_18_PATH \
    && rm docker.tgz \
    && for tool_path in $DOCKER_18_PATH/*; do \
          tool=`basename $tool_path`; \
          update-alternatives --install /usr/local/bin/$tool $tool $tool_path 10000; \
        done \
# for new version (docker 19)
    && mkdir $DOCKER_PATH; cd $DOCKER_PATH ; curl -fSL "https://${DOCKER_BUCKET}/linux/static/${DOCKER_CHANNEL}/aarch64/docker-${DOCKER_VERSION}.tgz" -o docker.tgz \
    && echo "${DOCKER_SHA256} *docker.tgz" | sha256sum -c - \
    && tar --extract --file docker.tgz --strip-components 1  --directory $DOCKER_PATH \
    && rm docker.tgz \
    && for tool_path in $DOCKER_PATH/*; do \
          tool=`basename $tool_path`; \
          update-alternatives --install /usr/local/bin/$tool $tool $tool_path 10000; \
          update-alternatives --set $tool $tool_path; \
        done \
    && docker -v \
# set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
    && groupadd dockremap \
    && useradd -g dockremap dockremap \
    && echo 'dockremap:165536:65536' >> /etc/subuid \
    && echo 'dockremap:165536:65536' >> /etc/subgid \
    && wget "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind" -O /usr/local/bin/dind 
# TODO there is no existing docker compose executable for ARM. 
#   && curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-Linux-x86_64 > /usr/local/bin/docker-compose \
#   && chmod +x /usr/local/bin/dind /usr/local/bin/docker-compose
#   && docker-compose version

# https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html
RUN curl -sS -o /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/linux/amd64/aws-iam-authenticator \
 && curl -sS -o /usr/local/bin/kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/linux/amd64/kubectl \
 && curl -sS -o /usr/local/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest \
 && chmod +x /usr/local/bin/kubectl /usr/local/bin/aws-iam-authenticator /usr/local/bin/ecs-cli

VOLUME /var/lib/docker

# Configure SSH
COPY ssh_config /root/.ssh/config

COPY runtimes.yml /codebuild/image/config/runtimes.yml

COPY dockerd-entrypoint.sh /usr/local/bin/

#**************** RUBY *********************************************************

ENV RBENV_SRC_DIR="/usr/local/rbenv"

ENV PATH="/root/.rbenv/shims:$RBENV_SRC_DIR/bin:$RBENV_SRC_DIR/shims:$PATH" \
    RUBY_BUILD_SRC_DIR="$RBENV_SRC_DIR/plugins/ruby-build"

RUN set -ex \
    && git clone https://github.com/rbenv/rbenv.git $RBENV_SRC_DIR \
    && mkdir -p $RBENV_SRC_DIR/plugins \
    && git clone https://github.com/rbenv/ruby-build.git $RUBY_BUILD_SRC_DIR \
    && sh $RUBY_BUILD_SRC_DIR/install.sh \
    && rbenv install $RUBY_VERSION && rbenv global $RUBY_VERSION \
    && ruby -v

#**************** END RUBY *****************************************************

#****************        PYTHON 3.7    *********************************************
# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.

ENV PATH="/usr/local/bin:$PATH" \
    GPG_KEY="0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D" \
    PYTHON_PIP_VERSION="19.3" \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8

RUN yum install -y tcl-devel tk-devel bzip2-devel gdbm-devel libuuid-devel \
    &&  wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_37_VERSION%%[a-z]*}/Python-$PYTHON_37_VERSION.tar.xz" \
    && wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_37_VERSION%%[a-z]*}/Python-$PYTHON_37_VERSION.tar.xz.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && (gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$GPG_KEY" \
        || gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "$GPG_KEY" \
        || gpg --keyserver pgp.mit.edu --recv-keys "$GPG_KEY") \
    && gpg --batch --verify python.tar.xz.asc python.tar.xz \
    && rm -r "$GNUPGHOME" python.tar.xz.asc \
    && mkdir -p /usr/src/python \
    && tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
    && rm python.tar.xz \
    && cd /usr/src/python \
    && ./configure \
        --enable-loadable-sqlite-extensions \
        --enable-shared \
        --prefix=/usr/local/python37 \
    && make -j$(nproc) \
    && make install \
    && ln -s /usr/local/python37/lib/libpython3.7m.so.1.0 /usr/lib64/libpython3.7m.so.1.0 \
    && /usr/local/python37/bin/python3 --version \
    && ldconfig \
# explicit path to "pip3" to ensure distribution-provided "pip3" cannot interfere
   && if [ ! -e /usr/local/bin/pip3 ]; then \
         wget -O /tmp/get-pip.py 'https://bootstrap.pypa.io/get-pip.py' \
        && /usr/local/python37/bin/python3 /tmp/get-pip.py "pip==$PYTHON_PIP_VERSION" \
        && rm /tmp/get-pip.py ; \
     fi \
   && yum clean all

# we use "--force-reinstall" for the case where the version of pip we're trying to install is the same as the version bundled with Python
# ("Requirement already up-to-date: pip==8.1.2 in /usr/local/lib/python3.6/site-packages")
# https://github.com/docker-library/python/pull/143#issuecomment-241032683
 RUN set -ex; \
     /usr/local/python37/bin/pip3 install --no-cache-dir --upgrade --force-reinstall "pip==$PYTHON_PIP_VERSION" \
        && /usr/local/python37/bin/pip3 install pipenv virtualenv --no-cache-dir

RUN /usr/local/python37/bin/pip3 install --no-cache-dir --upgrade setuptools wheel tox codecov  \
# then we use "pip list" to ensure we don't have more than one pip version installed
# https://github.com/docker-library/python/pull/100
    && [ "$(/usr/local/python37/bin/pip3 list |tac|tac| awk -F '[ ()]+' '$1 == "pip" { print $2; exit }')" = "$PYTHON_PIP_VERSION" ] \
    \
    && find /usr/local -depth \
        \( \
            \( -type d -a -name test -o -name tests \) \
            -o \
            \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
        \) -exec rm -rf '{}' + \
    && rm -rf /usr/src/python ~/.cache \
    && rm -fr /tmp/* /var/tmp/*

RUN cd /usr/local/python37/bin \
    &&  { [ -e easy_install ] || ln -s easy_install-* easy_install; } \
    &&  { [ -e python ] || ln -s python3 python; } \
    && for tool_path in /usr/local/python37/bin/*; do \
          tool=`basename $tool_path`; \
          update-alternatives --install /usr/local/bin/$tool $tool $tool_path 10000; \
        done

#****************        PYTHON 3.8    *********************************************
# extra dependencies (over what buildpack-deps already includes)
RUN yum install -y \
        tcl tcl-dev \
		tk  tk-dev \
		uuid-dev \
		libedit-devel dpkg-dev libargon2-devel re2c expat-devel expat\
	&& yum clean all

ENV GPG_KEY E3FF2839C048B25C084DEBE9B26995E310250568

RUN set -ex \
	\
	&& wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" \
	&& wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
	&& gpg --batch --verify python.tar.xz.asc python.tar.xz \
	&& { command -v gpgconf > /dev/null && gpgconf --kill all || :; } \
	&& rm -rf "$GNUPGHOME" python.tar.xz.asc \
	&& mkdir -p /usr/src/python \
	&& tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
	&& rm python.tar.xz \
	\
	&& cd /usr/src/python \
	&& ./configure \
		--enable-loadable-sqlite-extensions \
		--enable-optimizations \
		--enable-shared \
		--with-system-expat \
		--with-system-ffi \
		--without-ensurepip \
		--prefix=/usr/local/python38 \
	&& make -j 2 \
	&& make install \
	&& ln -s /usr/local/python38/lib/libpython3.8.so.1.0 /usr/lib64/libpython3.8.so.1.0 \
	&& ldconfig \
	\
	&& find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests \) \) \
			-o \
			\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' + \
	&& rm -rf /usr/src/python \
	\
	&& /usr/local/python38/bin/python3 --version

# make some useful symlinks that are expected to exist
RUN cd /usr/local/bin \
    && rm -f idle idle3; ln -s /usr/local/python38/bin/idle3 idle ; ln -s /usr/local/python38/bin/idle3 idle3 \
    && rm -f pydoc pydoc3; ln -s /usr/local/python38/bin/pydoc3 pydoc ;ln -s /usr/local/python38/bin/pydoc3 pydoc3 \
    && rm -f python python3; ln -s /usr/local/python38/bin/python3 python; ln -s /usr/local/python38/bin/python3 python3 \
    && rm -f python-config python-config3; ln -s /usr/local/python38/bin/python3-config python-config ; ln -s /usr/local/python38/bin/python3-config python-config3

# https://github.com/pypa/get-pip
ENV PYTHON_GET_PIP_URL https://github.com/pypa/get-pip/raw/65986a26949050d26e6ec98915da4aade8d8679d/get-pip.py
ENV PYTHON_GET_PIP_SHA256 8d412752ae26b46a39a201ec618ef9ef7656c5b2d8529cdcbe60cd70dc94f40c

RUN set -ex; \
	\
	wget -O get-pip.py "$PYTHON_GET_PIP_URL"; \
	echo "$PYTHON_GET_PIP_SHA256 *get-pip.py" | sha256sum --check --strict -; \
	\
	/usr/local/python38/bin/python3 get-pip.py \
		--disable-pip-version-check \
		--no-cache-dir \
		"pip==$PYTHON_PIP_VERSION" \
    && rm -f /usr/local/bin/pip ; ln -s  /usr/local/python38/bin/pip  /usr/local/bin/ \
    && rm -f /usr/local/bin/pip3; ln -s  /usr/local/python38/bin/pip3 /usr/local/bin/ ; \
	pip --version; \
	pip install -U pip tox virtualenv codecov && \
	\
	find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests \) \) \
			-o \
			\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' +; \
	rm -f get-pip.py

ENV PATH="/root/.local/bin:$PATH"

RUN set -ex \
    && /usr/local/python38/bin/pip3 install --user aws-sam-cli \
    && sam --version \
    && /usr/local/python38/bin/pip3 install awscli boto3

RUN cd /usr/local/python38/bin \
    &&  { [ -e easy_install ] || ln -s easy_install-* easy_install; } \
    &&  { [ -e python ] || ln -s python3 python; } \
    && for tool_path in /usr/local/python38/bin/*; do \
          tool=`basename $tool_path`; \
          update-alternatives --install /usr/local/bin/$tool $tool $tool_path 10000; \
          update-alternatives --set $tool $tool_path; \
        done \
    && rm -fr /tmp/* /var/tmp/*
#****************      END PYTHON     *********************************************

#****************      PHP     ****************************************************
 ENV GPG_KEYS CBAF69F173A0FEA4B537F470D66C9593118BCCB6 F38252826ACD957EF380D39F2F7956BC5DA04B5D
 ENV PHP_DOWNLOAD_SHA="42f00a15419e05771734b7159c8d39d639b8a5a6770413adfa2615f6f923d906" \
     PHPPATH="/php" \
     PHP_INI_DIR="/usr/local/etc/php" \
     PHP_CFLAGS="-fstack-protector -fpic -fpie -O2" \
     PHP_LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie"
 ENV PHP_SRC_DIR="$SRC_DIR/php" \
     PHP_CPPFLAGS="$PHP_CFLAGS" \
     PHP_URL="https://secure.php.net/get/php-$PHP_VERSION.tar.xz/from/this/mirror" \
     PHP_ASC_URL="https://secure.php.net/get/php-$PHP_VERSION.tar.xz.asc/from/this/mirror"
 RUN set -xe; \
     mkdir -p $SRC_DIR; \
     cd $SRC_DIR; \
     yum install -y curl-devel; \
     wget -O php.tar.xz "$PHP_URL"; \
     echo "$PHP_DOWNLOAD_SHA *php.tar.xz" | sha256sum -c -; \
     wget -O php.tar.xz.asc "$PHP_ASC_URL"; \
     export GNUPGHOME="$(mktemp -d)"; \
     for key in $GPG_KEYS; do \
         ( gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" \
           || gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "$key" \
           || gpg --keyserver pgp.mit.edu --recv-keys "$key" ); \
     done; \
     gpg --batch --verify php.tar.xz.asc php.tar.xz; \
     rm -rf "$GNUPGHOME"; \
     set -eux; \
     yum install -y libedit-devel dpkg-dev libargon2-devel re2c; \
     export \
         CFLAGS="$PHP_CFLAGS" \
         CPPFLAGS="$PHP_CPPFLAGS" \
         LDFLAGS="$PHP_LDFLAGS" \
     ; \
     mkdir -p $PHP_SRC_DIR; \
     tar -Jxf $SRC_DIR/php.tar.xz -C $PHP_SRC_DIR --strip-components=1; \
     cd $PHP_SRC_DIR; \
     gnuArch="$(dpkg-architecture -qDEB_BUILD_GNU_TYPE)"; \
     debMultiarch="$(dpkg-architecture -qDEB_BUILD_MULTIARCH)"; \
     if [ ! -d /usr/include/curl ]; then \
         ln -sT "/usr/include/$debMultiarch/curl" /usr/local/include/curl; \
     fi; \
     ./configure \
         --build="$gnuArch" \
         --with-config-file-path="$PHP_INI_DIR" \
         --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
         --disable-cgi \
     # --enable-ftp is included here because ftp_ssl_connect() needs ftp to be compiled statically (see https://github.com/docker-library/php/issues/236)
         --enable-ftp \
     # --enable-mbstring is included here because otherwise there's no way to get pecl to use it properly (see https://github.com/docker-library/php/issues/195)
         --enable-mbstring \
     # --enable-mysqlnd is included here because it's harder to compile after the fact than extensions are (since it's a plugin for several extensions, not an extension in itself)
         --enable-mysqlnd \
         --enable-sockets \
         --enable-pcntl \
     # https://wiki.php.net/rfc/argon2_password_hash (7.2+)
         --with-password-argon2 \
         --with-curl \
         --with-pdo-pgsql \
         --with-pdo-mysql \
         --with-libedit \
         --with-openssl \
         --with-zlib \
     $(test "$gnuArch" = 's390x-linux-gnu' && echo '--without-pcre-jit') \
         --with-libdir="lib/$debMultiarch" \
     ${PHP_EXTRA_CONFIGURE_ARGS:-} \
     ; \
     make -j "$(nproc)"; \
     make install; \
     find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; \
     make clean; \
     cd /; \
     rm -rf $PHP_SRC_DIR; \
     rm $SRC_DIR/php.tar.xz; \
     php --version; \
     pecl update-channels; \
     rm -rf /tmp/pear ~/.pearrc; \
     mkdir "$PHP_INI_DIR"; \
     mkdir "$PHP_INI_DIR/conf.d"; \
     touch "$PHP_INI_DIR/conf.d/memory.ini" \
     && echo "memory_limit = 1G;" >> "$PHP_INI_DIR/conf.d/memory.ini" \
     && yum clean all

 ENV PATH="$PHPPATH/bin:/usr/local/php/bin:$PATH"

 # Install Composer globally
 RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer
#****************      END PHP     ****************************************************

#****************      NODEJS     ****************************************************

 ENV N_SRC_DIR="$SRC_DIR/n"

 RUN git clone https://github.com/tj/n $N_SRC_DIR \
     && cd $N_SRC_DIR && make install \
     && n $NODE_8_VERSION && npm install --save-dev -g grunt && npm install --save-dev -g grunt-cli && npm install --save-dev -g webpack \
     && n $NODE_10_VERSION && npm install --save-dev -g grunt && npm install --save-dev -g grunt-cli && npm install --save-dev -g webpack \
     && n $NODE_VERSION && npm install --save-dev -g grunt && npm install --save-dev -g grunt-cli && npm install --save-dev -g webpack \
     && curl -sSL https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo \
     && rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg \
     && yum install -y yarn \
     && yarn --version \
     && cd / && rm -rf $N_SRC_DIR \
     && yum clean all

#****************      END NODEJS     ****************************************************

#****************      JAVA     ****************************************************
ENV JAVA_11_HOME="/opt/jvm/amazon-corretto-11" \
    JDK_11_HOME="/opt/jvm/amazon-corretto-11" \
    JRE_11_HOME="/opt/jvm/amazon-corretto-11" \
    JAVA_8_HOME="/usr/lib/jvm/java-1.8.0-amazon-corretto.aarch64" \
    JDK_8_HOME="/usr/lib/jvm/java-1.8.0-amazon-corretto.aarch64" \
    JRE_8_HOME="/usr/lib/jvm/java-1.8.0-amazon-corretto.aarch64/jre" \
    ANT_VERSION=1.10.6 \
    MAVEN_HOME="/opt/maven" \
    MAVEN_VERSION=3.6.3 \
    MAVEN_CONFIG="/root/.m2" \
    INSTALLED_GRADLE_VERSIONS="4.10.3 5.4.1" \
    GRADLE_VERSION=5.4.1 \
    SBT_VERSION=1.2.8 \
    JDK_VERSION=11.0.4.11.1 \
    GRADLE_PATH="$SRC_DIR/gradle" \
    JDK_DOWNLOAD_SHA256="7534c8037db02fedef0b7e782cebd661979516bf7fc17dff7befd72548b56795" \
    ANT_DOWNLOAD_SHA512="c1a9694c3018e248000ff6f46d48af85f537ef3935e0d5256543c58a240084c0aff5289fd9e94cbc40d5442f3cc43592398047f2548fded40d9882be2b40750d" \
    MAVEN_DOWNLOAD_SHA512="c35a1803a6e70a126e80b2b3ae33eed961f83ed74d18fcd16909b2d44d7dada3203f1ffe726c17ef8dcca2dcaa9fca676987befeadc9b9f759967a8cb77181c0" \
    GRADLE_DOWNLOADS_SHA256="14cd15fc8cc8705bd69dcfa3c8fefb27eb7027f5de4b47a8b279218f76895a91 5.4.1\n336b6898b491f6334502d8074a6b8c2d73ed83b92123106bd4bf837f04111043 4.10.3"

ENV JDK_DOWNLOAD_TAR="amazon-corretto-${JDK_VERSION}-linux-aarch64.tar.gz" \
    JAVA_HOME="$JAVA_11_HOME" \
    JDK_HOME="$JDK_11_HOME" \
    JRE_HOME="$JRE_11_HOME"

ENV JDK_DOWNLOAD_URL="https://d3pxv6yz143wms.cloudfront.net/${JDK_VERSION}/${JDK_DOWNLOAD_TAR}"

RUN set -ex \
    # Install Amazon Corretto 8
    && yum -y update; yum -y install java-1.8.0-amazon-corretto-devel \
    # Ensure Java cacerts symlink points to valid location
    && update-ca-trust \
    # Install Amazon Corretto 11
    # Note: We will use update-alternatives to make sure JDK11 has higher priority for all the tools
    && mkdir -p $JAVA_HOME \
    && curl -LSso /var/tmp/$JDK_DOWNLOAD_TAR $JDK_DOWNLOAD_URL \
    && echo "$JDK_DOWNLOAD_SHA256 /var/tmp/$JDK_DOWNLOAD_TAR" | sha256sum -c - \
    && tar xzvf /var/tmp/$JDK_DOWNLOAD_TAR -C $JAVA_HOME --strip-components=1 \
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
    && update-alternatives --install /usr/bin/ant ant /opt/apache-ant-$ANT_VERSION/bin/ant 10000 \
    # Install Maven
    && mkdir -p $MAVEN_HOME \
    && curl -LSso /var/tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz https://apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    && echo "$MAVEN_DOWNLOAD_SHA512 /var/tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz" | sha512sum -c - \
    && tar xzvf /var/tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz -C $MAVEN_HOME --strip-components=1 \
    && update-alternatives --install /usr/bin/mvn mvn /opt/maven/bin/mvn 10000 \
    && mkdir -p $MAVEN_CONFIG \
    # Install Gradle
    && mkdir -p $GRADLE_PATH \
    && for version in $INSTALLED_GRADLE_VERSIONS; do { \
       wget "https://services.gradle.org/distributions/gradle-$version-all.zip" -O "$GRADLE_PATH/gradle-$version-all.zip" \
       && unzip "$GRADLE_PATH/gradle-$version-all.zip" -d /usr/local \
       && echo -e "$GRADLE_DOWNLOADS_SHA256" | grep "$version" | sed "s|$version|$GRADLE_PATH/gradle-$version-all.zip|" | sha256sum -c - \
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
    && wget https://dl.bintray.com/sbt/rpm/sbt-$SBT_VERSION.rpm \
    && yum install -y sbt-$SBT_VERSION.rpm \
    && rm -fr sbt-$SBT_VERSION.rpm \
    # Cleanup
    && rm -fr /tmp/* /var/tmp/* \
    && yum clean all
#****************     END JAVA     ****************************************************

#****************     GO (latest 1.13)   **********************************************************
ENV GOLANG_DOWNLOAD_SHA256="8af8787b7c2a3c0eb3f20f872577fcb6c36098bf725c59c4923921443084c807" \
    GOPATH="/go" \
    DEP_VERSION="0.5.1" \
    DEP_BINARY="dep-linux-arm64"

RUN set -ex \
    && mkdir -p "$GOPATH/src" "$GOPATH/bin" \
    && chmod -R 777 "$GOPATH" \
    && wget "https://dl.google.com/go/go$GOLANG_VERSION.linux-arm64.tar.gz" -O /tmp/golang.tar.gz \
    && echo "$GOLANG_DOWNLOAD_SHA256 /tmp/golang.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/golang.tar.gz -C /tmp \
    && mv /tmp/go /usr/local/go13  \
    && rm -fr /tmp/* /var/tmp/* \
    && wget "https://github.com/golang/dep/releases/download/v$DEP_VERSION/$DEP_BINARY" -O "$GOPATH/bin/dep" \
    && chmod +x "$GOPATH/bin/dep"

RUN ln -s /usr/local/go13 /usr/local/go

ENV PATH="$GOPATH/bin:/usr/local/go/bin:$PATH"

#***************    GO 1.12   *************************************************

ENV GOLANG_12_DOWNLOAD_SHA256="3606dc6ce8b4a5faad81d7365714a86b3162df041a32f44568418c9efbd7f646"

RUN set -ex \
    && wget "https://dl.google.com/go/go$GOLANG_12_VERSION.linux-arm64.tar.gz" -O /tmp/golang.tar.gz \
    && echo "$GOLANG_12_DOWNLOAD_SHA256 /tmp/golang.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/golang.tar.gz -C /tmp \
    && mv /tmp/go /usr/local/go12  \
    && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

#****************     END GO     **********************************************************

# TODO Download libgit2 (no aarch version at rpmfind.net/linux/centos/7/extras)

RUN set -ex \
    && wget "https://github.com/GitTools/GitVersion/releases/download/v${GITVERSION_VERSION}/GitVersion-bin-net40-v${GITVERSION_VERSION}.zip" -O /tmp/GitVersion_${GITVERSION_VERSION}.zip \
    && mkdir -p /usr/local/GitVersion_${GITVERSION_VERSION} \
    && unzip /tmp/GitVersion_${GITVERSION_VERSION}.zip -d /usr/local/GitVersion_${GITVERSION_VERSION} \
    && rm /tmp/GitVersion_${GITVERSION_VERSION}.zip \
    && echo "mono /usr/local/GitVersion_${GITVERSION_VERSION}/GitVersion.exe \$@" >> /usr/local/bin/gitversion \
    && chmod +x /usr/local/bin/gitversion

RUN set -ex \
   && yum install -y openssl \
   && curl -o stunnel-5.55.tar.gz https://www.stunnel.org/downloads/stunnel-5.55.tar.gz \
   && tar xvfz stunnel-5.55.tar.gz \
   && cd stunnel-5.55 \
   && ./configure \
   && make \
   && make install \
   && openssl genrsa -out key.pem 2048 \
   && openssl req -new -x509 -key key.pem -out cert.pem -days 1095 -subj "/C=US/ST=Washington/L=Seattle/O=Amazon/OU=Codebuild/CN=codebuild.amazon.com" \
   && cat key.pem cert.pem >> /usr/local/etc/stunnel/stunnel.pem \
   && cd .. ; rm -rf stunnel-5.55* \
   && yum clean all

ENTRYPOINT ["dockerd-entrypoint.sh"]
