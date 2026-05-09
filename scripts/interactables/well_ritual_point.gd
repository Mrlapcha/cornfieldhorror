extends StaticBody3D

@export var required_item_id: String = "music_box"
@export var required_item_count: int = 1
@export var consume_item_on_use: bool = true


func interact(player: Node) -> void:
	if not player:
		return

	if not player.has_method("has_inventory_item"):
		return

	var has_required_item: bool = bool(player.call("has_inventory_item", required_item_id, required_item_count))
	if not has_required_item:
		_push_message(player, "The well feels wrong. Maybe a music box belongs here.", 2.4)
		return

	if consume_item_on_use and player.has_method("consume_inventory_item"):
		player.call("consume_inventory_item", required_item_id, required_item_count)

	var ending_manager: Node = _get_ending_manager()
	if ending_manager and ending_manager.has_method("trigger_well_ending"):
		ending_manager.call("trigger_well_ending", player)


func get_interact_prompt() -> String:
	return "Use music box at well"


func _get_ending_manager() -> Node:
	var managers: Array[Node] = get_tree().get_nodes_in_group("ending_manager")
	if managers.is_empty():
		return null
	return managers[0]


func _push_message(player: Node, message: String, duration: float) -> void:
	if player.has_method("show_status_message"):
		player.call("show_status_message", message, duration)
