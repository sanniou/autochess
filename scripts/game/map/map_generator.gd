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
	var map_nodes = config_manager.get_all_map_nodes()
	if map_nodes:
		# 处理地图模板
		map_templates = {}
		for node_id in map_nodes:
			var node_model = map_nodes[node_id] as MapNodeConfig
			if node_model.get_node_type() == "template":
				map_templates[node_id] = node_model.get_data()

		# 处理节点类型
		node_types = {}
		for node_id in map_nodes:
			var node_model = map_nodes[node_id] as MapNodeConfig
			if node_model.get_node_type() != "template":
				node_types[node_id] = node_model.get_data()

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
		"connections": [],
		"difficulty": GameManager.get_current_difficulty(),
		"special_nodes": {},
		"generation_seed": randi(), # 记录生成种子
		"generation_time": Time.get_unix_time_from_system() # 记录生成时间
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
				"mystery":
					# 神秘节点不需要额外数据
					pass
				"challenge":
					node["difficulty"] = _calculate_battle_difficulty(layer, true) * 1.2  # 挑战难度更高
					node["enemy_level"] = _calculate_enemy_level(layer) + 1  # 挑战敌人等级更高
					node["challenge_type"] = _select_challenge_type()
				"altar":
					node["altar_type"] = _select_altar_type()
				"blacksmith":
					node["discount"] = randf() < 0.3  # 30%概率铁匠铺有折扣

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

	# 第一层固定为起始节点
	if layer == 0:
		return "start"

	# 最后一层固定为Boss节点
	if layer == template.layers - 1:
		return "boss"

	# 特殊层处理
	if layer == template.layers - 2:
		# Boss前一层必定有一个休息节点
		if pos == 0 or (template.nodes_per_layer[layer] > 1 and pos == template.nodes_per_layer[layer] - 1):
			return "rest"

	# 精英战斗分布
	if layer > 1 and layer < template.layers - 1:
		# 每两层至少有一个精英战斗
		if layer % 2 == 0 and pos == template.nodes_per_layer[layer] / 2:
			return "elite_battle"

	# 商店分布
	if layer > 0 and layer < template.layers - 1:
		# 每三层至少有一个商店
		if layer % 3 == 1 and pos == template.nodes_per_layer[layer] - 1:
			return "shop"

	# 宝藏分布
	if layer > 1 and layer < template.layers - 2:
		# 每四层至少有一个宝藏
		if layer % 4 == 2 and pos == 0:
			return "treasure"

	# 随机选择节点类型
	var node_types = []
	var weights = []

	# 根据难度调整权重
	var difficulty_factor = 1.0
	if template.has("difficulty"):
		if template.difficulty == "easy":
			difficulty_factor = 0.8  # 简单难度减少战斗节点
		elif template.difficulty == "hard":
			difficulty_factor = 1.2  # 困难难度增加战斗节点
		elif template.difficulty == "expert":
			difficulty_factor = 1.5  # 专家难度显著增加战斗节点

	for type in template.node_distribution.keys():
		node_types.append(type)

		var weight = template.node_distribution[type]

		# 根据难度调整战斗节点权重
		if type == "battle":
			weight *= difficulty_factor
		elif type == "elite_battle":
			weight *= difficulty_factor
		elif type == "rest" and difficulty_factor > 1.0:
			weight /= difficulty_factor  # 高难度减少休息节点

		weights.append(weight)

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

		# 计算连接密度
		var connection_density = 0.3  # 默认连接密度

		# 根据层数调整连接密度
		if layer == 0 or layer == template.layers - 2:
			# 第一层和最后一层前的连接密度更高
			connection_density = 0.5
		elif layer > template.layers / 2:
			# 后半部分地图连接密度逐渐增加
			connection_density = 0.3 + (layer - template.layers / 2) * 0.05

		# 根据难度调整连接密度
		if template.has("difficulty"):
			if template.difficulty == "easy":
				# 简单难度增加连接密度，提供更多选择
				connection_density += 0.1
			elif template.difficulty == "hard" or template.difficulty == "expert":
				# 困难难度减少连接密度，减少选择
				connection_density -= 0.05

		# 添加随机性变化
		var random_variation = randf_range(-0.05, 0.05)
		connection_density += random_variation

		# 确保连接密度在合理范围内
		connection_density = clamp(connection_density, 0.2, 0.7)

		# 确保每个节点至少有一个连接
		var min_connections_per_node = 1

		# 对于简单难度，增加最小连接数
		if template.has("difficulty") and template.difficulty == "easy":
			min_connections_per_node = 2

		# 初始化下一层节点的连接计数
		var node_connections_count = {}
		for node in next_layer_nodes:
			node_connections_count[node.id] = 0

		for from_node in current_layer_nodes:
			var connection = {
				"from": from_node.id,
				"to": []
			}

			# 计算可能的连接
			var from_pos = from_node.position
			var from_pos_normalized = float(from_pos) / (current_layer_nodes.size() - 1) if current_layer_nodes.size() > 1 else 0.5

			# 特殊节点类型处理
			var is_special_node = from_node.type in ["elite_battle", "shop", "treasure", "rest"]
			var special_connection_bonus = 0.1 if is_special_node else 0.0

			for to_node in next_layer_nodes:
				var to_pos = to_node.position
				var to_pos_normalized = float(to_pos) / (next_layer_nodes.size() - 1) if next_layer_nodes.size() > 1 else 0.5

				# 计算距离，决定是否连接
				var distance = abs(from_pos_normalized - to_pos_normalized)

				# 特殊节点有更高的连接概率
				var current_density = connection_density + special_connection_bonus

				# 添加随机性
				var random_factor = randf_range(-0.05, 0.05)
				current_density += random_factor

				if distance <= current_density:
					connection.to.append(to_node.id)
					# 更新节点连接计数
					node_connections_count[to_node.id] += 1

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

			# 限制连接数量，避免过多连接
			if connection.to.size() > 3:
				# 随机保留三个连接
				connection.to.shuffle()
				while connection.to.size() > 3:
					connection.to.pop_back()

			layer_connections.append(connection)

		# 确保下一层的每个节点都有足够的连接
		for node_id in node_connections_count.keys():
			if node_connections_count[node_id] < min_connections_per_node:
				# 找到最近的节点来添加连接
				var to_node = null
				for n in next_layer_nodes:
					if n.id == node_id:
						to_node = n
						break

				if to_node:
					var to_pos = to_node.position
					var to_pos_normalized = float(to_pos) / (next_layer_nodes.size() - 1) if next_layer_nodes.size() > 1 else 0.5

					# 找到最近的上层节点
					var closest_from_node = null
					var min_distance = 1.0

					for from_node in current_layer_nodes:
						var from_pos = from_node.position
						var from_pos_normalized = float(from_pos) / (current_layer_nodes.size() - 1) if current_layer_nodes.size() > 1 else 0.5
						var distance = abs(from_pos_normalized - to_pos_normalized)

						if distance < min_distance:
							min_distance = distance
							closest_from_node = from_node

					# 添加连接
					if closest_from_node:
						for connection in layer_connections:
							if connection.from == closest_from_node.id and not connection.to.has(to_node.id):
								connection.to.append(to_node.id)
								node_connections_count[to_node.id] += 1
								break

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
		"mystery":
			# 神秘节点的奖励在触发时决定
			pass
		"challenge":
			# 挑战节点奖励更丰厚
			rewards = {
				"gold": 25 + layer * 4,
				"exp": 5 + layer * 1.5,
				"equipment": {
					"guaranteed": true,
					"quality": min(1 + floor(layer / 2), 3)  # 装备品质随层数提升
				},
				"relic_chance": 0.4 + layer * 0.05  # 遗物掉落概率更高
			}
		"altar":
			# 祭坛节点没有直接奖励，需要献祭才能获得效果
			pass
		"blacksmith":
			# 铁匠铺节点没有直接奖励，需要支付才能获得服务
			pass

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

## 选择挑战类型
func _select_challenge_type() -> String:
	# 这里应该返回不同类型的挑战
	var challenge_types = ["time_limit", "no_abilities", "limited_mana", "elite_enemies", "restricted_movement"]
	return challenge_types[randi() % challenge_types.size()]

## 选择祭坛类型
func _select_altar_type() -> String:
	# 这里应该返回不同类型的祭坛
	var altar_types = ["health", "attack", "defense", "ability", "gold"]
	return altar_types[randi() % altar_types.size()]
