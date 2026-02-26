# Meta-package: no app binary, only nfpm packaging with dependencies on all demo apps.
FROM golang:1.22-alpine AS nfpm-build
RUN go install github.com/goreleaser/nfpm/v2/cmd/nfpm@v2.34.0

FROM alpine:3.18 AS package
COPY --from=nfpm-build /go/bin/nfpm /usr/local/bin/nfpm
WORKDIR /workspace
COPY distribution ./distribution
COPY nfpm.yaml ./
RUN mkdir -p /packages
ARG TARGETARCH
ARG VERSION=dev
ENV TARGETARCH=$TARGETARCH
ENV VERSION=$VERSION
# Debian version must start with a digit; strip tag prefix "v" (e.g. v0.0.12 -> 0.0.12)
RUN VERSION="${VERSION#v}" \
 && export VERSION \
 && nfpm pkg --packager rpm --target /packages \
 && nfpm pkg --packager deb --target /packages
CMD ["true"]
