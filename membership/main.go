package main

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"os"
	"strconv"
	"strings"

	"github.com/google/uuid"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
)

const (
	httpPort               = 8080
	pricingEndpointEnvName = "PRICING_SERVICE_HOST"
)

type IsMemberResponse struct {
	IsMember bool `json:"isMember"`
}

func (imr *IsMemberResponse) CheckIsMember() bool {
	return imr.IsMember
}

var tracer = otel.Tracer("github.com/keyval-dev/test-apps/kv-shop/membership")

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

func checkIfMember(ctx context.Context, userId uuid.UUID) bool {
	_, span := tracer.Start(ctx, "checkIfMember")
	defer span.End()

	slog.Info("Checking if user is a member", "userId", userId)

	// arbitrary decide if user is a member by it's id
	res := IsMemberResponse{
		IsMember: userId.String()[29] >= '0' && userId.String()[29] <= '6',
	}
	isMember := res.CheckIsMember()
	span.SetAttributes(attribute.String("simple_demo.userId", userId.String()), attribute.Bool("simple_demo.is_member", isMember))

	return isMember
}

func buildServiceURL(endpoint, path string) string {
	base := endpoint
	if !strings.HasPrefix(base, "http://") && !strings.HasPrefix(base, "https://") {
		base = "http://" + base
	}
	if path != "" && !strings.HasPrefix(path, "/") {
		path = "/" + path
	}
	return base + path
}

func main() {
	port := getPortFromEnvOrDefault()
	slog.Info("Starting Membership service", "port", port)

	http.HandleFunc("/isMember", func(writer http.ResponseWriter, request *http.Request) {
		slog.Info("isMember called")

		// inject odigos-special-header
		writer.Header().Set("odigos-special-header", "membership-service")
		request.Header.Set("odigos-special-header", "membership-service")

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

		req, err := http.NewRequestWithContext(request.Context(), "GET", buildServiceURL(os.Getenv(pricingEndpointEnvName), "/price?id=0"), nil)
		if err != nil {
			slog.Error("failed to create request to pricing service", "error", err)
			writer.WriteHeader(http.StatusInternalServerError)
			return
		}
		req.Header.Set("odigos-special-header", "membership-service")
		_, err = http.DefaultClient.Do(req)
		if err != nil {
			slog.Error("failed to call pricing service", "error", err)
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
