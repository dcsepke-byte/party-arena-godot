import http.server
import socketserver
import os
import functools

os.chdir('/opt/data/party-arena-godot/build/web')

class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # WASM und COOP/COEP für Threads nötig (nicht Threads, aber trotzdem)
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        super().end_headers()

    def log_message(self, format, *args):
        pass

with socketserver.TCPServer(("", 8099), Handler) as httpd:
    print("Web-Build läuft auf http://localhost:8099")
    httpd.serve_forever()
