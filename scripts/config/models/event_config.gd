extends "res://scripts/config/config_model.gd"
class_name EventConfig
## 事件配置模型
## 提供事件配置数据的访问和验证

# 获取配置类型
func _get_config_type() -> String:
	return "event"

# 获取默认架构
func _get_default_schema() -> Dictionary:
	return {
  "id": {
	"type": "string",
	"required": true,
	"description": "事件ID"
  },
  "title": {
	"type": "string",
	"required": true,
	"description": "事件标题"
  },
  "description": {
	"type": "string",
	"required": true,
	"description": "事件描述"
  },
  "image_path": {
	"type": "string",
	"required": false,
	"description": "事件图片路径"
  },
  "event_type": {
	"type": "string",
	"required": true,
	"description": "事件类型"
  },
  "weight": {
	"type": "int",
	"required": false,
	"description": "事件权重"
  },
  "is_one_time": {
	"type": "bool",
	"required": false,
	"description": "是否为一次性事件"
  },
  "choices": {
	"type": "array[dictionary]",
	"required": true,
	"description": "事件选项",
	"schema": {
	  "text": {
		"type": "string",
		"required": true,
		"description": "选项文本"
	  },
	  "requirements": {
		"type": "dictionary",
		"required": false,
		"description": "选项要求",
		"schema": {
		  "gold": {
			"type": "int",
			"required": false,
			"description": "金币要求"
		  },
		  "has_item": {
			"type": "string",
			"required": false,
			"description": "物品要求"
		  },
		  "health": {
			"type": "int",
			"required": false,
			"description": "生命值要求"
		  },
		  "level": {
			"type": "int",
			"required": false,
			"description": "等级要求"
		  },
		  "synergy": {
			"type": "dictionary",
			"required": false,
			"description": "羁绊要求",
			"schema": {
			  "id": {
				"type": "string",
				"required": true,
				"description": "羁绊ID"
			  },
			  "count": {
				"type": "int",
				"required": true,
				"description": "羁绊数量"
			  }
			}
		  },
		  "chess_piece": {
			"type": "dictionary",
			"required": false,
			"description": "棋子要求",
			"schema": {
			  "id": {
				"type": "string",
				"required": true,
				"description": "棋子ID"
			  },
			  "count": {
				"type": "int",
				"required": true,
				"description": "棋子数量"
			  }
			}
		  },
		  "map_depth": {
			"type": "int",
			"required": false,
			"description": "地图深度要求"
		  },
		  "relic": {
			"type": "dictionary",
			"required": false,
			"description": "遗物要求",
			"schema": {
			  "id": {
				"type": "string",
				"required": true,
				"description": "遗物ID"
			  }
			}
		  },
		  "effects": {
			"type": "array[dictionary]",
			"required": false,
			"description": "选项效果",
			"schema": {
			  "type": {
				"type": "string",
				"required": true,
				"description": "效果类型"
			  },
			  "description": {
				"type": "string",
				"required": false,
				"description": "效果描述"
			  },
			  "trigger": {
				"type": "string",
				"required": false,
				"description": "触发条件"
			  },
			  "value": {
				"type": "int",
				"required": false,
				"description": "效果值"
			  },
			  "Stats": {
				"type": "dictionary",
				"required": false,
				"description": "效果属性修改",
				"schema": {
				  "attack_damage": {
					"type": "float",
					"required": false,
					"description": "攻击力"
				  },
				  "attack_speed": {
					"type": "float",
					"required": false,
					"description": "攻击速度"
				  },
				  "armor": {
					"type": "float",
					"required": false,
					"description": "护甲"
				  },
				  "magic_resist": {
					"type": "float",
					"required": false,
					"description": "魔抗"
				  },
				  "spell_power": {
					"type": "float",
					"required": false,
					"description": "法术强度"
				  }
				}
			  },
			  "operation": {
				"type": "string",
				"required": false,
				"description": "效果操作"
			  }
			}
		  }
		}
	  }
	}
  }
}


# 验证自定义规则
func _validate_custom_rules(config_data: Dictionary) -> void:
	# 验证事件类型
	if config_data.has("event_type"):
		var valid_types = ["normal", "shop", "battle", "treasure","curse","story"]
		if not valid_types.has(config_data.event_type):
			validation_errors.append(config_data.event_type+ " 事件类型必须是有效的类型: " + ", ".join(valid_types))
	
	# 验证事件权重
	if config_data.has("weight") and config_data.weight < 0:
		validation_errors.append("事件权重必须大于等于0")
	
	# 验证事件选项
	if config_data.has("choices") and config_data.choices is Array:
		if config_data.choices.is_empty():
			validation_errors.append("事件必须至少有一个选项")
		
		for choice in config_data.choices:
			if not choice is Dictionary:
				validation_errors.append("选项必须是字典")
				continue
			
			# 验证选项文本
			if not choice.has("text") or not choice.text is String or choice.text.is_empty():
				validation_errors.append("选项必须有有效的文本")
			
			# 验证选项要求
			if choice.has("requirements") and choice.requirements is Dictionary:
				for req_type in choice.requirements:
					var req_value = choice.requirements[req_type]
					
					match req_type:
						"gold":
							if not req_value is int or req_value < 0:
								validation_errors.append("金币要求必须是非负整数:"+str(req_value))
						"has_item":
							if not req_value is String or req_value.is_empty():
								validation_errors.append("物品要求必须是有效的字符串")
						"health":
							if not req_value is int or req_value <= 0:
								validation_errors.append("生命值要求必须是正整数")
						"level":
							if not req_value is int or req_value <= 0:
								validation_errors.append("等级要求必须是正整数")
						"synergy":
							if not req_value is Dictionary or not req_value.has("id") or not req_value.has("count"):
								validation_errors.append("羁绊要求必须包含id和count字段")
							elif not req_value.id is String or req_value.id.is_empty():
								validation_errors.append("羁绊ID必须是有效的字符串")
							elif not req_value.count is int or req_value.count <= 0:
								validation_errors.append("羁绊数量必须是正整数")
			
			# 验证选项效果
			if choice.has("effects") and choice.effects is Array:
				for effect in choice.effects:
					if not effect is Dictionary:
						validation_errors.append("效果必须是字典")
						continue
					
					# 验证效果类型
					if not effect.has("type") or not effect.type is String or effect.type.is_empty():
						validation_errors.append("效果必须有有效的类型")
					else:
						var valid_types = ["gold", "health", "relic", "item", "shop", "chess_piece"]
						if not valid_types.has(effect.type):
							validation_errors.append("效果类型必须是有效的类型: " + ", ".join(valid_types))
					
					# 验证效果操作
					if not effect.has("operation") or not effect.operation is String or effect.operation.is_empty():
						validation_errors.append("效果必须有有效的操作")
					else:
						var valid_operations = ["add", "subtract", "buff", "remove"]
						if not valid_operations.has(effect.operation):
							validation_errors.append(effect.operation + "效果操作必须是有效的操作: " + ", ".join(valid_operations))
					
					# 验证效果值
					if effect.has("value"):
						if not (effect.value is int or effect.value is float or effect.value is String):
							validation_errors.append("效果值必须是数字或字符串")
					
					# 验证效果概率
					if effect.has("chance"):
						if not (effect.chance is float or effect.chance is int) or effect.chance < 0 or effect.chance > 1:
							validation_errors.append("效果概率必须在0到1之间")

# 获取事件标题
func get_title() -> String:
	return data.get("title", "")

# 获取事件描述
func get_description() -> String:
	return data.get("description", "")

# 获取事件图片路径
func get_image_path() -> String:
	return data.get("image_path", "")

# 获取事件类型
func get_event_type() -> String:
	return data.get("event_type", "")

# 获取事件权重
func get_weight() -> int:
	return data.get("weight", 100)

# 获取是否为一次性事件
func is_one_time() -> bool:
	return data.get("is_one_time", false)

# 获取事件选项
func get_choices() -> Array:
	return data.get("choices", [])

# 获取特定索引的选项
func get_choice(index: int) -> Dictionary:
	var choices = get_choices()
	
	if index >= 0 and index < choices.size():
		return choices[index]
	
	return {}

# 检查选项是否满足要求
func choice_meets_requirements(choice_index: int, player_data: Dictionary) -> bool:
	var choice = get_choice(choice_index)
	
	if not choice.has("requirements"):
		return true
	
	var requirements = choice.requirements
	
	for req_type in requirements:
		var req_value = requirements[req_type]
		
		match req_type:
			"gold":
				if not player_data.has("gold") or player_data.gold < req_value:
					return false
			"has_item":
				if not player_data.has("inventory") or not player_data.inventory.has(req_value):
					return false
			"health":
				if not player_data.has("health") or player_data.health < req_value:
					return false
			"level":
				if not player_data.has("level") or player_data.level < req_value:
					return false
			"synergy":
				if not player_data.has("synergies") or not player_data.synergies.has(req_value.id) or player_data.synergies[req_value.id] < req_value.count:
					return false
	
	return true

# 获取选项的效果
func get_choice_effects(choice_index: int) -> Array:
	var choice = get_choice(choice_index)
	
	if choice.has("effects"):
		return choice.effects
	
	return []

# 检查事件是否为特定类型
func is_type(event_type: String) -> bool:
	return get_event_type() == event_type
