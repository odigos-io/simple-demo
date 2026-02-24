package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"strconv"

	"github.com/google/uuid"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.26.0"
)

const (
	httpPort = 8080
	pricingEndpointEnvName = "PRICING_SERVICE_HOST"
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

func initTracer(ctx context.Context) (func(context.Context) error, error) {
	exporter, err := otlptracegrpc.New(ctx)
	if err != nil {
		return nil, err
	}

	res, err := resource.New(ctx,
		resource.WithAttributes(semconv.ServiceNameKey.String("membership")),
		resource.WithFromEnv(),
	)
	if err != nil {
		return nil, err
	}

	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter),
		sdktrace.WithResource(res),
	)

	otel.SetTracerProvider(tp)
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(
		propagation.TraceContext{},
		propagation.Baggage{},
	))

	return tp.Shutdown, nil
}

var httpClient = &http.Client{
	Transport: otelhttp.NewTransport(http.DefaultTransport),
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
	ctx := context.Background()
	shutdown, err := initTracer(ctx)
	if err != nil {
		slog.Error("failed to initialize tracer", "error", err)
	} else {
		defer shutdown(ctx)
	}

	port := getPortFromEnvOrDefault()
	slog.Info("Starting Membership service", "port", port)
	isMemberHandler := http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
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

		req, err := http.NewRequestWithContext(request.Context(), "GET", (fmt.Sprintf("http://%s/price?id=0", os.Getenv(pricingEndpointEnvName))), nil)
		if err != nil {
			slog.Error("failed to create request to pricing service", "error", err)
			writer.WriteHeader(http.StatusInternalServerError)
			return
		}

		_, err = httpClient.Do(req)
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
	http.Handle("/isMember", otelhttp.NewHandler(isMemberHandler, "isMember"))

	err = http.ListenAndServe(":"+strconv.Itoa(port), nil)
	if err != nil {
		slog.Error("failed to start Membership service", "error", err)
	}
}
