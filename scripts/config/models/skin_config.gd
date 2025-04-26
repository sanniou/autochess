extends ConfigModel
class_name SkinConfig
## 皮肤配置模型
## 提供皮肤配置数据的访问和验证

# 引入常量
const GameConsts = preload("res://scripts/constants/game_constants.gd")

# 皮肤类型枚举
enum SkinType {
	CHESS,  # 棋子皮肤
	BOARD,  # 棋盘皮肤
	UI      # UI皮肤
}

# 配置文件路径
var _config_path: String = ""

# 设置配置文件路径
func set_config_path(path: String) -> void:
	_config_path = path

# 获取配置文件路径
func get_config_path() -> String:
	return _config_path

# 获取配置类型
func _get_config_type() -> String:
	# 根据配置文件路径确定配置类型
	var path = get_config_path()
	if path.contains("chess_skins"):
		return "chess_skins"
	elif path.contains("board_skins"):
		return "board_skins"
	elif path.contains("ui_skins"):
		return "ui_skins"
	else:
		return "skins"

# 获取默认架构
func _get_default_schema() -> Dictionary:
	# 基础架构
	var base_schema = {
		"id": {
			"type": "string",
			"required": true,
			"description": "皮肤ID"
		},
		"name": {
			"type": "string",
			"required": true,
			"description": "皮肤名称"
		},
		"description": {
			"type": "string",
			"required": true,
			"description": "皮肤描述"
		},
		"rarity": {
			"type": "int",
			"required": true,
			"description": "皮肤稀有度"
		},
		"icon": {
			"type": "string",
			"required": true,
			"description": "皮肤图标路径"
		},
		"preview": {
			"type": "string",
			"required": true,
			"description": "皮肤预览图路径"
		},
		"unlock_condition": {
			"type": "dictionary",
			"required": false,
			"description": "解锁条件",
			"schema": {
				"gold": {
					"type": "int",
					"required": false,
					"description": "解锁所需金币"
				},
				"achievement": {
					"type": "string",
					"required": false,
					"description": "解锁所需成就"
				},
				"level": {
					"type": "int",
					"required": false,
					"description": "解锁所需等级"
				},
				"win_count": {
					"type": "int",
					"required": false,
					"description": "解锁所需胜利次数"
				}
			}
		}
	}

	# 根据配置类型添加特定字段
	var config_type = _get_config_type()
	match config_type:
		"chess_skins":
			base_schema["texture_overrides"] = {
				"type": "dictionary",
				"required": false,
				"description": "棋子纹理覆盖",
				"check_schema": false
			}
		"board_skins":
			base_schema["texture"] = {
				"type": "string",
				"required": true,
				"description": "棋盘纹理路径"
			}
			base_schema["cell_textures"] = {
				"type": "dictionary",
				"required": false,
				"description": "棋盘格子纹理",
				"check_schema": false
			}
		"ui_skins":
			base_schema["theme"] = {
				"type": "string",
				"required": true,
				"description": "UI主题路径"
			}
			base_schema["color_scheme"] = {
				"type": "dictionary",
				"required": false,
				"description": "UI颜色方案",
				"check_schema": false
			}

	return base_schema

# 验证自定义规则
func _validate_custom_rules(config_data: Dictionary) -> void:
	# 验证稀有度范围
	if config_data.has("rarity") and not GameConsts.is_valid_rarity(config_data.rarity):
		validation_errors.append("稀有度必须是有效的 GameConstants.Rarity 枚举值: " + str(config_data.rarity))

	# 验证图标路径
	if config_data.has("icon") and (not config_data.icon is String or config_data.icon.is_empty()):
		validation_errors.append("图标路径必须是有效的字符串")

	# 验证预览图路径
	if config_data.has("preview") and (not config_data.preview is String or config_data.preview.is_empty()):
		validation_errors.append("预览图路径必须是有效的字符串")

	# 验证解锁条件
	if config_data.has("unlock_condition") and config_data.unlock_condition is Dictionary:
		# 检查至少有一个有效的解锁条件
		var has_valid_condition = false
		var valid_condition_types = ["gold", "achievement", "level", "win_count"]

		for condition_type in valid_condition_types:
			if config_data.unlock_condition.has(condition_type):
				has_valid_condition = true
				var condition_value = config_data.unlock_condition[condition_type]

				match condition_type:
					"achievement":
						if not condition_value is String or condition_value.is_empty():
							validation_errors.append("成就解锁条件必须是有效的字符串")
					"level", "gold", "win_count":
						if not condition_value is int or condition_value <= 0:
							validation_errors.append(condition_type + "解锁条件必须是正整数")

		if not has_valid_condition and not config_data.unlock_condition.is_empty():
			validation_errors.append("解锁条件必须包含至少一个有效的条件类型: " + ", ".join(valid_condition_types))

	# 根据配置类型验证特定字段
	var config_type = _get_config_type()
	match config_type:
		"chess_skins":
			# 验证纹理覆盖
			if config_data.has("texture_overrides") and not config_data.texture_overrides is Dictionary:
				validation_errors.append("纹理覆盖必须是字典")

		"board_skins":
			# 验证棋盘纹理
			if config_data.has("texture"):
				if not config_data.texture is String or config_data.texture.is_empty():
					validation_errors.append("棋盘纹理路径必须是有效的字符串")
			else:
				validation_errors.append("棋盘皮肤必须包含纹理路径")

			# 验证格子纹理
			if config_data.has("cell_textures") and not config_data.cell_textures is Dictionary:
				validation_errors.append("格子纹理必须是字典")

		"ui_skins":
			# 验证UI主题
			if config_data.has("theme"):
				if not config_data.theme is String or config_data.theme.is_empty():
					validation_errors.append("UI主题路径必须是有效的字符串")
			else:
				validation_errors.append("UI皮肤必须包含主题路径")

			# 验证颜色方案
			if config_data.has("color_scheme") and not config_data.color_scheme is Dictionary:
				validation_errors.append("颜色方案必须是字典")

# 获取皮肤名称
func get_skin_name() -> String:
	return data.get("name", "")

# 获取皮肤描述
func get_description() -> String:
	return data.get("description", "")

# 获取皮肤ID
func get_id() -> String:
	return data.get("id", "")

# 获取皮肤稀有度
func get_rarity() -> int:
	return data.get("rarity", 0)

# 获取皮肤图标路径
func get_icon() -> String:
	return data.get("icon", "")

# 获取皮肤预览图路径
func get_preview() -> String:
	return data.get("preview", "")

# 获取解锁条件
func get_unlock_condition() -> Dictionary:
	return data.get("unlock_condition", {})

# 获取皮肤类型
func get_skin_type() -> int:
	var config_type = _get_config_type()
	match config_type:
		"chess_skins":
			return SkinType.CHESS
		"board_skins":
			return SkinType.BOARD
		"ui_skins":
			return SkinType.UI
		_:
			# 对于通用皮肤，根据配置判断
			if data.has("type"):
				match data.type:
					"chess":
						return SkinType.CHESS
					"board":
						return SkinType.BOARD
					"ui":
						return SkinType.UI
			return -1

# 获取皮肤类型字符串
func get_skin_type_string() -> String:
	var skin_type = get_skin_type()
	match skin_type:
		SkinType.CHESS:
			return "chess"
		SkinType.BOARD:
			return "board"
		SkinType.UI:
			return "ui"
		_:
			return ""

# 根据皮肤类型获取特定属性
func get_type_specific_property(property_name: String, default_value = null):
	if data.has(property_name):
		return data[property_name]
	return default_value

# 获取棋子皮肤纹理覆盖
func get_texture_overrides() -> Dictionary:
	if get_skin_type() == SkinType.CHESS:
		return get_type_specific_property("texture_overrides", {})
	return {}

# 获取棋盘皮肤纹理
func get_board_texture() -> String:
	if get_skin_type() == SkinType.BOARD:
		return get_type_specific_property("texture", "")
	return ""

# 获取棋盘格子纹理
func get_cell_textures() -> Dictionary:
	if get_skin_type() == SkinType.BOARD:
		return get_type_specific_property("cell_textures", {})
	return {}

# 获取UI主题路径
func get_theme_path() -> String:
	if get_skin_type() == SkinType.UI:
		return get_type_specific_property("theme", "")
	return ""

# 获取UI颜色方案
func get_color_scheme() -> Dictionary:
	if get_skin_type() == SkinType.UI:
		return get_type_specific_property("color_scheme", {})
	return {}

# 检查是否满足解锁条件
func meets_unlock_condition(player_data: Dictionary) -> bool:
	var unlock_condition = get_unlock_condition()

	if unlock_condition.is_empty():
		return true

	# 检查金币条件
	if unlock_condition.has("gold"):
		var required_gold = unlock_condition.gold
		if not player_data.has("gold") or player_data.gold < required_gold:
			return false

	# 检查等级条件
	if unlock_condition.has("level"):
		var required_level = unlock_condition.level
		if not player_data.has("level") or player_data.level < required_level:
			return false

	# 检查胜利次数条件
	if unlock_condition.has("win_count"):
		var required_wins = unlock_condition.win_count
		if not player_data.has("win_count") or player_data.win_count < required_wins:
			return false

	# 检查成就条件
	if unlock_condition.has("achievement"):
		var required_achievement = unlock_condition.achievement
		if not player_data.has("achievements") or not player_data.achievements.has(required_achievement) or not player_data.achievements[required_achievement]:
			return false

	return true
