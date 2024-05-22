#!/bin/bash
set -Eeuo pipefail

# all config to be created!
chown node:node /config 

# service udev start
# gosu "node" "$@"
cat << EOF > "/app/docker-env-companion-satellite.json"
{
    "remoteIp": "${COMPANION_REMOTEIP:-127.0.0.1}",
    "remotePort": ${COMPANION_REMOTEPORT:-16622},
    "restEnabled": ${COMPANION_RESTENABLED:-true},
    "restPort": ${COMPANION_RESTPORT:-9999}
}
EOF

echo "${COMPANION_REMOTEIP:-127.0.0.1}" 
cat "${COMPANION_PATH_CONFIG}"

# Run this as container root:
{
    while true; do
        ln -sf /dev/hostdev/hidraw* /dev
        inotifywait -e create /dev/hostdev 2>/dev/null |
        while read -r directory event filename; do
            echo inotifywait: "${directory} ${event} ${filename}"
            ln -sf "${directory}/${filename}" /dev

            if [[ "$filename" == hidraw* ]]; then
                # This is a quick hack for non udev docker!
                echo restarting node...
                killall node
            fi
        done
    done
} &

# Run this is user
gosu "${DOCKER_USER:-node}" bash -c "while true; do $*; done"