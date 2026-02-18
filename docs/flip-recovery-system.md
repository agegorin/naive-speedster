# Flip Recovery System

## Overview

The flip recovery system automatically rights the vehicle when it ends up upside down, preventing the player from getting stuck. The system detects when the car is flipped, waits for a configurable timeout, then smoothly rotates the car back to an upright position.

## How It Works

### 1. Detection

The system continuously monitors the vehicle's orientation by checking its up vector (`basis.y`) against the world up direction.

**Detection Method**: Rotation angle only
- Calculates the angle between the car's up vector and world up (Vector3.UP)
- If angle exceeds `flip_detection_angle` (default: 120°), the car is considered upside down
- Threshold of 120° means the car must be significantly tilted before triggering recovery

### 2. Timeout Period

Once the car is detected as upside down, a timer starts counting.

**Timeout Duration**: Configurable via `flip_timeout` (default: 1.0 second)
- Gives the player a chance to naturally recover from a flip
- Prevents false triggers during mid-air flips or brief rollovers
- If the car rights itself before timeout, the timer resets

### 3. Recovery Sequence

When the timeout is reached, the recovery sequence begins:

1. **Freeze Physics**
   - `freeze = true` disables all physics simulation
   - Prevents player input from affecting the car
   - Stops all current motion

2. **Calculate Target Transform**
   - **Position**: Keeps current XZ (horizontal) position
   - **Height**: Lifts car by `recovery_height` (default: 2.0 units) above ground
   - **Ground Detection**: Uses raycast to find actual ground level below car
   - **Rotation**: Preserves current yaw (facing direction), resets pitch/roll to upright

3. **Smooth Animation**
   - **Duration**: `recovery_duration` (default: 0.5 seconds)
   - **Position**: Linear interpolation (lerp) from start to target
   - **Rotation**: Spherical interpolation (slerp) for smooth rotation
   - **Easing**: Ease-out cubic function for natural deceleration

4. **Complete Recovery**
   - Re-enables physics (`freeze = false`)
   - Resets linear and angular velocities to zero
   - Resets all flip detection state
   - Player regains full control

## Configuration Parameters

All parameters are exposed in the Inspector under the "Flip Recovery" group:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `flip_detection_angle` | float | 120.0 | Angle in degrees from upright to trigger flip detection |
| `flip_timeout` | float | 1.0 | Seconds to wait before starting auto-recovery |
| `recovery_height` | float | 2.0 | Height in units to lift car above ground during recovery |
| `recovery_duration` | float | 0.5 | Duration in seconds for the recovery animation |

## Technical Implementation

### File Location
`scripts/vehicle/vehicle_controller.gd`

### State Variables
```gdscript
var is_upside_down: bool = false        # Currently detected as flipped
var upside_down_timer: float = 0.0      # Time spent upside down
var is_recovering: bool = false          # Recovery sequence active
var recovery_timer: float = 0.0          # Progress through recovery animation
var recovery_start_transform: Transform3D   # Starting transform for interpolation
var recovery_target_transform: Transform3D  # Target upright transform
```

### Core Functions

**`_check_flip_status(delta)`**
- Runs every physics frame when not recovering
- Calculates angle from upright
- Manages timeout timer
- Triggers recovery when conditions met

**`_start_recovery()`**
- Freezes physics
- Calculates target position using raycast for ground detection
- Preserves yaw, resets pitch/roll
- Initializes recovery animation

**`_handle_recovery(delta)`**
- Runs every physics frame during recovery
- Interpolates position and rotation
- Uses ease-out cubic for smooth motion
- Completes when animation finishes

**`_complete_recovery()`**
- Unfreezes physics
- Zeros out velocities
- Resets all state variables

## Edge Cases Handled

1. **Mid-Air Flips**: Timer only counts when upside down, so brief flips during jumps don't trigger recovery
2. **Terrain Height**: Raycast detects ground below car, adjusting recovery height accordingly
3. **Velocity Reset**: All velocities zeroed to prevent sudden jerky motion after recovery
4. **Direction Preservation**: Car keeps its facing direction (yaw), only rotation to upright changes

## Future Enhancements

Possible improvements for later:

- Visual effects (particles, flash) during recovery
- Audio feedback (whoosh sound, impact sound)
- Manual recovery trigger (press a key to force flip recovery)
- Penalty system (time penalty, speed reduction after recovery)
- Disable recovery during trials (player must complete without flipping)
