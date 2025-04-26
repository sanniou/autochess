extends ConfigModel
class_name TutorialConfig2
## 教程配置模型
## 提供教程配置数据的访问和验证

# 教程类别枚举
enum TutorialCategory {
	BASIC,      # 基础教程
	COMBAT,     # 战斗教程
	SHOP,       # 商店教程
	MAP,        # 地图教程
	SYNERGY,    # 羁绊教程
	EQUIPMENT,  # 装备教程
	ADVANCED    # 高级教程
}

# 触发条件类型枚举
enum TriggerConditionType {
	FIRST_TIME,    # 首次进入游戏
	LEVEL,         # 达到特定等级
	SCENE,         # 进入特定场景
	EVENT,         # 特定事件触发
	ITEM_OBTAINED, # 获得特定物品
	CHESS_OBTAINED,# 获得特定棋子
	BATTLE_COUNT,  # 战斗次数达到
	SHOP_VISIT,    # 商店访问次数
	CUSTOM         # 自定义条件
}

# 完成条件类型枚举
enum CompletionConditionType {
	CLICK,         # 点击特定元素
	ACTION,        # 执行特定动作
	WAIT,          # 等待特定时间
	EVENT,         # 特定事件触发
	ITEM_USE,      # 使用特定物品
	CHESS_PLACE,   # 放置特定棋子
	BATTLE_WIN,    # 战斗胜利
	SHOP_PURCHASE, # 商店购买
	CUSTOM         # 自定义条件
}

# 动作类型枚举
enum ActionType {
	HIGHLIGHT,     # 高亮UI元素
	FOCUS,         # 聚焦UI元素
	DISABLE,       # 禁用UI元素
	ENABLE,        # 启用UI元素
	WAIT,          # 等待事件
	SHOW,          # 显示UI元素
	HIDE,          # 隐藏UI元素
	MOVE_CAMERA,   # 移动相机
	PLAY_ANIMATION,# 播放动画
	CUSTOM         # 自定义动作
}

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
			"description": "教程类别",
			"enum": ["basic", "combat", "shop", "map", "synergy", "equipment", "advanced"]
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
		"next_tutorial": {
			"type": "string",
			"required": false,
			"description": "下一个教程ID"
		},
		"trigger_conditions": {
			"type": "array[dictionary]",
			"required": false,
			"description": "触发条件列表",
			"schema": {
				"type": {
					"type": "string",
					"required": true,
					"description": "条件类型",
					"enum": ["first_time", "level", "scene", "event", "item_obtained", "chess_obtained", "battle_count", "shop_visit", "custom"]
				},
				"value": {
					"type": "string",
					"required": true,
					"description": "条件值"
				},
				"operator": {
					"type": "string",
					"required": false,
					"description": "条件运算符",
					"enum": ["equal", "not_equal", "greater", "less", "greater_equal", "less_equal", "contains"]
				},
				"description": {
					"type": "string",
					"required": false,
					"description": "条件描述"
				}
			}
		},
		"condition_logic": {
			"type": "string",
			"required": false,
			"description": "条件逻辑关系",
			"enum": ["and", "or"]
		},
		"steps": {
			"type": "array[dictionary]",
			"required": true,
			"description": "教程步骤",
			"schema": {
				"title": {
					"type": "string",
					"required": true,
					"description": "步骤标题"
				},
				"content": {
					"type": "string",
					"required": true,
					"description": "步骤内容"
				},
				"image_path": {
					"type": "string",
					"required": false,
					"description": "步骤图片路径"
				},
				"target": {
					"type": "string",
					"required": false,
					"description": "步骤目标节点路径"
				},
				"highlight": {
					"type": "bool",
					"required": false,
					"description": "是否高亮目标"
				},
				"completion_conditions": {
					"type": "array[dictionary]",
					"required": false,
					"description": "完成条件列表",
					"schema": {
						"type": {
							"type": "string",
							"required": true,
							"description": "条件类型",
							"enum": ["click", "action", "wait", "event", "item_use", "chess_place", "battle_win", "shop_purchase", "custom"]
						},
						"value": {
							"type": "string",
							"required": true,
							"description": "条件值"
						},
						"operator": {
							"type": "string",
							"required": false,
							"description": "条件运算符",
							"enum": ["equal", "not_equal", "greater", "less", "greater_equal", "less_equal", "contains"]
						},
						"description": {
							"type": "string",
							"required": false,
							"description": "条件描述"
						}
					}
				},
				"condition_logic": {
					"type": "string",
					"required": false,
					"description": "条件逻辑关系",
					"enum": ["and", "or"]
				},
				"actions": {
					"type": "array[dictionary]",
					"required": false,
					"description": "步骤操作",
					"schema": {
						"type": {
							"type": "string",
							"required": true,
							"description": "操作类型",
							"enum": ["highlight", "focus", "disable", "enable", "wait", "show", "hide", "move_camera", "play_animation", "custom"]
						},
						"target": {
							"type": "string",
							"required": false,
							"description": "操作目标"
						},
						"targets": {
							"type": "array[string]",
							"required": false,
							"description": "操作目标列表"
						},
						"duration": {
							"type": "float",
							"required": false,
							"description": "操作持续时间"
						},
						"event": {
							"type": "string",
							"required": false,
							"description": "等待的事件名称"
						},
						"timeout": {
							"type": "float",
							"required": false,
							"description": "等待超时时间"
						},
						"position": {
							"type": "vector2",
							"required": false,
							"description": "位置坐标"
						},
						"animation": {
							"type": "string",
							"required": false,
							"description": "动画名称"
						},
						"speed": {
							"type": "float",
							"required": false,
							"description": "动画速度"
						},
						"params": {
							"type": "dictionary",
							"required": false,
							"description": "自定义参数",
							"check_schema": false
						}
					}
				},
				"timeout": {
					"type": "float",
					"required": false,
					"description": "步骤超时时间"
				},
				"auto_advance": {
					"type": "bool",
					"required": false,
					"description": "是否自动进入下一步"
				}
			}
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
	if config_data.has("trigger_conditions") and config_data.trigger_conditions is Array:
		for condition in config_data.trigger_conditions:
			if not condition is Dictionary:
				validation_errors.append("触发条件必须是字典")
				continue
			
			# 验证条件类型
			if not condition.has("type") or not condition.type is String:
				validation_errors.append("触发条件必须有有效的类型")
				continue
			
			# 验证条件值
			if not condition.has("value"):
				validation_errors.append("触发条件必须有值")
				continue
			
			# 验证特定类型的条件
			match condition.type:
				"first_time":
					if not condition.value is bool and not (condition.value is String and (condition.value == "true" or condition.value == "false")):
						validation_errors.append("首次触发条件值必须是布尔值或布尔字符串")
				"level":
					var level_value = condition.value
					if condition.value is String:
						if not condition.value.is_valid_int():
							validation_errors.append("等级触发条件值必须是整数或可转换为整数的字符串")
						else:
							level_value = condition.value.to_int()
					
					if not level_value is int or level_value <= 0:
						validation_errors.append("等级触发条件值必须是正整数")
				"scene", "event", "item_obtained", "chess_obtained":
					if not condition.value is String or condition.value.is_empty():
						validation_errors.append(condition.type + "触发条件值必须是有效的字符串")
				"battle_count", "shop_visit":
					var count_value = condition.value
					if condition.value is String:
						if not condition.value.is_valid_int():
							validation_errors.append(condition.type + "触发条件值必须是整数或可转换为整数的字符串")
						else:
							count_value = condition.value.to_int()
					
					if not count_value is int or count_value < 0:
						validation_errors.append(condition.type + "触发条件值必须是非负整数")
	
	# 验证条件逻辑关系
	if config_data.has("condition_logic"):
		var valid_logics = ["and", "or"]
		if not valid_logics.has(config_data.condition_logic):
			validation_errors.append("条件逻辑关系必须是有效的值: " + ", ".join(valid_logics))
	
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
			if step.has("completion_conditions") and step.completion_conditions is Array:
				for condition in step.completion_conditions:
					if not condition is Dictionary:
						validation_errors.append("完成条件必须是字典")
						continue
					
					# 验证条件类型
					if not condition.has("type") or not condition.type is String:
						validation_errors.append("完成条件必须有有效的类型")
						continue
					
					# 验证条件值
					if not condition.has("value"):
						validation_errors.append("完成条件必须有值")
						continue
					
					# 验证特定类型的条件
					match condition.type:
						"click", "action", "event", "item_use", "chess_place":
							if not condition.value is String or condition.value.is_empty():
								validation_errors.append(condition.type + "完成条件值必须是有效的字符串")
						"wait":
							var wait_value = condition.value
							if condition.value is String:
								if not condition.value.is_valid_float():
									validation_errors.append("等待完成条件值必须是数字或可转换为数字的字符串")
								else:
									wait_value = condition.value.to_float()
							
							if not (wait_value is int or wait_value is float) or wait_value <= 0:
								validation_errors.append("等待完成条件值必须是正数")
						"battle_win", "shop_purchase":
							if not condition.value is bool and not (condition.value is String and (condition.value == "true" or condition.value == "false")):
								validation_errors.append(condition.type + "完成条件值必须是布尔值或布尔字符串")
			
			# 验证步骤操作
			if step.has("actions") and step.actions is Array:
				for action in step.actions:
					if not action is Dictionary:
						validation_errors.append("步骤操作必须是字典")
						continue
					
					# 验证操作类型
					if not action.has("type") or not action.type is String:
						validation_errors.append("步骤操作必须有有效的类型")
						continue
					
					# 验证特定类型的操作
					match action.type:
						"highlight", "focus", "play_animation":
							if not action.has("target") or not action.target is String or action.target.is_empty():
								validation_errors.append(action.type + "操作必须有有效的目标")
						"disable", "enable", "show", "hide":
							if not action.has("targets") or not action.targets is Array or action.targets.is_empty():
								if not action.has("target") or not action.target is String or action.target.is_empty():
									validation_errors.append(action.type + "操作必须有有效的目标或目标列表")
						"wait":
							if not action.has("event") or not action.event is String or action.event.is_empty():
								validation_errors.append("等待操作必须有有效的事件名称")
						"move_camera":
							if not action.has("position") or not (action.position is Vector2 or (action.position is String and action.position.begins_with("Vector2"))):
								validation_errors.append("移动相机操作必须有有效的位置坐标")

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

# 获取下一个教程ID
func get_next_tutorial() -> String:
	return data.get("next_tutorial", "")

# 获取触发条件
func get_trigger_conditions() -> Array:
	return data.get("trigger_conditions", [])

# 获取条件逻辑关系
func get_condition_logic() -> String:
	return data.get("condition_logic", "and")

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
func meets_trigger_conditions(player_data: Dictionary) -> bool:
	var trigger_conditions = get_trigger_conditions()
	
	# 如果没有触发条件，默认满足
	if trigger_conditions.is_empty():
		return true
	
	# 获取条件逻辑关系
	var logic = get_condition_logic()
	var result = logic == "and"  # 如果是AND逻辑，初始为true；如果是OR逻辑，初始为false
	
	for condition in trigger_conditions:
		var condition_type = condition.type
		var condition_value = condition.value
		var operator = condition.get("operator", "equal")
		var condition_result = false
		
		match condition_type:
			"first_time":
				var bool_value = condition_value is bool ? condition_value : (condition_value == "true")
				condition_result = player_data.get("first_time", false) == bool_value
			"level":
				var level = int(condition_value) if condition_value is String else condition_value
				var player_level = player_data.get("level", 0)
				
				match operator:
					"equal": condition_result = player_level == level
					"not_equal": condition_result = player_level != level
					"greater": condition_result = player_level > level
					"less": condition_result = player_level < level
					"greater_equal": condition_result = player_level >= level
					"less_equal": condition_result = player_level <= level
			"scene":
				var current_scene = player_data.get("current_scene", "")
				
				match operator:
					"equal": condition_result = current_scene == condition_value
					"not_equal": condition_result = current_scene != condition_value
					"contains": condition_result = current_scene.contains(condition_value)
			"event":
				var triggered_events = player_data.get("triggered_events", {})
				
				match operator:
					"equal", "contains": condition_result = triggered_events.has(condition_value)
					"not_equal": condition_result = not triggered_events.has(condition_value)
			"item_obtained":
				var inventory = player_data.get("inventory", {})
				var items = inventory.get("items", [])
				
				match operator:
					"equal", "contains": 
						for item in items:
							if item.get("id", "") == condition_value:
								condition_result = true
								break
					"not_equal": 
						condition_result = true
						for item in items:
							if item.get("id", "") == condition_value:
								condition_result = false
								break
			"chess_obtained":
				var chess_pieces = player_data.get("chess_pieces", [])
				
				match operator:
					"equal", "contains": 
						for piece in chess_pieces:
							if piece.get("id", "") == condition_value:
								condition_result = true
								break
					"not_equal": 
						condition_result = true
						for piece in chess_pieces:
							if piece.get("id", "") == condition_value:
								condition_result = false
								break
			"battle_count":
				var count = int(condition_value) if condition_value is String else condition_value
				var battle_count = player_data.get("battle_count", 0)
				
				match operator:
					"equal": condition_result = battle_count == count
					"not_equal": condition_result = battle_count != count
					"greater": condition_result = battle_count > count
					"less": condition_result = battle_count < count
					"greater_equal": condition_result = battle_count >= count
					"less_equal": condition_result = battle_count <= count
			"shop_visit":
				var count = int(condition_value) if condition_value is String else condition_value
				var shop_visit = player_data.get("shop_visit", 0)
				
				match operator:
					"equal": condition_result = shop_visit == count
					"not_equal": condition_result = shop_visit != count
					"greater": condition_result = shop_visit > count
					"less": condition_result = shop_visit < count
					"greater_equal": condition_result = shop_visit >= count
					"less_equal": condition_result = shop_visit <= count
			"custom":
				# 自定义条件需要在游戏代码中实现
				if player_data.has("custom_conditions") and player_data.custom_conditions is Dictionary:
					condition_result = player_data.custom_conditions.get(condition_value, false)
		
		# 根据逻辑关系更新结果
		if logic == "and":
			result = result and condition_result
			if not result:  # 如果已经为false，可以提前返回
				return false
		else:  # OR逻辑
			result = result or condition_result
			if result:  # 如果已经为true，可以提前返回
				return true
	
	return result

# 检查步骤是否满足完成条件
func step_meets_completion_conditions(step_index: int, player_data: Dictionary) -> bool:
	var step = get_step(step_index)
	
	# 如果没有完成条件，默认满足
	if not step.has("completion_conditions") or step.completion_conditions.is_empty():
		return true
	
	# 获取条件逻辑关系
	var logic = step.get("condition_logic", "and")
	var result = logic == "and"  # 如果是AND逻辑，初始为true；如果是OR逻辑，初始为false
	
	for condition in step.completion_conditions:
		var condition_type = condition.type
		var condition_value = condition.value
		var operator = condition.get("operator", "equal")
		var condition_result = false
		
		match condition_type:
			"click":
				var clicked_elements = player_data.get("clicked_elements", {})
				
				match operator:
					"equal", "contains": condition_result = clicked_elements.has(condition_value)
					"not_equal": condition_result = not clicked_elements.has(condition_value)
			"action":
				var performed_actions = player_data.get("performed_actions", {})
				
				match operator:
					"equal", "contains": condition_result = performed_actions.has(condition_value)
					"not_equal": condition_result = not performed_actions.has(condition_value)
			"wait":
				var wait_time = float(condition_value) if condition_value is String else condition_value
				var elapsed_time = player_data.get("elapsed_time", 0.0)
				
				match operator:
					"equal": condition_result = elapsed_time == wait_time
					"not_equal": condition_result = elapsed_time != wait_time
					"greater": condition_result = elapsed_time > wait_time
					"less": condition_result = elapsed_time < wait_time
					"greater_equal": condition_result = elapsed_time >= wait_time
					"less_equal": condition_result = elapsed_time <= wait_time
			"event":
				var triggered_events = player_data.get("triggered_events", {})
				
				match operator:
					"equal", "contains": condition_result = triggered_events.has(condition_value)
					"not_equal": condition_result = not triggered_events.has(condition_value)
			"item_use":
				var used_items = player_data.get("used_items", {})
				
				match operator:
					"equal", "contains": condition_result = used_items.has(condition_value)
					"not_equal": condition_result = not used_items.has(condition_value)
			"chess_place":
				var placed_chess = player_data.get("placed_chess", {})
				
				match operator:
					"equal", "contains": condition_result = placed_chess.has(condition_value)
					"not_equal": condition_result = not placed_chess.has(condition_value)
			"battle_win":
				var bool_value = condition_value is bool ? condition_value : (condition_value == "true")
				condition_result = player_data.get("battle_win", false) == bool_value
			"shop_purchase":
				var bool_value = condition_value is bool ? condition_value : (condition_value == "true")
				condition_result = player_data.get("shop_purchase", false) == bool_value
			"custom":
				# 自定义条件需要在游戏代码中实现
				if player_data.has("custom_conditions") and player_data.custom_conditions is Dictionary:
					condition_result = player_data.custom_conditions.get(condition_value, false)
		
		# 根据逻辑关系更新结果
		if logic == "and":
			result = result and condition_result
			if not result:  # 如果已经为false，可以提前返回
				return false
		else:  # OR逻辑
			result = result or condition_result
			if result:  # 如果已经为true，可以提前返回
				return true
	
	return result

# 兼容旧版API
func get_trigger_condition() -> Dictionary:
	# 将新的触发条件数组转换为旧的字典格式
	var old_format = {}
	var conditions = get_trigger_conditions()
	
	for condition in conditions:
		if condition.has("type") and condition.has("value"):
			old_format[condition.type] = condition.value
	
	return old_format

# 兼容旧版API
func meets_trigger_condition(player_data: Dictionary) -> bool:
	return meets_trigger_conditions(player_data)

# 兼容旧版API
func step_meets_completion_condition(step_index: int, player_data: Dictionary) -> bool:
	var step = get_step(step_index)
	
	# 如果使用新格式，调用新方法
	if step.has("completion_conditions"):
		return step_meets_completion_conditions(step_index, player_data)
	
	# 旧格式处理
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
