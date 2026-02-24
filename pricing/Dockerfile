# --- Build nfpm binary (for package stage) ---
FROM golang:1.22-alpine AS nfpm-build
RUN go install github.com/goreleaser/nfpm/v2/cmd/nfpm@v2.34.0

# --- Build ---
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS builder
WORKDIR /workspace
COPY . .
RUN dotnet restore && dotnet publish --no-restore -c Release -o /workspace/out

# --- Runtime image ---
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS app
WORKDIR /app
COPY --from=builder /workspace/out .
ENTRYPOINT ["dotnet", "pricing.dll"]

# --- Package stage: copy published app from builder, run nfpm (one arch per image via TARGETARCH) ---
FROM alpine:3.18 AS package
COPY --from=nfpm-build /go/bin/nfpm /usr/local/bin/nfpm
WORKDIR /workspace
COPY distribution ./distribution
COPY nfpm.yaml ./
RUN mkdir -p dist/app /packages
COPY --from=builder /workspace/out dist/app/
ARG TARGETARCH
ARG VERSION=dev
ENV TARGETARCH=$TARGETARCH
ENV VERSION=$VERSION
RUN nfpm pkg --packager rpm --target /packages && nfpm pkg --packager deb --target /packages
CMD ["true"]
