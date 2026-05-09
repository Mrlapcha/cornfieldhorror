# Phase 1 Checklist - Player Controller

## Scope
- First-person movement (walk and sprint).
- Crouch with smooth camera/collider transition.
- Flashlight with battery drain.
- Interaction ray for usable objects.

## Input Actions (logical names)
- `move_forward`, `move_back`, `move_left`, `move_right`
- `sprint`, `crouch`
- `flashlight_toggle`, `interact`

Note: this phase auto-registers default keyboard input at runtime if actions do not exist yet, so iteration can start immediately.

## Manual Test Flow
1. Run the project.
2. Move using WASD or arrow keys.
3. Hold sprint and confirm faster movement.
4. Hold crouch and confirm lower camera + slower movement.
5. Press flashlight toggle and confirm on/off behavior.
6. Leave flashlight on and confirm it eventually dies.
7. Point at an interactable object (with `interact(player)` method) and press interact.

## Done Definition
- No script errors.
- Smooth movement on desktop test build.
- Ready for Phase 2 world greybox.