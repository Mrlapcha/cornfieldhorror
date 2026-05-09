extends Node3D

@export var snap_player_to_spawn_on_ready: bool = true


func _ready() -> void:
	if SaveManager.is_loading_save and SaveManager.current_save_data.size() > 0:
		_restore_save_data()
	elif snap_player_to_spawn_on_ready:
		var player := get_node_or_null("Player") as Node3D
		var spawn_point := get_node_or_null("World/SpawnPoint") as Marker3D
		if player and spawn_point:
			player.global_position = spawn_point.global_position
			player.global_rotation = spawn_point.global_rotation


func _restore_save_data() -> void:
	var data := SaveManager.current_save_data
	
	# Delete destroyed interactables
	if data.has("destroyed_interactables"):
		var collectibles := get_node_or_null("World/Collectibles")
		if collectibles:
			for child in collectibles.get_children():
				if child.name in data["destroyed_interactables"]:
					child.queue_free()

	# Restore player state
	var player := get_node_or_null("Player")
	if player and data.has("player"):
		var p_data: Dictionary = data["player"]
		if p_data.has("pos_x"):
			player.global_position = Vector3(p_data["pos_x"], p_data["pos_y"], p_data["pos_z"])
		if p_data.has("rot_y"):
			player.global_rotation.y = p_data["rot_y"]
			
		# Restore internal states (using a deferred call or direct setting if accessible)
		if player.has_method("restore_save_state"):
			player.restore_save_state(p_data)
			
	SaveManager.is_loading_save = false