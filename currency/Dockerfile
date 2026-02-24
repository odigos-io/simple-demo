# --- Runtime image: matches original Dockerfile (PHP-FPM only; nginx runs in separate container in k8s) ---
FROM php:8.2.29-fpm AS app
WORKDIR /app
COPY . /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    zip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install pcntl

RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    composer install

EXPOSE 9000
CMD ["php-fpm"]

# --- Package stage: copy app from app image, run nfpm (one arch per image via TARGETARCH) ---
FROM golang:1.22-alpine AS nfpm-build
RUN go install github.com/goreleaser/nfpm/v2/cmd/nfpm@v2.34.0

FROM alpine:3.18 AS package
COPY --from=nfpm-build /go/bin/nfpm /usr/local/bin/nfpm
WORKDIR /workspace
COPY distribution ./distribution
COPY nfpm.yaml ./
RUN mkdir -p dist/app /packages
COPY --from=app /app dist/app/
ARG TARGETARCH
ARG VERSION=dev
ENV TARGETARCH=$TARGETARCH
ENV VERSION=$VERSION
RUN nfpm pkg --packager rpm --target /packages && nfpm pkg --packager deb --target /packages
CMD ["true"]
