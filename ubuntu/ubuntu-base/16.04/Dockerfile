FROM ubuntu:xenial-20180123

# defines root user, to perform privileged operations
USER root

# upgrade Ubuntu packages, install security updates and additional packages
RUN readonly __packages=" \
      ca-certificates \
      curl=7.47.0* \
      git=1:2.7.4* \
      less=481* \
      libasn1-8-heimdal=1.7* \
      libcurl3-gnutls=7.47.0* \
      liberror-perl=0.17* \
      libexpat1=2.1.0* \
      libffi6=3.2.1* \
      libgdbm3=1.8.3* \
      libgmp10=2:6.1.0* \
      libgnutls30=3.4.10* \
      libgssapi-krb5-2=1.13.2* \
      libgssapi3-heimdal=1.7* \
      libhcrypto4-heimdal=1.7* \
      libheimbase1-heimdal=1.7* \
      libheimntlm0-heimdal=1.7* \
      libhogweed4=3.2* \
      libhx509-5-heimdal=1.7* \
      libidn11=1.32* \
      libk5crypto3=1.13.2* \
      libkeyutils1=1.5.9* \
      libkrb5-26-heimdal=1.7* \
      libkrb5-3=1.13.2* \
      libkrb5support0=1.13.2* \
      libldap-2.4-2=2.4.42* \
      libnettle6=3.2* \
      libp11-kit0=0.23.2* \
      libperl5.22=5.22.1* \
      libpython-stdlib=2.7.11* \
      libpython2.7-minimal=2.7.12* \
      libpython2.7-stdlib=2.7.12* \
      libroken18-heimdal=1.7* \
      librtmp1=2.4* \
      libsasl2-2=2.1.26* \
      libsasl2-modules-db=2.1.26* \
      libsqlite3-0=3.11.0* \
      libssl1.0.0=1.0.2* \
      libtasn1-6=4.7* \
      libwind0-heimdal=1.7* \
      mime-support=3.59ubuntu1* \
      openssl=1.0.2* \
      perl-modules-5.22=5.22.1* \
      perl=5.22.1* \
      python2.7-minimal=2.7.12* \
      python-pip=8.1.1-* \
      unzip=6.0* \
      wget=1.17.1* \
      zip=3.0* \
    " \
    && apt-get update \
    && apt-get upgrade --assume-yes \
    && apt-get install --no-install-recommends \
                        --assume-yes \
                        ${__packages} \
# clean up apt cache to make Docker image slimmer
    && apt-get clean \
# upgrade Python pip
    && pip install --no-cache-dir \
            pip==9.0.1 \
            setuptools==38.4.0 \
# install AWS CLI
    && readonly __python_packages="\
      awscli==1.14.30 \
      botocore==1.8.34 \
      colorama==0.3.7 \
      docutils==0.14 \
      futures==3.2.0 \
      jmespath==0.9.3 \
      pyasn1==0.4.2 \
      python-dateutil==2.6.1 \
      PyYAML==3.12 \
      rsa==3.4.2 \
      s3transfer==0.1.12 \
      six==1.11.0 \
    " \
    && pip install --no-cache-dir ${__python_packages} \
# print versions
    && git --version \
    && python --version \
    && aws --version \
    && perl --version
