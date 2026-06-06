import http.server
import json


def greet(name: str = "Ali") -> str:
    return f"Hello, {name}!"


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps({"message": greet()}).encode())


def main() -> None:
    server = http.server.HTTPServer(("0.0.0.0", 8080), Handler)
    print("Serving on port 8080...")
    server.serve_forever()


if __name__ == "__main__":
    main()
