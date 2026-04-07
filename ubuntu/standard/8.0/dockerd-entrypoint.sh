#!/bin/sh
set -e

if [ "$CODEBUILD_GPU_BUILD" = "true" ]; then
  mkdir -p /etc/docker
  echo "{}" >> /etc/docker/daemon.json
  echo "[nvidia-setup] Installing nvidia-container-toolkit" >&2
  curl -fsSL --retry 3 --connect-timeout 10 --max-time 30 https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && curl -fSL --retry 3 --connect-timeout 10 --max-time 30 https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list && sudo apt-get update
  apt-get install -y nvidia-container-toolkit
  echo "[nvidia-setup] nvidia-container-toolkit installed successfully" >&2
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
		echo '[EntryScript] Docker daemon failed to start within '"$d_timeout"' seconds. Dumping docker logs...' >&2
		cat /var/log/docker.log
		if [ "$DOCKER_RETRY_ATTEMPTED" = "1" ]; then
			echo '[EntryScript] This is the second attempt (DOCKER_RETRY_ATTEMPTED=1). Retry already exhausted. Exiting with status 1.' >&2
			echo 'Timed out trying to connect to internal docker host.' >&2
			exit 1
		fi
		echo '[EntryScript] First attempt failed. Beginning cleanup before retry...' >&2
		echo '[EntryScript] Sending SIGKILL to dockerd and containerd processes...' >&2
		pkill -9 dockerd 2>/dev/null || true
		pkill -9 containerd 2>/dev/null || true
		echo '[EntryScript] Finished killing dockerd/containerd processes.' >&2
		echo '[EntryScript] Removing BoltDB directories to clear potentially corrupted metadata...' >&2
		rm -rf /var/lib/containerd/io.containerd.metadata.v1.bolt/ 2>/dev/null || true
		rm -rf /var/lib/docker/containerd/daemon/io.containerd.metadata.v1.bolt/ 2>/dev/null || true
		echo '[EntryScript] BoltDB directory cleanup complete.' >&2
		sleep 2
		export DOCKER_RETRY_ATTEMPTED=1
		echo '[EntryScript] Re-executing entrypoint for retry attempt (DOCKER_RETRY_ATTEMPTED=1)...' >&2
		exec "$0" "$@"
	fi
        tries=$(( $tries + 1 ))
	sleep 1
done

eval "$@"
