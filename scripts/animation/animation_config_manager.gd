extends Node
class_name AnimationConfigManager
## 动画配置管理器
## 负责加载和管理动画配置

# 信号
signal config_loaded(config_type: String)
signal config_error(error_message: String)

# 配置类型
enum ConfigType {
	CHESS,    # 棋子动画
	BATTLE,   # 战斗动画
	UI,       # UI动画
	EFFECT    # 特效动画
}

# 配置路径
const CONFIG_PATH = "res://config/animations/animation_config.json"

# 配置数据
var chess_animations = {}
var battle_animations = {}
var ui_animations = {}
var effect_animations = {}

# 是否已加载
var _loaded = false

# 初始化
func _init() -> void:
	# 加载配置
	load_config()

# 加载配置
func load_config() -> bool:
	# 检查文件是否存在
	if not FileAccess.file_exists(CONFIG_PATH):
		push_error("动画配置文件不存在: " + CONFIG_PATH)
		config_error.emit("动画配置文件不存在: " + CONFIG_PATH)
		return false

	# 打开文件
	var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if not file:
		push_error("无法打开动画配置文件: " + CONFIG_PATH)
		config_error.emit("无法打开动画配置文件: " + CONFIG_PATH)
		return false

	# 读取文件内容
	var json_text = file.get_as_text()
	file.close()

	# 解析JSON
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("解析动画配置文件失败: " + json.get_error_message() + " at line " + str(json.get_error_line()))
		config_error.emit("解析动画配置文件失败: " + json.get_error_message())
		return false

	# 获取配置数据
	var config_data = json.get_data()

	# 加载棋子动画配置
	if config_data.has("chess_animations"):
		chess_animations = config_data.chess_animations
		config_loaded.emit("chess_animations")

	# 加载战斗动画配置
	if config_data.has("battle_animations"):
		battle_animations = config_data.battle_animations
		config_loaded.emit("battle_animations")

	# 加载UI动画配置
	if config_data.has("ui_animations"):
		ui_animations = config_data.ui_animations
		config_loaded.emit("ui_animations")

	# 加载特效动画配置
	if config_data.has("effect_animations"):
		effect_animations = config_data.effect_animations
		config_loaded.emit("effect_animations")

	# 标记为已加载
	_loaded = true

	return true

# 重新加载配置
func reload_config() -> bool:
	# 清空配置
	chess_animations.clear()
	battle_animations.clear()
	ui_animations.clear()
	effect_animations.clear()

	# 重新加载
	return load_config()

# 获取棋子动画配置
func get_chess_animation(animation_name: String) -> Dictionary:
	if not _loaded:
		load_config()

	if chess_animations.has(animation_name):
		return chess_animations[animation_name]

	return {}

# 获取战斗动画配置
func get_battle_animation(animation_name: String) -> Dictionary:
	if not _loaded:
		load_config()

	if battle_animations.has(animation_name):
		return battle_animations[animation_name]

	return {}

# 获取UI动画配置
func get_ui_animation(animation_name: String) -> Dictionary:
	if not _loaded:
		load_config()

	if ui_animations.has(animation_name):
		return ui_animations[animation_name]

	return {}

# 获取粒子特效配置
func get_particle_effect(effect_name: String) -> Dictionary:
	if not _loaded:
		load_config()

	if effect_animations.has("particle_effects") and effect_animations.particle_effects.has(effect_name):
		return effect_animations.particle_effects[effect_name]

	return {}

# 获取精灵特效配置
func get_sprite_effect(effect_name: String) -> Dictionary:
	if not _loaded:
		load_config()

	if effect_animations.has("sprite_effects") and effect_animations.sprite_effects.has(effect_name):
		return effect_animations.sprite_effects[effect_name]

	return {}

# 获取组合特效配置
func get_combined_effect(effect_name: String) -> Dictionary:
	if not _loaded:
		load_config()

	if effect_animations.has("combined_effects") and effect_animations.combined_effects.has(effect_name):
		return effect_animations.combined_effects[effect_name]

	return {}

# 获取所有棋子动画名称
func get_all_chess_animation_names() -> Array:
	if not _loaded:
		load_config()

	return chess_animations.keys()

# 获取所有战斗动画名称
func get_all_battle_animation_names() -> Array:
	if not _loaded:
		load_config()

	return battle_animations.keys()

# 获取所有UI动画名称
func get_all_ui_animation_names() -> Array:
	if not _loaded:
		load_config()

	return ui_animations.keys()

# 获取所有粒子特效名称
func get_all_particle_effect_names() -> Array:
	if not _loaded:
		load_config()

	if effect_animations.has("particle_effects"):
		return effect_animations.particle_effects.keys()

	return []

# 获取所有精灵特效名称
func get_all_sprite_effect_names() -> Array:
	if not _loaded:
		load_config()

	if effect_animations.has("sprite_effects"):
		return effect_animations.sprite_effects.keys()

	return []

# 获取所有组合特效名称
func get_all_combined_effect_names() -> Array:
	if not _loaded:
		load_config()

	if effect_animations.has("combined_effects"):
		return effect_animations.combined_effects.keys()

	return []

# 检查棋子动画是否存在
func has_chess_animation(animation_name: String) -> bool:
	if not _loaded:
		load_config()

	return chess_animations.has(animation_name)

# 检查战斗动画是否存在
func has_battle_animation(animation_name: String) -> bool:
	if not _loaded:
		load_config()

	return battle_animations.has(animation_name)

# 检查UI动画是否存在
func has_ui_animation(animation_name: String) -> bool:
	if not _loaded:
		load_config()

	return ui_animations.has(animation_name)

# 检查粒子特效是否存在
func has_particle_effect(effect_name: String) -> bool:
	if not _loaded:
		load_config()

	return effect_animations.has("particle_effects") and effect_animations.particle_effects.has(effect_name)

# 检查精灵特效是否存在
func has_sprite_effect(effect_name: String) -> bool:
	if not _loaded:
		load_config()

	return effect_animations.has("sprite_effects") and effect_animations.sprite_effects.has(effect_name)

# 检查组合特效是否存在
func has_combined_effect(effect_name: String) -> bool:
	if not _loaded:
		load_config()

	return effect_animations.has("combined_effects") and effect_animations.combined_effects.has(effect_name)

# 获取配置部分
func get_config_section(section_name: String) -> Dictionary:
	if not _loaded:
		load_config()

	# 检查部分是否存在
	match section_name:
		"chess_animations":
			return chess_animations
		"battle_animations":
			return battle_animations
		"ui_animations":
			return ui_animations
		"effect_animations":
			return effect_animations
		_:
			# 尝试从配置数据中获取
			var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
			if not file:
				return {}

			# 读取文件内容
			var json_text = file.get_as_text()
			file.close()

			# 解析JSON
			var json = JSON.new()
			var error = json.parse(json_text)
			if error != OK:
				return {}

			# 获取配置数据
			var config_data = json.get_data()

			# 检查部分是否存在
			if config_data.has(section_name):
				return config_data[section_name]

			return {}
