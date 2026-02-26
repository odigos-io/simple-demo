package receiver

import (
	"context"
	"encoding/hex"
	"fmt"
	"log/slog"
	"net"
	"strconv"

	"github.com/odigos-io/simple-demo/ai-processor/pkg/stats"
	collectorpb "go.opentelemetry.io/proto/otlp/collector/trace/v1"
	commonpb "go.opentelemetry.io/proto/otlp/common/v1"
	tracepb "go.opentelemetry.io/proto/otlp/trace/v1"
	"google.golang.org/grpc"
	_ "google.golang.org/grpc/encoding/gzip"
)

type TraceReceiver struct {
	collectorpb.UnimplementedTraceServiceServer
	engine *stats.Engine
	server *grpc.Server
}

func New(engine *stats.Engine) *TraceReceiver {
	return &TraceReceiver{engine: engine}
}

func (r *TraceReceiver) Start(addr string) error {
	lis, err := net.Listen("tcp", addr)
	if err != nil {
		return fmt.Errorf("listen %s: %w", addr, err)
	}

	r.server = grpc.NewServer()
	collectorpb.RegisterTraceServiceServer(r.server, r)

	slog.Info("OTLP gRPC receiver listening", "addr", addr)
	return r.server.Serve(lis)
}

func (r *TraceReceiver) Stop() {
	if r.server != nil {
		r.server.GracefulStop()
	}
}

func (r *TraceReceiver) Export(_ context.Context, req *collectorpb.ExportTraceServiceRequest) (*collectorpb.ExportTraceServiceResponse, error) {
	for _, rs := range req.GetResourceSpans() {
		serviceName := extractServiceName(rs.GetResource().GetAttributes())
		if serviceName == "" {
			serviceName = "unknown"
		}

		for _, ss := range rs.GetScopeSpans() {
			for _, span := range ss.GetSpans() {
				r.processSpan(serviceName, span)
			}
		}
	}
	return &collectorpb.ExportTraceServiceResponse{}, nil
}

func (r *TraceReceiver) processSpan(serviceName string, span *tracepb.Span) {
	durationMs := float64(span.GetEndTimeUnixNano()-span.GetStartTimeUnixNano()) / 1e6
	isError := span.GetStatus().GetCode() == tracepb.Status_STATUS_CODE_ERROR

	var errorMsg string
	var httpStatus int

	for _, ev := range span.GetEvents() {
		if ev.GetName() == "exception" {
			for _, attr := range ev.GetAttributes() {
				if attr.GetKey() == "exception.message" {
					errorMsg = attr.GetValue().GetStringValue()
				}
			}
		}
	}

	if isError && errorMsg == "" {
		errorMsg = span.GetStatus().GetMessage()
	}

	for _, attr := range span.GetAttributes() {
		if attr.GetKey() == "http.status_code" || attr.GetKey() == "http.response.status_code" {
			httpStatus = int(attr.GetValue().GetIntValue())
			if httpStatus == 0 {
				httpStatus, _ = strconv.Atoi(attr.GetValue().GetStringValue())
			}
		}
		if !isError && httpStatus >= 500 {
			isError = true
		}
		if isError && errorMsg == "" && (attr.GetKey() == "http.status_code" || attr.GetKey() == "http.response.status_code") {
			errorMsg = fmt.Sprintf("HTTP %d", httpStatus)
		}
	}

	spanID := hex.EncodeToString(span.GetSpanId())
	parentSpanID := hex.EncodeToString(span.GetParentSpanId())
	traceID := hex.EncodeToString(span.GetTraceId())

	if parentSpanID == "0000000000000000" {
		parentSpanID = ""
	}

	r.engine.RecordSpan(serviceName, span.GetName(), spanID, parentSpanID, traceID, durationMs, isError, errorMsg, httpStatus)
}

func extractServiceName(attrs []*commonpb.KeyValue) string {
	for _, attr := range attrs {
		if attr.GetKey() == "service.name" {
			return attr.GetValue().GetStringValue()
		}
	}
	return ""
}
