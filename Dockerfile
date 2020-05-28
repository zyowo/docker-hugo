FROM golang:1.14-alpine@sha256:c11dac79f0b25f3f3188429f8dd37cb6004021624b42085f745cb907ca1560a9 AS builder

# renovate: datasource=github-tags depName=gohugoio/hugo
ENV HUGO_VERSION="v0.71.1"

# TODO: Integrate with Renovate once available as datasource
ENV GIT_VERSION="2.24.3-r0"

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

FROM snapserv/alpine:3.11.6-7@sha256:44833d07cc7746282f2d18a3b9b317455aa4ca1ac32d743350ad81ead6d52e9e

RUN true \
    # Prepare container runtime environment
    && ctutil account -u 2000 -g 2000 hugo \
    && ctutil directory -u hugo -g hugo -m 0700 \
        /cts/hugo/persistent/data \
    && true

COPY --from=builder /build/bin/hugo /usr/local/bin/hugo
COPY rootfs /
RUN chmod 0755 /docker-entrypoint.sh

USER 2000
EXPOSE 1313/tcp
VOLUME [ "/cts/hugo/persistent" ]

WORKDIR /cts/hugo/persistent/data
ENTRYPOINT [ "/docker-entrypoint.sh" ]
