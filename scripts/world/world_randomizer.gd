extends Node

## WorldRandomizer — Randomly places collectibles across the cornfield.
## Also handles adding collision and visibility fixes to the scarecrow models.

@export var search_width: float = 32.0
@export var search_depth: float = 135.0
@export var min_distance_between_items: float = 22.0

@onready var collectibles_node: Node3D = get_parent().get_node_or_null("Collectibles")
@onready var scarecrows_node: Node3D = get_parent().get_node_or_null("ScarecrowCluster")

var _rng := RandomNumberGenerator.new()

# Positions of main landmarks to avoid placing items inside walls
var _barn_pos := Vector3(-24, 0, -28)
var _well_pos := Vector3(22, 0, -26)

func _ready() -> void:
	_rng.randomize()
	# Wait a frame to ensure scene is ready
	await get_tree().process_frame
	_randomize_positions()
	_setup_scarecrow_polish()

func _randomize_positions() -> void:
	var placed_positions: Array[Vector3] = []
	
	# Randomize Collectibles (Keys, Notes, Batteries)
	if collectibles_node:
		for child in collectibles_node.get_children():
			if child is Node3D:
				var pos := _get_valid_random_pos(placed_positions)
				child.global_position = pos
				placed_positions.append(pos)
				print("RANDOMIZER: Placed ", child.name, " at ", pos)

func _get_valid_random_pos(existing: Array[Vector3]) -> Vector3:
	var attempts := 0
	while attempts < 150:
		var rx := _rng.randf_range(-search_width * 0.5, search_width * 0.5)
		var rz := _rng.randf_range(-search_depth * 0.5, search_depth * 0.5)
		var potential_pos := Vector3(rx, 0.0, rz)
		
		# AVOIDANCE CHECK: Don't place inside landmarks (walls)
		if potential_pos.distance_to(_barn_pos) < 14.0: attempts += 1; continue
		if potential_pos.distance_to(_well_pos) < 6.0: attempts += 1; continue

		var too_close := false
		for p in existing:
			if potential_pos.distance_to(p) < min_distance_between_items:
				too_close = true
				break
		
		if not too_close:
			return potential_pos
		attempts += 1
	
	# Fallback if no valid position found
	return Vector3(_rng.randf_range(-10, 10), 0, _rng.randf_range(-10, 10))

func _setup_scarecrow_polish() -> void:
	if not scarecrows_node: return
	
	for child in scarecrows_node.get_children():
		if child is Node3D:
			# 1. ADD COLLISION
			if not child.get_node_or_null("StaticBody3D"):
				var body := StaticBody3D.new()
				child.add_child(body)

				var collision := CollisionShape3D.new()
				var shape := CylinderShape3D.new()
				shape.height = 2.4
				shape.radius = 0.5
				collision.shape = shape
				collision.position.y = 1.2 # Center of the height
				body.add_child(collision)
				print("RANDOMIZER: Added collision to ", child.name)

			# 2. FIX LIGHTING (Silhouette issue)
			# Traverse children to find MeshInstance3D and apply visibility fix
			_apply_visibility_fix(child)

func _apply_visibility_fix(node: Node) -> void:
	if node is MeshInstance3D:
		# We force the scarecrow to be UNSHADED. This is the ultimate fix for silhouettes.
		# It ensures the model shows its full colors/textures from every angle without
		# needing any light source at all (though the flashlight still 'looks' like it hits it).
		var mat = node.get_active_material(0)
		if mat is StandardMaterial3D:
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	for child in node.get_children():
		_apply_visibility_fix(child)
