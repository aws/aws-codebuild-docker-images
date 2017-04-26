#!/bin/sh
set -e

/usr/local/bin/dind docker daemon \
	--host=unix:///var/run/docker.sock \
	--host=tcp://0.0.0.0:2375 \
	--storage-driver=overlay &>/var/log/docker.log &

d_timeout=$(( 60 + SECONDS ))
until docker info >/dev/null 2>&1
do
	if (( SECONDS >= d_timeout )); then
		echo 'Timed out trying to connect to internal docker host.' >&2
		exit 1
	fi
	sleep 1
done

eval "$@"
