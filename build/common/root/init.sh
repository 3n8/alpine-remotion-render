#!/bin/bash

set -e

exec 3>&1 4>&2 &> >(tee -a /config/supervisord.log)

source '/usr/local/bin/system/scripts/docker/utils.sh'

cat << "EOF"
Remotion Render Node
 _ __      _             _ 
| '_|____| |___  ___   | |
| |/ __| / _ \/ _ \   |_|
|_|\__|_|\___/\___/   (_)
EOF

source '/etc/image-build-info'

if [[ -z "${TZ}" ]]; then
    export TZ="UTC"
fi

if [[ -f "/usr/share/zoneinfo/${TZ}" ]]; then
    ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime 2>/dev/null || true
fi

echo "[info] Timezone set to '${TZ}'" | ts '%Y-%m-%d %H:%M:%.S'

echo "[info] System information: $(uname -a)" | ts '%Y-%m-%d %H:%M:%.S'
echo "[info] Image architecture: '${TARGETARCH}'" | ts '%Y-%m-%d %H:%M:%.S'
echo "[info] Base image: '${BASE_RELEASE_TAG}'" | ts '%Y-%m-%d %H:%M:%.S'
echo "[info] Application: '${APPNAME}'" | ts '%Y-%m-%d %H:%M:%.S'

export PUID=$(id -u)
export PGID=$(id -g)

echo "[info] Running as UID='${PUID}', GID='${PGID}'" | ts '%Y-%m-%d %H:%M:%.S'

sed -i 's/^passwd:.*/passwd: files/' /etc/nsswitch.conf 2>/dev/null || true
sed -i 's/^group:.*/group: files/' /etc/nsswitch.conf 2>/dev/null || true

current_uid=$(id -u nobody 2>/dev/null || echo "99999")
if [[ "${current_uid}" != "${PUID}" ]]; then
    echo "[info] Executing usermod to match UID '${PUID}'..." | ts '%Y-%m-%d %H:%M:%.S'
    usermod -o -u "${PUID}" nobody 2>/dev/null || true
    echo "[info] usermod completed" | ts '%Y-%m-%d %H:%M:%.S'
fi

current_gid=$(getent group users 2>/dev/null | cut -d: -f3 || echo "100")
if [[ "${current_gid}" != "${PGID}" ]]; then
    echo "[info] Executing groupmod to match GID '${PGID}'..." | ts '%Y-%m-%d %H:%M:%.S'
    groupmod -o -g "${PGID}" users 2>/dev/null || true
    echo "[info] groupmod completed" | ts '%Y-%m-%d %H:%M:%.S'
fi

if [[ ! -z "${UMASK}" ]]; then
    echo "[info] UMASK defined as '${UMASK}'" | ts '%Y-%m-%d %H:%M:%.S'
else
    echo "[warn] UMASK not defined (via -e UMASK), defaulting to '000'" | ts '%Y-%m-%d %H:%M:%.S'
    export UMASK="000"
fi

if [[ ! -f "/config/perms.txt" ]]; then
    for dir in /config/projects /config/renders /config/compositions /config; do
        if [[ -d "${dir}" ]]; then
            set +e
            chown -R "${PUID}":"${PGID}" "${dir}" 2>/dev/null
            chmod -R 775 "${dir}" 2>/dev/null
            set -e
        fi
    done
    echo "Permissions set" > /config/perms.txt 2>/dev/null || true
fi

echo "[info] GPU support:" | ts '%Y-%m-%d %H:%M:%.S'
if [[ -d "/dev/dri" ]]; then
    echo "[info] DRI devices found:" | ts '%Y-%m-%d %H:%M:%.S'
    ls -la /dev/dri/ 2>/dev/null | ts '%Y-%m-%d %H:%M:%.S' || true
else
    echo "[info] No DRI devices found (GPU passthrough not enabled)" | ts '%Y-%m-%d %H:%M:%.S'
fi

echo "[info] Checking VAAPI..." | ts '%Y-%m-%d %H:%M:%.S'
vainfo 2>/dev/null | ts '%Y-%m-%d %H:%M:%.S' || echo "[info] vainfo not available" | ts '%Y-%m-%d %H:%M:%.S'

echo "[info] Setting up Remotion directories..." | ts '%Y-%m-%d %H:%M:%.S'
mkdir -p /config/projects
mkdir -p /config/renders
mkdir -p /config/compositions
mkdir -p /config/remotion

if [[ ! -f /config/remotion/config.json ]]; then
    echo "[info] Creating default Remotion config..." | ts '%Y-%m-%d %H:%M:%.S'
    cat > /config/remotion/config.json << 'EOF'
{
  "outDir": "/config/renders",
  "projectDir": "/config/projects",
  "compositionDir": "/config/compositions",
  "ffmpegBinary": "/usr/bin/ffmpeg",
  "ffprobeBinary": "/usr/bin/ffprobe"
}
EOF
else
    echo "[info] Remotion config already exists, skipping..." | ts '%Y-%m-%d %H:%M:%.S'
fi

echo "[info] Starting Supervisor as user 'nobody'..." | ts '%Y-%m-%d %H:%M:%.S'

exec 1>&3 2>&4

exec /usr/bin/gosu nobody /usr/bin/supervisord -c /etc/supervisord.conf -n
