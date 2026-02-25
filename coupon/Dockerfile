# --- Build nfpm binary (for package stage) ---
FROM golang:1.22-alpine AS nfpm-build
RUN go install github.com/goreleaser/nfpm/v2/cmd/nfpm@v2.34.0

# --- Common build: one npm ci for both app and package ---
FROM node:18.3.0-alpine3.14 AS builder
WORKDIR /workspace
COPY . .
RUN npm ci

# --- Runtime image ---
FROM node:18.3.0-alpine3.14 AS app
COPY --from=builder /workspace /app
WORKDIR /app
USER 15000
CMD ["node", "app.js"]

# --- Package stage: arch from docker --platform (TARGETARCH=amd64|arm64); one image per arch, one nfpm run ---
FROM node:18.3.0-alpine3.14 AS package
RUN apk add --no-cache ca-certificates
COPY --from=nfpm-build /go/bin/nfpm /usr/local/bin/nfpm
WORKDIR /workspace
COPY --from=builder /workspace /workspace
ARG TARGETARCH
ARG VERSION=dev
ENV VERSION=$VERSION
ENV TARGETARCH=$TARGETARCH
RUN mkdir -p dist/app
COPY --from=builder /workspace/app.js /workspace/package.json /workspace/package-lock.json dist/app/
COPY --from=builder /workspace/node_modules dist/app/node_modules
RUN mkdir -p /packages && \
    nfpm pkg --packager rpm --target /packages && \
    nfpm pkg --packager deb --target /packages
CMD ["true"]
