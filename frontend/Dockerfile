# --- Build nfpm binary (for package stage) ---
FROM golang:1.22-alpine AS nfpm-build
RUN go install github.com/goreleaser/nfpm/v2/cmd/nfpm@v2.34.0

# --- Next.js static export ---
FROM node:20-alpine AS fe-build
USER root
WORKDIR /home/node
COPY webapp/package* webapp/yarn.lock /home/node/
RUN yarn
COPY webapp /home/node/
RUN chown -R node:node /home/node
USER node
RUN mkdir -p /home/node/.next && chown -R node:node /home/node/.next
RUN yarn build

# --- Maven build: one build for both app and package ---
FROM maven:3.8.5-openjdk-17 AS builder
WORKDIR /home/app
COPY . .
COPY --from=fe-build /home/node/out src/main/resources/static
RUN mvn --no-transfer-progress clean package -DskipTests
COPY distribution nfpm.yaml ./

# --- Runtime image ---
FROM eclipse-temurin:17-jre-jammy AS app
COPY --from=builder /home/app/target/*.jar /app/frontend.jar
CMD ["java", "-jar", "/app/frontend.jar"]

# --- Package stage: arch from docker --platform (TARGETARCH); one image per arch ---
FROM eclipse-temurin:17-jre-jammy AS package
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY --from=nfpm-build /go/bin/nfpm /usr/local/bin/nfpm
WORKDIR /workspace
COPY --from=builder /home/app/distribution ./distribution
COPY --from=builder /home/app/nfpm.yaml ./
RUN mkdir -p dist/app
COPY --from=builder /home/app/target/*.jar dist/app/
RUN mv dist/app/*.jar dist/app/frontend.jar
ARG TARGETARCH
ARG VERSION=dev
ENV VERSION=$VERSION
ENV TARGETARCH=$TARGETARCH
RUN mkdir -p /packages && \
    nfpm pkg --packager rpm --target /packages && \
    nfpm pkg --packager deb --target /packages
CMD ["true"]
