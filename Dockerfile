FROM golang:1.14.4-alpine3.12@sha256:9887985d9de3d1c2a37be9e2e9c6dbc44f4cbcc7afe3d564cf6c3916a58b1a5c AS builder

# renovate: datasource=github-tags depName=gohugoio/hugo
ENV HUGO_VERSION="v0.72.0"

# renovate: datasource=repology depName=alpine_3_12/git
ENV GIT_VERSION="2.26.2-r0"

WORKDIR /build/src
RUN true \
    # Install build dependencies
    && apk add --no-cache --virtual .build-deps \
        git="${GIT_VERSION}" \
    # Build oauth2-proxy from sources
    && git clone --depth 1 -b "${HUGO_VERSION}" https://github.com/gohugoio/hugo.git . \
    && CGO_ENABLED=0 go build -ldflags="-s -w" -o /build/bin/hugo . \
    # Uninstall build dependencies
    && apk del --purge --no-cache .build-deps \
    && true

FROM snapserv/alpine:3.12.0-2@sha256:9426bbc54182af01d57423efab92ae00c1e105d6ef999909b7519b0f67b05b62

RUN true \
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
