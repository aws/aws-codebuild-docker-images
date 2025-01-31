#!/bin/sh
set -e

if [ "$CODEBUILD_GPU_BUILD" = "true" ]; then
  mkdir -p /etc/docker
  echo "{}" >> /etc/docker/daemon.json
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list && sudo apt-get update
  apt-get install -y nvidia-container-toolkit
  nvidia-ctk runtime configure --runtime=docker
  export NVIDIA_VISIBLE_DEVICES=all
  export NVIDIA_DRIVER_CAPABILITIES=compute,utility
fi

/usr/local/bin/dockerd \
	--host=unix:///var/run/docker.sock \
	--host=tcp://127.0.0.1:2375 \
	--storage-driver=overlay2 &>/var/log/docker.log &


tries=0
d_timeout=60
until docker info >/dev/null 2>&1
do
	if [ "$tries" -gt "$d_timeout" ]; then
                cat /var/log/docker.log
		echo 'Timed out trying to connect to internal docker host.' >&2
		exit 1
	fi
        tries=$(( $tries + 1 ))
	sleep 1
done

eval "$@"
