extends "res://scripts/config/config_model.gd"
class_name TutorialConfig
## 教程配置模型
## 提供教程配置数据的访问和验证

# 获取配置类型
func _get_config_type() -> String:
	return "tutorial"

# 获取默认架构
func _get_default_schema() -> Dictionary:
	return {
		"id": {
			"type": "string",
			"required": true,
			"description": "教程ID"
		},
		"title": {
			"type": "string",
			"required": true,
			"description": "教程标题"
		},
		"description": {
			"type": "string",
			"required": true,
			"description": "教程描述"
		},
		"category": {
			"type": "string",
			"required": true,
			"description": "教程类别"
		},
		"order": {
			"type": "int",
			"required": true,
			"description": "教程顺序"
		},
		"is_required": {
			"type": "bool",
			"required": false,
			"description": "是否必须完成"
		},
		"trigger_condition": {
			"type": "dictionary",
			"required": false,
			"description": "触发条件"
		},
		"steps": {
			"type": "array[dictionary]",
			"required": true,
			"description": "教程步骤"
		}
	}

# 验证自定义规则
func _validate_custom_rules(config_data: Dictionary) -> void:
	# 验证教程类别
	if config_data.has("category"):
		var valid_categories = ["basic", "combat", "shop", "map", "synergy", "equipment", "advanced"]
		if not valid_categories.has(config_data.category):
			validation_errors.append("教程类别必须是有效的类别: " + ", ".join(valid_categories))
	
	# 验证教程顺序
	if config_data.has("order") and config_data.order < 0:
		validation_errors.append("教程顺序必须大于等于0")
	
	# 验证触发条件
	if config_data.has("trigger_condition") and config_data.trigger_condition is Dictionary:
		for condition_type in config_data.trigger_condition:
			var condition_value = config_data.trigger_condition[condition_type]
			
			match condition_type:
				"first_time":
					if not condition_value is bool:
						validation_errors.append("首次触发条件必须是布尔值")
				"level":
					if not condition_value is int or condition_value <= 0:
						validation_errors.append("等级触发条件必须是正整数")
				"scene":
					if not condition_value is String or condition_value.is_empty():
						validation_errors.append("场景触发条件必须是有效的字符串")
				"event":
					if not condition_value is String or condition_value.is_empty():
						validation_errors.append("事件触发条件必须是有效的字符串")
	
	# 验证教程步骤
	if config_data.has("steps") and config_data.steps is Array:
		if config_data.steps.is_empty():
			validation_errors.append("教程必须至少有一个步骤")
		
		for step in config_data.steps:
			if not step is Dictionary:
				validation_errors.append("步骤必须是字典")
				continue
			
			# 验证步骤标题
			if not step.has("title") or not step.title is String or step.title.is_empty():
				validation_errors.append("步骤必须有有效的标题")
			
			# 验证步骤内容
			if not step.has("content") or not step.content is String or step.content.is_empty():
				validation_errors.append("步骤必须有有效的内容")
			
			# 验证步骤目标
			if step.has("target") and not step.target is String:
				validation_errors.append("步骤目标必须是字符串")
			
			# 验证步骤高亮
			if step.has("highlight") and not step.highlight is bool:
				validation_errors.append("步骤高亮必须是布尔值")
			
			# 验证步骤完成条件
			if step.has("completion_condition") and step.completion_condition is Dictionary:
				for condition_type in step.completion_condition:
					var condition_value = step.completion_condition[condition_type]
					
					match condition_type:
						"click":
							if not condition_value is String or condition_value.is_empty():
								validation_errors.append("点击完成条件必须是有效的字符串")
						"action":
							if not condition_value is String or condition_value.is_empty():
								validation_errors.append("动作完成条件必须是有效的字符串")
						"wait":
							if not condition_value is int or condition_value <= 0:
								validation_errors.append("等待完成条件必须是正整数")
						"event":
							if not condition_value is String or condition_value.is_empty():
								validation_errors.append("事件完成条件必须是有效的字符串")

# 获取教程标题
func get_title() -> String:
	return data.get("title", "")

# 获取教程描述
func get_description() -> String:
	return data.get("description", "")

# 获取教程类别
func get_category() -> String:
	return data.get("category", "")

# 获取教程顺序
func get_order() -> int:
	return data.get("order", 0)

# 获取是否必须完成
func is_required() -> bool:
	return data.get("is_required", false)

# 获取触发条件
func get_trigger_condition() -> Dictionary:
	return data.get("trigger_condition", {})

# 获取教程步骤
func get_steps() -> Array:
	return data.get("steps", [])

# 获取步骤数量
func get_step_count() -> int:
	return get_steps().size()

# 获取特定索引的步骤
func get_step(index: int) -> Dictionary:
	var steps = get_steps()
	
	if index >= 0 and index < steps.size():
		return steps[index]
	
	return {}

# 检查是否为特定类别
func is_category(category: String) -> bool:
	return get_category() == category

# 检查是否满足触发条件
func meets_trigger_condition(player_data: Dictionary) -> bool:
	var trigger_condition = get_trigger_condition()
	
	if trigger_condition.is_empty():
		return true
	
	for condition_type in trigger_condition:
		var condition_value = trigger_condition[condition_type]
		
		match condition_type:
			"first_time":
				if not player_data.has("first_time") or not player_data.first_time == condition_value:
					return false
			"level":
				if not player_data.has("level") or player_data.level < condition_value:
					return false
			"scene":
				if not player_data.has("current_scene") or player_data.current_scene != condition_value:
					return false
			"event":
				if not player_data.has("triggered_events") or not player_data.triggered_events.has(condition_value):
					return false
	
	return true

# 检查步骤是否满足完成条件
func step_meets_completion_condition(step_index: int, player_data: Dictionary) -> bool:
	var step = get_step(step_index)
	
	if not step.has("completion_condition"):
		return true
	
	var completion_condition = step.completion_condition
	
	for condition_type in completion_condition:
		var condition_value = completion_condition[condition_type]
		
		match condition_type:
			"click":
				if not player_data.has("clicked_elements") or not player_data.clicked_elements.has(condition_value):
					return false
			"action":
				if not player_data.has("performed_actions") or not player_data.performed_actions.has(condition_value):
					return false
			"wait":
				if not player_data.has("elapsed_time") or player_data.elapsed_time < condition_value:
					return false
			"event":
				if not player_data.has("triggered_events") or not player_data.triggered_events.has(condition_value):
					return false
	
	return true
