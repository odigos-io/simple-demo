FROM golang:1.21.4 AS builder
WORKDIR /go/src/app
COPY . .
RUN CGO_ENABLED=0 go build -o /go/bin/membership main.go

FROM gcr.io/distroless/base-debian10
COPY --from=builder /go/bin/membership /
USER 15000
ENTRYPOINT ["/membership"]
