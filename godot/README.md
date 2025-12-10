# MoonBunny - Godot Edition

A modern Godot 4.5 conversion of the classic 2007 rhythm game MoonBunny.

## About

MoonBunny is a 3D rhythm game where you control a bunny character flying through musical rings synchronized to the beat. This version has been completely rebuilt in Godot while maintaining the core gameplay mechanics of the original.

## Features

- **3D Rhythm Gameplay**: Fly through rings timed to music beats
- **Multiple Control Methods**: 
  - Keyboard (Arrow keys for movement + WASD/Spacebar for hitting)
  - Mouse (Direct positioning + Left click for hitting)
  - Gamepad (Left stick + Face buttons for hitting)
  - Touch screen (Direct touch with automatic hitting)
- **Scoring System**: Precision-based scoring (PERFECT, GOOD, OK, BAD, MISS)
- **Chain System**: Build combos for higher scores
- **Multiple Levels**: Various songs with different difficulty patterns
- **Modern Graphics**: Updated 3D graphics with particle effects
- **Smart Input Switching**: Automatic detection and switching between input methods

## Controls

### Movement
- **Arrow Keys**: Move the bunny (keyboard mode)
- **Mouse**: Direct position control (mouse mode)
- **Gamepad Left Stick**: Move the bunny (gamepad mode)
- **Touch Screen**: Direct touch control (touch mode)

### Ring Hitting
#### Type-Specific Hitting (Keyboard/Gamepad)
- **S Key / A Button**: Hit A rings (Blue)
- **A Key / X Button**: Hit C rings (Red)
- **D Key / B Button**: Hit B rings (Magenta)
- **W Key / Y Button**: Hit D rings (Yellow/Green)

#### Centralized Hitting (All Input Methods)
- **Spacebar**: Hit any ring (keyboard mode)
- **Left Mouse Button**: Hit any ring (mouse mode)
- **A Button**: Hit any ring (gamepad mode)
- **Touch Screen**: Automatic hitting when passing through rings (touch mode)

### Menu Navigation
- **Arrow Keys**: Navigate menus (traditional)
- **Mouse**: Click and hover on menu items
- **Touch**: Tap menu items and drag to scroll
- **Gamepad**: Left stick for navigation, A button to confirm
- **Space/Enter**: Confirm selection
- **Escape**: Back/Cancel

### Results Screen
- **Space/Enter/Escape**: Continue to main menu
- **Left Mouse Button**: Continue to main menu
- **A Button/Start Button**: Continue to main menu (gamepad)
- **Touch Screen**: Tap to continue to main menu

### Smart Input Switching
The game automatically detects and switches between input methods:
- Moving with keyboard activates keyboard control
- Moving mouse activates mouse control
- Using gamepad stick activates gamepad control  
- Touching screen activates touch control

## Installation

1. Download and install Godot 4.5 or later
2. Clone or download this repository
3. Open the project in Godot
4. Press F5 or click "Play" to run the game

## Level Format

Levels are stored in `assets/levels/[level_name]/`:
- `header.json`: Contains level metadata (title, artist, BPM, music file) in JSON format
- `Normal.json`: Contains ring positions and timing data as JSON with "content" field
- `[level_name].ogg`: Music file for the level
- `image.png`: Level preview image

### Example Level Structure
```
assets/levels/my_level/
├── header.json     # {"TITLE": "My Level", "ARTIST": "Artist", "BPM": 120}
├── Normal.json     # {"content": "0,0;1.5;A\n1,0;1.5;B\n..."}
├── my_level.ogg    # Music file
└── image.png       # Preview image
```

## Development

### Project Structure
- `scripts/`: Game logic and controllers
- `scenes/`: Godot scene files
- `assets/`: Game assets (sounds, textures, levels)
- `shaders/`: Custom shader files

### Key Components
- **Main.gd**: Main game state manager and UI controller
- **Level.gd**: Level gameplay logic, ring spawning, and hit detection
- **LevelSelect.gd**: Level selection interface
- **LevelResourceManager.gd**: Resource loading and management for web compatibility
- **AudioManager.gd**: Audio system management
- **HighScoreManager.gd**: Score tracking and persistence

### Level Creation
The project includes a level creator tool:
- `LevelCreator.gd` and `LevelCreator.tscn`: Interactive level creation interface
- See `LEVEL_CREATOR_README.md` for detailed instructions

## Export

### HTML5/Web Export
Use the provided export script:
```bash
./export_html.sh
```

This will:
1. Validate the project for errors
2. Export to HTML5 format
3. Create a compressed archive for deployment

## Original Credits

Based on the original MoonBunny (2007) by:
- Félix Cardoso
- Kao Félix  
- Marcelo Zacarias

## License

This Godot conversion maintains the spirit of the original academic project while modernizing it for current systems.
