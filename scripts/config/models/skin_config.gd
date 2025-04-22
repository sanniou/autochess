extends ConfigModel
class_name SkinConfig
## 皮肤配置模型
## 提供皮肤配置数据的访问和验证

# 引入常量
const GameConsts = preload("res://scripts/constants/game_constants.gd")

# 获取配置类型
func _get_config_type() -> String:
	return "skins"

# 获取默认架构
func _get_default_schema() -> Dictionary:
	return {
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
		"type": {
			"type": "string",
			"required": true,
			"description": "皮肤类型"
		},
		"rarity": {
			"type": "int",
			"required": true,
			"description": "皮肤稀有度"
		},
		"price": {
			"type": "float",
			"required": false,
			"description": "皮肤价格"
		},
		"icon_path": {
			"type": "string",
			"required": false,
			"description": "皮肤图标路径"
		},
		"unlock_condition": {
			"type": "dictionary",
			"required": false,
			"description": "解锁条件",
			"schema": {
				"type": {
					"type": "string",
					"required": true,
					"description": "解锁条件类型"
				},
				"value": {
					"type": "int",
					"required": false,
					"description": "解锁条件值"
				},
				"threshold": {
					"type": "int",
					"required": false,
					"description": "解锁条件阈值"
				}
			}
		},
		"assets": {
			"type": "dictionary",
			"required": true,
			"description": "皮肤资源路径",
			"schema": {
				"chess": {
					"type": "dictionary",
					"required": false,
					"description": "棋子资源路径",
					"check_schema": false
					},
					"board": {
						"type": "dictionary",
						"required": false,
						"description": "棋盘资源路径",
						"check_schema": false
						},
						"ui": {
							"type": "dictionary",
							"required": false,
							"description": "UI资源路径",
							"check_schema": false
							}
						}
			}
	}

# 验证自定义规则
func _validate_custom_rules(config_data: Dictionary) -> void:
	# 验证皮肤类型
	if config_data.has("type"):
		var valid_types = ["theme", "chess", "board", "ui"]
		if not valid_types.has(config_data.type):
			validation_errors.append("皮肤类型必须是有效的类型: " + ", ".join(valid_types))

	# 验证稀有度范围
	if config_data.has("rarity") and not GameConsts.is_valid_rarity(config_data.rarity):
		validation_errors.append("稀有度必须是有效的 GameConstants.Rarity 枚举值: " + str(config_data.rarity))

	# 验证价格
	if config_data.has("price") and config_data.price < 0:
		validation_errors.append("价格不能为负数")

	# 验证解锁条件
	if config_data.has("unlock_condition") and config_data.unlock_condition is Dictionary:
		if not config_data.unlock_condition.has("type"):
			validation_errors.append("解锁条件必须有type字段")
		else:
			var condition_type = config_data.unlock_condition.type
			var valid_condition_types = ["gold", "achievement", "level", "win_count"]

			if not valid_condition_types.has(condition_type):
				validation_errors.append("解锁条件类型必须是有效的类型: " + ", ".join(valid_condition_types))

			if not config_data.unlock_condition.has("value"):
				validation_errors.append("解锁条件必须有value字段")
			else:
				var condition_value = config_data.unlock_condition.value

				match condition_type:
					"achievement":
						if not condition_value is String or condition_value.is_empty():
							validation_errors.append("成就解锁条件必须是有效的字符串")
					"level", "gold", "win_count":
						if not condition_value is int or condition_value <= 0:
							validation_errors.append(condition_type + "解锁条件必须是正整数")

	# 验证资源路径
	if config_data.has("assets"):
		if not config_data.assets is Dictionary:
			validation_errors.append("assets必须是字典")
		else:
			# 根据皮肤类型验证必要的资源类型
			if config_data.has("type"):
				match config_data.type:
					"theme":
						# 主题皮肤应该包含所有类型的资源
						if not config_data.assets.has("chess") or not config_data.assets.chess is Dictionary:
							validation_errors.append("主题皮肤必须包含棋子资源")
						if not config_data.assets.has("board") or not config_data.assets.board is Dictionary:
							validation_errors.append("主题皮肤必须包含棋盘资源")
						if not config_data.assets.has("ui") or not config_data.assets.ui is Dictionary:
							validation_errors.append("主题皮肤必须包含UI资源")
					"chess":
						# 棋子皮肤必须包含棋子资源
						if not config_data.assets.has("chess") or not config_data.assets.chess is Dictionary:
							validation_errors.append("棋子皮肤必须包含棋子资源")
					"board":
						# 棋盘皮肤必须包含棋盘资源
						if not config_data.assets.has("board") or not config_data.assets.board is Dictionary:
							validation_errors.append("棋盘皮肤必须包含棋盘资源")
					"ui":
						# UI皮肤必须包含UI资源
						if not config_data.assets.has("ui") or not config_data.assets.ui is Dictionary:
							validation_errors.append("UI皮肤必须包含UI资源")

			# 验证资源路径是否有效
			for asset_type in config_data.assets:
				if config_data.assets[asset_type] is Dictionary:
					for asset_key in config_data.assets[asset_type]:
						var asset_path = config_data.assets[asset_type][asset_key]
						if not asset_path is String or asset_path.is_empty():
							validation_errors.append("资源路径必须是有效的字符串: " + asset_type + "." + asset_key)

# 获取皮肤名称
func get_skin_name() -> String:
	return data.get("name", "")

# 获取皮肤描述
func get_description() -> String:
	return data.get("description", "")

# 获取皮肤类型
func get_skin_type() -> String:
	return data.get("type", "")

# 获取皮肤稀有度
func get_rarity() -> int:
	return data.get("rarity", 0)

# 获取皮肤价格
func get_price() -> float:
	return data.get("price", 0.0)

# 获取皮肤图标路径
func get_icon_path() -> String:
	return data.get("icon_path", "")

# 获取解锁条件
func get_unlock_condition() -> Dictionary:
	return data.get("unlock_condition", {})

# 获取资源路径
func get_assets() -> Dictionary:
	return data.get("assets", {})

# 获取特定类型的资源
func get_assets_by_type(asset_type: String) -> Dictionary:
	var assets = get_assets()
	if assets.has(asset_type):
		return assets[asset_type]
	return {}

# 获取特定资源路径
func get_asset_path(asset_type: String, asset_key: String) -> String:
	var assets_by_type = get_assets_by_type(asset_type)
	if assets_by_type.has(asset_key):
		return assets_by_type[asset_key]
	return ""

# 检查是否为特定皮肤类型
func is_skin_type(skin_type: String) -> bool:
	return get_skin_type() == skin_type

# 检查是否有特定类型的资源
func has_asset_type(asset_type: String) -> bool:
	return get_assets().has(asset_type)

# 检查是否满足解锁条件
func meets_unlock_condition(player_data: Dictionary) -> bool:
	var unlock_condition = get_unlock_condition()

	if unlock_condition.is_empty():
		return true

	if not unlock_condition.has("type") or not unlock_condition.has("value"):
		return false

	var condition_type = unlock_condition.type
	var condition_value = unlock_condition.value

	match condition_type:
		"achievement":
			if not player_data.has("achievements") or not player_data.achievements.has(condition_value) or not player_data.achievements[condition_value]:
				return false
		"level":
			if not player_data.has("level") or player_data.level < condition_value:
				return false
		"gold":
			if not player_data.has("gold") or player_data.gold < condition_value:
				return false
		"win_count":
			if not player_data.has("win_count") or player_data.win_count < condition_value:
				return false
		_:
			return false

	return true
