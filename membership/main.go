package main

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"os"
	"strconv"

	"github.com/google/uuid"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
)

const (
	httpPort = 8080
)

type IsMemberResponse struct {
	IsMember bool `json:"isMember"`
}

func getPortFromEnvOrDefault() int {
	port := httpPort
	if envPort := os.Getenv("PORT"); envPort != "" {
		p, err := strconv.Atoi(envPort)
		if err != nil {
			slog.Error("failed to parse PORT env variable", "error", err)
			return port
		}
		port = p
	}
	return port
}

var tracer = otel.Tracer("github.com/keyval-dev/test-apps/kv-shop/membership")

func checkIfMember(ctx context.Context, userId uuid.UUID) bool {
	_, span := tracer.Start(ctx, "checkIfMember")
	defer span.End()

	slog.Info("Checking if user is a member", "userId", userId)

	// arbitrary decide if user is a member by it's id
	isMember := userId.String()[29] >= '0' && userId.String()[29] <= '6'
	span.SetAttributes(attribute.String("simple_demo.userId", userId.String()), attribute.Bool("simple_demo.is_member", isMember))

	return isMember
}

func main() {
	port := getPortFromEnvOrDefault()
	slog.Info("Starting Membership service", "port", port)
	http.HandleFunc("/isMember", func(writer http.ResponseWriter, request *http.Request) {
		slog.Info("isMember called")

		userId := uuid.New()

		isMember := checkIfMember(request.Context(), userId)
		res := IsMemberResponse{
			IsMember: isMember,
		}

		data, err := json.Marshal(res)
		if err != nil {
			slog.Error("failed to marshal response", "error", err)
			writer.WriteHeader(http.StatusInternalServerError)
			return
		}

		_, err = writer.Write(data)
		if err != nil {
			slog.Error("failed to write response", "error", err)
			writer.WriteHeader(http.StatusInternalServerError)
			return
		}

	})

	err := http.ListenAndServe(":"+strconv.Itoa(port), nil)
	if err != nil {
		slog.Error("failed to start Membership service", "error", err)
	}
}
