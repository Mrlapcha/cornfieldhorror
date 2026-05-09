extends Node

## Handles saving and loading of game state and profile data (Premium Status)

const PROFILE_FILE := "user://profile.json"
const SAVEGAME_FILE := "user://savegame.json"

var is_loading_save: bool = false
var current_save_data: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


# --- PROFILE SAVING (Premium, Settings) ---

func save_profile(data: Dictionary) -> void:
	var json_string := JSON.stringify(data)
	var file := FileAccess.open(PROFILE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(json_string)


func load_profile() -> Dictionary:
	if not FileAccess.file_exists(PROFILE_FILE):
		return {}
	
	var file := FileAccess.open(PROFILE_FILE, FileAccess.READ)
	if file:
		var json_string := file.get_as_text()
		var data = JSON.parse_string(json_string)
		if data is Dictionary:
			return data
	return {}


# --- GAMEPLAY SAVING ---

func has_savegame() -> bool:
	return FileAccess.file_exists(SAVEGAME_FILE)


func delete_savegame() -> void:
	if has_savegame():
		DirAccess.remove_absolute(SAVEGAME_FILE)


func save_game(data: Dictionary) -> void:
	var json_string := JSON.stringify(data)
	var file := FileAccess.open(SAVEGAME_FILE, FileAccess.WRITE)
	if file:
		file.store_string(json_string)


func load_game() -> Dictionary:
	if not has_savegame():
		return {}
	
	var file := FileAccess.open(SAVEGAME_FILE, FileAccess.READ)
	if file:
		var json_string := file.get_as_text()
		var data = JSON.parse_string(json_string)
		if data is Dictionary:
			current_save_data = data
			return data
			
	return {}


func track_destroyed_interactable(node_name: String) -> void:
	if not current_save_data.has("destroyed_interactables"):
		current_save_data["destroyed_interactables"] = []
	
	if not current_save_data["destroyed_interactables"].has(node_name):
		current_save_data["destroyed_interactables"].append(node_name)
