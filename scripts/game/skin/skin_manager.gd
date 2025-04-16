extends Node
class_name SkinManager
## 皮肤管理器
## 负责管理游戏皮肤的加载、应用和解锁

# 信号
signal skin_applied(skin_id, skin_type)
signal skin_unlocked(skin_id, skin_type)

# 皮肤类型
enum SkinType {
	CHESS,  # 棋子皮肤
	BOARD,  # 棋盘皮肤
	UI      # UI皮肤
}

# 皮肤配置文件路径
const SKIN_CONFIG_PATH = "res://configs/skins/"

# 皮肤配置文件
const SKIN_CONFIG_FILES = {
	"chess": "chess_skins.json",
	"board": "board_skins.json",
	"ui": "ui_skins.json"
}

# 皮肤数据
var chess_skins = {}
var board_skins = {}
var ui_skins = {}

# 已解锁的皮肤
var unlocked_skins = {
	"chess": [],
	"board": [],
	"ui": []
}

# 当前选中的皮肤
var selected_skins = {
	"chess": "default",
	"board": "default",
	"ui": "default"
}

# 引用
@onready var config_manager = get_node("/root/ConfigManager")
@onready var save_manager = get_node("/root/SaveManager")

# 初始化
func _ready():
	# 加载皮肤配置
	_load_skin_configs()
	
	# 加载已解锁的皮肤
	_load_unlocked_skins()
	
	# 加载选中的皮肤
	_load_selected_skins()

# 加载皮肤配置
func _load_skin_configs() -> void:
	# 加载棋子皮肤配置
	chess_skins = _load_skin_config("chess")
	
	# 加载棋盘皮肤配置
	board_skins = _load_skin_config("board")
	
	# 加载UI皮肤配置
	ui_skins = _load_skin_config("ui")

# 加载皮肤配置文件
func _load_skin_config(skin_type: String) -> Dictionary:
	var config_file = SKIN_CONFIG_PATH + SKIN_CONFIG_FILES[skin_type]
	
	# 检查文件是否存在
	if not FileAccess.file_exists(config_file):
		EventBus.debug_message.emit("皮肤配置文件不存在: " + config_file, 1)
		return {}
	
	# 加载配置文件
	var file = FileAccess.open(config_file, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	# 解析JSON
	var json = JSON.new()
	var error = json.parse(content)
	
	if error == OK:
		return json.data
	else:
		EventBus.debug_message.emit("无法解析皮肤配置文件: " + json.get_error_message(), 1)
		return {}

# 加载已解锁的皮肤
func _load_unlocked_skins() -> void:
	# 从存档中加载已解锁的皮肤
	var save_data = save_manager.get_save_data()
	
	if save_data.has("unlocked_skins"):
		unlocked_skins = save_data.unlocked_skins
	else:
		# 默认解锁基础皮肤
		unlocked_skins = {
			"chess": ["default"],
			"board": ["default"],
			"ui": ["default"]
		}
		
		# 保存到存档
		save_data.unlocked_skins = unlocked_skins
		save_manager.save_game()

# 加载选中的皮肤
func _load_selected_skins() -> void:
	# 从存档中加载选中的皮肤
	var save_data = save_manager.get_save_data()
	
	if save_data.has("selected_skins"):
		selected_skins = save_data.selected_skins
	else:
		# 默认选择基础皮肤
		selected_skins = {
			"chess": "default",
			"board": "default",
			"ui": "default"
		}
		
		# 保存到存档
		save_data.selected_skins = selected_skins
		save_manager.save_game()

# 获取所有皮肤
func get_all_skins(skin_type: String) -> Dictionary:
	match skin_type:
		"chess":
			return chess_skins
		"board":
			return board_skins
		"ui":
			return ui_skins
		_:
			return {}

# 获取皮肤数据
func get_skin_data(skin_id: String, skin_type: String) -> Dictionary:
	var skins = get_all_skins(skin_type)
	
	if skins.has(skin_id):
		return skins[skin_id]
	
	return {}

# 获取已解锁的皮肤
func get_unlocked_skins(skin_type: String) -> Array:
	if unlocked_skins.has(skin_type):
		return unlocked_skins[skin_type]
	
	return []

# 获取选中的皮肤
func get_selected_skins() -> Dictionary:
	return selected_skins.duplicate()

# 获取选中的皮肤ID
func get_selected_skin_id(skin_type: String) -> String:
	if selected_skins.has(skin_type):
		return selected_skins[skin_type]
	
	return "default"

# 检查皮肤是否已解锁
func is_skin_unlocked(skin_id: String, skin_type: String) -> bool:
	if unlocked_skins.has(skin_type):
		return unlocked_skins[skin_type].has(skin_id)
	
	return false

# 解锁皮肤
func unlock_skin(skin_id: String, skin_type: String) -> bool:
	# 检查皮肤是否存在
	var skins = get_all_skins(skin_type)
	if not skins.has(skin_id):
		return false
	
	# 检查皮肤是否已解锁
	if is_skin_unlocked(skin_id, skin_type):
		return true
	
	# 获取皮肤数据
	var skin_data = skins[skin_id]
	
	# 检查是否有解锁条件
	if skin_data.has("unlock_condition"):
		var condition = skin_data.unlock_condition
		
		# 检查金币条件
		if condition.has("gold"):
			var required_gold = condition.gold
			var player_gold = save_manager.get_save_data().gold
			
			if player_gold < required_gold:
				return false
			
			# 扣除金币
			save_manager.get_save_data().gold -= required_gold
		
		# 检查成就条件
		if condition.has("achievement"):
			var required_achievement = condition.achievement
			var player_achievements = save_manager.get_save_data().achievements
			
			if not player_achievements.has(required_achievement):
				return false
	
	# 解锁皮肤
	unlocked_skins[skin_type].append(skin_id)
	
	# 保存到存档
	save_manager.get_save_data().unlocked_skins = unlocked_skins
	save_manager.save_game()
	
	# 发送解锁信号
	skin_unlocked.emit(skin_id, skin_type)
	
	return true

# 应用皮肤
func apply_skins(skins: Dictionary) -> void:
	# 检查皮肤是否已解锁
	for skin_type in skins:
		var skin_id = skins[skin_type]
		
		if not is_skin_unlocked(skin_id, skin_type):
			EventBus.debug_message.emit("皮肤未解锁: " + skin_id, 1)
			continue
		
		# 应用皮肤
		selected_skins[skin_type] = skin_id
		
		# 发送应用信号
		skin_applied.emit(skin_id, skin_type)
	
	# 保存到存档
	save_manager.get_save_data().selected_skins = selected_skins
	save_manager.save_game()
	
	# 应用皮肤效果
	_apply_skin_effects()

# 应用皮肤效果
func _apply_skin_effects() -> void:
	# 应用棋子皮肤
	_apply_chess_skin()
	
	# 应用棋盘皮肤
	_apply_board_skin()
	
	# 应用UI皮肤
	_apply_ui_skin()

# 应用棋子皮肤
func _apply_chess_skin() -> void:
	var skin_id = selected_skins.chess
	var skin_data = get_skin_data(skin_id, "chess")
	
	if skin_data.is_empty():
		return
	
	# 应用棋子皮肤效果
	if skin_data.has("texture_overrides"):
		var overrides = skin_data.texture_overrides
		
		# 通知棋子工厂更新皮肤
		if has_node("/root/GameManager/ChessFactory"):
			var chess_factory = get_node("/root/GameManager/ChessFactory")
			chess_factory.update_skin_overrides(overrides)

# 应用棋盘皮肤
func _apply_board_skin() -> void:
	var skin_id = selected_skins.board
	var skin_data = get_skin_data(skin_id, "board")
	
	if skin_data.is_empty():
		return
	
	# 应用棋盘皮肤效果
	if skin_data.has("texture"):
		var texture_path = skin_data.texture
		
		# 通知棋盘管理器更新皮肤
		if has_node("/root/GameManager/BoardManager"):
			var board_manager = get_node("/root/GameManager/BoardManager")
			board_manager.update_board_texture(texture_path)

# 应用UI皮肤
func _apply_ui_skin() -> void:
	var skin_id = selected_skins.ui
	var skin_data = get_skin_data(skin_id, "ui")
	
	if skin_data.is_empty():
		return
	
	# 应用UI皮肤效果
	if skin_data.has("theme"):
		var theme_path = skin_data.theme
		
		# 加载主题
		var theme = load(theme_path)
		if theme:
			# 应用主题到根节点
			get_tree().root.theme = theme
