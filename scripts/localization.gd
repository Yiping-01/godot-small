extends Node

signal language_changed

const SAVE_PATH := "user://language.cfg"
const DEFAULT_LOCALE := "zh"

var current_locale := DEFAULT_LOCALE

var texts := {
	"zh": {
		"MENU_START": "開始新篇章",
		"MENU_CONTINUE": "繼續遊戲",
		"MENU_QUIT": "離開遊戲",
		"MENU_SETTINGS": "設置",
		"MENU_SOUND": "聲音",
		"MENU_LANGUAGE": "語言",
		"MENU_CLOSE": "離開",
		"KEYBOARD_TITLE": "鍵盤",
		"KEYBOARD_WAITING": "點擊要修改的按鍵，或按 Esc 返回。",
		"KEYBOARD_CANCELLED": "已取消修改。",
		"KEYBOARD_SAVED": "按鍵已修改。",
		"KEYBOARD_FAILED": "這個按鍵無法使用。",
		"KEYBOARD_RESET": "重置",
		"KEYBOARD_RESET_DONE": "已重置按鍵。",
		"KEYBOARD_PRESS_NEW": "請按新的「%s」按鍵，Esc 取消。",
		"MENU_BACK": "返回",
		"ACTION_MOVE_UP": "上",
		"ACTION_MOVE_DOWN": "下",
		"ACTION_MOVE_LEFT": "左",
		"ACTION_MOVE_RIGHT": "右",
		"ACTION_JUMP": "跳躍",
		"ACTION_ATTACK": "攻擊",
		"ACTION_DASH": "衝刺",
		"ACTION_FAR_ATTACK": "水槍",
		"ACTION_INTERACT": "互動 / 使用藥水",
		"ACTION_MAP": "地圖",
		"ACTION_INVENTORY": "物品欄",
		"ACTION_AUDIO_SETTINGS": "聲音",
		"PAUSE_TITLE": "暫停",
		"PAUSE_RESUME": "返回遊戲",
		"PAUSE_SETTINGS": "按鍵設定",
		"PAUSE_SOUND": "聲音",
		"PAUSE_MAIN_MENU": "回主選單",
		"AUDIO_TITLE": "音量設定",
		"AUDIO_MUSIC": "背景音樂：%d%%",
		"AUDIO_SFX": "音效：%d%%",
		"CURRENCY_AMOUNT": "金錢：%d",
		"INVENTORY_TITLE": "背包",
		"INVENTORY_EMPTY": "背包目前是空的。",
		"INVENTORY_FIRST_HINT": "獲得物品後可按 {inventory} 打開背包。",
		"SHOP_TITLE": "%s 的商店",
		"SHOP_HINT": "點選購買 / {inventory} 或 Esc：關閉",
		"SHOP_INVENTORY_HINT": "購買的物品會放進背包，按 {inventory} 可以查看。",
		"SHOP_OWNED": "（已擁有）",
		"SHOP_LIMIT": "（已達到購買上限）",
		"SHOP_ITEM_LINE": "%s - %d 金錢%s\n%s",
		"SHOP_ALREADY_HAVE": "已擁有：%s",
		"SHOP_POTION_LIMIT": "回復藥水已達上限",
		"SHOP_NOT_ENOUGH_MONEY": "金錢不足",
		"SHOP_GOT_ITEM": "取得：%s",
		"MAP_TITLE": "區域地圖",
		"MAP_HINT": "{map} 或 Esc：關閉",
		"MAP_EMPTY": "這個場景還沒有地圖房間標記。",
		"DIALOGUE_SHOP_HINT": "{interact}：打開商店 / Esc：關閉",
		"DIALOGUE_NEXT_HINT": "{interact}：下一句 / Esc：關閉",
		"SKILL_NOT_OWNED": "技能尚未取得",
		"ITEM_HEALTH_POTION": "回復藥水",
		"ITEM_HEALTH_POTION_DESC": "按下E鍵回復生命",
		"ITEM_TRAVELER_NOTE": "旅行者筆記",
		"ITEM_TRAVELER_NOTE_DESC": "一份簡單的冒險紀錄，用來提醒你目前學過的操作。",
		"ITEM_ROUGH_CHARM": "粗糙護符",
		"ITEM_ROUGH_CHARM_DESC": "商人販售的暫時道具，目前只會收進背包。",
		"ITEM_LIFE_FRAGMENT": "生命碎片",
		"ITEM_LIFE_FRAGMENT_DESC": "暫時的血量道具，之後可以改成提升最大生命。",
		"ITEM_OLD_MAP": "破舊地圖",
		"ITEM_OLD_MAP_DESC": "記錄附近房間配置的道具，之後可接上地圖 UI。",
		"ITEM_UNKNOWN_DESC": "沒有詳細說明。",
		"TOAST_COIN": "取得金錢 +%d",
		"TOAST_POTION_USED": "使用回血飲料",
		"TOAST_HEALTH_FULL": "血量是滿的",
		"TOAST_NO_POTION": "沒有回血飲料了",
		"TOAST_BENCH_REST": "你坐在長椅上休息。生命回滿，敵人重生。",
		"INTRO_TEXT": "深邃且寂靜的大海之中。",
		"INTRO_PROMPT": "按 Enter 繼續",
	},
	"en": {
		"MENU_START": "Start",
		"MENU_CONTINUE": "Continue",
		"MENU_QUIT": "Quit",
		"MENU_SETTINGS": "Settings",
		"MENU_SOUND": "Sound",
		"MENU_LANGUAGE": "Language",
		"MENU_CLOSE": "Close",
		"KEYBOARD_TITLE": "Keyboard",
		"KEYBOARD_WAITING": "Click a key setting, or press Esc to go back.",
		"KEYBOARD_CANCELLED": "Canceled.",
		"KEYBOARD_SAVED": "Key changed.",
		"KEYBOARD_FAILED": "This key cannot be used.",
		"KEYBOARD_RESET": "Reset",
		"KEYBOARD_RESET_DONE": "Controls reset.",
		"KEYBOARD_PRESS_NEW": "Press a new key for \"%s\". Esc cancels.",
		"MENU_BACK": "Back",
		"ACTION_MOVE_UP": "Up",
		"ACTION_MOVE_DOWN": "Down",
		"ACTION_MOVE_LEFT": "Left",
		"ACTION_MOVE_RIGHT": "Right",
		"ACTION_JUMP": "Jump",
		"ACTION_ATTACK": "Attack",
		"ACTION_DASH": "Dash",
		"ACTION_FAR_ATTACK": "Water Shot",
		"ACTION_INTERACT": "Interact / Potion",
		"ACTION_MAP": "Map",
		"ACTION_INVENTORY": "Inventory",
		"ACTION_AUDIO_SETTINGS": "Sound",
		"PAUSE_TITLE": "Pause",
		"PAUSE_RESUME": "Resume",
		"PAUSE_SETTINGS": "Key Settings",
		"PAUSE_SOUND": "Sound",
		"PAUSE_MAIN_MENU": "Main Menu",
		"AUDIO_TITLE": "Audio Settings",
		"AUDIO_MUSIC": "Music: %d%%",
		"AUDIO_SFX": "SFX: %d%%",
		"CURRENCY_AMOUNT": "Coins: %d",
		"INVENTORY_TITLE": "Inventory",
		"INVENTORY_EMPTY": "Your inventory is empty.",
		"INVENTORY_FIRST_HINT": "Press {inventory} to open your inventory after getting an item.",
		"SHOP_TITLE": "%s's Shop",
		"SHOP_HINT": "Click to buy / {inventory} or Esc: Close",
		"SHOP_INVENTORY_HINT": "Bought items go into your inventory. Press {inventory} to check them.",
		"SHOP_OWNED": " (Owned)",
		"SHOP_LIMIT": " (Limit reached)",
		"SHOP_ITEM_LINE": "%s - %d Coins%s\n%s",
		"SHOP_ALREADY_HAVE": "Already have: %s",
		"SHOP_POTION_LIMIT": "Healing potion limit reached",
		"SHOP_NOT_ENOUGH_MONEY": "Not enough coins",
		"SHOP_GOT_ITEM": "Got: %s",
		"MAP_TITLE": "Area Map",
		"MAP_HINT": "{map} or Esc: Close",
		"MAP_EMPTY": "This scene has no map room markers yet.",
		"DIALOGUE_SHOP_HINT": "{interact}: Open Shop / Esc: Close",
		"DIALOGUE_NEXT_HINT": "{interact}: Next / Esc: Close",
		"SKILL_NOT_OWNED": "Skill not acquired",
		"ITEM_HEALTH_POTION": "Healing Potion",
		"ITEM_HEALTH_POTION_DESC": "Press E to restore health",
		"ITEM_TRAVELER_NOTE": "Traveler's Note",
		"ITEM_TRAVELER_NOTE_DESC": "A simple adventure note that reminds you of the controls you have learned.",
		"ITEM_ROUGH_CHARM": "Rough Charm",
		"ITEM_ROUGH_CHARM_DESC": "A temporary charm sold by the merchant. It is stored in your inventory.",
		"ITEM_LIFE_FRAGMENT": "Life Fragment",
		"ITEM_LIFE_FRAGMENT_DESC": "A temporary health item. Later it can be changed to raise max health.",
		"ITEM_OLD_MAP": "Old Map",
		"ITEM_OLD_MAP_DESC": "Records nearby room layouts. Later it can connect to the map UI.",
		"ITEM_UNKNOWN_DESC": "No description yet.",
		"TOAST_COIN": "Coins +%d",
		"TOAST_POTION_USED": "Used healing drink",
		"TOAST_HEALTH_FULL": "Health is already full",
		"TOAST_NO_POTION": "No healing drinks left",
		"TOAST_BENCH_REST": "You rest on the bench. Health restored and enemies respawned.",
		"INTRO_TEXT": "In the deep and silent sea.",
		"INTRO_PROMPT": "Press Enter to continue",
	},
}

var raw_texts := {
	"按 E 互動": "Press {interact} to interact",
	"按 E 對話": "Press {interact} to talk",
	"按 E 商店": "Press {interact} to shop",
	"按 E 進入新場景": "Press {interact} to enter the next scene",
	"按 E 進入下一個區域": "Press {interact} to enter the next area",
	"按 E 坐下休息": "Press {interact} to sit and rest",
	"生命已回滿。按 E 起身": "Health restored. Press {interact} to stand up",
	"怪物聚集地,請試著打敗他們": "A monster nest. Try to defeat them.",
	"按 Z 可進行跳躍": "Press {jump} to jump",
	"按 X 可進行攻擊": "Press {attack} to attack",
	"靠近 NPC 後按 E 對話。": "Move near an NPC and press {interact} to talk.",
	"按 C 可以短衝刺。衝刺可用來快速接近敵人或越過小空隙。": "Press {dash} to dash. Dash to approach enemies or cross small gaps.",
	"敵人會造成傷害。跳起來後按 S+X 可以下砍，命中敵人會把你往上彈。": "Enemies deal damage. Jump and press S+X to slash downward; hitting an enemy bounces you up.",
	"商人可以購買物品。按 I 可以打開背包。": "You can buy items from merchants. Press {inventory} to open your inventory.",
	"穿過通道可以前往下一段區域。鏡頭會持續跟著角色。": "Go through passages to reach the next area. The camera follows the player.",
	"貼著牆壁按下 Z 可使用蹬牆跳": "Press Z while touching a wall to wall jump.",
	"靠近長椅按 E 坐下休息，生命會回滿。再按 E 起身。": "Press {interact} near a bench to rest and restore health. Press {interact} again to stand.",
	"按下兩下 Z 可進行二段跳": "Press {jump} twice to double jump.",
	"你可以用金錢購買測試物品。": "You can spend coins to buy test items.",
	"按 I 可以打開背包查看。": "Press {inventory} to open your inventory.",
	"打倒敵人取得金錢後，可以回來買一些暫時道具。": "After defeating enemies for coins, come back to buy temporary items.",
	"尚未寫入說明。": "No description written yet.",
	"前面會開始會有敵人，可以善用前面學到的技巧": "Enemies are ahead. Use the techniques you have learned.",
	"Z是跳躍，X是攻擊，順帶一提 按下C可進行衝刺！": "{jump} jumps, {attack} attacks, and {dash} lets you dash!",
	"小心尖刺陷阱，碰到了可是會扣血的。": "Watch out for spikes. Touching them will hurt you.",
	"小怪一": "Monster 1",
	"小怪二": "Monster 2",
	"Boss房": "Boss Room",
	"教學路線": "Tutorial Route",
	"休息房間": "Rest Room",
	"上方入口": "Upper Entrance",
	"下行道路": "Downward Path",
	"底層通道": "Lower Passage",
	"商人房": "Merchant Room",
	"休息房": "Rest Room",
	"旅人": "Traveler",
	"商人": "Merchant",
	"可回復部分血量": "Restores some health",
	"暫時用的護符道具，會放入背包。": "A temporary charm stored in your inventory.",
	"暫時用的生命道具，之後可接最大血量。": "A temporary life item. Later it can increase max health.",
	"記錄附近房間配置的道具。": "Records the layout of nearby rooms.",
}


func _ready() -> void:
	_load_locale()
	TranslationServer.set_locale(current_locale)


func text(key: String) -> String:
	var locale_texts: Dictionary = texts.get(current_locale, texts[DEFAULT_LOCALE])
	var default_texts: Dictionary = texts[DEFAULT_LOCALE]
	return String(locale_texts.get(key, default_texts.get(key, key)))


func translate_raw(source: String) -> String:
	if current_locale == DEFAULT_LOCALE:
		return source
	return String(raw_texts.get(source, source))


func toggle_language() -> void:
	set_locale("en" if current_locale == "zh" else "zh")


func set_locale(locale: String) -> void:
	if not texts.has(locale):
		return
	current_locale = locale
	TranslationServer.set_locale(locale)
	_save_locale()
	language_changed.emit()


func _save_locale() -> void:
	var config := ConfigFile.new()
	config.set_value("language", "locale", current_locale)
	config.save(SAVE_PATH)


func _load_locale() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var saved_locale := String(config.get_value("language", "locale", DEFAULT_LOCALE))
	if texts.has(saved_locale):
		current_locale = saved_locale
