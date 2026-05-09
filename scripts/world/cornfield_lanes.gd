extends Node3D

## CornfieldLanes — Generates a realistic cornfield using MultiMeshInstance3D and a 3D model.

@export_group("Lane Generation")
@export var lane_count: int = 13
@export var row_spacing: float = 2.9
@export var row_width: float = 0.9
@export var row_height: float = 2.4
@export var segment_count: int = 5
@export var segment_length: float = 20.0
@export var segment_gap: float = 6.0
@export var start_z: float = 20.0

@export_group("Corn Density")
@export var stalks_per_meter: float = 1.5
@export var height_variation: float = 0.3
@export var scale_variation: float = 0.15

@export_group("Gap Distribution")
@export var gap_probability: float = 0.2
@export var min_segment_length: float = 3.0
@export var max_segment_length: float = 8.0
@export var passage_width: float = 2.2

@export_group("Landmark Clear Zones")
@export var barn_clear_radius: float = 14.0
@export var well_clear_radius: float = 9.0
@export var collision_clearance: float = 0.8

@export var model_rotation_offset: Vector3 = Vector3(0, 0, 0)
@export var corn_model_scene: PackedScene

var _generated_root: Node3D
var _rng := RandomNumberGenerator.new()
var _merged_mesh: ArrayMesh

func _ready() -> void:
	if not corn_model_scene:
		corn_model_scene = load("res://assets/models/world/maize_corn_plant.glb")
	
	_rng.randomize()
	
	# Try to load cached mesh first to save 3-5 seconds of start-up time
	var cache_path := "user://corn_merged_cache.res"
	if FileAccess.file_exists(cache_path):
		_merged_mesh = load(cache_path)
		print("SUCCESS: Loaded merged corn mesh from cache.")
	elif corn_model_scene:
		var instance = corn_model_scene.instantiate()
		_merged_mesh = _merge_all_meshes(instance)
		instance.queue_free()
		# Save to cache for next run
		ResourceSaver.save(_merged_mesh, cache_path)
		print("SUCCESS: Merged and cached corn mesh to disk.")
	
	_rebuild()

func _merge_all_meshes(root: Node) -> ArrayMesh:
	var amesh := ArrayMesh.new()
	var surface_count := 0
	
	var mesh_instances: Array[MeshInstance3D] = []
	var transforms: Array[Transform3D] = []
	
	var stack = [[root, Transform3D()]]
	while stack.size() > 0:
		var pair = stack.pop_back()
		var node = pair[0]
		var parent_trans = pair[1]
		
		var current_trans = parent_trans * node.transform
		
		if node is MeshInstance3D:
			mesh_instances.append(node)
			transforms.append(current_trans)
		
		for child in node.get_children():
			stack.append([child, current_trans])
	
	for i in mesh_instances.size():
		var mi = mesh_instances[i]
		var trans = transforms[i]
		var m = mi.mesh
		if not m: continue
		for s in m.get_surface_count():
			var arrays = m.surface_get_arrays(s)
			# Apply cumulative transform to vertices
			var verts = arrays[Mesh.ARRAY_VERTEX]
			for v in verts.size():
				verts[v] = trans * verts[v]
			arrays[Mesh.ARRAY_VERTEX] = verts
			
			# Apply rotation to normals
			if arrays[Mesh.ARRAY_NORMAL]:
				var norms = arrays[Mesh.ARRAY_NORMAL]
				for n in norms.size():
					norms[n] = trans.basis * norms[n]
				arrays[Mesh.ARRAY_NORMAL] = norms
				
			amesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			amesh.surface_set_material(surface_count, mi.get_active_material(s))
			surface_count += 1
			
	return amesh

func _rebuild() -> void:
	if _generated_root and is_instance_valid(_generated_root):
		_generated_root.queue_free()

	_generated_root = Node3D.new()
	_generated_root.name = "Generated"
	add_child(_generated_root)

	if not _merged_mesh or _merged_mesh.get_surface_count() == 0:
		printerr("CornfieldLanes: No meshes found to merge in corn_model_scene!")
		return

	# Visuals (One big MultiMesh)
	var mm_instance := MultiMeshInstance3D.new()
	_generated_root.add_child(mm_instance)
	mm_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _merged_mesh
	
	var total_count := 0
	var lane_data := []
	
	for row_index in lane_count:
		var x := (float(row_index) - (float(lane_count - 1) * 0.5)) * row_spacing
		var lane_segments = _calculate_procedural_lane_segments(x)
		for seg in lane_segments:
			total_count += int(row_width * seg.length * stalks_per_meter)
			lane_data.append(seg)
	
	mm.instance_count = total_count
	mm_instance.multimesh = mm
	
	var rot_basis: Basis = Basis.from_euler(model_rotation_offset)
	var current_instance := 0
	
	for seg in lane_data:
		_create_collision_for_segment(seg.pos, seg.length)
		
		var count := int(row_width * seg.length * stalks_per_meter)
		for i in count:
			if current_instance >= total_count: break
			var rx := _rng.randf_range(-row_width * 0.5, row_width * 0.5)
			var rz := _rng.randf_range(-seg.length * 0.5, seg.length * 0.5)
			var ry := _rng.randf_range(0.0, 0.05)
			var stalk_pos: Vector3 = seg.pos + Vector3(rx, ry - row_height * 0.5, rz)
			
			# DON'T place corn inside landmarks.
			if _is_pos_forbidden(stalk_pos):
				continue
				
			var stalk_rot: Vector3 = Vector3(0, _rng.randf_range(0, TAU), 0)
			var stalk_scale: Vector3 = Vector3.ONE * _rng.randf_range(1.0 - scale_variation, 1.0 + scale_variation)
			var _basis: Basis = Basis().rotated(Vector3.UP, stalk_rot.y) * rot_basis
			_basis = _basis.scaled(stalk_scale)
			mm.set_instance_transform(current_instance, Transform3D(_basis, stalk_pos))
			current_instance += 1

	mm.visible_instance_count = current_instance

func _is_pos_forbidden(pos: Vector3) -> bool:
	for area in _get_forbidden_areas():
		var center: Vector3 = area["center"]
		var radius: float = area["radius"]
		if pos.distance_to(center) < radius:
			return true
	return false

func _get_forbidden_areas() -> Array[Dictionary]:
	return [
		{"center": Vector3(-24, 0, -28), "radius": barn_clear_radius},
		{"center": Vector3(22, 0, -26), "radius": well_clear_radius},
	]

func _calculate_procedural_lane_segments(x: float) -> Array:
	var segments = []
	var current_z := start_z
	var total_dist := segment_count * (segment_length + segment_gap)
	# CLAMP: Ensure corn never spawns beyond the world boundary (Z=-100)
	var end_z := maxf(start_z - total_dist, -95.0)
	
	while current_z > end_z:
		var length := _rng.randf_range(min_segment_length, max_segment_length)
		if _rng.randf() > gap_probability:
			segments.append({"pos": Vector3(x, row_height * 0.5, current_z - length * 0.5), "length": length})
			current_z -= length
		else:
			current_z -= passage_width
		current_z -= 1.0
	return segments

func _create_collision_for_segment(pos: Vector3, length: float) -> void:
	for z_range in _get_allowed_collision_ranges(pos, length):
		var range_length := z_range.y - z_range.x
		if range_length <= 0.25:
			continue
		var center_z := (z_range.x + z_range.y) * 0.5
		_create_collision_box(Vector3(pos.x, pos.y, center_z), range_length)

func _get_allowed_collision_ranges(pos: Vector3, length: float) -> Array[Vector2]:
	var ranges: Array[Vector2] = [Vector2(pos.z - length * 0.5, pos.z + length * 0.5)]
	for area in _get_forbidden_areas():
		var center: Vector3 = area["center"]
		var radius: float = float(area["radius"]) + collision_clearance
		var x_distance := maxf(abs(pos.x - center.x) - row_width * 0.5, 0.0)
		if x_distance >= radius:
			continue

		var z_reach := sqrt((radius * radius) - (x_distance * x_distance))
		ranges = _subtract_z_range(ranges, center.z - z_reach, center.z + z_reach)
	return ranges

func _subtract_z_range(ranges: Array[Vector2], blocked_min_z: float, blocked_max_z: float) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for z_range in ranges:
		if blocked_max_z <= z_range.x or blocked_min_z >= z_range.y:
			result.append(z_range)
			continue

		if blocked_min_z > z_range.x:
			result.append(Vector2(z_range.x, blocked_min_z))
		if blocked_max_z < z_range.y:
			result.append(Vector2(blocked_max_z, z_range.y))
	return result

func _create_collision_box(pos: Vector3, length: float) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	_generated_root.add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(row_width, row_height, length)
	collision.shape = shape
	body.add_child(collision)
