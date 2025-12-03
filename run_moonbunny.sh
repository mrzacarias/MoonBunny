#!/bin/bash

# MoonBunny Game Launcher
# This script activates the virtual environment and runs the game

cd "$(dirname "$0")"

echo "Starting MoonBunny..."
echo "Activating virtual environment..."

source moonbunny_env/bin/activate

echo "Launching game..."
python main.py

echo "Game ended."
