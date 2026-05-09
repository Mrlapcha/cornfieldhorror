# Phase 6 Checklist - Ending Trigger System

## Scope
- Escape ending via final key inside the locked barn.
- Well ritual ending using music box at the well.
- Caught ending when clown reaches player during chase.
- Burn ending by igniting burn pile with matches + fuel can.
- Secret stay ending after standing still for 5 minutes.

## Scene and Script References
- Ending manager: `res://scripts/systems/ending_manager.gd`
- Ending UI: `res://scenes/ui/EndingOverlay.tscn`
- Ending UI script: `res://scripts/ui/ending_overlay.gd`
- Barn door gate check: `res://scripts/interactables/barn_door_gate.gd`
- Final key completion trigger: `res://scripts/interactables/collectible_item.gd`
- Well interaction: `res://scripts/interactables/well_ritual_point.gd`
- Burn interaction: `res://scripts/interactables/burn_pile.gd`

## Behavior Summary
1. Escape: collect 3 keys, unlock the barn door, and pick up the final barn key.
2. Well: collect music box and interact with well.
3. Caught: clown reaches player in chase state.
4. Burn: collect matches + fuel can and interact with burn pile.
5. Stay: avoid movement for full timer duration.

## Manual Test Flow
1. Collect 3 keys, unlock the barn, and pick up the final barn key for Escape ending.
2. Collect music box and use the well for Well ending.
3. Let clown chase and catch player for Caught ending.
4. Collect matches and fuel can, then use burn pile for Burn ending.
5. Stand still for timer duration for Stay ending.

Testing note:
- To test Stay quickly, temporarily lower `stay_duration_seconds` on `EndingManager` in inspector.

## Done Definition
- All 5 endings can be intentionally triggered.
- Ending overlay appears with restart prompt.
- Gameplay freezes on ending to prevent duplicate triggers.
