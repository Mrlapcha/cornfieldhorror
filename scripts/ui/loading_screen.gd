extends Control
var next_scene_path: String = "res://scenes/Main.tscn"
var progress: Array = []
func _ready() -> void:
    ResourceLoader.load_threaded_request(next_scene_path)
    set_process(true)
func _process(delta: float) -> void:
    var status = ResourceLoader.load_threaded_get_status(next_scene_path, progress)
    if status == ResourceLoader.THREAD_LOAD_LOADED:
        set_process(false)
        get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(next_scene_path))
    elif status == ResourceLoader.THREAD_LOAD_FAILED:
        print("Failed to load scene")
        set_process(false)
