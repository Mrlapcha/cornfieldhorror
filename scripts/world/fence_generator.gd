extends Node3D

## Procedurally generates a visible wooden fence around the world perimeter.
## Posts every 4 units with horizontal rails, plus a solid collision wall behind
## the fence line so players cannot pass through.
## Replaces the previous invisible StaticBody boundary walls.

@export_group("Layout")
@export var west_x: float = -90.0
@export var east_x: float = 90.0
@export var north_z: float = 100.0
@export var south_z: float = -100.0
@export var fence_height: float = 1.6
@export var post_spacing: float = 4.0
@export var rail_count: int = 2

@export_group("Post / Rail Geometry")
@export var post_width: float = 0.14
@export var post_depth: float = 0.14
@export var rail_height: float = 0.10
@export var rail_depth: float = 0.08

@export_group("Collision Wall")
@export var wall_depth: float = 0.3
@export var wall_height: float = 8.0

var _rng := RandomNumberGenerator.new()
var _post_mat: Material
var _rail_mat: Material


func _ready() -> void:
	_rng.randomize()
	_materials()
	_build_west()
	_build_east()
	_build_north()
	_build_south()
	print("FenceGenerator: built.")


func _materials() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.22, 0.17, 0.12)
	m.roughness = 0.96
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	_post_mat = m

	var r := m.duplicate() as StandardMaterial3D
	r.albedo_color = Color(0.18, 0.14, 0.10)
	_rail_mat = r


func _posts_along(centres: Array[Vector3], is_vertical: bool) -> void:
	for c in centres:
		var post := MeshInstance3D.new()
		post.name = "FencePost"
		var mesh := BoxMesh.new()
		mesh.size = Vector3(post_width, fence_height, post_depth)
		post.position = Vector3(c.x, fence_height * 0.5, c.z)
		post.mesh = mesh
		post.material_override = _post_mat
		add_child(post)


func _rails_along(centres: Array[Vector3], is_vertical: bool, total_len: float) -> void:
	var count := centres.size()
	if count < 2:
		return

	for r in rail_count:
		var rail_y := ((float(r) + 1.0) / float(rail_count + 1)) * fence_height
		for i in count - 1:
			var a := centres[i]
			var b := centres[i + 1]
			var mid := (a + b) * 0.5
			var seg_len := a.distance_to(b)
			var rail := MeshInstance3D.new()
			rail.name = "FenceRail"
			var mesh := BoxMesh.new()
			if is_vertical:
				mesh.size = Vector3(post_width, rail_height, seg_len)
			else:
				mesh.size = Vector3(seg_len, rail_height, post_width)
			rail.position = Vector3(mid.x, rail_y, mid.z)
			rail.mesh = mesh
			rail.material_override = _rail_mat
			add_child(rail)


func _collision_segment(from: Vector3, to: Vector3, is_vertical: bool) -> void:
	var length := from.distance_to(to)
	var centre := (from + to) * 0.5

	var body := StaticBody3D.new()
	body.name = "FenceCollision"
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	if is_vertical:
		shape.size = Vector3(wall_depth, wall_height, length)
	else:
		shape.size = Vector3(length, wall_height, wall_depth)
	col.shape = shape
	body.add_child(col)
	body.position = Vector3(centre.x, wall_height * 0.5, centre.z)
	add_child(body)


func _build_side(is_vertical: bool, p1: Vector3, p2: Vector3) -> void:
	var length := p1.distance_to(p2)
	var count: int = maxi(2, int(length / post_spacing))

	var centres: Array[Vector3] = []
	for i in count + 1:
		var t := float(i) / float(count)
		var pos: Vector3
		if is_vertical:
			pos = Vector3(p1.x, 0.0, lerp(p1.z, p2.z, t))
		else:
			pos = Vector3(lerp(p1.x, p2.x, t), 0.0, p1.z)
		centres.append(pos)

	_posts_along(centres, is_vertical)
	_rails_along(centres, is_vertical, length)
	_collision_segment(p1, p2, is_vertical)


func _build_west() -> void:
	_build_side(true,
		Vector3(west_x, 0, south_z),
		Vector3(west_x, 0, north_z))


func _build_east() -> void:
	_build_side(true,
		Vector3(east_x, 0, south_z),
		Vector3(east_x, 0, north_z))


func _build_north() -> void:
	_build_side(false,
		Vector3(west_x, 0, north_z),
		Vector3(east_x, 0, north_z))


func _build_south() -> void:
	_build_side(false,
		Vector3(west_x, 0, south_z),
		Vector3(east_x, 0, south_z))
