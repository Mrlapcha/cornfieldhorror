# Phase 7 Checklist - Audio Manager

## Scope
- State-based audio system driven by gameplay state.
- Procedural sound generation (no external audio files needed).
- Audio bus routing for independent volume control.

## Architecture

### Audio Buses
Created programmatically on startup:
- **Master** — global volume
- **Ambient** — wind, environment
- **Music** — dark ambient drone
- **SFX** — footsteps, pickups, interactions
- **Voice** — heartbeat, breathing

### Autoload
- AudioManager: `res://scripts/systems/audio_manager.gd`
  - Registered in project.godot as `AudioManager`
  - Polls player/enemy state each frame
  - Drives all generators

### Procedural Generators
All use `AudioStreamGenerator` + `AudioStreamGeneratorPlayback`:

| Generator | Bus | Driven By |
|-----------|-----|-----------|
| `ProceduralHeartbeat` | Voice | Clown distance (BPM + volume) |
| `ProceduralWind` | Ambient | Constant + slight threat modulation |
| `ProceduralBreathing` | Voice | Stamina ratio + sprint/exhaustion |
| `ProceduralFootsteps` | SFX | Player velocity + sprint/crouch |
| `ProceduralDrone` | Music | Clown distance (dissonance + volume) |
| `SfxGenerator` | SFX | Game events (pickup, alert, chase) |

## Script References
- AudioManager: `res://scripts/systems/audio_manager.gd`
- Heartbeat: `res://scripts/audio/procedural_heartbeat.gd`
- Wind: `res://scripts/audio/procedural_wind.gd`
- Breathing: `res://scripts/audio/procedural_breathing.gd`
- Footsteps: `res://scripts/audio/procedural_footsteps.gd`
- Drone: `res://scripts/audio/procedural_drone.gd`
- SFX: `res://scripts/audio/sfx_generator.gd`

## Integration Points
- `collectible_item.gd` → `AudioManager.play_sfx("pickup")`
- `clown_ai.gd` → `AudioManager.play_sfx("alert")`, `AudioManager.play_sfx("chase_start")`
- `ending_manager.gd` → `AudioManager.trigger_ending_fade()`
- `player_controller.gd` → Added `is_sprinting()`, `is_crouching()` API

## Manual Test Flow
1. Run game → hear wind ambient + dark drone immediately.
2. Walk forward → hear timed footstep sounds.
3. Sprint → footsteps get faster, breathing intensifies.
4. Stop sprinting when exhausted → hear heavy breathing.
5. Approach clown → heartbeat starts, drone gets more dissonant.
6. Clown spots you → hear alert tension hit.
7. Chase begins → hear chase stinger sound.
8. Pick up item → hear chime SFX.
9. Trigger ending → all audio fades out over ~2.5 seconds.

## Swapping In Real Audio
To replace any procedural generator with a real audio file:
1. Replace the generator node with an `AudioStreamPlayer` using an `.ogg` or `.wav` file.
2. AudioManager's update methods will still control volume/pitch.
3. No other code changes needed.

## Done Definition
- Wind ambient plays on game start.
- Footsteps sync to player movement speed.
- Breathing intensifies on stamina drain.
- Heartbeat audio responds to clown proximity.
- Chase stinger plays on chase start.
- Pickup chime on item collection.
- Audio fades on ending trigger.
