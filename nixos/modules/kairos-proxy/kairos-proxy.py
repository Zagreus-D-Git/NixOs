# ~/nixos-config/nixos/modules/kairos-proxy/kairos-proxy.py
#!/usr/bin/env python3
import argparse, json, logging, http.server, urllib.request, sys
from datetime import datetime

ALLOWED = {"/api/generate", "/api/chat", "/api/tags"}

class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        logging.info(f"{self.client_address[0]} - {fmt % args}")

    def do_GET(self):
        if self.path not in ALLOWED:
            self.send_error(403, "Deny by default")
            return
        self._proxy()

    def do_POST(self):
        if self.path not in ALLOWED:
            self.send_error(403, f"Blocked: {self.path}")
            return
        self._proxy()

    def _proxy(self):
        try:
            cl = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(cl) if cl else b''
            req = urllib.request.Request(
                f"{OLLAMA_URL}{self.path}",
                data=body,
                headers={k:v for k,v in self.headers.items() if k.lower() not in ('host','content-length')},
                method=self.command
            )
            with urllib.request.urlopen(req, timeout=300) as r:
                self.send_response(r.status)
                for k,v in r.headers.items():
                    self.send_header(k, v)
                self.end_headers()
                self.wfile.write(r.read())
        except Exception as e:
            logging.error(f"ERR: {e}")
            self.send_error(502, str(e))

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--host", default="127.0.0.1")
    p.add_argument("--port", type=int, default=18888)
    p.add_argument("--ollama-url", default="http://127.0.0.1:11434")
    p.add_argument("--log-file", default="/var/log/kairos-proxy/access.log")
    args = p.parse_args()

    global OLLAMA_URL
    OLLAMA_URL = args.ollama_url

    logging.basicConfig(filename=args.log_file, level=logging.INFO,
                        format='%(asctime)s %(message)s')

    srv = http.server.HTTPServer((args.host, args.port), Handler)
    logging.info(f"Kairos proxy en {args.host}:{args.port}")
    srv.serve_forever()

if __name__ == "__main__":
    main()
