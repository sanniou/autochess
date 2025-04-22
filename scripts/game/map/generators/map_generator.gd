extends Node
class_name MapGenerator
## 地图生成器基类
## 定义地图生成器的基本接口

# 生成信号
signal map_generated(map_data)

# 配置
var map_config: MapConfig

func _ready() -> void:
	map_config = GameManager.config_manager.get_map_config()

## 生成地图
## 这是一个虚函数，子类需要实现
func generate_map(template_id: String, seed_value: int = -1) -> MapData:
	push_error("MapGenerator.generate_map() 是一个虚函数，子类需要实现")
	return null

## 验证地图
## 检查生成的地图是否有效
func validate_map(map_data: MapData) -> Array:
	var errors = []

	# 检查基本信息
	if map_data.id.is_empty():
		errors.append("地图ID为空")

	if map_data.nodes.is_empty():
		errors.append("地图没有节点")

	if map_data.layers <= 0:
		errors.append("地图层数无效")

	# 检查节点
	var node_ids = {}
	for node in map_data.nodes:
		# 检查节点ID是否唯一
		if node_ids.has(node.id):
			errors.append("重复的节点ID: " + node.id)
		else:
			node_ids[node.id] = true

		# 检查节点类型是否有效
		if not map_config.get_node_type(node.type):
			errors.append("无效的节点类型: " + node.type + " (节点ID: " + node.id + ")")

		# 检查节点层数是否有效
		if node.layer < 0 or node.layer >= map_data.layers:
			errors.append("节点层数超出范围: " + str(node.layer) + " (节点ID: " + node.id + ")")

	# 检查连接
	for connection in map_data.connections:
		# 检查连接的节点是否存在
		if not node_ids.has(connection.from_node_id):
			errors.append("连接的起始节点不存在: " + connection.from_node_id)

		if not node_ids.has(connection.to_node_id):
			errors.append("连接的目标节点不存在: " + connection.to_node_id)

	# 检查可达性
	var start_nodes = map_data.get_nodes_by_type("start")
	if start_nodes.is_empty():
		errors.append("地图没有起始节点")
	else:
		# 检查起点连接规则
		var start_node = start_nodes[0]
		var next_layer_nodes = map_data.get_nodes_by_layer(1)  # 第二层节点
		var connected_next_layer_nodes = []

		for to_id in start_node.connections_to:
			var to_node = map_data.get_node_by_id(to_id)
			if to_node and to_node.layer == 1:
				connected_next_layer_nodes.append(to_node)

		if connected_next_layer_nodes.size() != next_layer_nodes.size():
			errors.append("起始节点应该连接到所有第二层节点")

		# 检查Boss节点连接规则
		var boss_nodes = map_data.get_nodes_by_type("boss")
		if not boss_nodes.is_empty():
			var boss_node = boss_nodes[0]
			var prev_layer = boss_node.layer - 1
			var prev_layer_nodes = map_data.get_nodes_by_layer(prev_layer)
			var connected_prev_nodes = []

			for from_id in boss_node.connections_from:
				var from_node = map_data.get_node_by_id(from_id)
				if from_node and from_node.layer == prev_layer:
					connected_prev_nodes.append(from_node)

			if connected_prev_nodes.size() != prev_layer_nodes.size():
				errors.append("Boss节点应该从所有上一层节点连接")

		# 检查边缘节点连接规则
		for layer_idx in range(map_data.layers - 1):
			var current_layer_nodes_check = map_data.get_nodes_by_layer(layer_idx)
			var next_layer_nodes_check = map_data.get_nodes_by_layer(layer_idx + 1)

			if not current_layer_nodes_check.is_empty() and not next_layer_nodes_check.is_empty():
				# 找到当前层最左和最右节点
				var leftmost_current = null
				var rightmost_current = null
				var leftmost_current_pos = 999
				var rightmost_current_pos = -1

				for node in current_layer_nodes_check:
					if node.position < leftmost_current_pos:
						leftmost_current_pos = node.position
						leftmost_current = node

					if node.position > rightmost_current_pos:
						rightmost_current_pos = node.position
						rightmost_current = node

				# 找到下一层最左和最右节点
				var leftmost_next = null
				var rightmost_next = null
				var leftmost_next_pos = 999
				var rightmost_next_pos = -1

				for node in next_layer_nodes_check:
					if node.position < leftmost_next_pos:
						leftmost_next_pos = node.position
						leftmost_next = node

					if node.position > rightmost_next_pos:
						rightmost_next_pos = node.position
						rightmost_next = node

				# 检查最左侧节点是否连接到下一层最左侧节点
				if leftmost_current and leftmost_next:
					var connected = false
					for to_id in leftmost_current.connections_to:
						if to_id == leftmost_next.id:
							connected = true
							break

					if not connected:
						errors.append("第" + str(layer_idx) + "层最左侧节点应该连接到第" + str(layer_idx + 1) + "层最左侧节点")

				# 检查最右侧节点是否连接到下一层最右侧节点
				if rightmost_current and rightmost_next and rightmost_next != leftmost_next:
					var connected = false
					for to_id in rightmost_current.connections_to:
						if to_id == rightmost_next.id:
							connected = true
							break

					if not connected:
						errors.append("第" + str(layer_idx) + "层最右侧节点应该连接到第" + str(layer_idx + 1) + "层最右侧节点")

		# 检查每一层节点的可达性
		for layer in range(1, map_data.layers):
			var layer_nodes = map_data.get_nodes_by_layer(layer)

			for node in layer_nodes:
				if node.connections_from.is_empty() and node.type != "boss":  # Boss节点已经单独检查
					errors.append("第" + str(layer) + "层节点" + node.id + "没有任何连接")

		# 检查总体可达性
		var reachable_nodes = _get_reachable_nodes(map_data, start_node.id)
		if reachable_nodes.size() != map_data.nodes.size():
			errors.append("地图存在不可达节点")

	return errors

## 获取可达节点
## 使用广度优先搜索算法获取从指定节点可达的所有节点
func _get_reachable_nodes(map_data: MapData, start_node_id: String) -> Array:
	var reachable = {}
	var queue = [start_node_id]
	reachable[start_node_id] = true

	while not queue.is_empty():
		var current_id = queue.pop_front()
		var current_node = map_data.get_node_by_id(current_id)

		for to_id in current_node.connections_to:
			if not reachable.has(to_id):
				reachable[to_id] = true
				queue.append(to_id)

	return reachable.keys()
