# --- Build nfpm binary (for package stage) ---
FROM golang:1.22-alpine AS nfpm-build
RUN go install github.com/goreleaser/nfpm/v2/cmd/nfpm@v2.34.0

# --- Build C++ binary (cpp-httplib is header-only, vendored in third_party/) ---
FROM debian:bookworm-slim AS cpp-builder
RUN apt-get update \
    && apt-get install -y --no-install-recommends g++ \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /workspace
COPY main.cpp .
COPY third_party ./third_party
RUN g++ -std=c++17 -O2 -pthread -Wall -Wextra -o /workspace/shipping main.cpp

# --- Runtime image ---
FROM debian:bookworm-slim AS app
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --uid 15000 --no-create-home --shell /usr/sbin/nologin appuser
COPY --from=cpp-builder /workspace/shipping /shipping
USER 15000
ENTRYPOINT ["/shipping"]

# --- Package stage ---
FROM debian:bookworm-slim AS package
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY --from=nfpm-build /go/bin/nfpm /usr/local/bin/nfpm
WORKDIR /workspace
COPY distribution ./distribution
COPY nfpm.yaml ./
RUN mkdir -p dist/app /packages
COPY --from=cpp-builder /workspace/shipping dist/app/odigos-demo-shipping
ARG TARGETARCH
ARG VERSION=dev
ENV TARGETARCH=$TARGETARCH
ENV VERSION=$VERSION
RUN nfpm pkg --packager rpm --target /packages && nfpm pkg --packager deb --target /packages
CMD ["true"]
