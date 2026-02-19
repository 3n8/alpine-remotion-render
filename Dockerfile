FROM 3n88/alpine-base-image:latest
LABEL maintainer="3n8"
LABEL org.opencontainers.image.source="https://github.com/3n8/alpine-remotion-render"

ARG APPNAME=alpine-remotion-render
ARG RELEASETAG=latest
ARG TARGETARCH=amd64
ARG NODE_VERSION=20

ENV HOME=/home/nobody \
    TERM=xterm \
    LANG=en_GB.UTF-8 \
    REMOTION_PORT=3003 \
    PATH=/usr/local/bin/system/scripts/docker:/usr/local/bin/run:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apk add --no-cache \
        nodejs \
        npm \
        ffmpeg \
        ffmpeg-libs \
        libva \
        libva-intel-driver \
        ca-certificates \
        curl

COPY build/common/root/supervisord.conf /etc/supervisord.conf
COPY build/common/root/init.sh /usr/bin/init.sh
COPY build/common/root/supervisor-remotion.conf /etc/supervisor/conf.d/remotion.conf

RUN chmod +x /tmp/install.sh && /tmp/install.sh; rm -f /tmp/install.sh; \
    chmod +x /usr/bin/init.sh && \
    mkdir -p /run/supervisor

RUN echo "export BASE_RELEASE_TAG=${RELEASETAG}" > /etc/image-build-info && \
    echo "export TARGETARCH=${TARGETARCH}" >> /etc/image-build-info && \
    echo "export APPNAME=${APPNAME}" >> /etc/image-build-info

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/usr/bin/init.sh"]
