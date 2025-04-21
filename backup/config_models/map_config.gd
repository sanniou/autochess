extends "res://scripts/config/config_model.gd"
class_name MapConfig
## 地图配置模型
## 提供地图配置数据的访问和验证

# 导入地图组件类
const MapTemplate = preload("res://scripts/game/map/data/map_template.gd")
const NodeType = preload("res://scripts/game/map/data/node_type.gd")
const ConnectionType = preload("res://scripts/game/map/data/connection_type.gd")
const BattleConfig = preload("res://scripts/game/map/data/battle_config.gd")

# 获取配置类型
func _get_config_type() -> String:
	return "map_config"

# 获取默认架构
func _get_default_schema() -> Dictionary:
	return {
		"templates": {
			"type": "dictionary",
			"required": true,
			"description": "地图模板配置",
			"schema_for_all_field":true,
			"schema":{
				"id":{
					"type": "string",
					"required": true,
					"description": "模板ID"
				},
				"name":{
					"type": "string",
					"required": true,
					"description": "模板名称"
				},
				"description":{
					"type": "string",
					"required": true,
					"description": "模板描述"
				},
				"difficulty":{
					"type": "int",
					"required": true,
					"description": "模板难度"
				},
				"layers":{
					"type": "int",
					"required": true,
					"description": "模板层数"
				},
				"nodes_per_layer":{
					"type": "array[int]",
					"required": true,
					"description": "每层节点数"
				},
				"node_distribution":{
					"type": "dictionary",
					"required": true,
					"description": "节点类型分布",
					"schema":{
						"battle":{
							"type": "float",
							"required": true,
							"description": "战斗节点占比"
						},
						"elite_battle":{
							"type": "float",
							"required": true,
							"description": "精英战斗节点占比"
						},
						"shop":{
							"type": "float",
							"required": true,
							"description": "商店节点占比"
						},
						"event":{
							"type": "float",
							"required": true,
							"description": "事件节点占比"
						},
						"treasure":{
							"type": "float",
							"required": true,
							"description": "遗物节点占比"
						},
						"rest":{
							"type": "float",
							"required": true,
							"description": "休息节点占比"
						},
						"mystery":{
							"type": "float",
							"required": true,
							"description": "神秘节点占比"
						},
						"challenge":{
							"type": "float",
							"required": true,
							"description": "挑战节点占比"
						},
						"altar":{
							"type": "float",
							"required": true,
							"description": "祭坛节点占比"
						},
						"blacksmith":{
							"type": "float",
							"required": true,
							"description": "铁匠铺节点占比"
						}
					}
				},
				"fixed_nodes":{
					"type": "array[dictionary]",
					"required": true,
					"description": "固定节点",
					"schema":{
						"layer":{
							"type": "int",
							"required": true,
							"description": "层索引"
						},
						"position":{
							"type": "int",
							"required": true,
							"description": "位置索引"
						},
						"type":{
							"type": "string",
							"required": true,
							"description": "节点类型"
						}
					}
				},
				"connection_rules":{
					"type": "dictionary",
					"required": true,
					"description": "连接规则",
					"schema":{
						"min_connections_per_node":{
							"type": "int",
							"required": true,
							"description": "每个节点最少连接数"
						},
						"max_connections_per_node":{
							"type": "int",
							"required": true,
							"description": "每个节点最多连接数"
						},
						"connection_density":{
							"type": "float",
							"required": true,
							"description": "连接密度"
						},
						"allow_cross_connections":{
							"type": "bool",
							"required": true,
							"description": "是否允许跨层连接"
						}
					}
				}

			}
		},
		"node_types": {
			"type": "dictionary",
			"required": true,
			"description": "节点类型配置",
			"schema_for_all_field":true,
			"schema":{
				"id":{
					"type": "string",
					"required": true,
					"description": "类型ID"
				},
				"name":{
					"type": "string",
					"required": true,
					"description": "类型名称"
				},
				"description":{
					"type": "string",
					"required": true,
					"description": "类型描述"
				},
				"icon":{
					"type": "string",
					"required": false,
					"description": "类型图标"
				},
				"color":{
					"type": "string",
					"required": false,
					"description": "类型颜色"
				},
				"properties":{
					"type": "dictionary",
					"required": true,
					"description": "类型属性",
					"check_schema": false
		
					}
					}
		},
		"connection_types": {
			"type": "dictionary",
			"required": true,
			"description": "连接类型配置",
			"schema_for_all_field":true,
			"schema":{
				"id":{
					"type": "string",
					"required": true,
					"description": "类型ID"
				},
				"name":{
					"type": "string",
					"required": true,
					"description": "类型名称"
				},
				"description":{
					"type": "string",
					"required": true,
					"description": "类型描述"
				},
				"icon":{
					"type": "string",
					"required": false,
					"description": "类型图标"
				},
				"color":{
					"type": "string",
					"required": false,
					"description": "类型颜色"
				},
				"properties":{
					"type": "dictionary",
					"required": true,
					"description": "类型属性",
					"schema":{
						"is_bidirectional":{
							"type": "bool",
							"required": true,
							"description": "是否为双向连接"
						},
						"traversal_cost":{
							"type": "int",
							"required": true,
							"description": "连接遍历花费"
						},
						"is_hidden":{
							"type": "bool",
							"required": false,
							"description": "是否隐藏"
						}
						}
				}
				}
		},
		"battle_configs": {
			"type": "dictionary",
			"required": true,
			"description": "战斗配置",
			"schema_for_all_field":true,
			"schema": {	
				"id": {
					"type": "string",
					"required": true,
					"description": "配置ID"
				},
				"name": {
					"type": "string",
					"required": true,
					"description": "配置名称"
				},
				"min_units": {
					"type": "int",
					"required": true,
					"description": "最少单位数量"
				},
				"max_units": {
					"type": "int",
					"required": true,
					"description": "最多单位数量"
				},
				"difficulty_multiplier": {
					"type": "float",
					"required": true,
					"description": "难度乘数"
				},
				"rewards": {
					"type": "dictionary",
					"required": true,
					"description": "奖励配置",
					"schema": {
						"gold": {
							"type": "dictionary",
							"required": true,
							"description": "金币配置",
							"schema": {
								"base": {
									"type": "int",
									"required": true,
									"description": "基础金币数量"
								},
								"per_difficulty": {
									"type": "float",
									"required": true,
									"description": "每个难度金币数量"
								}
							}
						},
						"item_drop_chance": {
							"type": "float",
							"required": true,
							"description": "物品掉落概率"
						},
						"guaranteed_relic": {
							"type": "bool",
							"required": false,
							"description": "是否保证遗物掉落"
						}
					}
				},
				"special_rules": {
					"type": "dictionary",
					"required": false,
					"description": "特殊规则",
					"schema": {
						"time_limit": {
							"type": "int",
							"required": true,
							"description": "时间限制"
						},
						"restricted_abilities": {
							"type": "bool",
							"required": false,
							"description": "是否限制技能"	
							}
						}
				}
			}
		}
	}

# 验证自定义规则
func _validate_custom_rules(config_data: Dictionary) -> void:
	# 验证模板配置
	if config_data.has("templates"):
		for template_id in config_data.templates:
			var template = config_data.templates[template_id]

			# 验证模板ID
			if not template.has("id"):
				validation_errors.append("模板缺少ID: " + template_id)

			# 验证模板层数
			if not template.has("layers") or template.layers <= 0:
				validation_errors.append("模板层数无效: " + template_id)

			# 验证每层节点数
			if not template.has("nodes_per_layer") or not template.nodes_per_layer is Array:
				validation_errors.append("模板每层节点数配置无效: " + template_id)
			elif template.nodes_per_layer.size() != template.layers:
				validation_errors.append("模板每层节点数配置与层数不匹配: " + template_id)

	# 验证节点类型配置
	if config_data.has("node_types"):
		for type_id in config_data.node_types:
			var node_type = config_data.node_types[type_id]

			# 验证节点类型ID
			if not node_type.has("id"):
				validation_errors.append("节点类型缺少ID: " + type_id)

			# 验证节点类型名称
			if not node_type.has("name"):
				validation_errors.append("节点类型缺少名称: " + type_id)

			# 验证节点类型颜色
			if node_type.has("color") and node_type.color is String:
				if not node_type.color.begins_with("#") or node_type.color.length() != 7:
					validation_errors.append("节点类型颜色必须是有效的十六进制颜色代码，例如 #FF0000: " + type_id)

	# 验证连接类型配置
	if config_data.has("connection_types"):
		for type_id in config_data.connection_types:
			var connection_type = config_data.connection_types[type_id]

			# 验证连接类型ID
			if not connection_type.has("id"):
				validation_errors.append("连接类型缺少ID: " + type_id)

			# 验证连接类型名称
			if not connection_type.has("name"):
				validation_errors.append("连接类型缺少名称: " + type_id)

	# 验证战斗配置
	if config_data.has("battle_configs"):
		for config_id in config_data.battle_configs:
			var battle_config = config_data.battle_configs[config_id]

			# 验证战斗配置ID
			if not battle_config.has("id"):
				validation_errors.append("战斗配置缺少ID: " + config_id)

			# 验证战斗配置名称
			if not battle_config.has("name"):
				validation_errors.append("战斗配置缺少名称: " + config_id)

# 获取模板配置
func get_templates() -> Dictionary:
	var templates_dict = {}
	var templates_data = data.get("templates", {})

	for template_id in templates_data:
		templates_dict[template_id] = MapTemplate.from_dict(templates_data[template_id])

	return templates_dict

# 获取节点类型配置
func get_node_types() -> Dictionary:
	var node_types_dict = {}
	var node_types_data = data.get("node_types", {})

	for type_id in node_types_data:
		node_types_dict[type_id] = NodeType.from_dict(node_types_data[type_id])

	return node_types_dict

# 获取连接类型配置
func get_connection_types() -> Dictionary:
	var connection_types_dict = {}
	var connection_types_data = data.get("connection_types", {})

	for type_id in connection_types_data:
		connection_types_dict[type_id] = ConnectionType.from_dict(connection_types_data[type_id])

	return connection_types_dict

# 获取战斗配置
func get_battle_configs() -> Dictionary:
	var battle_configs_dict = {}
	var battle_configs_data = data.get("battle_configs", {})

	for config_id in battle_configs_data:
		battle_configs_dict[config_id] = BattleConfig.from_dict(battle_configs_data[config_id])

	return battle_configs_dict

# 获取特定模板配置
func get_template(template_id: String) -> MapTemplate:
	var templates = get_templates()
	if templates.has(template_id):
		return templates[template_id]

	# 如果找不到指定模板，返回默认模板
	if templates.has("standard"):
		return templates["standard"]

	# 如果没有默认模板，返回空模板
	return MapTemplate.new()

# 获取特定节点类型配置
func get_node_type(type_id: String) -> NodeType:
	var node_types = get_node_types()
	if node_types.has(type_id):
		return node_types[type_id]

	# 如果找不到指定类型，返回空节点类型
	return NodeType.new()

# 获取特定连接类型配置
func get_connection_type(type_id: String) -> ConnectionType:
	var connection_types = get_connection_types()
	if connection_types.has(type_id):
		return connection_types[type_id]

	# 如果找不到指定类型，返回默认类型
	if connection_types.has("standard"):
		return connection_types["standard"]

	# 如果没有默认类型，返回空连接类型
	return ConnectionType.new()

# 获取特定战斗配置
func get_battle_config(config_id: String) -> BattleConfig:
	var battle_configs = get_battle_configs()
	if battle_configs.has(config_id):
		return battle_configs[config_id]

	# 如果找不到指定配置，返回默认配置
	if battle_configs.has("normal"):
		return battle_configs["normal"]

	# 如果没有默认配置，返回空战斗配置
	return BattleConfig.new()

# 获取节点类型名称
func get_node_type_name(type_id: String) -> String:
	var node_type = get_node_type(type_id)
	return node_type.name

# 获取节点类型描述
func get_node_type_description(type_id: String) -> String:
	var node_type = get_node_type(type_id)
	return node_type.description

# 获取节点类型图标
func get_node_type_icon(type_id: String) -> String:
	var node_type = get_node_type(type_id)
	return node_type.icon

# 获取节点类型颜色
func get_node_type_color(type_id: String) -> String:
	var node_type = get_node_type(type_id)
	return node_type.color

# 获取节点类型属性
func get_node_type_property(type_id: String, property_name: String, default_value = null):
	var node_type = get_node_type(type_id)
	return node_type.get_property(property_name, default_value)

# 获取节点类型颜色为Color对象
func get_node_type_color_object(type_id: String) -> Color:
	var node_type = get_node_type(type_id)
	return node_type.get_color_object()
