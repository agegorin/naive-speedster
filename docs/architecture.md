# Naive Speedster Game Architecture

## Overview

Naive Speedster is a minimalist racing game with an open world and trial system. The game is built around a single large location where the player freely explores the world and participates in various trials, receiving unique car parts with personalities as rewards.

## Core Systems

### 1. World System

#### Location Structure
- **Single large map** divided into **zones (chunks)** for optimization
- Each zone is a separate subscene with its own geometry and objects
- Zones are organized in a grid system for ease of management

#### Dynamic Streaming
```
WorldManager (Singleton)
├── ChunkLoader - manages zone loading/unloading
├── VisibilityController - determines visible zones
└── StreamingConfiguration - loading distance settings
```

**Operating Principle:**
- Zones are loaded/unloaded dynamically based on player position
- Loading radius: active zone + neighboring zones (e.g., radius of 2-3 chunks)
- Distant zones are unloaded to free memory
- LOD (Level of Detail) for objects at far distances

**Technical Implementation (Godot):**
- `WorldManager` - Autoload singleton
- Zones as separate `.tscn` scenes
- `add_child()` / `remove_child()` for loading/unloading
- Using `Thread` or `ResourceLoader.load_threaded_*` for asynchronous loading

#### Zone Coordination
```
Chunk (Zone)
├── StaticGeometry (StaticBody3D) - landscape, walls
├── Props (Node3D) - decorations
├── TrialTriggers (Area3D) - trial triggers
└── SpawnPoints - spawn points for trial objects
```

### 2. Trials System

#### Trial Types
1. **Checkpoint Trial** - drive through a series of "gates" within a time limit
2. **Destination Trial** - reach a specific point
3. **Secret Trial** - find a hidden object/location
4. (Extensible for future types)

#### Trials Architecture
```
TrialManager (Singleton)
├── ActiveTrial - currently active trial (null if none)
├── CompletedTrials - list of completed trials (IDs)
└── TrialDefinitions - configuration of all trials

TrialDefinition (Resource)
├── id: String
├── type: TrialType enum
├── spawn_zone: String - ID of zone where trial is located
├── trial_objects: Array[TrialObject] - obstacles, gates, etc.
├── reward: PersonalityPart - reward for completion
└── parameters: Dictionary - specific parameters (time, coordinates)

TrialObject (Resource)
├── scene_path: String - path to .tscn object
├── position: Vector3 - position relative to zone
└── rotation: Vector3
```

#### Trial Activation
1. Player approaches trial trigger (`Area3D`)
2. UI shows prompt "Press [Button] to start"
3. On activation:
   - `TrialManager.start_trial(trial_id)`
   - All `trial_objects` are spawned (walls, ramps, obstacles, gates)
   - Trial timer/logic starts
   - UI switches to trial mode (timer, progress)

#### Trial Completion
- **Success:** reward added to inventory, trial marked as completed, objects removed
- **Failure/Exit:** objects removed, return to free exploration
- **Important:** location changes are **temporary** - all spawned objects are removed after completion

#### Technical Implementation
```gdscript
# Example structure
class_name TrialManager extends Node

var active_trial: Trial = null
var spawned_objects: Array[Node3D] = []

func start_trial(trial_id: String):
    var definition = get_trial_definition(trial_id)
    active_trial = Trial.new(definition)

    # Spawn objects
    for obj_def in definition.trial_objects:
        var obj = load(obj_def.scene_path).instantiate()
        obj.global_position = obj_def.position
        spawned_objects.append(obj)
        get_tree().current_scene.add_child(obj)

    active_trial.start()

func complete_trial(success: bool):
    # Clean up spawned objects
    for obj in spawned_objects:
        obj.queue_free()
    spawned_objects.clear()

    if success:
        PlayerInventory.add_part(active_trial.definition.reward)
        SaveManager.mark_trial_completed(active_trial.definition.id)

    active_trial = null
```

### 3. Personality Parts System

#### Part Structure
```
PersonalityPart (Resource)
├── id: String
├── part_type: PartType enum (Engine, Wheels, Body, etc.)
├── display_name: String
├── personality_traits: Array[Trait]
├── base_stats: Dictionary (speed, handling, acceleration, etc.)
└── compatibility_rules: Dictionary - which parts it's compatible with

Trait (Resource)
├── trait_name: String ("Aggressive", "Calm", "Playful")
├── influence_on_stats: Dictionary
└── harmony_preferences: Array[String] - list of compatible traits
```

#### Harmony System
- Each part has **traits (personality characteristics)**
- Parts can be **harmonious** or **conflicting**
- Harmony affects the vehicle's final characteristics

**Harmony Calculation:**
```gdscript
func calculate_vehicle_harmony(parts: Array[PersonalityPart]) -> float:
    var harmony_score = 0.0

    for i in range(parts.size()):
        for j in range(i + 1, parts.size()):
            harmony_score += calculate_part_compatibility(parts[i], parts[j])

    return clamp(harmony_score / max_possible_harmony, -1.0, 1.0)

func apply_harmony_modifier(base_stats: Dictionary, harmony: float) -> Dictionary:
    var modified = base_stats.duplicate()
    # Positive harmony enhances characteristics
    # Negative harmony weakens them
    for stat in modified:
        modified[stat] *= (1.0 + harmony * 0.3) # 30% maximum bonus/penalty
    return modified
```

#### Visual/Audio Feedback
- Visual effects on the car (color tints, particle effects) depending on harmony
- Engine and other parts sound effects change
- Animations can be more/less smooth

### 4. Vehicle System

#### Architecture
```
Vehicle (CharacterBody3D or VehicleBody3D)
├── VehiclePhysics - physical model
├── VehicleController - input and control
├── EquippedParts - current parts configuration
├── VehicleStats - resulting characteristics
└── VehicleVisuals - visual representation

EquippedParts
├── engine: PersonalityPart
├── wheels: PersonalityPart
├── body: PersonalityPart
└── (other slots)
```

#### Customization
- Customization menu opens via pause or special points
- UI shows:
  - Available parts in inventory
  - Current configuration
  - Preview of characteristics
  - Harmony indicator between parts
- Changes applied instantly (or with a short transition effect)

### 5. UI/UX Flows

#### Game Loading
```
App Start
    ↓
Loading Screen (with large location background if possible)
    ↓
Main Menu
├── Start/Continue
├── Settings
└── Exit
    ↓
[Start/Continue pressed]
    ↓
World Loading (progress bar)
    ↓
Spawn in World (starting position)
```

#### In-Game UI
```
HUD
├── Minimap (optional)
├── Speed/Stats
├── Trial Indicator (if trial is active)
└── Interaction Prompts

Pause Menu
├── Resume
├── Vehicle Customization
├── Settings
└── Exit to Main Menu
```

#### Customization Menu
```
Customization Screen
├── Part Slots Display
│   ├── Engine (with personality icon)
│   ├── Wheels (with personality icon)
│   └── Body (with personality icon)
├── Inventory Panel (available parts)
├── Stats Preview
│   ├── Base Stats
│   └── Harmony Modifier
└── Harmony Indicator (visual compatibility indicator)
```

### 6. Save System

#### What Gets Saved
```
SaveData (Resource)
├── player_progress
│   ├── completed_trials: Array[String] - IDs of completed trials
│   ├── unlocked_parts: Array[String] - IDs of unlocked parts
│   └── current_parts: Dictionary - current configuration
├── world_state
│   ├── player_position: Vector3
│   └── player_rotation: Vector3
└── metadata
    ├── save_version: int
    └── timestamp: int
```

#### Autosave
- Save after each **successful** trial completion
- Save on game exit
- Using Godot `ConfigFile` or `JSON` for cross-platform compatibility
- Path: `user://savegame.save`

#### Technical Implementation
```gdscript
# SaveManager (Singleton)
class_name SaveManager extends Node

const SAVE_PATH = "user://savegame.save"

func save_game():
    var save_data = {
        "player_progress": {
            "completed_trials": TrialManager.completed_trials,
            "unlocked_parts": PlayerInventory.unlocked_parts,
            "current_parts": Vehicle.equipped_parts.serialize()
        },
        "world_state": {
            "position": Player.global_position,
            "rotation": Player.global_rotation
        },
        "metadata": {
            "version": 1,
            "timestamp": Time.get_unix_time_from_system()
        }
    }

    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify(save_data))
    file.close()

func load_game() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return {}

    var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
    var json_string = file.get_as_text()
    file.close()

    var json = JSON.new()
    json.parse(json_string)
    return json.get_data()
```

### 7. Technical Implementation (Godot-specific)

#### Project Structure
```
res://
├── scenes/
│   ├── main_menu.tscn
│   ├── world/
│   │   ├── world.tscn (main scene)
│   │   └── chunks/
│   │       ├── chunk_0_0.tscn
│   │       ├── chunk_0_1.tscn
│   │       └── ...
│   ├── vehicle/
│   │   └── player_vehicle.tscn
│   ├── trials/
│   │   ├── checkpoint_gate.tscn
│   │   ├── obstacle_wall.tscn
│   │   └── ramp.tscn
│   └── ui/
│       ├── hud.tscn
│       ├── customization_menu.tscn
│       └── trial_ui.tscn
├── scripts/
│   ├── managers/
│   │   ├── world_manager.gd (Autoload)
│   │   ├── trial_manager.gd (Autoload)
│   │   ├── save_manager.gd (Autoload)
│   │   └── game_manager.gd (Autoload)
│   ├── vehicle/
│   │   ├── vehicle.gd
│   │   └── vehicle_controller.gd
│   ├── trials/
│   │   └── trial.gd
│   └── parts/
│       └── personality_part.gd
├── resources/
│   ├── parts/
│   │   ├── engines/
│   │   ├── wheels/
│   │   └── bodies/
│   ├── trials/
│   │   └── trial_definitions/
│   └── traits/
└── assets/
    ├── models/
    ├── materials/
    └── audio/
```

#### Autoload Singletons
Order matters for dependencies:
1. `SaveManager` - save system handling
2. `PlayerInventory` - parts inventory
3. `GameManager` - general game management
4. `WorldManager` - world and zone management
5. `TrialManager` - trial management

#### Optimization

**For mobile devices:**
- GL Compatibility renderer (already selected)
- Aggressive LOD for distant objects
- Smaller zone loading radius (1-2 chunks instead of 2-3)
- Simplified physics collisions
- Reduced particle effects

**For web:**
- Texture compression
- Bundle size minimization
- Progressive loading (if possible)

**For desktop:**
- Maximum quality
- Larger loading radius
- Extended visual effects

#### Camera
- **Third-person follow camera** behind the car
- Smoothed following (lerp/spring arm)
- Possibility of slight camera control (optional)
- Automatic adaptation at high speed

### 8. Development Phases (recommended)

#### Phase 1: Basic Infrastructure
1. Setup basic project structure
2. Create simple test location (without zones yet)
3. Basic car control with physics
4. Autoload managers (stubs)

#### Phase 2: World System
1. Divide test location into zones
2. Implement `WorldManager` with dynamic streaming
3. Performance testing

#### Phase 3: Trials System
1. Create basic trial types
2. Triggers and UI for activation
3. Spawn/despawn system for trial objects
4. Pass/fail logic

#### Phase 4: Personality Parts System
1. Data structure for parts
2. Harmony system and characteristics calculation
3. Customization UI
4. Integration with vehicle

#### Phase 5: Progress and Saves
1. Inventory system
2. Autosave
3. Reward system

#### Phase 6: Polish
1. Final UI/UX
2. Main menu
3. Platform optimization
4. Sound and visual effects

## Conclusion

This architecture provides:
- ✅ Scalability (easy to add new zones, trials, parts)
- ✅ Cross-platform compatibility (dynamic loading + optimization)
- ✅ Modularity (systems are independent)
- ✅ Gameplay uniqueness (personality parts system)
- ✅ Testing simplicity (each system is isolated)

Next steps: start with Phase 1 and iteratively build a prototype.
