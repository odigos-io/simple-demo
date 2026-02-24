# syntax=docker/dockerfile:1
# check=error=true

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.4
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 sqlite3 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV=production \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_DISABLE_SHARED_GEMS=1 \
    BUNDLE_PATH=/rails/vendor/bundle

FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ /rails/vendor/bundle/ruby/*/cache /rails/vendor/bundle/ruby/*/bundler/gems/*/.git

COPY . .
RUN rm -rf /rails/deployment /rails/distribution /rails/nfpm.yaml /rails/Makefile /rails/docker-bake.hcl /rails/README.md /rails/bin 2>/dev/null || true
RUN chmod +x /rails/binaries/*

# --- Build nfpm binary (for package stage) ---
FROM golang:1.22-alpine AS nfpm-build
RUN go install github.com/goreleaser/nfpm/v2/cmd/nfpm@v2.34.0

# --- Runtime image ---
FROM base AS app

COPY --from=build /usr/local /usr/local
COPY --from=build /rails      /rails

ENTRYPOINT ["/rails/binaries/docker-entrypoint"]
EXPOSE 3000
CMD ["./binaries/rails", "server"]

# --- Package stage: copy app from build, run nfpm (one arch per image via TARGETARCH) ---
FROM alpine:3.18 AS package
COPY --from=nfpm-build /go/bin/nfpm /usr/local/bin/nfpm
WORKDIR /workspace
COPY distribution ./distribution
COPY nfpm.yaml ./
RUN mkdir -p dist/app /packages
COPY --from=build /rails dist/app/
# Don't ship vendor/bundle (built for Docker Ruby 3.4); postinstall runs bundle install for host Ruby
RUN rm -rf dist/app/vendor/bundle
# Persist Bundler "without development test" so runtime does not require dev/test gems
RUN mkdir -p dist/app/.bundle && printf '---\nBUNDLE_WITHOUT: "development:test"\nBUNDLE_DEPLOYMENT: "true"\nBUNDLE_PATH: "vendor/bundle"\n' > dist/app/.bundle/config
ARG TARGETARCH
ARG VERSION=dev
ENV TARGETARCH=$TARGETARCH
ENV VERSION=$VERSION
RUN nfpm pkg --packager rpm --target /packages && nfpm pkg --packager deb --target /packages
CMD ["true"]
