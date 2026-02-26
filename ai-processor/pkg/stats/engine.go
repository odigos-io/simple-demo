package stats

import (
	"math"
	"sort"
	"sync"
	"time"
)

const (
	windowDuration = 5 * time.Minute
	bucketSize     = 10 * time.Second
	numBuckets     = int(windowDuration / bucketSize)
	maxErrorsPerSvc = 100
)

type ErrorSpan struct {
	Timestamp   time.Time `json:"timestamp"`
	SpanName    string    `json:"span_name"`
	ErrorMsg    string    `json:"error_message"`
	HTTPStatus  int       `json:"http_status,omitempty"`
	DurationMs  float64   `json:"duration_ms"`
	ServiceName string    `json:"service_name"`
	TraceID     string    `json:"trace_id,omitempty"`
}

type bucket struct {
	requests int64
	errors   int64
	latencies []float64
}

type ServiceStats struct {
	mu           sync.Mutex
	buckets      [numBuckets]bucket
	lastBucketAt time.Time
	errorRing    []ErrorSpan
	errorHead    int
	errorCount   int
}

func newServiceStats() *ServiceStats {
	return &ServiceStats{
		errorRing: make([]ErrorSpan, maxErrorsPerSvc),
	}
}

func (s *ServiceStats) currentBucketIndex(now time.Time) int {
	return int(now.Unix()/int64(bucketSize.Seconds())) % numBuckets
}

func (s *ServiceStats) expireOld(now time.Time) {
	cutoff := now.Add(-windowDuration)
	for i := range s.buckets {
		age := now.Add(-time.Duration(i) * bucketSize)
		if age.Before(cutoff) {
			s.buckets[i] = bucket{}
		}
	}
}

func (s *ServiceStats) Record(durationMs float64, isError bool, now time.Time) {
	s.mu.Lock()
	defer s.mu.Unlock()

	idx := s.currentBucketIndex(now)
	s.buckets[idx].requests++
	s.buckets[idx].latencies = append(s.buckets[idx].latencies, durationMs)
	if isError {
		s.buckets[idx].errors++
	}
	s.lastBucketAt = now
}

func (s *ServiceStats) AddError(e ErrorSpan) {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.errorRing[s.errorHead%maxErrorsPerSvc] = e
	s.errorHead++
	if s.errorCount < maxErrorsPerSvc {
		s.errorCount++
	}
}

func (s *ServiceStats) RecentErrors() []ErrorSpan {
	s.mu.Lock()
	defer s.mu.Unlock()

	result := make([]ErrorSpan, 0, s.errorCount)
	start := s.errorHead - s.errorCount
	if start < 0 {
		start = 0
	}
	for i := start; i < s.errorHead; i++ {
		result = append(result, s.errorRing[i%maxErrorsPerSvc])
	}
	return result
}

type ServiceSummary struct {
	Name        string  `json:"name"`
	Requests    int64   `json:"requests"`
	Errors      int64   `json:"errors"`
	ErrorRate   float64 `json:"error_rate"`
	AvgLatency  float64 `json:"avg_latency_ms"`
	P50Latency  float64 `json:"p50_latency_ms"`
	P95Latency  float64 `json:"p95_latency_ms"`
	P99Latency  float64 `json:"p99_latency_ms"`
	RecentErrs  int     `json:"recent_error_count"`
}

func (s *ServiceStats) Summary(name string) ServiceSummary {
	s.mu.Lock()
	defer s.mu.Unlock()

	var totalReqs, totalErrs int64
	var allLatencies []float64

	for _, b := range s.buckets {
		totalReqs += b.requests
		totalErrs += b.errors
		allLatencies = append(allLatencies, b.latencies...)
	}

	var errRate, avgLat, p50, p95, p99 float64
	if totalReqs > 0 {
		errRate = float64(totalErrs) / float64(totalReqs)
	}
	if len(allLatencies) > 0 {
		sort.Float64s(allLatencies)
		var sum float64
		for _, l := range allLatencies {
			sum += l
		}
		avgLat = sum / float64(len(allLatencies))
		p50 = percentile(allLatencies, 0.50)
		p95 = percentile(allLatencies, 0.95)
		p99 = percentile(allLatencies, 0.99)
	}

	return ServiceSummary{
		Name:       name,
		Requests:   totalReqs,
		Errors:     totalErrs,
		ErrorRate:  math.Round(errRate*10000) / 10000,
		AvgLatency: math.Round(avgLat*100) / 100,
		P50Latency: math.Round(p50*100) / 100,
		P95Latency: math.Round(p95*100) / 100,
		P99Latency: math.Round(p99*100) / 100,
		RecentErrs: s.errorCount,
	}
}

func percentile(sorted []float64, p float64) float64 {
	if len(sorted) == 0 {
		return 0
	}
	idx := p * float64(len(sorted)-1)
	lower := int(math.Floor(idx))
	upper := int(math.Ceil(idx))
	if lower == upper {
		return sorted[lower]
	}
	frac := idx - float64(lower)
	return sorted[lower]*(1-frac) + sorted[upper]*frac
}

// Engine is the central stats aggregator.
type Engine struct {
	mu       sync.RWMutex
	services map[string]*ServiceStats

	topoMu   sync.RWMutex
	topology  map[string]map[string]uint64 // parent -> child -> callCount

	spanIndex sync.Map // spanID -> serviceName (for parent resolution)

	startTime time.Time
}

func NewEngine() *Engine {
	return &Engine{
		services:  make(map[string]*ServiceStats),
		topology:  make(map[string]map[string]uint64),
		startTime: time.Now(),
	}
}

func (e *Engine) getOrCreate(svc string) *ServiceStats {
	e.mu.RLock()
	s, ok := e.services[svc]
	e.mu.RUnlock()
	if ok {
		return s
	}

	e.mu.Lock()
	defer e.mu.Unlock()
	s, ok = e.services[svc]
	if ok {
		return s
	}
	s = newServiceStats()
	e.services[svc] = s
	return s
}

func (e *Engine) RecordSpan(serviceName, spanName, spanID, parentSpanID, traceID string, durationMs float64, isError bool, errorMsg string, httpStatus int) {
	now := time.Now()
	ss := e.getOrCreate(serviceName)
	ss.Record(durationMs, isError, now)

	if isError && errorMsg != "" {
		ss.AddError(ErrorSpan{
			Timestamp:   now,
			SpanName:    spanName,
			ErrorMsg:    errorMsg,
			HTTPStatus:  httpStatus,
			DurationMs:  durationMs,
			ServiceName: serviceName,
			TraceID:     traceID,
		})
	}

	if spanID != "" {
		e.spanIndex.Store(spanID, serviceName)
	}

	if parentSpanID != "" {
		if parentSvc, ok := e.spanIndex.Load(parentSpanID); ok {
			parentName := parentSvc.(string)
			if parentName != serviceName {
				e.recordEdge(parentName, serviceName)
			}
		}
	}
}

func (e *Engine) recordEdge(parent, child string) {
	e.topoMu.Lock()
	defer e.topoMu.Unlock()
	if e.topology[parent] == nil {
		e.topology[parent] = make(map[string]uint64)
	}
	e.topology[parent][child]++
}

func (e *Engine) ServiceNames() []string {
	e.mu.RLock()
	defer e.mu.RUnlock()
	names := make([]string, 0, len(e.services))
	for n := range e.services {
		names = append(names, n)
	}
	sort.Strings(names)
	return names
}

func (e *Engine) ServiceSummary(name string) (ServiceSummary, bool) {
	e.mu.RLock()
	s, ok := e.services[name]
	e.mu.RUnlock()
	if !ok {
		return ServiceSummary{}, false
	}
	return s.Summary(name), true
}

func (e *Engine) AllSummaries() []ServiceSummary {
	names := e.ServiceNames()
	result := make([]ServiceSummary, 0, len(names))
	for _, n := range names {
		if s, ok := e.ServiceSummary(n); ok {
			result = append(result, s)
		}
	}
	return result
}

func (e *Engine) ServiceErrors(name string) []ErrorSpan {
	e.mu.RLock()
	s, ok := e.services[name]
	e.mu.RUnlock()
	if !ok {
		return nil
	}
	return s.RecentErrors()
}

type TopologyEdge struct {
	Parent string `json:"parent"`
	Child  string `json:"child"`
	Calls  uint64 `json:"calls"`
}

func (e *Engine) Topology() []TopologyEdge {
	e.topoMu.RLock()
	defer e.topoMu.RUnlock()
	var edges []TopologyEdge
	for p, children := range e.topology {
		for c, count := range children {
			edges = append(edges, TopologyEdge{Parent: p, Child: c, Calls: count})
		}
	}
	return edges
}

func (e *Engine) ServiceCount() int {
	e.mu.RLock()
	defer e.mu.RUnlock()
	return len(e.services)
}

func (e *Engine) UptimeSeconds() float64 {
	return time.Since(e.startTime).Seconds()
}

type ClusterHealth struct {
	Status          string           `json:"status"` // healthy, degraded, critical
	ServicesTracked int              `json:"services_tracked"`
	UptimeSeconds   float64          `json:"uptime_seconds"`
	TopErrors       []ServiceSummary `json:"services_with_errors,omitempty"`
}

func (e *Engine) ClusterHealth() ClusterHealth {
	summaries := e.AllSummaries()
	var withErrors []ServiceSummary
	for _, s := range summaries {
		if s.Errors > 0 {
			withErrors = append(withErrors, s)
		}
	}

	status := "healthy"
	for _, s := range withErrors {
		if s.ErrorRate > 0.1 {
			status = "critical"
			break
		}
		if s.ErrorRate > 0.01 {
			status = "degraded"
		}
	}

	return ClusterHealth{
		Status:          status,
		ServicesTracked: e.ServiceCount(),
		UptimeSeconds:   math.Round(e.UptimeSeconds()*10) / 10,
		TopErrors:       withErrors,
	}
}
