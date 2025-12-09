#!/bin/bash

# MoonBunny Local Server Script
# Serves the HTML export on a local HTTP server

set -e

echo "🌐 Starting local HTTP server for MoonBunny..."

# Check if the HTML files exist
HTML_DIR="../html"
if [ ! -f "$HTML_DIR/index.html" ]; then
    echo "❌ Error: HTML files not found in $HTML_DIR"
    echo "Run ./export_html.sh first to generate the HTML files"
    exit 1
fi

# Start Python HTTP server
cd "$HTML_DIR"
PORT=8000

echo "📂 Serving files from: $(pwd)"
echo "🚀 Server starting on: http://localhost:$PORT"
echo "🎮 Open http://localhost:$PORT in your browser to play"
echo "⏹️  Press Ctrl+C to stop the server"
echo ""

# Try Python 3 first, then Python 2
if command -v python3 &> /dev/null; then
    python3 -m http.server $PORT
elif command -v python &> /dev/null; then
    python -m SimpleHTTPServer $PORT
else
    echo "❌ Error: Python not found. Please install Python to run the local server."
    exit 1
fi
