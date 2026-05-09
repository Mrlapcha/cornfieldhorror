# Phase 2 Checklist - World Greybox

## Scope
- Cornfield lanes with maze-like route variation.
- Barn, well, scarecrow cluster, and final objective spaces.
- Spawn and objective markers for gameplay flow.

## Scene Layout
- Main world scene: `res://scenes/world/WorldGreybox.tscn`
- Corn lane generator: `res://scripts/world/cornfield_lanes.gd`
- Main spawn bootstrap: `res://scripts/world/main_bootstrap.gd`

## Manual Test Flow
1. Run the project.
2. Confirm player starts at `SpawnPoint`.
3. Walk through the cornfield and verify alternating lane gaps allow pathing.
4. Reach barn and well areas and confirm placeholders are visible.
5. Continue to scarecrow cluster and finally the barn objective side.

## Done Definition
- A complete route exists from spawn through the world toward the barn objective.
- All major locations are represented as playable greybox spaces.
- Scene is ready to host clown AI patrol nodes in Phase 3.
