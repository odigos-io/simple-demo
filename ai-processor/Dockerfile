FROM golang:1.22 AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /ai-processor .

FROM alpine:3.21
RUN apk add --no-cache ca-certificates
COPY --from=build /ai-processor /usr/local/bin/ai-processor
EXPOSE 4317 8080
ENTRYPOINT ["ai-processor"]
