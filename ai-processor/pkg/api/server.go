package api

import (
	"encoding/json"
	"log/slog"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/odigos-io/simple-demo/ai-processor/pkg/stats"
)

type Server struct {
	engine *stats.Engine
	router *chi.Mux
}

func New(engine *stats.Engine) *Server {
	s := &Server{engine: engine}
	r := chi.NewRouter()
	r.Use(middleware.Recoverer)
	r.Use(middleware.Logger)

	r.Get("/health", s.health)
	r.Get("/services", s.services)
	r.Get("/services/{name}/errors", s.serviceErrors)
	r.Get("/topology", s.topology)
	r.Get("/summary", s.summary)

	s.router = r
	return s
}

func (s *Server) Handler() http.Handler {
	return s.router
}

func (s *Server) health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, map[string]any{
		"status":           "ok",
		"services_tracked": s.engine.ServiceCount(),
		"uptime_seconds":   s.engine.UptimeSeconds(),
	})
}

func (s *Server) services(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, s.engine.AllSummaries())
}

func (s *Server) serviceErrors(w http.ResponseWriter, r *http.Request) {
	name := chi.URLParam(r, "name")
	errors := s.engine.ServiceErrors(name)
	if errors == nil {
		errors = []stats.ErrorSpan{}
	}
	writeJSON(w, errors)
}

func (s *Server) topology(w http.ResponseWriter, _ *http.Request) {
	edges := s.engine.Topology()
	if edges == nil {
		edges = []stats.TopologyEdge{}
	}
	writeJSON(w, edges)
}

func (s *Server) summary(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, s.engine.ClusterHealth())
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(v); err != nil {
		slog.Error("failed to encode JSON response", "error", err)
	}
}
