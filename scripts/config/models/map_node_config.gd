extends "res://scripts/config/config_model.gd"
class_name MapNodeConfig
## 地图节点配置模型
## 提供地图节点配置数据的访问和验证

# 获取配置类型
func _get_config_type() -> String:
	return "map_node"

# 获取默认架构
func _get_default_schema() -> Dictionary:
	return {
		"id": {
			"type": "string",
			"required": true,
			"description": "节点ID"
		},
		"name": {
			"type": "string",
			"required": true,
			"description": "节点名称"
		},
		"description": {
			"type": "string",
			"required": true,
			"description": "节点描述"
		},
		"icon_path": {
			"type": "string",
			"required": false,
			"description": "节点图标路径"
		},
		"color": {
			"type": "string",
			"required": false,
			"description": "节点颜色"
		},
		"node_type": {
			"type": "string",
			"required": true,
			"description": "节点类型"
		},
		"weight": {
			"type": "int",
			"required": false,
			"description": "节点权重"
		},
		"rewards": {
			"type": "dictionary",
			"required": false,
			"description": "节点奖励"
		},
		"connections": {
			"type": "array[string]",
			"required": false,
			"description": "节点连接"
		}
	}

# 验证自定义规则
func _validate_custom_rules(config_data: Dictionary) -> void:
	# 验证节点类型
	if config_data.has("node_type"):
		var valid_types = ["battle", "elite", "shop", "event", "rest", "treasure", "boss"]
		if not valid_types.has(config_data.node_type):
			validation_errors.append("节点类型必须是有效的类型: " + ", ".join(valid_types))
	
	# 验证节点颜色
	if config_data.has("color") and config_data.color is String:
		if not config_data.color.begins_with("#") or config_data.color.length() != 7:
			validation_errors.append("节点颜色必须是有效的十六进制颜色代码，例如 #FF0000")
	
	# 验证节点权重
	if config_data.has("weight") and config_data.weight is int:
		if config_data.weight < 0:
			validation_errors.append("节点权重必须大于等于0")
	
	# 验证节点奖励
	if config_data.has("rewards") and config_data.rewards is Dictionary:
		for reward_type in config_data.rewards:
			var reward_value = config_data.rewards[reward_type]
			
			match reward_type:
				"gold":
					if not reward_value is int or reward_value < 0:
						validation_errors.append("金币奖励必须是非负整数")
				"experience":
					if not reward_value is int or reward_value < 0:
						validation_errors.append("经验奖励必须是非负整数")
				"health":
					if not reward_value is int:
						validation_errors.append("生命值奖励必须是整数")
				"equipment":
					if not reward_value is Array:
						validation_errors.append("装备奖励必须是数组")
					else:
						for equipment_id in reward_value:
							if not equipment_id is String or equipment_id.is_empty():
								validation_errors.append("装备ID必须是有效的字符串")
				"chess_piece":
					if not reward_value is Array:
						validation_errors.append("棋子奖励必须是数组")
					else:
						for piece_id in reward_value:
							if not piece_id is String or piece_id.is_empty():
								validation_errors.append("棋子ID必须是有效的字符串")
				"relic":
					if not reward_value is Array:
						validation_errors.append("遗物奖励必须是数组")
					else:
						for relic_id in reward_value:
							if not relic_id is String or relic_id.is_empty():
								validation_errors.append("遗物ID必须是有效的字符串")
	
	# 验证节点连接
	if config_data.has("connections") and config_data.connections is Array:
		for connection in config_data.connections:
			if not connection is String or connection.is_empty():
				validation_errors.append("节点连接必须是有效的字符串")

# 获取节点名称
func get_name() -> String:
	return data.get("name", "")

# 获取节点描述
func get_description() -> String:
	return data.get("description", "")

# 获取节点图标路径
func get_icon_path() -> String:
	return data.get("icon_path", "")

# 获取节点颜色
func get_color() -> String:
	return data.get("color", "#FFFFFF")

# 获取节点类型
func get_node_type() -> String:
	return data.get("node_type", "")

# 获取节点权重
func get_weight() -> int:
	return data.get("weight", 0)

# 获取节点奖励
func get_rewards() -> Dictionary:
	return data.get("rewards", {})

# 获取节点连接
func get_connections() -> Array:
	return data.get("connections", [])

# 检查节点是否有特定类型的奖励
func has_reward_type(reward_type: String) -> bool:
	var rewards = get_rewards()
	return rewards.has(reward_type)

# 获取特定类型的奖励
func get_reward(reward_type: String, default_value = null) -> Variant:
	var rewards = get_rewards()
	return rewards.get(reward_type, default_value)

# 获取节点颜色为Color对象
func get_color_object() -> Color:
	return Color.from_string(get_color(), Color.WHITE)
