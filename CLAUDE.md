# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Naive Speedster** is a minimalist racing game built with Godot 4. Players control a customizable car in a stark white open world environment, discovering and completing trials scattered throughout the landscape.

**Design Philosophy:**
- Minimalist white aesthetic
- Exploration-based gameplay with trials/challenges
- Cross-platform targeting (mobile, web, desktop)
- Focus on car customization with unique "personality" system where car parts have characteristics that affect performance

## Development Commands

### Running the Project
```bash
# Open in Godot Editor
godot -e project.godot

# Run the game
godot project.godot

# Run in debug mode
godot --debug project.godot
```

### Building Exports
```bash
# Export for specific platform (after setting up export presets in editor)
godot --export "Linux/X11" build/linux/naive-speedster.x86_64
godot --export "Windows Desktop" build/windows/naive-speedster.exe
godot --export "HTML5" build/web/index.html
godot --export "Android" build/android/naive-speedster.apk
```

### Testing
Godot doesn't have a built-in command-line test runner by default. Tests are typically run through:
- The Godot editor's built-in test features
- GUT (Godot Unit Test) addon if added to the project
- Manual playtesting via the play button in the editor

## Technical Configuration

**Engine Version:** Godot 4.5
**Renderer:** GL Compatibility (selected for broad platform support including mobile and web)

The GL Compatibility renderer is intentionally chosen over Forward+ or Mobile renderers to ensure the game runs on the widest range of devices while maintaining the clean, minimalist aesthetic.

## Architecture Notes

### Project Structure
As this project develops, expect the following Godot-standard organization:
- **Scenes (.tscn):** Godot's node-based scene files for game objects, UI, levels
- **Scripts (.gd):** GDScript files containing game logic
- **Resources:** Reusable data assets (materials, meshes, textures)
- **Autoload/Singletons:** Global managers for game state, settings, etc.

### Key Design Considerations

**Car Personality System:**
The core innovation is that car parts have personalities/characteristics:
- Parts can "prefer" certain conditions or behaviors
- Parts develop relationships affecting combined performance
- Customization involves harmony between parts, not just stats
- Performance changes based on how parts "get along"

When implementing vehicle systems, this personality mechanic should be considered as a first-class feature, not an afterthought.

**Open World with Trials:**
The game is structured as a small open world with scattered challenges rather than a linear track sequence. Navigation, discovery, and exploration are as important as racing mechanics.

**Visual Style:**
The white, minimalist aesthetic is central to the game's identity. Any visual elements added should reinforce this clean, stark look rather than adding complexity.

**Vehicle Systems:**
The vehicle includes several quality-of-life features:
- **Flip Recovery System**: Automatically rights the car if it's upside down for more than 1 second. See `docs/flip-recovery-system.md` for full details.
- **Smooth Follow Camera**: Camera smoothly follows the vehicle with banking effects during turns while maintaining horizontal stabilization.
- **Chunk Streaming**: World dynamically loads/unloads zones based on player position for optimal performance.

## Working with Godot Projects

**Scene Files:** `.tscn` files are Godot's node-tree format. While they're text-based, direct editing is discouraged - use the Godot editor instead.

**GDScript:** Godot's primary scripting language. Python-like syntax with static typing support (use type hints).

**Node System:** Godot uses a tree of nodes. Every game object is a node or scene composed of nodes. Understanding the node system is essential for working with this codebase.

**Signals:** Godot's event system. Prefer signals over direct function calls for decoupled communication between nodes.

## Documentation

Design documentation is in `docs/main.md` - refer to it for the full game concept, feature ideas, and design rationale.
