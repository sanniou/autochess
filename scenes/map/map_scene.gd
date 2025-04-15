extends Control
## 地图场景
## 显示杀戮尖塔式的分支路径地图，玩家可以选择不同的路径前进

# 地图节点场景
const MAP_NODE_SCENE = preload("res://scenes/map/map_node.tscn")

# 地图管理器
var map_manager: MapManager

# 节点实例存储
var node_instances = {}

func _ready():
	# 设置标题
	$Title.text = LocalizationManager.tr("ui.map.title")

	# 创建地图管理器
	map_manager = get_node("/root/GameManager").map_manager
	if not map_manager:
		map_manager = MapManager.new()
		add_child(map_manager)

	# 连接信号
	map_manager.map_initialized.connect(_on_map_initialized)
	map_manager.node_selected.connect(_on_map_node_selected)
	map_manager.map_completed.connect(_on_map_completed)

	# 设置连接容器的鼠标过滤模式
	$ConnectionsContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 设置玩家信息
	_update_player_info()

	# 初始化地图
	var difficulty = get_node("/root/GameManager").difficulty_level
	map_manager.initialize_map("standard", difficulty)

	# 播放地图音乐
	AudioManager.play_music("map.ogg")

## 更新玩家信息
func _update_player_info() -> void:
	# 从玩家管理器获取数据
	var player_manager = get_node("/root/GameManager/PlayerManager")
	if player_manager and player_manager.current_player:
		var player = player_manager.current_player
		$PlayerInfo/HealthLabel.text = LocalizationManager.tr("ui.player.health", [str(player.current_health), str(player.max_health)])
		$PlayerInfo/GoldLabel.text = LocalizationManager.tr("ui.player.gold", [str(player.gold)])
		$PlayerInfo/LevelLabel.text = LocalizationManager.tr("ui.player.level", [str(player.level)])
	else:
		# 没有玩家数据时使用默认值
		$PlayerInfo/HealthLabel.text = LocalizationManager.tr("ui.player.health", ["100", "100"])
		$PlayerInfo/GoldLabel.text = LocalizationManager.tr("ui.player.gold", ["0"])
		$PlayerInfo/LevelLabel.text = LocalizationManager.tr("ui.player.level", ["1"])

## 地图初始化处理
func _on_map_initialized(map_data: Dictionary) -> void:
	# 清除现有地图
	for child in $MapContainer.get_children():
		child.queue_free()

	# 清除节点实例存储
	node_instances.clear()

	# 创建地图节点
	_create_map_nodes(map_data)

	# 创建连接线
	_create_map_connections(map_data)



## 创建地图节点
func _create_map_nodes(map_data: Dictionary) -> void:
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

			# 存储节点实例
			node_instances[node_data.id] = node_instance

	# 更新节点状态
	_update_node_states()

## 创建地图连接线
func _create_map_connections(map_data: Dictionary) -> void:
	# 清除现有连接线
	for child in $ConnectionsContainer.get_children():
		child.queue_free()

	# 遍历所有连接
	for layer_idx in range(map_data.connections.size()):
		var layer_connections = map_data.connections[layer_idx]

		for connection in layer_connections:
			var from_node_id = connection.from
			var from_node_instance = node_instances.get(from_node_id)

			if from_node_instance == null:
				continue

			for to_node_id in connection.to:
				var to_node_instance = node_instances.get(to_node_id)

				if to_node_instance == null:
					continue

				# 创建连接线
				var line = Line2D.new()
				line.width = 2.0
				line.default_color = Color(0.7, 0.7, 0.7, 0.7)  # 浅灰色半透明

				# 设置线的起点和终点
				# 使用固定的节点大小计算中心点
				var node_size = Vector2(80, 80)  # 与 map_node.tscn 中的大小一致
				var from_pos = from_node_instance.position + node_size / 2
				var to_pos = to_node_instance.position + node_size / 2

				line.add_point(from_pos)
				line.add_point(to_pos)

				# 添加到连接容器
				$ConnectionsContainer.add_child(line)

				# 存储连接信息
				line.set_meta("from_node", from_node_id)
				line.set_meta("to_node", to_node_id)

## 更新节点状态
func _update_node_states() -> void:
	# 获取当前节点和可选节点
	var current_node = map_manager.get_current_node()
	var selectable_nodes = map_manager.get_selectable_nodes()

	# 更新所有节点状态
	for node_id in node_instances.keys():
		var node_instance = node_instances[node_id]
		var is_current = (current_node and node_id == current_node.id)
		var is_selectable = false

		# 检查是否是可选节点
		for selectable_node in selectable_nodes:
			if node_id == selectable_node.id:
				is_selectable = true
				break

		# 检查是否已访问
		var is_visited = false
		var node = map_manager.get_all_nodes().get(node_id)
		if node:
			is_visited = node.visited

		# 设置节点状态
		node_instance.set_state(is_current, is_selectable, is_visited)

	# 更新连接线状态
	_update_connection_states(current_node)

## 节点选择处理
func _on_node_selected(node_data) -> void:
	# 使用地图管理器选择节点
	var success = map_manager.select_node(node_data.id)

	# 如果选择成功，更新节点状态
	if success:
		_update_node_states()

## 地图节点选择处理
func _on_map_node_selected(node_data: Dictionary) -> void:
	# 处理地图节点选择后的UI更新
	_update_player_info()

	# 显示节点信息提示
	var node_type_name = LocalizationManager.tr("ui.map.node_" + node_data.type)
	EventBus.show_toast.emit(LocalizationManager.tr("ui.map.node_selected", [node_type_name]))

## 地图完成处理
func _on_map_completed() -> void:
	# 地图完成后的处理
	EventBus.show_toast.emit(LocalizationManager.tr("ui.map.completed"))
	# 播放完成音效
	AudioManager.play_sfx("victory.ogg")

## 更新连接线状态
func _update_connection_states(current_node) -> void:
	# 遍历所有连接线
	for line in $ConnectionsContainer.get_children():
		if not line is Line2D:
			continue

		var from_node_id = line.get_meta("from_node")
		var to_node_id = line.get_meta("to_node")

		# 获取节点
		var from_node = map_manager.get_all_nodes().get(from_node_id)
		var to_node = map_manager.get_all_nodes().get(to_node_id)

		if from_node == null or to_node == null:
			continue

		# 设置连接线颜色
		if current_node and from_node_id == current_node.id and to_node.is_accessible(current_node.layer, current_node.id):
			# 当前节点到可选节点的连接
			line.default_color = Color(1, 1, 0, 0.8)  # 黄色
			line.width = 4.0

			# 添加闪烁效果
			if not line.has_meta("tween_active"):
				line.set_meta("tween_active", true)
				var tween = create_tween().set_loops()
				tween.tween_property(line, "default_color", Color(1, 1, 0, 1), 0.5)
				tween.tween_property(line, "default_color", Color(1, 1, 0, 0.5), 0.5)
				tween.finished.connect(func(): line.set_meta("tween_active", false))
		elif from_node.visited and to_node.visited:
			# 已访问节点之间的连接
			line.default_color = Color(0.5, 0.5, 0.5, 0.8)  # 灰色
			line.width = 3.0
		elif from_node.visited:
			# 已访问节点到未访问节点的连接
			line.default_color = Color(0.7, 0.7, 0.7, 0.5)  # 浅灰色
			line.width = 2.0
		else:
			# 未访问节点之间的连接
			line.default_color = Color(0.3, 0.3, 0.3, 0.3)  # 深灰色半透明
			line.width = 1.0