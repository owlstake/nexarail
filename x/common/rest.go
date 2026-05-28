// Package common provides shared utilities for NexaRail modules.
package common

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/grpc-ecosystem/grpc-gateway/runtime"
	"github.com/grpc-ecosystem/grpc-gateway/utilities"
)

// QueryHandler is a function that returns a query response or error.
type QueryHandler func() (interface{}, error)

// QueryWithParam is a function that takes a path parameter and returns a response.
type QueryWithParam func(param string) (interface{}, error)

// RegisterQueryRoute registers a simple GET route (no path params) on the gateway mux.
// Example: GET /nexarail/fees/v1/params
func RegisterQueryRoute(mux *runtime.ServeMux, method, path string, handler QueryHandler) {
	pattern := runtime.MustPattern(runtime.NewPattern(1, patternOps(path), patternPool(path), ""))
	mux.Handle(method, pattern, func(w http.ResponseWriter, r *http.Request, _ map[string]string) {
		resp, err := handler()
		if err != nil {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
			return
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(resp)
	})
}

// RegisterQueryRouteWithParam registers a GET route with a single path parameter.
// Example: GET /nexarail/settlement/v1/settlement/{id}
func RegisterQueryRouteWithParam(mux *runtime.ServeMux, method, path, param string, handler QueryWithParam) {
	pattern := runtime.MustPattern(runtime.NewPattern(1, patternOps(path), patternPool(path), ""))
	mux.Handle(method, pattern, func(w http.ResponseWriter, r *http.Request, pathParams map[string]string) {
		val := pathParams[param]
		resp, err := handler(val)
		if err != nil {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
			return
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(resp)
	})
}

// patternOps returns grpc-gateway pattern opcodes for a path.
func patternOps(path string) []int {
	segments := pathSegments(path)
	ops := make([]int, 0, len(segments)*6)
	for i, seg := range segments {
		if isPathParam(seg) {
			ops = append(ops,
				int(utilities.OpPush), 0,
				int(utilities.OpConcatN), 1,
				int(utilities.OpCapture), i,
			)
			continue
		}
		ops = append(ops, int(utilities.OpLitPush), i)
	}
	return ops
}

// patternPool returns the path segments without slashes and braces.
func patternPool(path string) []string {
	segments := pathSegments(path)
	pool := make([]string, 0, len(segments))
	for _, seg := range segments {
		if isPathParam(seg) {
			pool = append(pool, seg[1:len(seg)-1])
			continue
		}
		pool = append(pool, seg)
	}
	return pool
}

func pathSegments(path string) []string {
	trimmed := strings.Trim(path, "/")
	if trimmed == "" {
		return nil
	}
	return strings.Split(trimmed, "/")
}

func isPathParam(segment string) bool {
	return len(segment) > 2 && strings.HasPrefix(segment, "{") && strings.HasSuffix(segment, "}")
}
