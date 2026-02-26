package main

import (
	"context"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/odigos-io/simple-demo/ai-processor/pkg/api"
	"github.com/odigos-io/simple-demo/ai-processor/pkg/receiver"
	"github.com/odigos-io/simple-demo/ai-processor/pkg/stats"
)

func main() {
	slog.Info("Starting ai-processor")

	engine := stats.NewEngine()

	otlpReceiver := receiver.New(engine)
	go func() {
		if err := otlpReceiver.Start(":4317"); err != nil {
			slog.Error("OTLP receiver failed", "error", err)
			os.Exit(1)
		}
	}()

	apiServer := api.New(engine)
	httpServer := &http.Server{
		Addr:    ":8080",
		Handler: apiServer.Handler(),
	}
	go func() {
		slog.Info("HTTP API listening", "addr", ":8080")
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			slog.Error("HTTP server failed", "error", err)
			os.Exit(1)
		}
	}()

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	<-ctx.Done()

	slog.Info("Shutting down")
	otlpReceiver.Stop()
	httpServer.Shutdown(context.Background())
}
