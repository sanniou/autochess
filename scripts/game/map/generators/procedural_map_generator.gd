extends MapGenerator
class_name ProceduralMapGenerator
## 程序化地图生成器
## 根据模板配置生成随机地图

## 生成地图
func generate_map(template_id: String = "standard", seed_value: int = -1) -> MapData:
	# 设置随机种子
	if seed_value >= 0:
		seed(seed_value)
	else:
		randomize()
		seed_value = randi()

	# 获取模板
	var template = map_config.get_template(template_id)
	if not template:
		push_error("无效的地图模板ID: " + template_id)
		return null

	# 创建地图数据
	var map_data = MapData.new()
	map_data.initialize(template_id, seed_value)
	map_data.name = template.name
	map_data.description = template.description
	map_data.difficulty = template.difficulty
	map_data.layers = template.layers

	# 设置地图配置为元数据
	map_data.set_meta("config", map_config)

	# 生成节点
	_generate_nodes(map_data, template)

	# 生成连接
	_generate_connections(map_data, template)

	# 验证地图
	var errors = validate_map(map_data)
	if not errors.is_empty():
		push_error("生成的地图无效: " + str(errors))
		return null

	# 发送生成信号
	map_generated.emit(map_data)

	return map_data

## 生成节点
func _generate_nodes(map_data: MapData, template: MapTemplate) -> void:
	var nodes_per_layer = template.nodes_per_layer
	var node_distribution = template.node_distribution
	var fixed_nodes = template.fixed_nodes

	# 处理固定节点
	var fixed_node_positions = {}
	for fixed_node in fixed_nodes:
		var layer:int = fixed_node.get("layer", 0)
		var position:int = fixed_node.get("position", 0)
		var type = fixed_node.get("type", "")

		if not fixed_node_positions.has(layer):
			fixed_node_positions[layer] = {}

		fixed_node_positions[layer][position] = type

	# 生成每一层的节点
	for layer in range(map_data.layers):
		var nodes_count = nodes_per_layer[layer] if layer < nodes_per_layer.size() else 1

		for position in range(nodes_count):
			var node_id = "node_" + str(layer) + "_" + str(position)
			var node_type = ""

			# 检查是否有固定节点
			if fixed_node_positions.has(layer) and fixed_node_positions[layer].has(position):
				node_type = fixed_node_positions[layer][position]
			else:
				# 随机选择节点类型
				node_type = _select_random_node_type(node_distribution)

			# 创建节点
			var node = MapNode.new()
			node.initialize(node_id, node_type, layer, position)

			# 设置节点属性
			var node_type_config = map_config.get_node_type(node_type)
			for key in node_type_config.properties:
				node.set_property(key, node_type_config.properties[key])

			# 添加到地图
			map_data.add_node(node)

## 生成连接
func _generate_connections(map_data: MapData, template: MapTemplate) -> void:
	var connection_rules = template.connection_rules
	var min_connections = connection_rules.min_connections_per_node
	var _max_connections = connection_rules.max_connections_per_node  # 暂时未使用，但保留以便将来扩展
	var connection_density = connection_rules.connection_density
	var allow_cross_connections = connection_rules.allow_cross_connections

	# 按层处理节点
	for layer in range(map_data.layers - 1):
		var current_layer_nodes = map_data.get_nodes_by_layer(layer)
		var next_layer_nodes = map_data.get_nodes_by_layer(layer + 1)

		# 如果下一层没有节点，跳过
		if next_layer_nodes.is_empty():
			continue

		# 检查下一层是否包含 Boss 节点
		var has_boss_in_next_layer = false
		var boss_node = null
		for node in next_layer_nodes:
			if node.type == "boss":
				has_boss_in_next_layer = true
				boss_node = node
				break

		# 为每个当前层的节点创建连接
		for from_node in current_layer_nodes:
			var target_nodes = []

			# 特殊处理：如果是起点，连接到所有下一层节点
			if from_node.type == "start":
				target_nodes = next_layer_nodes.duplicate()
			# 特殊处理：如果下一层有 Boss，所有节点都连接到 Boss
			elif has_boss_in_next_layer:
				target_nodes = [boss_node]
			else:
				# 简化的连接生成逻辑
				target_nodes = []

				# 1. 找到下一层的最左和最右节点
				var leftmost_next = null
				var rightmost_next = null
				var leftmost_pos = 999
				var rightmost_pos = -1

				for node in next_layer_nodes:
					if node.position < leftmost_pos:
						leftmost_pos = node.position
						leftmost_next = node

					if node.position > rightmost_pos:
						rightmost_pos = node.position
						rightmost_next = node

				# 2. 确保边缘节点连接
				# 如果当前节点是最左侧节点，连接到下一层最左侧节点
				var is_leftmost = true
				var is_rightmost = true

				for node in current_layer_nodes:
					if node != from_node and node.position <= from_node.position:
						is_leftmost = false
					if node != from_node and node.position >= from_node.position:
						is_rightmost = false

				if is_leftmost and leftmost_next:
					target_nodes.append(leftmost_next)

				if is_rightmost and rightmost_next and rightmost_next != leftmost_next:
					target_nodes.append(rightmost_next)

				# 3. 确保所有下一层节点都有连接
				# 找出所有还没有连接的节点
				var unconnected_nodes = []
				for node in next_layer_nodes:
					if node.connections_from.is_empty() and not target_nodes.has(node):
						unconnected_nodes.append(node)

				# 按与当前节点的位置距离排序
				unconnected_nodes.sort_custom(func(a, b):
					return abs(a.position - from_node.position) < abs(b.position - from_node.position)
				)

				# 添加这些节点到目标列表
				for node in unconnected_nodes:
					target_nodes.append(node)

				# 4. 如果连接数量不足，添加随机连接
				if target_nodes.size() < min_connections:
					var remaining_nodes = []
					for node in next_layer_nodes:
						if not target_nodes.has(node):
							remaining_nodes.append(node)

					# 随机打乱剩余节点
					remaining_nodes.shuffle()

					# 添加足够的节点以满足最小连接数要求
					var needed = min_connections - target_nodes.size()
					var to_add = min(needed, remaining_nodes.size())

					for i in range(to_add):
						target_nodes.append(remaining_nodes[i])

			# 创建连接
			for to_node in target_nodes:
				var connection_id = "conn_" + from_node.id + "_" + to_node.id
				var connection = MapConnection.new()
				connection.initialize(connection_id, from_node.id, to_node.id)

				# 设置连接属性
				var connection_type = map_config.get_connection_type("standard")
				for key in connection_type.properties:
					connection.set_property(key, connection_type.properties[key])

				# 添加到地图
				map_data.add_connection(connection)

				# 更新节点的连接信息
				from_node.add_connection_to(to_node.id)
				to_node.add_connection_from(from_node.id)

	# 如果允许跨层连接，添加一些额外的连接
	if allow_cross_connections:
		for layer in range(map_data.layers - 2):
			var current_layer_nodes = map_data.get_nodes_by_layer(layer)

			for from_node in current_layer_nodes:
				# 随机决定是否添加跨层连接
				if randf() < connection_density:
					# 随机选择目标层
					var layer_range = int(map_data.layers - layer - 2)
					var target_layer = layer + 2
					if layer_range > 0:
						target_layer += randi() % layer_range
					var target_layer_nodes = map_data.get_nodes_by_layer(target_layer)

					if not target_layer_nodes.is_empty():
						# 随机选择目标节点
						var to_node = target_layer_nodes[randi() % target_layer_nodes.size()]

						# 创建连接
						var connection_id = "cross_" + from_node.id + "_" + to_node.id
						var connection = MapConnection.new()
						connection.initialize(connection_id, from_node.id, to_node.id)

						# 设置连接属性
						var connection_type = map_config.get_connection_type("standard")
						for key in connection_type.properties:
							connection.set_property(key, connection_type.properties[key])

						# 添加到地图
						map_data.add_connection(connection)

						# 更新节点的连接信息
						from_node.add_connection_to(to_node.id)
						to_node.add_connection_from(from_node.id)

## 随机选择节点类型
func _select_random_node_type(distribution: Dictionary) -> String:
	var total_weight = 0.0
	for type in distribution:
		total_weight += distribution[type]

	var random_value = randf() * total_weight
	var current_weight = 0.0

	for type in distribution:
		current_weight += distribution[type]
		if random_value <= current_weight:
			return type

	# 如果没有选中任何类型，返回默认类型
	return "battle"
