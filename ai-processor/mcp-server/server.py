"""
MCP server that exposes cluster health data from the ai-processor HTTP API.
Cursor connects to this server to query real-time cluster observability.
"""

import json
import os

import httpx
from mcp.server.fastmcp import FastMCP

API_BASE = os.environ.get("AI_PROCESSOR_URL", "http://localhost:8080")

mcp = FastMCP("cluster-health")


def _get(path: str) -> dict | list:
    resp = httpx.get(f"{API_BASE}{path}", timeout=10)
    resp.raise_for_status()
    return resp.json()


@mcp.tool()
def get_cluster_health() -> str:
    """Get overall cluster health summary.

    Returns the cluster status (healthy/degraded/critical),
    number of services tracked, uptime, and a list of services
    that currently have errors with their error rates and latency stats.
    Call this first to understand the current state of the cluster.
    """
    data = _get("/summary")
    return json.dumps(data, indent=2)


@mcp.tool()
def get_service_errors(service_name: str) -> str:
    """Get recent error details for a specific service.

    Returns the last 100 error spans for the given service,
    including timestamp, span name, error message, HTTP status code,
    duration, and trace ID. Use this after get_cluster_health identifies
    a service with errors, to understand what exactly is failing.

    Args:
        service_name: The name of the service to get errors for (e.g. "coupon", "inventory")
    """
    data = _get(f"/services/{service_name}/errors")
    return json.dumps(data, indent=2)


@mcp.tool()
def get_service_stats(service_name: str) -> str:
    """Get detailed performance stats for a specific service.

    Returns request count, error count, error rate, and latency
    percentiles (p50, p95, p99) over the last 5 minutes.

    Args:
        service_name: The name of the service to get stats for
    """
    all_services = _get("/services")
    for svc in all_services:
        if svc.get("name") == service_name:
            return json.dumps(svc, indent=2)
    return json.dumps({"error": f"Service '{service_name}' not found"})


@mcp.tool()
def get_topology() -> str:
    """Get the service dependency graph.

    Returns the call relationships between services with call counts,
    derived from distributed trace parent-child span relationships.
    Useful for understanding which services depend on which,
    and how traffic flows through the system.
    """
    data = _get("/topology")
    return json.dumps(data, indent=2)


if __name__ == "__main__":
    mcp.run()
