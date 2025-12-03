MoonBunny
=========

Title Screen
<img src="http://i.imgur.com/xpuoms4.png"/>

MoonBunny it's a Rythm game about a BunnyBoy who flies inside rings on music based levels.

It's a python game, using pygame for basic game engine and Panda3D for graphics and state machine purposes. The game was a academic project released on 2007 for "Computer Graphics Project" discipline of my UFRGS graduation, made by <a href="http://www.ic.unicamp.br/~ra144644/index.html">Félix Cardoso</a>, <a href="https://github.com/kaofelix">Kao Félix</a> and myself. The project won the intern contest and granted us a brand new NVIDIA graphics card =)

## Running the Game (2024 Update)

This classic game has been updated to work with modern Python 3 and Panda3D. To run it:

### Prerequisites
- Python 3.8 or higher
- macOS, Linux, or Windows

### Installation & Running

1. **Clone or download this repository**

2. **Run the setup script:**
   ```bash
   ./run_moonbunny.sh
   ```

   Or manually:
   ```bash
   # Create virtual environment (first time only)
   python3 -m venv moonbunny_env
   
   # Activate virtual environment
   source moonbunny_env/bin/activate  # On macOS/Linux
   # or
   moonbunny_env\Scripts\activate     # On Windows
   
   # Install dependencies (first time only)
   pip install -r requirements.txt
   
   # Run the game
   python src/main.py
   ```

### Technical Notes

**Wiimote Compatibility Layer:**
The game includes a custom compatibility wrapper (`cwiid_compat.py`) that bridges the original `cwiid` API with the modern `wiiuse` library. This allows the 2007-era Wiimote code to work seamlessly with current systems while maintaining all original functionality.

**Dependencies:**
- **Panda3D 1.10+**: 3D graphics and game engine
- **pygame 2.0+**: Input handling and audio
- **wiiuse 0.12+**: Wiimote support (automatically installed)

### Controls

#### Keyboard (Default)
- **Arrow Keys**: Navigate menus and control the bunny
- **Space**: Confirm selection
- **Escape**: Back/Cancel

#### Wiimote Support 🎮
MoonBunny now supports Nintendo Wiimote controllers! The game includes:
- **Motion controls**: Use the Wiimote's accelerometer for character movement
- **Button controls**: A/B buttons for actions, D-pad for navigation
- **Nunchuk support**: Enhanced control with the Nunchuk attachment
- **IR pointer**: Point-and-click interface support

**Wiimote Setup:**
1. Enable Bluetooth on your computer
2. Put your Wiimote in pairing mode (press 1+2 buttons simultaneously)
3. Pair the Wiimote through your system's Bluetooth settings
4. Launch MoonBunny - it will automatically detect connected Wiimotes
5. Select "Wiimote" in the game's control options

**Note**: Wiimote support uses the modern `wiiuse` library with a compatibility layer for the original `cwiid` interface.

### Features
- Multiple levels with different music tracks
- Training mode
- Various control options (Keyboard, Mouse, Joystick, **Wiimote**)
- Motion-based gameplay with accelerometer support
- Particle effects and 3D graphics
- Score ranking system
- Alternative interaction methods (research project feature)

<a href="http://www.inf.ufrgs.br/~kcfelix/moonbunny.html">Older MoonBunny Project Page</a>

Later, in 2009, I used the game as base for my graduation final paper. The paper was a comparative study of several non-usual interaction methods, as WiiMote and Bratrack, a very intersting motion capture system based on infrared cameras. The work granted me a A grade and a publication on the 2010 Symposium on Virtual and Augmented Reality.

<a href="https://www.dropbox.com/s/95pffqe1p7fg47f/ZACARIAS_M_R_Estudo_de_Interacao_em_Jogos_de_Ritmo.pdf">Graduation Final Paper</a>

<a href="http://vimeo.com/5213718">Video Resume of project</a>

<a href="https://www.dropbox.com/s/ws5maop59ot4orw/non-conventional_interaction_study_on_rythm_games.pdf">SVR2010 Paper</a>

Ingame 1
<img src="http://i.imgur.com/M7Vj8hS.png"/>

Ingame 2
<img src="http://i.imgur.com/66l3aRl.png"/>
