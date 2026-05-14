extends Label

@export var source_text := ""


func _ready() -> void:
	if source_text == "":
		source_text = text
	_update_text()
	var localization: Node = get_node_or_null("/root/Localization")
	if localization != null:
		localization.connect("language_changed", Callable(self, "_update_text"))


func _update_text() -> void:
	var localization: Node = get_node_or_null("/root/Localization")
	if localization != null and localization.has_method("translate_raw"):
		text = String(localization.call("translate_raw", source_text))
	else:
		text = source_text
