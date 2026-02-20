ARG ALPINE=3.23.3
ARG XRAY=v26.2.6
ARG T2S=v2.6.0

FROM alpine:${ALPINE}
LABEL org.opencontainers.image.authors="Axl <https://github.com/ADKix>"
RUN apk add -U --no-cache 7zip iproute2-minimal
ARG XRAY
ARG T2S
ARG TARGETPLATFORM
WORKDIR "/opt"
RUN if   [ "${TARGETPLATFORM}" = "linux/arm64" ] || [ "${TARGETPLATFORM}" = "linux/arm64/v8" ]; then arch=arm64-v8a; \
    elif [ "${TARGETPLATFORM}" = "linux/arm/v7" ]; then arch=arm32-v7a; \
    elif [ "${TARGETPLATFORM}" = "linux/386" ]; then arch=32; \
    elif [ "${TARGETPLATFORM}" = "linux/amd64" ]; then arch=64; fi; \
    wget -qnc "https://github.com/XTLS/Xray-core/releases/download/${XRAY}/Xray-linux-${arch}.zip" -O- | \
      unzip -p - "xray" | \
        7z -si a "xray.7z"
RUN if   [ "${TARGETPLATFORM}" = "linux/arm64" ] || [ "${TARGETPLATFORM}" = "linux/arm64/v8" ]; then arch=arm64; \
    elif [ "${TARGETPLATFORM}" = "linux/arm/v7" ]; then arch=armv7; \
    elif [ "${TARGETPLATFORM}" = "linux/386" ]; then arch=386; \
    elif [ "${TARGETPLATFORM}" = "linux/amd64" ]; then arch=amd64; fi; \
    wget -qnc "https://github.com/xjasonlyu/tun2socks/releases/download/${T2S}/tun2socks-linux-${arch}.zip" -O- | \
      unzip -p - "tun2socks-linux-${arch}" | \
        7z -si a "tun2socks.7z"
COPY "entrypoint.sh" "command.sh" /
ENTRYPOINT ["sh", "/entrypoint.sh"]
CMD ["sh", "/command.sh"]
ENV PORT=443
ENV SNI=google.com
EXPOSE 1080
