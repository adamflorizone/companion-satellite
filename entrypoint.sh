#!/bin/bash
set -Eeuo pipefail

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
                echo restarting node... node /app/satellite/dist/main.js
                pkill --full "node /app/satellite/dist/main.js"
            fi 
        done
    done
} &

# allow config to be created
chown "${DOCKER_USER:-node}:${DOCKER_USER:-node}" /config 

# Run this is user
gosu "${DOCKER_USER:-node}" bash -c "id; while true; do $*; sleep 0.1; done"