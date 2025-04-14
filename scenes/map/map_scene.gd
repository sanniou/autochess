extends Control
## 地图场景
## 显示杀戮尖塔式的分支路径地图，玩家可以选择不同的路径前进

# 地图节点场景
const MAP_NODE_SCENE = preload("res://scenes/map/map_node.tscn")

# 地图数据
var map_data = {}
# 当前层
var current_layer = 0
# 当前节点
var current_node = null
# 可选节点
var selectable_nodes = []

func _ready():
	# 设置标题
	$Title.text = LocalizationManager.tr("ui.map.title")
	
	# 设置玩家信息
	_update_player_info()
	
	# 生成地图
	_generate_map()
	
	# 播放地图音乐
	AudioManager.play_music("map.ogg")

## 更新玩家信息
func _update_player_info() -> void:
	# 这里应该从玩家管理器获取数据
	# 暂时使用示例数据
	$PlayerInfo/HealthLabel.text = LocalizationManager.tr("ui.player.health", ["100", "100"])
	$PlayerInfo/GoldLabel.text = LocalizationManager.tr("ui.player.gold", ["0"])
	$PlayerInfo/LevelLabel.text = LocalizationManager.tr("ui.player.level", ["1"])

## 生成地图
func _generate_map() -> void:
	# 清除现有地图
	for child in $MapContainer.get_children():
		child.queue_free()
	
	# 获取地图模板
	var map_template = ConfigManager.get_map_templates().standard
	if map_template == null:
		push_error("无法加载地图模板")
		return
	
	# 生成地图数据
	map_data = _create_map_data(map_template)
	
	# 创建地图节点
	_create_map_nodes()
	
	# 设置初始节点
	current_layer = 0
	current_node = map_data.nodes[0][0]
	_update_selectable_nodes()

## 创建地图数据
func _create_map_data(template) -> Dictionary:
	var data = {
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
			var node = {
				"id": "node_%d_%d" % [layer, pos],
				"layer": layer,
				"position": pos,
				"type": node_type,
				"visited": false
			}
			nodes_in_layer.append(node)
		
		data.nodes.append(nodes_in_layer)
	
	# 创建连接
	for layer in range(template.layers - 1):
		var connections_from_layer = []
		var current_layer_nodes = data.nodes[layer]
		var next_layer_nodes = data.nodes[layer + 1]
		
		for from_node in current_layer_nodes:
			var connections_from_node = []
			
			# 计算可能的连接
			var from_pos = from_node.position
			var from_pos_normalized = float(from_pos) / (current_layer_nodes.size() - 1) if current_layer_nodes.size() > 1 else 0.5
			
			for to_node in next_layer_nodes:
				var to_pos = to_node.position
				var to_pos_normalized = float(to_pos) / (next_layer_nodes.size() - 1) if next_layer_nodes.size() > 1 else 0.5
				
				# 计算距离，决定是否连接
				var distance = abs(from_pos_normalized - to_pos_normalized)
				if distance <= 0.3:  # 调整这个值可以改变连接的密度
					connections_from_node.append(to_node.id)
			
			# 确保至少有一个连接
			if connections_from_node.size() == 0 and next_layer_nodes.size() > 0:
				var closest_node = next_layer_nodes[0]
				var closest_distance = 1.0
				
				for to_node in next_layer_nodes:
					var to_pos = to_node.position
					var to_pos_normalized = float(to_pos) / (next_layer_nodes.size() - 1) if next_layer_nodes.size() > 1 else 0.5
					var distance = abs(from_pos_normalized - to_pos_normalized)
					
					if distance < closest_distance:
						closest_distance = distance
						closest_node = to_node
				
				connections_from_node.append(closest_node.id)
			
			connections_from_layer.append({
				"from": from_node.id,
				"to": connections_from_node
			})
		
		data.connections.append(connections_from_layer)
	
	return data

## 获取指定位置的节点类型
func _get_node_type_for_position(template, layer, pos) -> String:
	# 检查是否是固定节点
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
func _weighted_choice(items, weights) -> Variant:
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

## 创建地图节点
func _create_map_nodes() -> void:
	# 计算节点位置
	var map_width = $MapContainer.size.x
	var map_height = $MapContainer.size.y
	var layer_height = map_height / (map_data.layers - 1) if map_data.layers > 1 else map_height
	
	# 创建节点
	for layer in range(map_data.layers):
		var nodes_in_layer = map_data.nodes[layer]
		var layer_width = map_width
		var node_spacing = layer_width / (nodes_in_layer.size() + 1)
		
		for i in range(nodes_in_layer.size()):
			var node_data = nodes_in_layer[i]
			var node_instance = MAP_NODE_SCENE.instantiate()
			$MapContainer.add_child(node_instance)
			
			# 设置节点位置
			var x_pos = (i + 1) * node_spacing
			var y_pos = layer * layer_height
			node_instance.position = Vector2(x_pos, y_pos)
			
			# 设置节点数据
			node_instance.setup(node_data)
			node_instance.node_selected.connect(_on_node_selected)
	
	# 创建连接线
	_create_map_connections()

## 创建地图连接线
func _create_map_connections() -> void:
	# 这里应该创建连接线
	# 暂时不实现
	pass

## 更新可选节点
func _update_selectable_nodes() -> void:
	selectable_nodes.clear()
	
	if current_layer >= map_data.layers - 1:
		return
	
	# 查找当前节点的连接
	for connection in map_data.connections[current_layer]:
		if connection.from == current_node.id:
			for to_node_id in connection.to:
				# 查找目标节点
				for layer_nodes in map_data.nodes:
					for node in layer_nodes:
						if node.id == to_node_id:
							selectable_nodes.append(node)
	
	# 更新节点状态
	for layer_nodes in map_data.nodes:
		for node in layer_nodes:
			var node_instance = _find_node_instance(node.id)
			if node_instance:
				var is_current = (node.id == current_node.id)
				var is_selectable = selectable_nodes.has(node)
				var is_visited = node.visited
				
				node_instance.set_state(is_current, is_selectable, is_visited)

## 查找节点实例
func _find_node_instance(node_id: String) -> Node:
	for child in $MapContainer.get_children():
		if child.has_method("get_node_id") and child.get_node_id() == node_id:
			return child
	
	return null

## 节点选择处理
func _on_node_selected(node_data) -> void:
	# 检查是否是可选节点
	var is_selectable = false
	for node in selectable_nodes:
		if node.id == node_data.id:
			is_selectable = true
			break
	
	if not is_selectable:
		return
	
	# 更新当前节点
	for layer_nodes in map_data.nodes:
		for node in layer_nodes:
			if node.id == node_data.id:
				current_node = node
				current_layer = node.layer
				node.visited = true
				break
	
	# 更新可选节点
	_update_selectable_nodes()
	
	# 触发节点事件
	_trigger_node_event(current_node)

## 触发节点事件
func _trigger_node_event(node_data) -> void:
	# 根据节点类型触发不同事件
	match node_data.type:
		"battle":
			GameManager.change_state(GameManager.GameState.BATTLE)
		"elite_battle":
			GameManager.change_state(GameManager.GameState.BATTLE)
		"shop":
			GameManager.change_state(GameManager.GameState.SHOP)
		"event":
			GameManager.change_state(GameManager.GameState.EVENT)
		"treasure":
			# 处理宝藏节点
			pass
		"rest":
			# 处理休息节点
			pass
		"boss":
			GameManager.change_state(GameManager.GameState.BATTLE)
	
	# 发送节点选择信号
	EventBus.map_node_selected.emit(node_data)
