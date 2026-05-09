class_name InventoryComponent
extends Node

signal item_changed(item_id: String, new_count: int)
signal note_added(note_id: String, note_text: String)

var _items: Dictionary = {}
var _notes: Dictionary = {}
var _note_order: Array[String] = []


func add_item(item_id: String, amount: int = 1) -> int:
	if item_id.is_empty() or amount <= 0:
		return get_item_count(item_id)

	var existing_value: Variant = _items.get(item_id, 0)
	var current_count: int = int(existing_value)
	var new_count: int = current_count + amount

	_items[item_id] = new_count
	item_changed.emit(item_id, new_count)
	return new_count


func has_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return true
	return get_item_count(item_id) >= amount


func consume_item(item_id: String, amount: int = 1) -> bool:
	if item_id.is_empty() or amount <= 0:
		return true

	var current_count: int = get_item_count(item_id)
	if current_count < amount:
		return false

	var new_count: int = current_count - amount
	if new_count <= 0:
		_items.erase(item_id)
		new_count = 0
	else:
		_items[item_id] = new_count

	item_changed.emit(item_id, new_count)
	return true


func get_item_count(item_id: String) -> int:
	if item_id.is_empty():
		return 0

	var existing_value: Variant = _items.get(item_id, 0)
	return int(existing_value)


func add_note(note_id: String, note_text: String) -> bool:
	var resolved_note_id: String = note_id
	if resolved_note_id.is_empty():
		resolved_note_id = "note_%d" % (_note_order.size() + 1)

	if _notes.has(resolved_note_id):
		return false

	_notes[resolved_note_id] = note_text
	_note_order.append(resolved_note_id)
	note_added.emit(resolved_note_id, note_text)
	return true


func get_note_count() -> int:
	return _note_order.size()


func get_note_text(note_id: String) -> String:
	if note_id.is_empty():
		return ""

	var note_value: Variant = _notes.get(note_id, "")
	return str(note_value)


func get_latest_note_text() -> String:
	if _note_order.is_empty():
		return ""
	var latest_note_id: String = _note_order[_note_order.size() - 1]
	return get_note_text(latest_note_id)


func get_save_state() -> Dictionary:
	return {
		"items": _items,
		"notes": _notes,
		"note_order": _note_order
	}


func restore_save_state(data: Dictionary) -> void:
	if data.has("items"):
		_items = data["items"]
	if data.has("notes"):
		_notes = data["notes"]
	if data.has("note_order"):
		# Typed arrays from JSON might be standard Arrays, so cast them safely
		_note_order.clear()
		for id in data["note_order"]:
			_note_order.append(str(id))
