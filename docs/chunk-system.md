# Chunk System Design

## Overview

The world is divided into a grid of square chunks, each 100×100 units in size. Chunks are loaded and unloaded dynamically based on the player's position to optimize memory and performance.

## Coordinate System

### Grid Coordinates
- Chunks use integer coordinates (x, y) where y represents the Z-axis in 3D space
- Chunk (0, 0) is centered at world position (0, 0, 0)
- Chunk (1, 0) is at world position (100, 0, 0)
- Chunk (0, -1) is at world position (0, 0, -100)

### Naming Convention
- Pattern: `chunk_X_Y.tscn`
- Examples:
  - `chunk_0_0.tscn` - Center chunk
  - `chunk_-1_1.tscn` - Northwest chunk
  - `chunk_2_-3.tscn` - Southeast chunk

### World Position to Chunk Coordinate
```gdscript
func get_chunk_coord(world_position: Vector3) -> Vector2i:
    return Vector2i(
        int(floor(world_position.x / CHUNK_SIZE)),
        int(floor(world_position.z / CHUNK_SIZE))
    )
```

### Chunk Coordinate to World Position
```gdscript
func get_world_position(chunk_coord: Vector2i) -> Vector3:
    return Vector3(
        chunk_coord.x * CHUNK_SIZE,
        0,
        chunk_coord.y * CHUNK_SIZE
    )
```

## Chunk Size

- **CHUNK_SIZE**: 100.0 units
- Each chunk covers a 100×100 area in the XZ plane
- Height (Y-axis) is unlimited per chunk

## Loading Radius

- **LOAD_RADIUS**: 2 chunks (configurable)
- Loads all chunks within LOAD_RADIUS of the player's current chunk
- For radius 2: loads a 5×5 grid (25 chunks total) centered on player
- For radius 1: loads a 3×3 grid (9 chunks total)

## Chunk Structure

### Scene Hierarchy
```
ChunkNode (Node3D with Chunk script)
├── StaticGeometry (StaticBody3D)
│   ├── MeshInstance3D
│   └── CollisionShape3D
├── Props (Node3D)
│   └── [Various prop nodes]
├── TrialTriggers (Node3D)
│   └── [Area3D trigger nodes]
└── SpawnPoints (Node3D)
    └── [Marker3D spawn points]
```

### ChunkData Resource
- Stores metadata about each chunk
- Fields:
  - `chunk_coord`: Vector2i - Grid coordinate
  - `scene_path`: String - Path to .tscn file
  - `is_loaded`: bool - Load state
  - `has_trials`: bool - Whether chunk contains trials
  - `trial_ids`: Array[String] - IDs of trials in this chunk

## Streaming Behavior

### Loading
1. Player moves to new position
2. WorldManager calculates current chunk coordinate
3. Determines which chunks should be loaded (within LOAD_RADIUS)
4. Loads missing chunks asynchronously
5. Adds loaded chunks to scene tree

### Unloading
1. Identifies chunks beyond LOAD_RADIUS
2. Removes chunks from scene tree
3. Frees memory (unless cached)

### Caching
- Recently unloaded chunks kept in cache
- Avoids reloading when player moves back and forth
- Cache size configurable (default: 5 chunks)

## Example Layout

For a 3×3 test grid:
```
(-1,1)  (0,1)  (1,1)
(-1,0)  (0,0)  (1,0)  <- Center row
(-1,-1) (0,-1) (1,-1)
```

World positions:
```
(-100,100)  (0,100)  (100,100)
(-100,0)    (0,0)    (100,0)    <- Center
(-100,-100) (0,-100) (100,-100)
```

## Performance Considerations

- Asynchronous loading prevents frame drops
- Chunk boundaries aligned to 100-unit grid for simple calculation
- LOD (Level of Detail) can be added per-chunk for distant geometry
- Static geometry should use merged meshes where possible
- Collision shapes should be simplified for better physics performance
