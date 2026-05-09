class_name CollectibleItem
extends StaticBody3D

enum CollectibleType {
	KEY,
	NOTE,
	BATTERY,
	GENERIC,
}

@export var collectible_type: CollectibleType = CollectibleType.KEY
@export var display_name: String = "Item"
@export var item_id: String = "key"
@export var amount: int = 1
@export var note_id: String = ""
@export_multiline var note_text: String = ""
@export var battery_charge_amount: float = 30.0
@export var custom_pickup_message: String = ""

@export_group("Completion")
@export var trigger_ending_on_collect: bool = false
@export var ending_manager_method: String = "trigger_escape_ending"

@export_group("Glow")
@export var glow_light_energy: float = 0.6
@export var glow_light_range: float = 5.0

@onready var visual: MeshInstance3D = $Visual

var _picked_up: bool = false
var _base_visual_position: Vector3 = Vector3.ZERO
var _hover_time: float = 0.0
var _glow_light: OmniLight3D


func _ready() -> void:
	_base_visual_position = visual.position
	_apply_visual_color()
	_create_glow_light()


func _process(delta: float) -> void:
	_hover_time += delta
	visual.position.y = _base_visual_position.y + sin(_hover_time * 2.2) * 0.14
	visual.rotate_y(delta * 1.4)


func interact(player: Node) -> void:
	if _picked_up:
		return
	if not player:
		return

	var did_collect: bool = _apply_collectible(player)
	if not did_collect:
		return

	_picked_up = true
	_push_status_message(player, _build_pickup_message(player), 2.5)
	if Engine.has_singleton("AudioManager") or has_node("/root/AudioManager"):
		var audio_mgr := get_node_or_null("/root/AudioManager")
		if audio_mgr and audio_mgr.has_method("play_sfx"):
			audio_mgr.call("play_sfx", "pickup")
			
	if Engine.has_singleton("SaveManager") or has_node("/root/SaveManager"):
		SaveManager.track_destroyed_interactable(name)

	if trigger_ending_on_collect:
		_trigger_collect_ending(player)

	queue_free()


func get_interact_prompt() -> String:
	return "Take %s" % display_name


func _apply_collectible(player: Node) -> bool:
	match collectible_type:
		CollectibleType.KEY:
			if not player.has_method("add_inventory_item"):
				return false
			player.call("add_inventory_item", item_id, amount)
			return true

		CollectibleType.NOTE:
			if not player.has_method("add_note_entry"):
				return false

			var resolved_note_text: String = note_text
			if resolved_note_text.is_empty():
				resolved_note_text = "A torn page mentions a ritual beneath the moon."

			var added_note: bool = bool(player.call("add_note_entry", note_id, resolved_note_text))
			if not added_note:
				return false

			if player.has_method("add_inventory_item"):
				player.call("add_inventory_item", "note", 1)
			return true

		CollectibleType.BATTERY:
			if not player.has_method("add_flashlight_battery"):
				return false

			player.call("add_flashlight_battery", battery_charge_amount)
			if player.has_method("add_inventory_item"):
				player.call("add_inventory_item", "battery", 1)
			return true

		CollectibleType.GENERIC:
			if not player.has_method("add_inventory_item"):
				return false
			player.call("add_inventory_item", item_id, amount)
			return true

	return false


func _build_pickup_message(player: Node = null) -> String:
	if not custom_pickup_message.is_empty():
		return custom_pickup_message

	match collectible_type:
		CollectibleType.KEY:
			var total_keys: int = amount
			if player and player.has_method("get_inventory_item_count"):
				total_keys = int(player.call("get_inventory_item_count", item_id))
			return "Picked up %s (%d/3 keys)." % [display_name, total_keys]
		CollectibleType.NOTE:
			return "Collected note: %s" % display_name
		CollectibleType.BATTERY:
			return "Battery found. Flashlight recharged."
		CollectibleType.GENERIC:
			return "Picked up %s." % display_name
	return "Picked up %s" % display_name


func _trigger_collect_ending(player: Node) -> void:
	if ending_manager_method.is_empty():
		return

	var managers: Array[Node] = get_tree().get_nodes_in_group("ending_manager")
	if managers.is_empty():
		return

	var manager: Node = managers[0]
	if manager.has_method(ending_manager_method):
		manager.call(ending_manager_method, player)


func _push_status_message(player: Node, message: String, duration: float) -> void:
	if player.has_method("show_status_message"):
		player.call("show_status_message", message, duration)


func _get_type_color() -> Color:
	match collectible_type:
		CollectibleType.KEY:
			return Color(0.92, 0.78, 0.2, 1)
		CollectibleType.NOTE:
			return Color(0.86, 0.82, 0.67, 1)
		CollectibleType.BATTERY:
			return Color(0.25, 0.88, 0.48, 1)
		CollectibleType.GENERIC:
			return Color(0.58, 0.68, 0.92, 1)
	return Color(0.7, 0.7, 0.7, 1)


func _apply_visual_color() -> void:
	var color := _get_type_color()

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.roughness = 0.25
	material.metallic = 0.15
	material.albedo_color = color

	# Emission glow so the item is visible even without direct light
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.8

	visual.material_override = material


func _create_glow_light() -> void:
	var color := _get_type_color()

	_glow_light = OmniLight3D.new()
	_glow_light.light_color = color
	_glow_light.light_energy = glow_light_energy
	_glow_light.omni_range = glow_light_range
	_glow_light.omni_attenuation = 1.8
	_glow_light.shadow_enabled = false
	_glow_light.position = visual.position
	add_child(_glow_light)
