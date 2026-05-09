# Asset and Audio Timeline

Use this as the sourcing plan while systems are being built.

## Right Now (During Phase 6)
- Start collecting core visual packs:
  - Cornfield environment modular pack.
  - Barn/well/farm prop low-poly or stylized realistic placeholders.
  - Scarecrow models and simple prop set (fences, barrels, crates).
- Start collecting core enemy options:
  - Clown model variants (at least 2 candidates).
  - Basic idle/walk/run animation set compatible with chosen rig.

Reason:
- Phase 6 endings are in progress, so this is ideal time to source world/enemy assets in parallel.

## Phase 7 (Audio Manager Build)
- Gather and import all audio assets now:
  - Ambient loops (wind, corn rustle, night tones).
  - Clown layers (humming, giggle, chase laugh/scream).
  - Player layers (footsteps, breathing, heartbeat).
  - Interaction SFX (pickup, door creak, match strike, whoosh, well resonance).

Reason:
- Audio implementation and tuning happen in Phase 7, so these assets are directly needed then.

## Phase 8 (Mobile Controls)
- Gather UI/control visuals now:
  - Joystick base/thumb sprites.
  - Button icons for sprint/crouch/interact/flashlight.
  - Scalable HUD variants for different phone aspect ratios.

Reason:
- Controls are functional first, then visual polish and usability tuning on-device.

## Phase 9 (Export and Performance Pass)
- Finalize production-quality replacements and optimization variants:
  - LOD meshes for heavy props.
  - Lower-resolution fallback textures.
  - Compressed audio variants for mobile memory budgets.

Reason:
- This phase focuses on stability and performance for Android/iOS targets.

## Suggested Collection Order (Practical)
1. Cornfield + barn/well/farm prop pack.
2. Clown model + animations.
3. Ambient + clown + player audio.
4. Mobile control UI assets.
5. Optimization variants for export.
