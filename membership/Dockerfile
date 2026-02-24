# --- Build nfpm binary (for package stage) ---
FROM golang:1.22-alpine AS nfpm-build
RUN go install github.com/goreleaser/nfpm/v2/cmd/nfpm@v2.34.0

# --- Build ---
FROM golang:1.21.4 AS builder
WORKDIR /workspace
COPY . .
RUN CGO_ENABLED=0 go build -o /workspace/membership main.go

# --- Runtime image ---
FROM gcr.io/distroless/base-debian10 AS app
COPY --from=builder /workspace/membership /membership
USER 15000
ENTRYPOINT ["/membership"]

# --- Package stage: copy binary from builder, run nfpm (one arch per image via TARGETARCH) ---
FROM alpine:3.18 AS package
COPY --from=nfpm-build /go/bin/nfpm /usr/local/bin/nfpm
WORKDIR /workspace
COPY distribution ./distribution
COPY nfpm.yaml ./
RUN mkdir -p dist/app /packages
COPY --from=builder /workspace/membership dist/app/odigos-demo-membership
ARG TARGETARCH
ARG VERSION=dev
ENV TARGETARCH=$TARGETARCH
ENV VERSION=$VERSION
RUN nfpm pkg --packager rpm --target /packages && nfpm pkg --packager deb --target /packages
CMD ["true"]
