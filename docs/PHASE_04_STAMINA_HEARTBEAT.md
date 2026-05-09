# Phase 4 Checklist - Stamina and Heartbeat

## Scope
- Sprint stamina drain and recovery loop.
- Exhaustion state that blocks sprint until recovery threshold.
- Breathing intensity pressure derived from sprint and low stamina.
- Heartbeat screen pulse driven by clown proximity.

## Scene and Script References
- Player controller: `res://scripts/player/player_controller.gd`
- Heartbeat UI script: `res://scripts/ui/heartbeat_overlay.gd`
- Heartbeat UI scene: `res://scenes/ui/HeartbeatOverlay.tscn`
- Main integration: `res://scenes/Main.tscn`

## Behavior Summary
1. Sprint drains stamina while active.
2. When stamina reaches zero, player enters exhausted state and cannot sprint.
3. Stamina recovers after a short delay and clears exhaustion at threshold.
4. Breathing intensity increases under sprint/exhaustion and adds detection pressure.
5. Screen pulse becomes stronger and faster as clown approaches.

## Manual Test Flow
1. Hold sprint until exhausted and verify speed drops to walk speed.
2. Keep moving and verify sprint remains locked briefly.
3. Wait for stamina recovery and verify sprint unlocks.
4. Approach clown and verify heartbeat pulse intensity ramps up.
5. Increase distance from clown and verify pulse softens.

## Done Definition
- Sprint is resource-limited and recoverable.
- Exhaustion adds pressure and detection risk.
- Heartbeat pulse gives reliable proximity feedback for threat awareness.