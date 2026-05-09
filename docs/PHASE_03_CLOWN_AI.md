# Phase 3 Checklist - Clown AI FSM

## Scope
- Finite state machine with Patrol, Alert, and Chase states.
- Sound-based alert behavior using player movement noise.
- Sight-based chase behavior with FOV + line-of-sight checks.
- Random short glitch teleport while in chase.

## Scene and Script References
- Clown scene: `res://scenes/enemy/Clown.tscn`
- AI script: `res://scripts/enemy/clown_ai.gd`
- World patrol points: `res://scenes/world/WorldGreybox.tscn`

## Behavior Summary
1. Patrol: moves between `ClownPatrolPoints` markers.
2. Alert: triggered by hearing player noise within dynamic hearing range.
3. Chase: triggered by visual detection; tracks player while visible, then searches last known position.
4. Glitch: teleports short distances at random intervals during chase.

## Manual Test Flow
1. Run project and verify clown moves among patrol points.
2. Sprint near clown but outside direct sight and verify alert response.
3. Enter clown view cone and verify chase starts.
4. Break line of sight and verify clown searches then returns to patrol.
5. During chase, verify occasional short teleport reposition.

## Done Definition
- All three AI states are reachable in normal play.
- State transitions feel stable and repeatable.
- Clown navigation works on current world greybox.