# Alpine Remotion Render

A lightweight Alpine-based Docker image for server-side video rendering using Remotion and FFmpeg with GPU acceleration support.

## Features

- **Alpine Linux** - Lightweight base
- **Node.js** - Latest LTS
- **FFmpeg** - With VAAPI support for hardware acceleration
- **GPU Support** - VAAPI for AMD, Intel, and NVIDIA GPUs
- **Supervisor** - Process management with logging
- **User/Group Mapping** - Run as any UID:GID via docker-compose user: directive

## What is this?

This container provides a Node.js + FFmpeg environment for rendering videos using Remotion. It runs as an API server - clients on your LAN send HTTP requests to trigger renders, and the rendered video is returned in the response or saved to a mounted path.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `UMASK` | 000 | File permissions mask |
| `TZ` | UTC | Timezone (e.g., Europe/London, America/New_York) |

The `user:` directive in docker-compose handles UID/GID - no environment variables needed.

## Volumes

| Volume | Description |
|--------|-------------|
| `/config` | Persistent data (logs, configs) |

## GPU Support

This image supports hardware-accelerated encoding via VAAPI. The GPU drivers come from the **Docker host**, not the container.

### Host Requirements

**AMD GPUs:**
- `amdgpu` kernel module loaded
- `/dev/dri` device available
- Mesa drivers installed

**Intel GPUs:**
- `i915` kernel module loaded
- `/dev/dri` device available

**NVIDIA GPUs:**
- `nvidia-container-toolkit` installed
- `nvidia-smi` works on host

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

## API Usage

This container runs a Remotion render server. To render videos, your client applications make HTTP requests to the server.

### Basic Workflow

1. Start the container with your Remotion project mounted
2. Your application sends render requests to the server
3. The server renders the video using FFmpeg with GPU acceleration
4. The rendered video is returned in the response or saved to a path

### Testing the API

```bash
# List available compositions
curl http://localhost:8000/

# Render a composition (depends on your project setup)
curl -X POST http://localhost:8000/render \
  -H "Content-Type: application/json" \
  -d '{"compositionId": "MyComposition", "codec": "h264"}'
```

### Custom Render Script

Mount a custom render script in your project and call it via the API. The script uses `@remotion/renderer` to render videos:

```javascript
import {renderMedia} from '@remotion/renderer';

await renderMedia({
  codec: 'h264',
  composition,
  serveUrl: yourBundledProject,
  outputLocation: 'path/to/output.mp4',
});
```

## Building

```bash
docker build -t 3n88/alpine-remotion-render:latest .
```

## Image Details

- **Base**: 3n88/alpine-base-image
- **Size**: ~460MB
- **Node.js**: Latest LTS
- **FFmpeg**: 8.x with VAAPI
