# MoonBunny - Godot Edition

A modern Godot 4.5 conversion of the classic 2007 rhythm game MoonBunny.

## About

MoonBunny is a 3D rhythm game where you control a bunny character flying through musical rings synchronized to the beat. This version has been completely rebuilt in Godot while maintaining the core gameplay mechanics of the original.

## Features

- **3D Rhythm Gameplay**: Fly through rings timed to music beats
- **Multiple Control Methods**: 
  - Keyboard (Arrow keys + ZXCV for buttons)
  - Gamepad support
  - Mouse control
- **Scoring System**: Precision-based scoring (PERFECT, GOOD, OK, BAD, MISS)
- **Chain System**: Build combos for higher scores
- **Multiple Levels**: Various songs with different difficulty patterns
- **Modern Graphics**: Updated 3D graphics with particle effects

## Controls

### Movement
- **Arrow Keys** or **WASD**: Move the bunny
- **Gamepad Left Stick**: Move the bunny
- **Mouse**: Direct position control (when mouse mode is enabled)

### Actions
- **Z**: Button A (Blue rings)
- **X**: Button B (Red rings) 
- **C**: Button C (Magenta rings)
- **V**: Button D (Green rings)
- **Gamepad Buttons**: Face buttons correspond to ring colors

### Menu Navigation
- **Arrow Keys**: Navigate menus
- **Space/Enter**: Confirm selection
- **Escape**: Back/Cancel

## Installation

1. Download and install Godot 4.5 or later
2. Clone or download this repository
3. Open the project in Godot
4. Press F5 or click "Play" to run the game

## Level Format

Levels are stored in `assets/levels/[level_name]/`:
- `header.lvl`: Contains level metadata (title, artist, BPM, music file)
- `Normal.rng`: Contains ring positions and timing data

## Development

### Project Structure
- `scripts/`: Game logic and controllers
- `scenes/`: Godot scene files
- `assets/`: Game assets (sounds, textures, levels)

### Key Components
- **GameManager**: Handles game state, scoring, and level loading
- **BunnyController**: Player character movement and input
- **LevelManager**: Level progression, ring spawning, and hit detection
- **UI Scripts**: Menu navigation and gameplay interface

## Original Credits

Based on the original MoonBunny (2007) by:
- Félix Cardoso
- Kao Félix  
- Marcelo Zacarias

## License

This Godot conversion maintains the spirit of the original academic project while modernizing it for current systems.
