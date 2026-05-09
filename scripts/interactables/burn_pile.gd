extends StaticBody3D

@export var required_matches_item_id: String = "matches"
@export var required_fuel_item_id: String = "fuel_can"
@export var consume_items_on_use: bool = true


func interact(player: Node) -> void:
	if not player:
		return
	if not player.has_method("has_inventory_item"):
		return

	var has_matches: bool = bool(player.call("has_inventory_item", required_matches_item_id, 1))
	var has_fuel: bool = bool(player.call("has_inventory_item", required_fuel_item_id, 1))

	if not has_matches or not has_fuel:
		var missing_parts: PackedStringArray = PackedStringArray()
		if not has_matches:
			missing_parts.append("matches")
		if not has_fuel:
			missing_parts.append("fuel")
		_push_message(player, "Need %s to burn the field." % ", ".join(missing_parts), 2.4)
		return

	if consume_items_on_use and player.has_method("consume_inventory_item"):
		player.call("consume_inventory_item", required_matches_item_id, 1)
		player.call("consume_inventory_item", required_fuel_item_id, 1)

	var ending_manager: Node = _get_ending_manager()
	if ending_manager and ending_manager.has_method("trigger_burn_ending"):
		ending_manager.call("trigger_burn_ending", player)


func get_interact_prompt() -> String:
	return "Ignite cornfield"


func _get_ending_manager() -> Node:
	var managers: Array[Node] = get_tree().get_nodes_in_group("ending_manager")
	if managers.is_empty():
		return null
	return managers[0]


func _push_message(player: Node, message: String, duration: float) -> void:
	if player.has_method("show_status_message"):
		player.call("show_status_message", message, duration)
