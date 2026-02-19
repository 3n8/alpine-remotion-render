# Alpine Remotion Render

A lightweight Alpine-based Docker image for server-side video rendering using Remotion and FFmpeg with GPU acceleration support.

## Features

- **Alpine Linux** - Lightweight base
- **Node.js** - Latest LTS
- **FFmpeg** - With VAAPI support for hardware acceleration
- **GPU Support** - VAAPI for AMD, Intel, and NVIDIA GPUs
- **Supervisor** - Process management with logging
- **User/Group Mapping** - Run as any UID:GID via docker-compose user: directive

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `UMASK` | 000 | File permissions mask |
| `TZ` | UTC | Timezone (e.g., Europe/London, America/New_York) |

The `user:` directive in docker-compose handles UID/GID - no environment variables needed.

## Volumes

| Volume | Description |
|--------|-------------|
| `/config` | Persistent data (projects, renders, compositions, logs) |

All Remotion data is stored under `/config`:
- `/config/projects` - Remotion project files
- `/config/renders` - Rendered output videos
- `/config/compositions` - Composition definitions
- `/config/remotion` - Remotion configuration
- `/config/supervisord.log` - Container logs

## GPU Support

This image supports hardware-accelerated encoding via VAAPI. The GPU drivers come from the **Docker host**, not the container.

### Supported GPUs

- **AMD** - RX 7800 XT, RDNA/RDNA2/RDNA3 architectures
- **Intel** - Quick Sync Video (QSV) integrated GPUs
- **NVIDIA** - Via VDPAU (limited) or NVENC (requires nvidia-container-toolkit)

### Docker Compose with GPU

```yaml
services:
  remotion-render:
    image: 3n88/alpine-remotion-render:latest
    container_name: remotion-render
    restart: always
    user: "${PUID}:${PGID}"
    devices:
      - /dev/dri:/dev/dri
    environment:
      - UMASK=${UMASK}
      - TZ=${TZ}
    volumes:
      - ${DOCKER_HOME}/remotion-render:/config
```

### Checking GPU Availability

The container logs will show:
- DRI devices found (if GPU passthrough is enabled)
- VAAPI driver info

### Running Remotion Commands

```bash
# Enter the container
docker exec -it remotion-render /bin/bash

# Check FFmpeg with VAAPI
ffmpeg -hide_banner -encoders | grep vaapi

# Render a composition
npx remotion render --input-dir=/config/projects --output=/config/renders MyComposition
```

## Configuration

On first run, a default `config.json` is created in `/config/remotion/`:

```json
{
  "outDir": "/config/renders",
  "projectDir": "/config/projects",
  "compositionDir": "/config/compositions",
  "ffmpegBinary": "/usr/bin/ffmpeg",
  "ffprobeBinary": "/usr/bin/ffprobe"
}
```

If this file already exists, it will not be overwritten.

## Building

```bash
docker build -t 3n88/alpine-remotion-render:latest .
```

## Image Details

- **Base**: 3n88/alpine-base-image
- **Size**: ~460MB
- **Node.js**: Latest LTS
- **FFmpeg**: 8.x with VAAPI
