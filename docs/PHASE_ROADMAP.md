# Cornfield Horror Phase Roadmap

## Phase 1 - Player Foundation
Goal: make movement and first-person interaction feel solid.

Deliverables:
- First-person controller scene.
- Walk, sprint, crouch.
- Flashlight toggle with battery drain.
- Basic interaction ray hook.

Exit criteria:
- Player can move smoothly with mouse and touch drag look.
- Flashlight battery drains and shuts off at zero.
- Interact key calls `interact(player)` on hit targets.

## Phase 2 - Greybox World
Goal: build playable navigation space before final art.

Deliverables:
- Cornfield maze lanes.
- Barn, well, scarecrow, and final objective placeholders.
- Spawn and objective points.

Exit criteria:
- Full loop from start point to barn objective exists.

## Phase 3 - Clown AI Core
Goal: create threat behavior loop.

Deliverables:
- FSM states: Patrol, Alert, Chase.
- Sound-based alert trigger.
- Sight-based chase trigger.
- Random short glitch teleport.

Exit criteria:
- AI reliably transitions across all three states in gameplay.

## Phase 4 - Tension Systems
Goal: raise fear and pressure.

Deliverables:
- Stamina drain/recover.
- Heavy breathing and noise impact.
- Heartbeat and screen pulse proximity cue.

Exit criteria:
- Sprint is resource-limited and affects clown detection pressure.

## Phase 5 - Inventory + Collectibles
Goal: add exploration rewards and progression locks.

Deliverables:
- Inventory UI and item pickups.
- Notes, batteries, keys, music box, matches.
- Barn lock-unlock flow.

Exit criteria:
- Required items gate progression and can be collected end-to-end.

## Phase 6 - Endings
Goal: support branching outcomes.

Deliverables:
- Escape ending.
- Well ritual ending.
- Caught ending.
- Burn ending.
- Secret stand-still ending.

Exit criteria:
- Each ending can be triggered intentionally in test runs.

## Phase 7 - Audio Manager
Goal: state-based audio that communicates danger.

Deliverables:
- Ambient bed + location layers.
- Clown audio by state.
- Player movement/breathing/heartbeat layers.

Exit criteria:
- Audio transitions correctly on gameplay state changes.

## Phase 8 - Mobile Controls
Goal: make the full loop playable on touch.

Deliverables:
- Virtual joystick.
- Sprint/crouch/interact/flashlight buttons.
- Touch look drag.

Exit criteria:
- Entire game loop playable on a phone without keyboard/mouse.

## Phase 9 - Mobile Ship Pass
Goal: stable Android/iOS builds.

Deliverables:
- Export presets.
- Performance pass (LOD, shadows, texture sizes).
- Input and UI scaling verification.

Exit criteria:
- Stable 30+ FPS target on representative mid-range devices.






/*
› bugs i got :
 
  the clown ai floats up a bit instead of being on floor lol
 
  21x this error W 0:00:04:935   _geometry_instance_add_surface_with_material: Attempting to use a shader  that requires tangents with a mesh (res://assets/models/scarecrow/
  scarecrow.glb::ArrayMesh_v24hy) that doesn't contain tangents. Ensure that meshes are imported with the 'ensure_tangents' option. If creating your own meshes, add an
  `ARRAY_TANGENT` array (when using ArrayMesh) or call `generate_tangents()` (when using SurfaceTool).
    <C++ Source>  servers/rendering/renderer_rd/forward_mobile/render_forward_mobile.cpp:2851 @ _geometry_instance_add_surface_with_material()
  the clown ai behaviour , its like its lagging , like when i get caught it still moves like far and close again and again like glitching
 
  and that scarecrow is like only head visible rest is under like earth not visible
 
  and its like it facing oppposite side
 
  also i can see color and all of head when moving towards it side but when coming back from opposite direction its black
 
  and clown ai is like walking through walls middle(supposedly cornfield we gonna replace later)
 
  i think whole clown AI behaiour is messed up like when to chase when to stay idle , when to keep patrolling whole area when to transport and all , need to make it 100x better
 
  the thing i hate most is clown like walks say 1 m straight and again gets to original point and repeats again and again lol , makes no sense
 
 */
