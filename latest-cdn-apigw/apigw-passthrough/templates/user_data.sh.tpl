#!/bin/bash
set -euo pipefail

APP_PORT=${app_port}
ROUTE_PREFIX="${api_route_prefix}"

cat >/opt/sample-app.py <<'PYEOF'
#!/usr/bin/env python3
import json
from http.server import BaseHTTPRequestHandler, HTTPServer
import os

APP_PORT = int(os.environ["APP_PORT"])
ROUTE_PREFIX = os.environ["ROUTE_PREFIX"]


class Handler(BaseHTTPRequestHandler):
    def _send_json(self, status_code, payload):
        body = json.dumps(payload, indent=2).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        payload = {
            "message": "Sample application is running behind private ALB via API Gateway passthrough",
            "service": "hub-passthrough-hub-central",
            "path": self.path,
            "route_prefix": ROUTE_PREFIX,
            "headers": {
                "host": self.headers.get("Host"),
                "x-forwarded-for": self.headers.get("X-Forwarded-For"),
            },
        }
        self._send_json(200, payload)

    def log_message(self, format, *args):
        return


if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", APP_PORT), Handler)
    server.serve_forever()
PYEOF

chmod +x /opt/sample-app.py

cat >/etc/systemd/system/sample-app.service <<EOF
[Unit]
Description=Hub passthrough sample application
After=network.target

[Service]
Type=simple
Environment=APP_PORT=${app_port}
Environment=ROUTE_PREFIX=${api_route_prefix}
ExecStart=/usr/bin/python3 /opt/sample-app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable sample-app
systemctl start sample-app
