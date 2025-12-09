#!/bin/bash

# MoonBunny HTML Export Script
# This script exports the Godot project to HTML5/WebAssembly format

set -e  # Exit on any error

echo "🚀 Starting MoonBunny HTML export..."

# Check if Godot is available
GODOT_PATH="/Applications/Godot.app/Contents/MacOS/Godot"
if [ ! -f "$GODOT_PATH" ]; then
    echo "❌ Error: Godot not found at $GODOT_PATH"
    echo "Please install Godot or update the GODOT_PATH in this script"
    exit 1
fi

# Create output directory if it doesn't exist
OUTPUT_DIR="../html"
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "📁 Creating output directory: $OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
fi

# First, validate the project by importing it
echo "🔍 Validating project..."
"$GODOT_PATH" --headless --validate-conversion-3to4 --quit 2>&1 | tee /tmp/godot_validation.log

# Check for script errors by doing a quick parse
echo "📝 Checking for script errors..."
"$GODOT_PATH" --headless --check-only --quit 2>&1 | tee /tmp/godot_check.log

# Look for errors in the check output
if grep -i "error\|failed\|exception" /tmp/godot_check.log > /dev/null; then
    echo "❌ Script validation failed! Errors found:"
    grep -i "error\|failed\|exception" /tmp/godot_check.log
    echo ""
    echo "📋 Full validation log:"
    cat /tmp/godot_check.log
    exit 1
fi

# Export the project
echo "🔨 Exporting project to HTML5..."
"$GODOT_PATH" --headless --export-release "Web" "$OUTPUT_DIR/index.html" 2>&1 | tee /tmp/godot_export.log

# Check if export was successful
EXPORT_EXIT_CODE=$?
if [ $EXPORT_EXIT_CODE -eq 0 ]; then
    # Double-check that key files were actually created
    if [ -f "$OUTPUT_DIR/index.html" ] && [ -f "$OUTPUT_DIR/index.js" ] && [ -f "$OUTPUT_DIR/index.wasm" ]; then
        echo "✅ Export completed successfully!"
        echo "📂 Files exported to: $(realpath $OUTPUT_DIR)"
        echo "🌐 Open http://localhost:8080 in your browser to play (if server is running)"
        
        # Show file sizes for verification
        echo "📊 Generated files:"
        ls -lh "$OUTPUT_DIR"/index.* | awk '{print "  " $9 " (" $5 ")"}'
    else
        echo "❌ Export appeared successful but required files are missing!"
        echo "📋 Export log:"
        cat /tmp/godot_export.log
        exit 1
    fi
else
    echo "❌ Export failed with exit code $EXPORT_EXIT_CODE!"
    echo "📋 Export log:"
    cat /tmp/godot_export.log
    exit 1
fi

# Clean up temp files
rm -f /tmp/godot_*.log
