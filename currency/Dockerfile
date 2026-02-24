# --- Build nfpm binary (for package stage) ---
FROM golang:1.22-alpine AS nfpm-build
RUN go install github.com/goreleaser/nfpm/v2/cmd/nfpm@v2.34.0

# --- Build (PHP app + composer) ---
FROM php:8.2.29-fpm AS builder
WORKDIR /workspace
COPY . .
RUN apt-get update && apt-get install -y --no-install-recommends git curl zip unzip \
    && rm -rf /var/lib/apt/lists/*
RUN docker-php-ext-install pcntl
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    composer install
# Payload dir: only app files (excludes distribution/, nfpm.yaml, Dockerfile, etc.)
RUN mkdir -p /workspace/payload && \
    cp composer.json composer.lock /workspace/payload/ && \
    cp *.php /workspace/payload/ 2>/dev/null || true && \
    cp -r vendor /workspace/payload/

# --- Runtime image: PHP-FPM only (nginx runs in separate container in k8s) ---
FROM php:8.2.29-fpm AS app
WORKDIR /app
COPY --from=builder /workspace/payload /app
EXPOSE 9000
CMD ["php-fpm"]

# --- Package stage: copy app from builder, run nfpm (one arch per image via TARGETARCH) ---
FROM alpine:3.18 AS package
COPY --from=nfpm-build /go/bin/nfpm /usr/local/bin/nfpm
WORKDIR /workspace
COPY distribution ./distribution
COPY nfpm.yaml ./
RUN mkdir -p dist/app /packages
COPY --from=builder /workspace/payload dist/app/
ARG TARGETARCH
ARG VERSION=dev
ENV TARGETARCH=$TARGETARCH
ENV VERSION=$VERSION
RUN nfpm pkg --packager rpm --target /packages && nfpm pkg --packager deb --target /packages
CMD ["true"]
