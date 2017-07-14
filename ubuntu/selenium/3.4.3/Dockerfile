FROM codebuild/python-3.6.1:latest

USER root

#========================
# Miscellaneous packages
# Includes minimal runtime used for executing non GUI Java programs
#========================
RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    tzdata \
    sudo \
    unzip \
    wget \
    xvfb \
    xserver-xephyr \
    vnc4server \
    libc6 \
    awscli\
    scrot\
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*


#===================
# Timezone settings
# Possible alternative: https://github.com/docker/docker/issues/3359#issuecomment-32150214
#===================
#ENV TZ "PST"
#RUN echo "${TZ}" > /etc/timezone \
#  && dpkg-reconfigure --frontend noninteractive tzdata


#==================
# Chrome webdriver
#==================
#https://chromedriver.storage.googleapis.com/2.29/chromedriver_linux64.zip

ARG CHROME_DRIVER_VERSION=2.29
RUN rm -rf /opt/selenium/chromedriver \
  && wget --no-verbose -P /tmp https://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip

RUN unzip /tmp/chromedriver_linux64.zip -d /opt/selenium \
  && rm /tmp/chromedriver_linux64.zip \
  && mv /opt/selenium/chromedriver /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION \
  && chmod 755 /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION \
  && ln -fs /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION /usr/bin/chromedriver

#=====
# VNC
#=====
#RUN apt-get update -qqy \
#  && apt-get -qqy install \
#  x11vnc \
#  && rm -rf /var/lib/apt/lists/* /var/cache/apt/* \
#  && mkdir -p /root/.vnc \
#  && x11vnc -storepasswd secret ~/.vnc/passwd

#=========
# fluxbox
# A fast, lightweight and responsive window manager
#=========
#RUN apt-get update -qqy \
#  && apt-get -qqy install \
#    fluxbox \
#  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#============================================
# Google Chrome
#============================================
ARG CHROME_VERSION="google-chrome-stable"
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update -qqy \
  && apt-get -qqy install \
    ${CHROME_VERSION:-google-chrome-stable} \
  && rm /etc/apt/sources.list.d/google-chrome.list \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

ENV DISPLAY=:0.0

# Following line fixes https://github.com/SeleniumHQ/docker-selenium/issues/87
ENV DBUS_SESSION_BUS_ADDRESS=/dev/null

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

ONBUILD COPY requirements.txt /usr/src/app/
ONBUILD RUN pip install --no-cache-dir -r requirements.txt
ONBUILD COPY . /usr/src/app

#EXPOSE 5900
