"""Taskboard — final DevOps project app."""
import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer

VERSION = os.getenv("APP_VERSION", "1.0.0")


def tasks():
    return [
        {"id": 1, "title": "Build CI pipeline", "done": True},
        {"id": 2, "title": "Scan image with Trivy", "done": True},
        {"id": 3, "title": "Deploy to Kubernetes", "done": False},
    ]


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, body, ctype="application/json"):
        data = body.encode() if isinstance(body, str) else body
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path == "/healthz":
            self._send(200, json.dumps({"status": "healthy"}))
        elif self.path == "/readyz":
            self._send(200, json.dumps({"status": "ready"}))
        elif self.path == "/api/tasks":
            self._send(200, json.dumps(tasks()))
        else:
            self._send(200, f"<h1>Taskboard v{VERSION}</h1>", "text/html")

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", 8000), Handler).serve_forever()
