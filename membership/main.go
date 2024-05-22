package main

import (
	"encoding/json"
	"log/slog"
	"net/http"
	"os"
	"strconv"
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

func main() {
	port := getPortFromEnvOrDefault()
	slog.Info("Starting Membership service", "port", port)
	http.HandleFunc("/isMember", func(writer http.ResponseWriter, request *http.Request) {
		slog.Info("isMember called")
		res := IsMemberResponse{
			IsMember: true,
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

	err := http.ListenAndServe(":"+strconv.Itoa(httpPort), nil)
	if err != nil {
		slog.Error("failed to start Membership service", "error", err)
	}
}
