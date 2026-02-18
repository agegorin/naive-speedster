# Naive Speedster Development Plan

This plan outlines the development roadmap for Naive Speedster. Each task has a checkbox to track completion status.

## Phase 1: Basic Infrastructure

### Project Setup
- [x] Create folder structure (scenes/, scripts/, resources/, assets/)
- [x] Set up Autoload singletons configuration in project settings
- [x] Configure project settings (physics layers, input map)
- [x] Create basic input action map (accelerate, brake, steer, pause, interact)
- [ ] Set up export presets for target platforms (desktop, mobile, web)

### Test Environment
- [x] Create simple test world scene (flat plane with boundaries)
- [x] Add basic lighting (DirectionalLight3D, environment)
- [x] Create test materials for ground and objects
- [x] Add basic camera placeholder

### Vehicle Foundation
- [x] Create player vehicle scene using VehicleBody3D
- [x] Implement basic vehicle physics (wheels, suspension)
- [x] Create VehicleController script for input handling
- [x] Implement basic movement (acceleration, braking, steering)
- [x] Add simple third-person camera with SpringArm3D
- [ ] Test vehicle physics and adjust parameters

### Manager Stubs
- [x] Create GameManager singleton (stub)
- [x] Create SaveManager singleton (stub)
- [x] Create PlayerInventory singleton (stub)
- [x] Create WorldManager singleton (stub)
- [x] Create TrialManager singleton (stub)
- [ ] Test that all singletons load correctly

## Phase 2: World System

### Zone System Design
- [x] Design grid coordinate system for chunks
- [x] Create chunk naming convention (chunk_X_Y.tscn)
- [x] Define chunk size and boundaries
- [x] Create ChunkData resource class

### World Manager Implementation
- [x] Implement chunk loading logic in WorldManager
- [x] Implement chunk unloading logic
- [x] Add chunk visibility detection based on player position
- [x] Implement asynchronous chunk loading (ResourceLoader.load_threaded_*)
- [x] Add loading radius configuration

### Test Chunks
- [x] Create 3x3 grid of test chunks (9 total)
- [x] Add unique identifiable features to each chunk
- [x] Add collision geometry to chunks
- [x] Test chunk streaming while driving

### Optimization
- [ ] Implement LOD system for distant objects
- [x] Add chunk caching to avoid reloading
- [x] Test performance with chunk streaming
- [x] Optimize memory usage

## Phase 3: Trials System

### Trial Data Structure
- [x] Create TrialDefinition resource class
- [x] Create TrialObject resource class
- [ ] Create Trait resource class
- [x] Define TrialType enum (Checkpoint, Destination, Secret)

### Trial Manager Core
- [x] Implement trial registration system
- [x] Implement start_trial() function
- [x] Implement complete_trial() function
- [x] Add trial object spawning logic
- [x] Add trial object cleanup logic
- [x] Track completed trials list

### Trial Types Implementation
- [x] Create checkpoint gate scene and script
- [x] Implement Checkpoint Trial logic (gates + timer)
- [ ] Create destination marker scene
- [ ] Implement Destination Trial logic (reach point)
- [ ] Create secret collectible scene
- [ ] Implement Secret Trial logic (find object)

### Trial Triggers
- [x] Create trial trigger Area3D scene
- [x] Implement trigger detection (player enters area)
- [x] Add trial activation prompt UI
- [x] Connect triggers to TrialManager

### Trial UI
- [x] Create trial HUD scene (timer, progress)
- [x] Implement timer display
- [x] Implement checkpoint counter
- [x] Add trial start/complete/fail notifications
- [x] Add trial exit option

### Test Trials
- [x] Create 3 test trials (one of each type)
- [x] Place trials in test chunks
- [x] Test trial activation and completion
- [x] Test trial failure and cleanup

## Phase 4: Personality Parts System

### Part Data Structure
- [ ] Create PersonalityPart resource class
- [ ] Create PartType enum (Engine, Wheels, Body, etc.)
- [ ] Define base stats structure (speed, handling, acceleration)
- [ ] Create Trait resource with harmony preferences

### Harmony System
- [ ] Implement calculate_part_compatibility() function
- [ ] Implement calculate_vehicle_harmony() function
- [ ] Implement apply_harmony_modifier() function
- [ ] Add harmony calculation to vehicle stats

### Test Parts Creation
- [ ] Create 3 engine parts with different traits
- [ ] Create 3 wheel parts with different traits
- [ ] Create 3 body parts with different traits
- [ ] Define trait compatibility rules

### Vehicle Integration
- [ ] Create EquippedParts class
- [ ] Add part slots to Vehicle
- [ ] Implement stats calculation from equipped parts
- [ ] Apply calculated stats to vehicle physics
- [ ] Test different part combinations

### Visual/Audio Feedback
- [ ] Add particle effects for harmony (positive/negative)
- [ ] Implement engine sound variation based on parts
- [ ] Add color tint based on harmony level
- [ ] Test feedback during gameplay

## Phase 5: Customization UI

### Menu Structure
- [ ] Create customization menu scene
- [ ] Design layout (part slots + inventory + stats)
- [ ] Implement menu open/close functionality
- [ ] Connect to pause menu

### Part Slots Display
- [ ] Create part slot UI component
- [ ] Display currently equipped parts
- [ ] Show part personality icons
- [ ] Implement part slot selection

### Inventory Panel
- [ ] Display available parts from PlayerInventory
- [ ] Show part stats and traits
- [ ] Implement part selection from inventory
- [ ] Add filtering by part type

### Stats Preview
- [ ] Display current vehicle base stats
- [ ] Calculate and show harmony modifier
- [ ] Show final stats after harmony
- [ ] Update preview in real-time

### Harmony Indicator
- [ ] Create visual harmony indicator (bar/gauge)
- [ ] Show compatibility between selected parts
- [ ] Update indicator when parts change
- [ ] Add color coding (green/yellow/red)

### Part Equipping
- [ ] Implement drag-and-drop or click-to-equip
- [ ] Apply part changes to vehicle
- [ ] Save current configuration
- [ ] Test customization flow

## Phase 6: Progress and Save System

### Player Inventory
- [ ] Implement PlayerInventory singleton
- [ ] Add part unlocking system
- [ ] Track owned parts list
- [ ] Implement part addition from trial rewards

### Save Data Structure
- [ ] Create SaveData structure
- [ ] Define what gets saved (progress, parts, position)
- [ ] Add save version for future compatibility

### Save/Load Implementation
- [ ] Implement save_game() function
- [ ] Implement load_game() function
- [ ] Use JSON format for cross-platform compatibility
- [ ] Handle missing/corrupted save files

### Autosave
- [ ] Trigger save after trial completion
- [ ] Trigger save on game exit
- [ ] Add save indicator UI
- [ ] Test save/load cycle

### Progress Tracking
- [ ] Track completed trials
- [ ] Track unlocked parts
- [ ] Store player position and rotation
- [ ] Restore state on load

## Phase 7: Main Menu and Flow

### Main Menu
- [ ] Create main menu scene
- [ ] Add Start/Continue button
- [ ] Add Settings button (placeholder)
- [ ] Add Exit button
- [ ] Implement scene transitions

### Loading Screen
- [ ] Create loading screen scene
- [ ] Add progress bar
- [ ] Show loading tips/hints
- [ ] Test with world loading

### Game Flow
- [ ] Implement app start → main menu flow
- [ ] Implement main menu → world loading flow
- [ ] Implement world spawn at saved position
- [ ] Add return to main menu from pause

### Settings (Basic)
- [ ] Create settings menu scene
- [ ] Add graphics quality options
- [ ] Add audio volume controls
- [ ] Save settings to config file

## Phase 8: Polish and Optimization

### HUD
- [ ] Create in-game HUD scene
- [ ] Add speedometer
- [ ] Add minimap (optional)
- [ ] Add interaction prompts

### Pause Menu
- [ ] Create pause menu scene
- [ ] Add Resume option
- [ ] Add Vehicle Customization option
- [ ] Add Settings option
- [ ] Add Exit to Main Menu option

### Platform Optimization
- [ ] Configure mobile-specific settings
- [ ] Configure web-specific settings
- [ ] Configure desktop-specific settings
- [ ] Test on all target platforms

### Audio
- [ ] Add engine sound effects
- [ ] Add UI sound effects
- [ ] Add ambient environment sounds
- [ ] Implement audio mixing

### Visual Polish
- [ ] Enhance minimalist aesthetic
- [ ] Add particle effects (dust, etc.)
- [ ] Improve lighting and shadows
- [ ] Add post-processing effects (if appropriate)

### Final Testing
- [ ] Full playthrough test
- [ ] Test all trial types
- [ ] Test save/load system thoroughly
- [ ] Test customization system
- [ ] Performance testing on target platforms
- [ ] Bug fixing and refinement

## Phase 9: Content Creation

### World Expansion
- [ ] Design full world layout
- [ ] Create all required chunks
- [ ] Add environmental details
- [ ] Place all trial locations

### Trial Design
- [ ] Create 10-15 Checkpoint Trials
- [ ] Create 5-10 Destination Trials
- [ ] Create 5-10 Secret Trials
- [ ] Balance difficulty progression

### Part Creation
- [ ] Create full set of engine parts (8-10)
- [ ] Create full set of wheel parts (8-10)
- [ ] Create full set of body parts (8-10)
- [ ] Balance stats and harmony relationships

### Reward Distribution
- [ ] Assign rewards to each trial
- [ ] Ensure progression balance
- [ ] Test unlock progression

## Notes

- Each phase builds on previous phases
- Test thoroughly before moving to next phase
- Some tasks can be done in parallel within a phase
- Adjust plan as needed based on discoveries during development
- Focus on core gameplay loop first (Phases 1-4)
- Polish comes after core systems work (Phases 7-8)
