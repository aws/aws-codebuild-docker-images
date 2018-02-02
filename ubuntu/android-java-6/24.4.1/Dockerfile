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
       wget=1.15-* python=2.7.5-* python2.7-dev=2.7.6-* fakeroot=1.20-* ca-certificates \
       tar=1.27.1-* gzip=1.6-* zip=3.0-* autoconf=2.69-* automake=1:1.14.1-* \
       bzip2=1.0.6-* file=1:5.14-* g++=4:4.8.2-* gcc=4:4.8.2-* imagemagick=8:6.7.7.10-* \
       libbz2-dev=1.0.6-* libc6-dev=2.19-* libcurl4-openssl-dev=7.35.0-* libdb-dev=1:5.3.21~* \
       libevent-dev=2.0.21-stable-* libffi-dev=3.1~rc1+r3.0.13-* libgeoip-dev=1.6.0-* libglib2.0-dev=2.40.2-* \
       libjpeg-dev=8c-* libkrb5-dev=1.12+dfsg-* liblzma-dev=5.1.1alpha+20120614-* \
       libmagickcore-dev=8:6.7.7.10-* libmagickwand-dev=8:6.7.7.10-* libmysqlclient-dev=5.5.59-* \
       libncurses5-dev=5.9+20140118-* libpng12-dev=1.2.50-* libpq-dev=9.3.20-* libreadline-dev=6.3-* \
       libsqlite3-dev=3.8.2-* libssl-dev=1.0.1f-* libtool=2.4.2-* libwebp-dev=0.4.0-* \
       libxml2-dev=2.9.1+dfsg1-* libxslt1-dev=1.1.28-* libyaml-dev=0.1.4-* make=3.81-* \
       patch=2.7.1-* xz-utils=5.1.1alpha+20120614-* zlib1g-dev=1:1.2.8.dfsg-* unzip=6.0-* curl=7.35.0-* \
    && apt-get install -y -qq less=458-* groff=1.22.2-* \
    && apt-get -qy build-dep git=1:1.9.1 \
    && apt-get -qy install libcurl4-openssl-dev=7.35.0-* git-man=1:1.9.1-* liberror-perl=0.17-* \
    && mkdir -p /usr/src/git-openssl \
    && cd /usr/src/git-openssl \
    && apt-get source git=1:1.9.1 \
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
    && pip install awscli==1.11.157 \
    && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/* 
 

# Copy install tools
COPY tools /opt/tools

ENV ANDROID_HOME="/usr/local/android-sdk-linux" \
    JAVA_HOME="/usr/lib/jvm/java-6-oracle" \
    JDK_HOME="/usr/lib/jvm/java-6-oracle" \
    JAVA_VERSION="6" \
    INSTALLED_GRADLE_VERSIONS="2.10 2.11 2.12 2.13 2.14.1" \
    GRADLE_VERSION="2.14.1" \
    ANDROID_TOOLS_VER="24.4.1" \
    ANDROID_TOOLS_SHA1="725bb360f0f7d04eaccff5a2d57abdd49061326d"
ENV PATH="${PATH}:/opt/tools:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools" \
    JAVA_PACKAGE_VERSION="${JAVA_VERSION}u45-0~webupd8~8"

# Install java6
RUN apt-get update \
      && apt-get install -y software-properties-common \
      && add-apt-repository -y ppa:webupd8team/java \
      && (echo oracle-java$JAVA_VERSION-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections) \
      && apt-get update \
      && apt-get install -y oracle-java$JAVA_VERSION-installer=$JAVA_PACKAGE_VERSION \
      && apt-get install -y -qq less groff \
      && dpkg --add-architecture i386 \
      && apt-get update && apt-get install -y --force-yes expect libc6-i386 lib32stdc++6 lib32gcc1 lib32ncurses5 lib32z1 libqt5widgets5 \
      && apt-get clean \
# Precache most relevant versions of Gradle for `gradlew` scripts
      && mkdir -p /usr/src/gradle \
      && for version in $INSTALLED_GRADLE_VERSIONS; do {\
           wget "https://services.gradle.org/distributions/gradle-$version-all.zip" -O "/usr/src/gradle/gradle-$version-all.zip" \
           && unzip "/usr/src/gradle/gradle-$version-all.zip" -d /usr/local \
           && mkdir "/tmp/gradle-$version" \
           && "/usr/local/gradle-$version/bin/gradle" -p "/tmp/gradle-$version" wrapper \
           # Android Studio uses the "-all" distribution for it's wrapper script.
           && perl -pi -e "s/gradle-$version-bin.zip/gradle-$version-all.zip/" "/tmp/gradle-$version/gradle/wrapper/gradle-wrapper.properties" \
           && "/tmp/gradle-$version/gradlew" -p "/tmp/gradle-$version" init \
           && rm -rf "/tmp/gradle-$version" \
           && if [ "$version" != "$GRADLE_VERSION" ]; then rm -rf "/usr/local/gradle-$version"; fi; \
         }; done \
# Install default GRADLE_VERSION to path
      && ln -s /usr/local/gradle-$GRADLE_VERSION/bin/gradle /usr/bin/gradle \
      && rm -rf /usr/src/gradle \
# Install Android SDK
      && wget "http://dl.google.com/android/android-sdk_r$ANDROID_TOOLS_VER-linux.tgz" -O /tmp/android-sdk.tgz \
      && echo "${ANDROID_TOOLS_SHA1} /tmp/android-sdk.tgz" | sha1sum -c - \
      && tar -xzf /tmp/android-sdk.tgz -C /usr/local/ \
      && chown -R root.root $ANDROID_HOME \
      && ln -s $ANDROID_HOME/tools/android /usr/bin/android \
      && /opt/tools/android-accept-licenses.sh "android update sdk --all --no-ui --filter platform-tools,build-tools-25.0.0,build-tools-23.0.3,android-23,android-25" \
      && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*
