package main

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
)

const (
	httpPort               = 8080
	pricingEndpointEnvName = "PRICING_SERVICE_HOST"
	tiersFile              = "/etc/odigos-demo/membership-tiers.json"
)

type IsMemberResponse struct {
	IsMember bool `json:"isMember"`
}

func (imr *IsMemberResponse) CheckIsMember() bool {
	return imr.IsMember
}

type tier struct {
	Name            string `json:"name"`
	DiscountPercent int    `json:"discountPercent"`
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

func loadTiers(ctx context.Context) (tiers []tier, err error) {
	_, span := tracer.Start(ctx, "loadTiers")
	defer func() {
		if err != nil {
			span.SetStatus(codes.Error, err.Error())
		}
		span.End()
	}()
	span.SetAttributes(attribute.String("simple_demo.tiers_file", tiersFile))

	// Read on every call so tier edits apply without a restart
	data, err := os.ReadFile(tiersFile)
	if err != nil {
		return nil, err
	}
	if err = json.Unmarshal(data, &tiers); err != nil {
		return nil, err
	}
	if len(tiers) == 0 {
		return nil, errors.New("no membership tiers defined")
	}

	span.SetAttributes(attribute.Int("simple_demo.tiers_count", len(tiers)))
	return tiers, nil
}

func checkIfMember(ctx context.Context, userId uuid.UUID) bool {
	ctx, span := tracer.Start(ctx, "checkIfMember")
	defer span.End()

	slog.Info("Checking if user is a member", "userId", userId)

	// arbitrary decide if user is a member by it's id
	res := IsMemberResponse{
		IsMember: userId.String()[29] >= '0' && userId.String()[29] <= '6',
	}
	isMember := res.CheckIsMember()
	span.SetAttributes(attribute.String("simple_demo.userId", userId.String()), attribute.Bool("simple_demo.is_member", isMember))

	tiers, err := loadTiers(ctx)
	if err != nil {
		slog.Error("failed to load membership tiers", "error", err)
	} else if isMember {
		t := tiers[int(userId[0])%len(tiers)]
		span.SetAttributes(attribute.String("simple_demo.tier", t.Name), attribute.Int("simple_demo.discount_pct", t.DiscountPercent))
	}

	codeCtx, cancel := context.WithTimeout(ctx, 500*time.Millisecond)
	defer cancel()
	code, err := exec.CommandContext(codeCtx, "openssl", "rand", "-hex", "4").Output()
	if err != nil {
		slog.Error("failed to mint promo code", "error", err)
	} else {
		span.SetAttributes(attribute.String("simple_demo.promo_code", strings.TrimSpace(string(code))))
	}

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
