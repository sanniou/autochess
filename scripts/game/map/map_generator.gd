extends Node
class_name MapGenerator
## 地图生成器
## 负责生成杀戮尖塔式的分支树形地图

# 地图生成信号
signal map_generated(map_data)

# 地图配置
var map_templates = {}
var node_types = {}

# 引用
@onready var config_manager = get_node("/root/ConfigManager")

func _ready():
	# 加载地图配置
	_load_map_config()

## 加载地图配置
func _load_map_config() -> void:
	var map_config = config_manager.map_nodes_config
	if map_config:
		map_templates = map_config.map_templates
		node_types = map_config.node_types

## 生成地图
func generate_map(template_id: String = "standard", seed_value: int = -1) -> Dictionary:
	# 设置随机种子
	if seed_value >= 0:
		seed(seed_value)
	else:
		randomize()

	# 获取地图模板
	var template = map_templates[template_id] if map_templates.has(template_id) else map_templates["standard"]
	if not template:
		push_error("无法加载地图模板: " + template_id)
		return {}

	# 创建地图数据
	var map_data = _create_map_data(template)

	# 发送地图生成信号
	map_generated.emit(map_data)

	return map_data

## 创建地图数据
func _create_map_data(template) -> Dictionary:
	var data = {
		"template_id": template.id,
		"layers": template.layers,
		"nodes": [],
		"connections": []
	}

	# 创建节点
	for layer in range(template.layers):
		var nodes_in_layer = []
		var node_count = template.nodes_per_layer[layer]

		for pos in range(node_count):
			var node_type = _get_node_type_for_position(template, layer, pos)
			var node_id = "node_%d_%d" % [layer, pos]

			# 创建节点数据
			var node = {
				"id": node_id,
				"layer": layer,
				"position": pos,
				"type": node_type,
				"visited": false,
				"rewards": _generate_node_rewards(node_type, layer)
			}

			# 添加特定节点类型的额外数据
			match node_type:
				"battle", "elite_battle":
					node["difficulty"] = _calculate_battle_difficulty(layer, node_type == "elite_battle")
					node["enemy_level"] = _calculate_enemy_level(layer)
				"event":
					node["event_id"] = _select_event_for_node(layer)
				"shop":
					node["discount"] = randf() < 0.3  # 30%概率商店有折扣
				"treasure":
					# 宝藏节点已经在rewards中设置了
					pass
				"rest":
					node["heal_amount"] = 20 + layer * 5  # 基础治疗量随层数增加
				"boss":
					node["boss_id"] = _select_boss_for_layer(layer)

			nodes_in_layer.append(node)

		data.nodes.append(nodes_in_layer)

	# 创建连接
	data.connections = _create_map_connections(data.nodes, template)

	return data

## 获取指定位置的节点类型
func _get_node_type_for_position(template, layer: int, pos: int) -> String:
	# 检查是否是固定节点
	if template.has("fixed_nodes"):
		for fixed_node in template.fixed_nodes:
			if fixed_node.layer == layer and fixed_node.position == pos:
				return fixed_node.type

	# 随机选择节点类型
	var node_types = []
	var weights = []

	for type in template.node_distribution.keys():
		node_types.append(type)
		weights.append(template.node_distribution[type])

	return _weighted_choice(node_types, weights)

## 加权随机选择
func _weighted_choice(items: Array, weights: Array) -> Variant:
	var total_weight = 0.0
	for weight in weights:
		total_weight += weight

	var random_value = randf() * total_weight
	var current_weight = 0.0

	for i in range(items.size()):
		current_weight += weights[i]
		if random_value <= current_weight:
			return items[i]

	return items[items.size() - 1]

## 创建地图连接
func _create_map_connections(nodes: Array, template) -> Array:
	var connections = []

	# 遍历每一层，创建到下一层的连接
	for layer in range(template.layers - 1):
		var layer_connections = []
		var current_layer_nodes = nodes[layer]
		var next_layer_nodes = nodes[layer + 1]

		for from_node in current_layer_nodes:
			var connection = {
				"from": from_node.id,
				"to": []
			}

			# 计算可能的连接
			var from_pos = from_node.position
			var from_pos_normalized = float(from_pos) / (current_layer_nodes.size() - 1) if current_layer_nodes.size() > 1 else 0.5

			for to_node in next_layer_nodes:
				var to_pos = to_node.position
				var to_pos_normalized = float(to_pos) / (next_layer_nodes.size() - 1) if next_layer_nodes.size() > 1 else 0.5

				# 计算距离，决定是否连接
				var distance = abs(from_pos_normalized - to_pos_normalized)
				if distance <= 0.3:  # 调整这个值可以改变连接的密度
					connection.to.append(to_node.id)

			# 确保每个节点至少有一个连接
			if connection.to.is_empty() and next_layer_nodes.size() > 0:
				# 找到最近的节点
				var closest_node = next_layer_nodes[0]
				var min_distance = 1.0

				for to_node in next_layer_nodes:
					var to_pos = to_node.position
					var to_pos_normalized = float(to_pos) / (next_layer_nodes.size() - 1) if next_layer_nodes.size() > 1 else 0.5
					var distance = abs(from_pos_normalized - to_pos_normalized)

					if distance < min_distance:
						min_distance = distance
						closest_node = to_node

				connection.to.append(closest_node.id)

			layer_connections.append(connection)

		connections.append(layer_connections)

	return connections

## 生成节点奖励
func _generate_node_rewards(node_type: String, layer: int) -> Dictionary:
	var rewards = {}

	match node_type:
		"battle":
			rewards = {
				"gold": 10 + layer * 2,
				"exp": 2 + layer,
				"equipment_chance": 0.3 + layer * 0.05  # 装备掉落概率随层数增加
			}
		"elite_battle":
			rewards = {
				"gold": 20 + layer * 3,
				"exp": 4 + layer,
				"equipment_chance": 0.6 + layer * 0.05,  # 精英战斗装备掉落概率更高
				"relic_chance": 0.3 + layer * 0.05  # 遗物掉落概率
			}
		"treasure":
			# 宝藏节点必定有奖励
			rewards = {
				"gold": 30 + layer * 5,
				"equipment": {
					"guaranteed": true,
					"quality": min(1 + floor(layer / 2), 3)  # 装备品质随层数提升
				}
			}

			# 50%概率获得遗物
			if randf() < 0.5:
				rewards["relic"] = {
					"guaranteed": true,
					"rarity": min(floor(layer / 3), 2)  # 遗物稀有度随层数提升
				}
		"shop":
			# 商店节点没有直接奖励
			pass
		"event":
			# 事件节点奖励由事件决定
			pass
		"rest":
			# 休息节点提供治疗
			rewards = {
				"heal": 20 + layer * 5
			}
		"boss":
			# Boss节点奖励丰厚
			rewards = {
				"gold": 50 + layer * 10,
				"exp": 10 + layer * 2,
				"equipment": {
					"guaranteed": true,
					"quality": min(2 + floor(layer / 3), 4)  # 高品质装备
				},
				"relic": {
					"guaranteed": true,
					"rarity": min(1 + floor(layer / 3), 3)  # 稀有遗物
				}
			}

	return rewards

## 计算战斗难度
func _calculate_battle_difficulty(layer: int, is_elite: bool) -> float:
	var base_difficulty = 1.0 + layer * 0.1  # 基础难度随层数增加

	if is_elite:
		base_difficulty *= 1.5  # 精英战斗难度提升50%

	# 添加一些随机变化
	var random_factor = randf_range(0.9, 1.1)

	return base_difficulty * random_factor

## 计算敌人等级
func _calculate_enemy_level(layer: int) -> int:
	return 1 + layer  # 敌人等级 = 1 + 层数

## 为节点选择事件
func _select_event_for_node(layer: int) -> String:
	# 这里应该根据层数和其他因素选择合适的事件
	# 暂时返回空字符串，由事件管理器随机选择
	return ""

## 为层选择Boss
func _select_boss_for_layer(layer: int, template = null) -> String:
	# 根据层数选择合适的Boss
	# 这里应该从配置中读取可用的Boss列表
	var boss_list = ["boss_1", "boss_2", "boss_3"]

	if template and layer < template.layers - 1:
		# 中间Boss
		return boss_list[randi() % (boss_list.size() - 1)]
	else:
		# 最终Boss
		return boss_list[boss_list.size() - 1]
