FROM aws/codebuild/ubuntu-base:16.04

# install Docker - from official page https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/#set-up-the-repository
RUN readonly __docker_required_packages=" \
      apt-transport-https=1.2.24* \
      dh-python=2.20* \
      distro-info-data=0.28* \
      gir1.2-glib-2.0=1.46.0-* \
      iso-codes=3.65-* \
      libapt-inst2.0=1.2.24* \
      libdbus-1-3=1.10.6-* \
      libdbus-glib-1-2=0.106-* \
      libgirepository-1.0-1=1.46.0-* \
      libglib2.0-0=2.48.2-* \
      libmpdec2=2.4.2-* \
      libpython3.5-minimal=3.5.2-* \
      libpython3.5-stdlib=3.5.2-* \
      lsb-release=9.20* \
      python-apt-common=1.1.0* \
      python-apt=1.1.0* \
      python3-dbus=1.2.0-* \
      python3-gi=3.20.0-* \
      python3-pycurl=7.43.0-* \
      python3-software-properties=0.96.20.7* \
      python3.5-minimal=3.5.2-* \
      software-properties-common=0.96.20.7* \
      software-properties-common=0.96.20* \
    " \
    && apt-get update \
    && apt-get install --no-install-recommends \
                       --assume-yes \
                        ${__docker_required_packages} \
    && curl --show-error \
            --location \
              https://download.docker.com/linux/ubuntu/gpg \
       | apt-key add - \
    && apt-key fingerprint 0EBFCD88 \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    && readonly __docker_packages=" \
      docker-ce=17.12.0* \
      iptables=1.6.0-* \
      libltdl7=2.4.6-* \
      libnfnetlink0=1.0.1-* \
      libxtables11=1.6.0-* \
    " \
    && apt-get update \
    && apt-get install --no-install-recommends \
                       --assume-yes \
                        ${__docker_packages} \
# clean up apt cache to make Docker image slimmer
    && apt-get clean \
# install Docker compose - from official page https://docs.docker.com/compose/install/#install-compose
    && readonly __docker_compose_version="1.18.0" \
    && curl --show-error \
            --location \
              https://github.com/docker/compose/releases/download/${__docker_compose_version}/docker-compose-$(uname -s)-$(uname -m) \
            --output \
              /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose \
# print versions
    && aws --version \
    && docker --version \
    && docker-compose --version \
    && git --version \
    && perl --version \
    && pip --version \
    && python --version
