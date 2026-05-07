extends Node2D
class_name ShopNpc

@export var display_name := "商人"
@export_multiline var prompt_text := "按 E 互動"
@export var opens_shop := true
@export var dialogue_lines: Array[String] = [
	"這裡往上會通到第二層，路線會比前一張地圖更像十字路。",
	"打倒敵人取得金錢後，可以回來買一些暫時道具。",
]
@export var shop_items: Array[Dictionary] = [
	{"name": "回復藥水", "price": 4, "description": "可回復部分血量"},
	{"name": "粗糙護符", "price": 4, "description": "暫時用的護符道具，會放入背包。"},
	{"name": "生命碎片", "price": 8, "description": "暫時用的生命道具，之後可接最大血量。"},
	{"name": "破舊地圖", "price": 12, "description": "記錄附近房間配置的道具。"},
]

var offered_shop_items: Array[Dictionary] = []
var player_nearby := false


func _ready() -> void:
	GameState.clear_scene_health_potion_purchase()
	_roll_shop_items()
	$InteractArea.body_entered.connect(_on_body_entered)
	$InteractArea.body_exited.connect(_on_body_exited)


func get_shop_items() -> Array[Dictionary]:
	return offered_shop_items


func _roll_shop_items() -> void:
	offered_shop_items.assign(shop_items)
	offered_shop_items.shuffle()

	if offered_shop_items.size() > 3:
		offered_shop_items.resize(3)


func _unhandled_input(event: InputEvent) -> void:
	if not player_nearby:
		return

	if event.is_action_pressed("interact") and not GameState.input_locked:
		var ui := get_tree().get_first_node_in_group("game_ui")
		if ui != null:
			ui.open_npc_dialogue(self)
			get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	player_nearby = true
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null:
		ui.show_prompt(prompt_text)


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	player_nearby = false
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null:
		ui.hide_prompt()
