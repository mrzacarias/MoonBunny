#!/bin/bash

# Audio conversion script for MoonBunny performance optimization
# Converts WAV files to OGG Vorbis for better web performance

echo "Converting WAV files to OGG Vorbis for web optimization..."

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed. Please install it first:"
    echo "  macOS: brew install ffmpeg"
    echo "  Ubuntu: sudo apt install ffmpeg"
    exit 1
fi

# Directory containing audio files
AUDIO_DIR="/Users/mrzacarias/go/src/github.com/mrzacarias/MoonBunny/godot/assets/sounds"
cd "$AUDIO_DIR"

# Convert each WAV file to OGG
for wav_file in *.wav; do
    if [ -f "$wav_file" ]; then
        # Get filename without extension
        basename=$(basename "$wav_file" .wav)
        ogg_file="${basename}.ogg"
        
        echo "Converting: $wav_file -> $ogg_file"
        
        # Convert with good quality settings for web
        # -q:a 6 = Quality level 6 (good balance of size/quality)
        # -ar 44100 = Sample rate 44.1kHz
        ffmpeg -i "$wav_file" -c:a libvorbis -q:a 6 -ar 44100 "$ogg_file" -y
        
        if [ $? -eq 0 ]; then
            # Show file size comparison
            wav_size=$(ls -lh "$wav_file" | awk '{print $5}')
            ogg_size=$(ls -lh "$ogg_file" | awk '{print $5}')
            echo "  ✓ Success: $wav_size -> $ogg_size"
        else
            echo "  ✗ Failed to convert $wav_file"
        fi
    fi
done

echo ""
echo "Conversion complete! Next steps:"
echo "1. Update your Godot scripts to use .ogg files instead of .wav"
echo "2. Test the audio quality in your game"
echo "3. If satisfied, you can delete the original .wav files"
echo ""
echo "File size comparison:"
du -sh *.wav *.ogg 2>/dev/null | sort
