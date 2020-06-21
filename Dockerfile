FROM golang:1.14.4-alpine3.12@sha256:9887985d9de3d1c2a37be9e2e9c6dbc44f4cbcc7afe3d564cf6c3916a58b1a5c AS builder

# renovate: datasource=github-tags depName=gohugoio/hugo
ENV HUGO_VERSION="v0.72.0"

# renovate: datasource=repology depName=alpine_3_12/gcc
ENV GCC_VERSION="9.3.0-r2"
# renovate: datasource=repology depName=alpine_3_12/git
ENV GIT_VERSION="2.26.2-r0"
# renovate: datasource=repology depName=alpine_3_12/g++
ENV GPP_VERSION="9.3.0-r2"
# renovate: datasource=repology depName=alpine_3_12/musl-dev
ENV MUSL_DEV_VERSION="1.1.24-r9"

WORKDIR /build/src
RUN true \
    # Install build dependencies
    && apk add --no-cache --virtual .build-deps \
        gcc="${GCC_VERSION}" \
        git="${GIT_VERSION}" \
        g++="${GPP_VERSION}" \
        musl-dev="${MUSL_DEV_VERSION}" \
    # Build hugo from sources
    # We need to use cgo for building the extended version
    && git clone --depth 1 -b "${HUGO_VERSION}" https://github.com/gohugoio/hugo.git . \
    && CGO_ENABLED=1 go build -ldflags="-s -w" -o /build/bin/hugo --tags extended . \
    # Uninstall build dependencies
    && apk del --purge --no-cache .build-deps \
    && true

FROM snapserv/alpine:3.12.0-4@sha256:314d13b1784f96d74684dcfbd5107feef4ade85cd9940fbc0eeda94fe630ba6b

# renovate: datasource=repology depName=alpine_3_12/libstdc++
ENV LIBSTDCPP_VERSION="9.3.0-r2"

RUN true \
    # Install runtime dependencies
    && apk add --no-cache \
        libstdc++="${LIBSTDCPP_VERSION}" \
    # Prepare container runtime environment
    && ctutil account -u 2000 -g 2000 hugo \
    && ctutil directory -u hugo -g hugo -m 0700 \
        /cts/hugo/persistent \
    && true

COPY --from=builder /build/bin/hugo /usr/local/bin/hugo
COPY rootfs /
RUN chmod 0755 /docker-entrypoint.sh

USER 2000
EXPOSE 1313/tcp
VOLUME [ "/cts/hugo/persistent" ]

WORKDIR /cts/hugo/persistent
ENTRYPOINT [ "/docker-entrypoint.sh" ]
