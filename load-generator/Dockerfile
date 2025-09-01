# Build stage
FROM rust:1.89.0 AS builder
WORKDIR /app

COPY . .
RUN cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates
COPY --from=builder /app/target/release/load-generator /usr/local/bin/load-generator

EXPOSE 8080
CMD ["/usr/local/bin/load-generator"]
