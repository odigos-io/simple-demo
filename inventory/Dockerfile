# --- Build nfpm binary (for package stage) ---
FROM golang:1.22-alpine AS nfpm-build
RUN go install github.com/goreleaser/nfpm/v2/cmd/nfpm@v2.34.0

# --- Common build: one poetry install for both app and package ---
FROM python:3.11-slim AS builder
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
RUN apt-get update \
    && apt-get install -y --no-install-recommends gcc libpq-dev \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /workspace
COPY . .
RUN pip install --no-cache-dir poetry==1.7.1 \
    && poetry config virtualenvs.create false \
    && poetry config installer.max-workers 1 \
    && poetry install --no-interaction --no-ansi

# --- Runtime image ---
FROM python:3.11-slim AS app
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
RUN apt-get update \
    && apt-get install -y --no-install-recommends libpq5 \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /workspace /app
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
ENV PYTHONPATH=/app
EXPOSE 8080
CMD ["python", "inventory/main.py"]

# --- Package stage: arch from docker --platform (TARGETARCH); one image per arch ---
FROM python:3.11-slim AS package
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY --from=nfpm-build /go/bin/nfpm /usr/local/bin/nfpm
WORKDIR /workspace
COPY --from=builder /workspace /workspace
RUN mkdir -p dist/app
COPY --from=builder /workspace/inventory dist/app/
COPY --from=builder /workspace/pyproject.toml /workspace/poetry.lock /workspace/README.md dist/app/
COPY --from=builder /usr/local/lib/python3.11/site-packages dist/app/site-packages
ARG TARGETARCH
ARG VERSION=dev
ENV VERSION=$VERSION
ENV TARGETARCH=$TARGETARCH
RUN mkdir -p /packages && \
    nfpm pkg --packager rpm --target /packages && \
    nfpm pkg --packager deb --target /packages
CMD ["true"]
