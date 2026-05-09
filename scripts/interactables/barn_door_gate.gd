extends StaticBody3D

@export var required_keys: int = 3
@export var key_item_id: String = "key"
@export var locked_blocker_path: NodePath

var _is_open: bool = false


func interact(player: Node) -> void:
	if _is_open or not player:
		return

	var key_count: int = 0
	if player.has_method("get_inventory_item_count"):
		key_count = int(player.call("get_inventory_item_count", key_item_id))

	if key_count < required_keys:
		var missing_keys := required_keys - key_count
		_push_message(player, "Barn door locked. Need %d more key(s)." % missing_keys, 2.3)
		return

	_open_gate(player)


func get_interact_prompt() -> String:
	return "Unlock barn door"


func _open_gate(player: Node) -> void:
	_is_open = true
	_push_message(player, "Barn unlocked. Find the final key inside.", 2.8)

	var audio_mgr := get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("play_sfx"):
		audio_mgr.call("play_sfx", "pickup")

	_release_locked_blocker()
	call_deferred("queue_free")


func _release_locked_blocker() -> void:
	if locked_blocker_path == NodePath(""):
		return

	var blocker := get_node_or_null(locked_blocker_path)
	if blocker:
		blocker.call_deferred("queue_free")


func _push_message(player: Node, message: String, duration: float) -> void:
	if player.has_method("show_status_message"):
		player.call("show_status_message", message, duration)
