# Phase 5 Checklist - Inventory and Collectibles

## Scope
- Inventory component attached to player.
- Collectible items for keys, notes, and flashlight batteries.
- On-screen inventory HUD with objective progress.
- Pickup status messaging and note collection tracking.
- Barn door gate check tied to key count.

## Scene and Script References
- Inventory component: `res://scripts/player/inventory_component.gd`
- Collectible logic: `res://scripts/interactables/collectible_item.gd`
- Collectible scene: `res://scenes/interactables/CollectibleItem.tscn`
- HUD script: `res://scripts/ui/inventory_overlay.gd`
- HUD scene: `res://scenes/ui/InventoryOverlay.tscn`
- Barn door gate check: `res://scripts/interactables/barn_door_gate.gd`

## Behavior Summary
1. Interact with collectible items to pick them up.
2. Keys increase key count toward barn access.
3. Notes are stored and counted in inventory.
4. Batteries recharge flashlight and increment battery pickup count.
5. HUD updates in real time and shows pickup messages.
6. Barn door reports locked/unlocked based on key total.

## Manual Test Flow
1. Run project and pick up each nearby collectible type.
2. Verify keys, notes, and battery pickup counters update.
3. Confirm flashlight percentage increases when battery is collected.
4. Confirm objective changes as keys are collected.
5. Confirm pickup message appears and auto-hides.
6. Try the barn door with fewer than 3 keys and confirm lock message.
7. Collect 3 keys and unlock the barn door.

## Done Definition
- Inventory counts are persisted for session runtime.
- Key/note/battery loop is fully playable in current world.
- HUD communicates progress clearly for next phases.
