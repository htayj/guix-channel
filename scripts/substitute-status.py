#!/usr/bin/env python3
"""Read-only HTTP health and metrics for completed full substitute evaluations."""
import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=Path, default=Path("/home/guixbot/substitutes/status"))
    parser.add_argument("--bind", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=8081)
    parser.add_argument("--fresh-seconds", type=int, default=108000)
    args = parser.parse_args()

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            try:
                data = json.loads((args.directory / "latest.json").read_text())
                valid = (data["schema"] == 1 and data["mode"] == "all"
                         and isinstance(data["completed_at"], (int, float))
                         and isinstance(data["failed"], list))
            except (OSError, ValueError, KeyError, TypeError):
                data, valid = {}, False
            completed = data.get("completed_at", 0) if valid else 0
            age = time.time() - completed
            fresh = valid and 0 <= age <= args.fresh_seconds
            success = valid and data.get("success") is True and not data["failed"]
            status = 200
            content_type = "application/json"
            if self.path in ("/status.json", "/status/latest.json"):
                status = 200 if valid else 503
                body = json.dumps(data if valid else {"error": "no completed full evaluation"}) + "\n"
            elif self.path in ("/status/success", "/status/fresh"):
                healthy = success if self.path.endswith("success") else fresh
                status = 200 if healthy else 503
                body = json.dumps(dict(success=success, fresh=fresh,
                                       completed_at=completed or None,
                                       age_seconds=age if valid else None)) + "\n"
            elif self.path == "/metrics":
                content_type = "text/plain; version=0.0.4"
                body = ("# HELP guix_substitutes_last_completion_seconds Last completed full evaluation timestamp.\n"
                        "# TYPE guix_substitutes_last_completion_seconds gauge\n"
                        f"guix_substitutes_last_completion_seconds {completed}\n"
                        "# HELP guix_substitutes_success Whether the last full evaluation succeeded.\n"
                        "# TYPE guix_substitutes_success gauge\n"
                        f"guix_substitutes_success {int(success)}\n"
                        "# HELP guix_substitutes_fresh Whether the last full evaluation completed within the freshness window.\n"
                        "# TYPE guix_substitutes_fresh gauge\n"
                        f"guix_substitutes_fresh {int(fresh)}\n"
                        "# TYPE guix_substitutes_failed_targets gauge\n"
                        f"guix_substitutes_failed_targets {len(data.get('failed', [])) if valid else 0}\n")
            else:
                status, body = 404, '{"error":"not found"}\n'
            encoded = body.encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(encoded)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(encoded)

    ThreadingHTTPServer((args.bind, args.port), Handler).serve_forever()


if __name__ == "__main__":
    main()
