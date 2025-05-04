import http.server
import socketserver
import os
import sys

PORT = 12000  # Use the port assigned to this workspace
DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "export/web")

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)
    
    def end_headers(self):
        # Add CORS headers
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'X-Requested-With, Content-Type, Accept')
        super().end_headers()

if __name__ == "__main__":
    # Check if export directory exists
    if not os.path.exists(DIRECTORY):
        print(f"Error: Export directory {DIRECTORY} does not exist.")
        print("Please export the game to the web platform first.")
        print("Run: godot --headless --export-release \"Web\" export/web/index.html")
        sys.exit(1)
    
    # Create server
    with socketserver.TCPServer(("0.0.0.0", PORT), Handler) as httpd:
        print(f"Serving at http://localhost:{PORT}")
        print(f"Access from outside at https://work-1-ulavphqlblrkazyh.prod-runtime.all-hands.dev")
        httpd.serve_forever()