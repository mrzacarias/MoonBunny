#!/bin/bash

# Music conversion script for MoonBunny performance optimization
# Converts MP3 files to OGG Vorbis with optimized settings for web

echo "Converting MP3 music files to OGG Vorbis for web optimization..."

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed. Please install it first:"
    echo "  macOS: brew install ffmpeg"
    exit 1
fi

# Find all MP3 files in level directories
find "/Users/mrzacarias/go/src/github.com/mrzacarias/MoonBunny/godot/assets/levels" -name "*.mp3" | while read mp3_file; do
    # Get directory and filename
    dir=$(dirname "$mp3_file")
    basename=$(basename "$mp3_file" .mp3)
    ogg_file="${dir}/${basename}.ogg"
    
    echo "Converting: $mp3_file"
    echo "       to: $ogg_file"
    
    # Convert with optimized settings for web
    # -q:a 4 = Quality level 4 (good for music, smaller than level 6)
    # -ar 44100 = Sample rate 44.1kHz
    ffmpeg -i "$mp3_file" -c:a libvorbis -q:a 4 -ar 44100 "$ogg_file" -y
    
    if [ $? -eq 0 ]; then
        # Show file size comparison
        mp3_size=$(ls -lh "$mp3_file" | awk '{print $5}')
        ogg_size=$(ls -lh "$ogg_file" | awk '{print $5}')
        echo "  ✓ Success: $mp3_size -> $ogg_size"
        
        # Calculate compression ratio
        mp3_bytes=$(stat -f%z "$mp3_file" 2>/dev/null || stat -c%s "$mp3_file")
        ogg_bytes=$(stat -f%z "$ogg_file" 2>/dev/null || stat -c%s "$ogg_file")
        ratio=$(echo "scale=1; $ogg_bytes * 100 / $mp3_bytes" | bc -l)
        echo "  Compression: ${ratio}% of original size"
    else
        echo "  ✗ Failed to convert $mp3_file"
    fi
    echo ""
done

echo "Music conversion complete!"
echo ""
echo "Total size comparison:"
echo "MP3 files:"
find "/Users/mrzacarias/go/src/github.com/mrzacarias/MoonBunny/godot/assets/levels" -name "*.mp3" -exec ls -lh {} \; | awk '{sum+=$5} END {print "Total MP3:", sum}'
echo "OGG files:"
find "/Users/mrzacarias/go/src/github.com/mrzacarias/MoonBunny/godot/assets/levels" -name "*.ogg" -exec ls -lh {} \; | awk '{sum+=$5} END {print "Total OGG:", sum}'
