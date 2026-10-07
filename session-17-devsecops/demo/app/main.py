"""DevSecOps demo app — tiny HTTP server."""
from http.server import BaseHTTPRequestHandler, HTTPServer


def message() -> str:
    return "Hello World from the DevSecOps pipeline!"


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = f"<h1>{message()}</h1>".encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/html")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", 8000), Handler).serve_forever()
