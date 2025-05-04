#!/bin/bash

# Create export directory
mkdir -p export/web

# Export the game
godot --headless --export-release "Web" export/web/index.html

# Check if export was successful
if [ $? -eq 0 ]; then
    echo "Export successful!"
    echo "Starting web server..."
    python server.py
else
    echo "Export failed!"
fi