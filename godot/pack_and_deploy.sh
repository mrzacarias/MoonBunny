#!/bin/bash

# MoonBunny Pack and Deploy Script
# This script exports the Godot project to HTML5/WebAssembly format, creates a compressed archive, and deploys to itch.io

set -e  # Exit on any error

echo "🚀 Starting MoonBunny pack and deploy..."

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

# Skip validation since this is already a Godot 4 project
echo "📝 Skipping validation (Godot 4 project)..."

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
        
        # Create compressed archive in the root MoonBunny directory
        echo "📦 Creating compressed archive..."
        ARCHIVE_NAME="../moonbunny-html.zip"
        
        # Remove old archive if it exists
        if [ -f "$ARCHIVE_NAME" ]; then
            rm "$ARCHIVE_NAME"
            echo "🗑️  Removed old archive"
        fi
        
        cd "$OUTPUT_DIR"
        zip -r "$ARCHIVE_NAME" . -x "*.DS_Store" > /dev/null 2>&1
        cd - > /dev/null
        
        if [ -f "$ARCHIVE_NAME" ]; then
            ARCHIVE_SIZE=$(ls -lh "$ARCHIVE_NAME" | awk '{print $5}')
            echo "✅ Archive created: moonbunny-html.zip ($ARCHIVE_SIZE)"
            echo "📁 Archive location: $(realpath $ARCHIVE_NAME)"
            
            # Deploy to itch.io using butler
            echo "🚀 Deploying to itch.io..."
            
            # Check if butler is available
            if ! command -v butler &> /dev/null; then
                echo "⚠️  Butler not found. Please install butler to deploy to itch.io:"
                echo "   Visit: https://itch.io/docs/butler/"
                echo "   Or run: brew install butler"
                echo "📦 Archive created successfully, but skipping itch.io deployment"
            else
                # Deploy using butler
                # The :web channel indicates this is a web/HTML5 build that runs in browser
                echo "📤 Uploading to zacasoft/moonbunny:web..."
                butler push "$ARCHIVE_NAME" zacasoft/moonbunny:web --userversion "$(date +%Y.%m.%d.%H%M)"
                
                if [ $? -eq 0 ]; then
                    echo "✅ Successfully deployed to itch.io!"
                    echo "🌐 Game updated at: https://zacasoft.itch.io/moonbunny"
                else
                    echo "❌ Failed to deploy to itch.io"
                    echo "📦 Archive is available locally for manual upload"
                fi
            fi
        else
            echo "⚠️  Warning: Failed to create archive"
        fi
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

echo "🎉 Pack and deploy process completed!"
