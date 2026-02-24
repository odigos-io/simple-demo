# --- Build nfpm binary (for package stage) ---
FROM golang:1.22-alpine AS nfpm-build
RUN go install github.com/goreleaser/nfpm/v2/cmd/nfpm@v2.34.0

# --- Build ---
FROM rust:1.82-bookworm AS builder
WORKDIR /app
COPY . .
RUN cargo build --release

# --- Runtime image ---
FROM debian:bookworm-slim AS app
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/load-generator /usr/local/bin/load-generator
EXPOSE 8080
CMD ["/usr/local/bin/load-generator"]

# --- Package stage ---
FROM alpine:3.18 AS package
COPY --from=nfpm-build /go/bin/nfpm /usr/local/bin/nfpm
WORKDIR /workspace
COPY distribution ./distribution
COPY nfpm.yaml ./
RUN mkdir -p dist/app /packages
COPY --from=builder /app/target/release/load-generator dist/app/odigos-demo-load-generator
ARG TARGETARCH
ARG VERSION=dev
ENV TARGETARCH=$TARGETARCH
ENV VERSION=$VERSION
RUN nfpm pkg --packager rpm --target /packages && nfpm pkg --packager deb --target /packages
CMD ["true"]
