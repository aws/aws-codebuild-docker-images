# Copyright 2017-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use this file except in compliance with the License.
# A copy of the License is located at
#
#    http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.
#

FROM ubuntu:14.04.5

# Building git from source code:
#   Ubuntu's default git package is built with broken gnutls. Rebuild git with openssl.
##########################################################################
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       wget python python2.7-dev fakeroot ca-certificates tar gzip zip \
       autoconf automake bzip2 file g++ gcc imagemagick libbz2-dev libc6-dev libcurl4-openssl-dev \
       libdb-dev libevent-dev libffi-dev libgeoip-dev libglib2.0-dev libjpeg-dev libkrb5-dev \
       liblzma-dev libmagickcore-dev libmagickwand-dev libmysqlclient-dev libncurses-dev libpng-dev \
       libpq-dev libreadline-dev libsqlite3-dev libssl-dev libtool libwebp-dev libxml2-dev libxslt-dev \
       libyaml-dev make patch xz-utils zlib1g-dev unzip curl \
    && apt-get -qy build-dep git \
    && apt-get -qy install libcurl4-openssl-dev git-man liberror-perl \
    && mkdir -p /usr/src/git-openssl \
    && cd /usr/src/git-openssl \
    && apt-get source git \
    && cd $(find -mindepth 1 -maxdepth 1 -type d -name "git-*") \
    && sed -i -- 's/libcurl4-gnutls-dev/libcurl4-openssl-dev/' ./debian/control \
    && sed -i -- '/TEST\s*=\s*test/d' ./debian/rules \
    && dpkg-buildpackage -rfakeroot -b \
    && find .. -type f -name "git_*ubuntu*.deb" -exec dpkg -i \{\} \; \
    && rm -rf /usr/src/git-openssl \
# Install dependencies by all python images equivalent to buildpack-deps:jessie
# on the public repos.
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

RUN wget "https://bootstrap.pypa.io/get-pip.py" -O /tmp/get-pip.py \
    && python /tmp/get-pip.py \
    && pip install awscli==1.11.25 \
    && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/* 
 

ENV RUBY_MAJOR="2.2" \
    RUBY_VERSION="2.2.5" \
    RUBY_DOWNLOAD_SHA256="30c4b31697a4ca4ea0c8db8ad30cf45e6690a0f09687e5d483c933c03ca335e3" \
    RUBYGEMS_VERSION="2.6.7" \
	BUNDLER_VERSION="1.13.5" \
    GEM_HOME="/usr/local/bundle"

ENV BUNDLE_PATH="$GEM_HOME" \
    BUNDLE_BIN="$GEM_HOME/bin" \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    BUNDLE_APP_CONFIG="$GEM_HOME"

ENV PATH $BUNDLE_BIN:$PATH

RUN mkdir -p /usr/local/etc \
	&& { \
        echo 'install: --no-document'; \
        echo 'update: --no-document'; \
    } >> /usr/local/etc/gemrc \
    && apt-get update && apt-get install -y --no-install-recommends \
       bison libgdbm-dev ruby \
    && wget "https://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.gz" -O /tmp/ruby.tar.gz \
    && echo "$RUBY_DOWNLOAD_SHA256 /tmp/ruby.tar.gz" | sha256sum -c - \
    && mkdir -p /usr/src/ruby \
    && tar -xzf /tmp/ruby.tar.gz -C /usr/src/ruby --strip-components=1 \
    && cd /usr/src/ruby \
	&& { \
             echo '#define ENABLE_PATH_CHECK 0'; \
             echo; \
             cat file.c; \
	   } > file.c.new \
    && mv file.c.new file.c \
    && autoconf \
    && ./configure --disable-install-doc \
    && make -j"$(nproc)" \
    && make install \
    && apt-get purge -y --auto-remove bison libgdbm-dev ruby \
    && cd / \
    && rm -r /usr/src/ruby \
    && gem update --system "$RUBYGEMS_VERSION" \
	&& gem install bundler --version "$BUNDLER_VERSION" \
    && mkdir -p "$GEM_HOME" "$BUNDLE_BIN" \
    && chmod 777 "$GEM_HOME" "$BUNDLE_BIN" \
    && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

CMD [ "irb" ]
