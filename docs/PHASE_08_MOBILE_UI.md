# Phase 8 Checklist - Mobile Controls + UI Overhaul + Real Audio

## Scope
- Replace emoji HUD with hand-drawn PNG icons
- Swap procedural audio generators with real audio files
- Add dark ambient background music loop
- Implement mobile virtual joystick + touch action buttons
- Auto-detect touch vs keyboard/mouse

## Assets Integrated

### UI Icons (128px Dark Set)
| File | Used For |
|------|---------|
| `icon_key.png` | Key inventory row |
| `icon_notes.png` | Notes inventory row |
| `icon_flashlight.png` | Flashlight row |
| `icon_battery.png` | Batteries row |
| `icon_matches.png` | Matches row |
| `icon_fuel.png` | Fuel can row |
| `icon_musicbox.png` | Music box row |
| `icon_skull.png` | Objective row |

### Mobile Controller Buttons
| File | Used For |
|------|---------|
| `Analog_background.png` | Joystick base |
| `Analog.png` | Joystick knob |
| `Sprint_icon.png` | Sprint button |
| `Hand_icon.png` | Interact button |
| `Flashlight_icon.png` | Flashlight toggle button |
| `Pause_icon.png` | Pause button |

### Audio Files
| File | Bus | Usage |
|------|-----|-------|
| `music/dark_ambient.ogg` | Music | Background music loop |
| `ambient/creepy_ambience.wav` | Ambient | Environmental ambience loop |
| `sfx/pickup_key.wav` | SFX | Item pickup |
| `sfx/flashlight_on.wav` | SFX | Flashlight toggle on |
| `sfx/flashlight_off.wav` | SFX | Flashlight toggle off |
| `sfx/match_strike.wav` | SFX | Match striking |
| `sfx/gasp.wav` | SFX | Player caught gasp |
| `sfx/clown_laugh.wav` | SFX | Clown encounter |
| `stingers/chase_stinger.wav` | SFX | Chase initiation |
| `stingers/alert_stinger.wav` | SFX | Clown alert |

## Architecture

### Touch Controls
- `TouchControlOverlay` (CanvasLayer, layer 12)
  - `VirtualJoystick` — injects move_forward/back/left/right input actions
  - `TouchLookArea` — converts screen drag to InputEventMouseMotion
  - `SprintBtn` — holds sprint action
  - `InteractBtn` — fires interact action (hidden when not near interactable)
  - `FlashlightBtn` — fires flashlight_toggle action
  - `PauseBtn` — toggles game pause
- Auto-hide: keyboard/mouse input hides touch controls, touch input shows them

### Audio
- Real audio files play first via AudioStreamPlayer
- Procedural generators kept as fallback + for dynamic sounds (heartbeat, breathing, drone)
- Dark ambient OGG loops as background music

## Manual Test Flow
1. Run on desktop: touch controls should be hidden
2. Touch the screen: touch controls appear
3. Use keyboard/mouse: touch controls auto-hide
4. HUD shows proper icons, no emojis
5. Background music plays
6. Flashlight toggle plays click sound
7. Item pickup plays key pickup sound
8. Clown alert/chase plays real stinger sounds
