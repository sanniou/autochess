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
	map_manager = GameManager.map_manager

	# 连接信号
	map_manager.map_loaded.connect(_on_map_loaded)
	map_manager.node_selected.connect(_on_map_node_selected)
	map_manager.map_completed.connect(_on_map_completed)

	# 设置连接容器的鼠标过滤模式
	$ConnectionsContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 设置玩家信息
	_update_player_info()

	# 初始化地图
	var difficulty = GameManager.difficulty_level
	map_manager.initialize_map("standard", difficulty)

	# 播放地图音乐
	AudioManager.play_music("map.ogg")

## 更新玩家信息
func _update_player_info() -> void:
	# 从玩家管理器获取数据
	var player_manager = GameManager.player_manager
	var player = player_manager.current_player
	$PlayerInfo/HealthLabel.text = LocalizationManager.tr("ui.player.health").format({"current": str(player.current_health), "max": str(player.max_health)})
	$PlayerInfo/GoldLabel.text = LocalizationManager.tr("ui.player.gold").format({"amount": str(player.gold)})
	$PlayerInfo/LevelLabel.text = LocalizationManager.tr("ui.player.level").format({"level": str(player.level)})

## 地图加载处理
func _on_map_loaded(map_data: MapData) -> void:
	# 清除现有地图
	for child in $MapContainer.get_children():
		child.queue_free()

	# 清除节点实例存储
	node_instances.clear()

	# 创建地图节点
	_create_map_nodes(map_data)

	# 创建连接线
	_create_map_connections(map_data)

	# 连接节点悬停信号
	EventBus.map.connect_event("map_node_hovered", _on_map_node_hovered)

	# 节点离开
	EventBus.map_node_unhovered.connect(_on_map_node_unhovered)



## 创建地图节点
func _create_map_nodes(map_data: MapData) -> void:
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
func _create_map_connections(map_data: MapData) -> void:
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

				# 创建连接线容器
				var connection_container = Control.new()
				connection_container.name = "Connection_%s_to_%s" % [from_node_id, to_node_id]
				connection_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
				$ConnectionsContainer.add_child(connection_container)

				# 设置线的起点和终点
				var node_size = Vector2(80, 80)  # 与 map_node.tscn 中的大小一致
				var from_pos = from_node_instance.position + node_size / 2
				var to_pos = to_node_instance.position + node_size / 2

				# 创建背景线（更宽一些）
				var bg_line = Line2D.new()
				bg_line.name = "BackgroundLine"
				bg_line.width = 6.0
				bg_line.default_color = Color(0.2, 0.2, 0.2, 0.3)  # 深灰色半透明
				bg_line.add_point(from_pos)
				bg_line.add_point(to_pos)
				connection_container.add_child(bg_line)

				# 创建主线
				var main_line = Line2D.new()
				main_line.name = "MainLine"
				main_line.width = 3.0
				main_line.default_color = Color(0.7, 0.7, 0.7, 0.7)  # 浅灰色半透明
				main_line.add_point(from_pos)
				main_line.add_point(to_pos)
				connection_container.add_child(main_line)

				# 创建流动线（初始不可见）
				var flow_line = Line2D.new()
				flow_line.name = "FlowLine"
				flow_line.width = 4.0
				flow_line.default_color = Color(1, 1, 0, 0.8)  # 黄色
				flow_line.add_point(from_pos)
				flow_line.add_point(from_pos)  # 初始时两个点重合
				flow_line.visible = false
				connection_container.add_child(flow_line)

				# 存储连接信息
				connection_container.set_meta("from_node", from_node_id)
				connection_container.set_meta("to_node", to_node_id)
				connection_container.set_meta("from_pos", from_pos)
				connection_container.set_meta("to_pos", to_pos)

## 更新节点状态
func _update_node_states() -> void:
	# 获取当前节点和可选节点
	var current_node = map_manager.get_current_node()
	var selectable_nodes = map_manager.get_selectable_nodes()
	var current_map = map_manager.get_current_map()

	if not current_map:
		return

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
		var node = current_map.get_node_by_id(node_id)
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

		# 如果是最后一层的Boss节点，显示从当前节点到Boss的最佳路径
		if node_data.type == "boss" and node_data.layer == map_manager.get_current_map().layers - 1:
			_show_best_path_to_boss()

## 地图节点选择处理
func _on_map_node_selected(node_data: Dictionary) -> void:
	# 处理地图节点选择后的UI更新
	_update_player_info()

	# 显示节点信息提示
	var node_type_name = LocalizationManager.tr("ui.map.node_" + node_data.type)
	GlobalEventBus.ui.dispatch_event(UIEvents.ToastShownEvent.new(LocalizationManager.tr("ui.map.node_selected").format({"type": node_type_name})))

## 地图完成处理
func _on_map_completed() -> void:
	# 地图完成后的处理
	GlobalEventBus.ui.dispatch_event(UIEvents.ToastShownEvent.new(LocalizationManager.tr("ui.map.completed")))
	# 播放完成音效
	AudioManager.play_sfx("victory.ogg")

## 节点悬停处理
func _on_map_node_hovered(node_data: Dictionary) -> void:
	# 获取当前节点
	var current_node = map_manager.get_current_node()
	if not current_node:
		return

	# 获取可选节点
	var selectable_nodes = map_manager.get_selectable_nodes()
	var is_selectable = false

	# 检查悬停的节点是否可选
	for node in selectable_nodes:
		if node.id == node_data.id:
			is_selectable = true
			break

	# 如果不是可选节点，不显示路径
	if not is_selectable:
		return

	# 高亮从当前节点到悬停节点的路径
	_highlight_path(current_node.id, node_data.id)

## 节点离开处理
func _on_map_node_unhovered() -> void:
	# 重置所有路径高亮
	_reset_path_highlights()

	# 更新连接线状态
	_update_connection_states(map_manager.get_current_node())

## 重置路径高亮
func _reset_path_highlights() -> void:
	# 遍历所有连接线容器
	for connection in $ConnectionsContainer.get_children():
		if not connection is Control:
			continue

		# 获取线条引用
		var main_line = connection.get_node("MainLine")
		var flow_line = connection.get_node("FlowLine")

		# 隐藏流动线
		if flow_line:
			flow_line.visible = false

		# 重置主线颜色
		if main_line:
			main_line.default_color = Color(0.7, 0.7, 0.7, 0.7)  # 浅灰色
			main_line.width = 3.0

## 高亮路径
func _highlight_path(from_node_id: String, to_node_id: String) -> void:
	# 首先重置所有连接线的高亮状态
	_reset_path_highlights()

	# 获取两个节点之间的路径
	var path = map_manager.get_path_between_nodes(from_node_id, to_node_id)

	# 如果没有路径，尝试获取最佳路径
	if path.is_empty():
		path = map_manager.get_best_path_to_node(to_node_id)

	# 如果还是没有路径，尝试直接连接
	if path.is_empty():
		# 查找直接连接
		var direct_connection = null
		for connection in $ConnectionsContainer.get_children():
			if not connection is Control:
				continue

			var connection_from = connection.get_meta("from_node")
			var connection_to = connection.get_meta("to_node")

			if connection_from == from_node_id and connection_to == to_node_id:
				direct_connection = connection
				break

		# 如果找到直接连接，高亮它
		if direct_connection:
			_animate_path_connection(direct_connection)
			return

	# 如果有路径，高亮整个路径
	if path.size() >= 2:
		# 高亮路径上的每一段连接
		for i in range(path.size() - 1):
			var from_id = path[i]
			var to_id = path[i + 1]

			# 查找这一段连接
			for connection in $ConnectionsContainer.get_children():
				if not connection is Control:
					continue

				var connection_from = connection.get_meta("from_node")
				var connection_to = connection.get_meta("to_node")

				if connection_from == from_id and connection_to == to_id:
					# 高亮这一段连接
					_animate_path_connection(connection)
					break

## 动画路径连接
func _animate_path_connection(connection, is_boss_path: bool = false) -> void:
	# 获取线条引用
	var main_line = connection.get_node("MainLine")
	var flow_line = connection.get_node("FlowLine")

	# 设置主线颜色
	if is_boss_path:
		# Boss路径使用红色
		main_line.default_color = Color(0.9, 0.2, 0.2, 0.8)  # 红色
		flow_line.default_color = Color(1.0, 0.3, 0.3, 0.8)  # 亮红色
	else:
		# 普通路径使用绿色
		main_line.default_color = Color(0.2, 0.8, 0.2, 0.8)  # 绿色
		flow_line.default_color = Color(0.2, 1.0, 0.2, 0.8)  # 亮绿色

	main_line.width = 5.0

	# 显示流动线
	flow_line.visible = true

	# 获取起点和终点
	var from_pos = connection.get_meta("from_pos")
	var to_pos = connection.get_meta("to_pos")

	# 重置流动线
	flow_line.clear_points()
	flow_line.add_point(from_pos)
	flow_line.add_point(from_pos)

	# 创建流动动画
	var flow_tween = create_tween().set_loops()

	# 从起点到终点的流动
	flow_tween.tween_method(func(progress: float):
		var current_pos = from_pos.lerp(to_pos, progress)
		flow_line.set_point_position(1, current_pos)
	, 0.0, 1.0, 0.8)

	# 消失效果
	flow_tween.tween_property(flow_line, "modulate:a", 0.3, 0.2)

	# 重置
	flow_tween.tween_callback(func():
		flow_line.modulate.a = 1.0
		flow_line.clear_points()
		flow_line.add_point(from_pos)
		flow_line.add_point(from_pos)
	)

## 显示到Boss的最佳路径
func _show_best_path_to_boss() -> void:
	# 首先重置所有路径高亮
	_reset_path_highlights()

	# 获取当前节点
	var current_node = map_manager.get_current_node()
	if not current_node:
		return

	# 查找Boss节点
	var boss_node = null
	var current_map = map_manager.get_current_map()
	if not current_map:
		return

	# 获取Boss节点
	var boss_nodes = current_map.get_nodes_by_type("boss")
	if not boss_nodes.is_empty():
		boss_node = boss_nodes[0]

	if not boss_node:
		return

	# 获取到Boss的最佳路径
	var path = map_manager.get_best_path_to_node(boss_node.id)

	# 如果有路径，高亮整个路径
	if path.size() >= 2:
		# 高亮路径上的每一段连接
		for i in range(path.size() - 1):
			var from_id = path[i]
			var to_id = path[i + 1]

			# 查找这一段连接
			for connection in $ConnectionsContainer.get_children():
				if not connection is Control:
					continue

				var connection_from = connection.get_meta("from_node")
				var connection_to = connection.get_meta("to_node")

				if connection_from == from_id and connection_to == to_id:
					# 高亮这一段连接（使用Boss路径颜色）
					_animate_path_connection(connection, true)
					break

		# 显示提示
		GlobalEventBus.ui.dispatch_event(UIEvents.ToastShownEvent.new("已显示到Boss的最佳路径", 2.0))

## 更新连接线状态
func _update_connection_states(current_node) -> void:
	# 遍历所有连接线容器
	for connection in $ConnectionsContainer.get_children():
		if not connection is Control:
			continue

		var from_node_id = connection.get_meta("from_node")
		var to_node_id = connection.get_meta("to_node")

		# 获取节点
		var current_map = map_manager.get_current_map()
		if not current_map:
			continue

		var from_node = current_map.get_node_by_id(from_node_id)
		var to_node = current_map.get_node_by_id(to_node_id)

		if from_node == null or to_node == null:
			continue

		# 获取线条引用
		var bg_line = connection.get_node("BackgroundLine")
		var main_line = connection.get_node("MainLine")
		var flow_line = connection.get_node("FlowLine")

		# 设置连接线状态
		if current_node and from_node_id == current_node.id and to_node.is_accessible(current_node.layer, current_node.id):
			# 当前节点到可选节点的连接
			main_line.default_color = Color(1, 1, 0, 0.8)  # 黄色
			main_line.width = 4.0

			# 显示流动线并创建动画
			flow_line.visible = true

			# 获取起点和终点
			var from_pos = connection.get_meta("from_pos")
			var to_pos = connection.get_meta("to_pos")

			# 如果没有活动的动画，创建新的流动动画
			if not connection.has_meta("flow_active") or not connection.get_meta("flow_active"):
				connection.set_meta("flow_active", true)

				# 重置流动线
				flow_line.clear_points()
				flow_line.add_point(from_pos)
				flow_line.add_point(from_pos)

				# 创建流动动画
				var flow_tween = create_tween().set_loops()

				# 第一步：从起点到终点的流动
				flow_tween.tween_method(func(progress: float):
					var current_pos = from_pos.lerp(to_pos, progress)
					flow_line.set_point_position(1, current_pos)
				, 0.0, 1.0, 1.0)

				# 第二步：消失效果
				flow_tween.tween_property(flow_line, "modulate:a", 0.0, 0.3)

				# 第三步：重置并准备下一次动画
				flow_tween.tween_callback(func():
					flow_line.modulate.a = 1.0
					flow_line.clear_points()
					flow_line.add_point(from_pos)
					flow_line.add_point(from_pos)
				)

				# 添加闪烁效果
				var pulse_tween = create_tween().set_loops()
				pulse_tween.tween_property(main_line, "default_color", Color(1, 1, 0, 1), 0.5)
				pulse_tween.tween_property(main_line, "default_color", Color(1, 1, 0, 0.5), 0.5)

				# 设置回调以在动画结束时重置状态
				flow_tween.finished.connect(func(): connection.set_meta("flow_active", false))
		elif from_node.visited and to_node.visited:
			# 已访问节点之间的连接
			main_line.default_color = Color(0.5, 0.5, 0.5, 0.8)  # 灰色
			main_line.width = 3.0
			bg_line.default_color = Color(0.3, 0.3, 0.3, 0.4)  # 稍深一点的灰色
			flow_line.visible = false
		elif from_node.visited:
			# 已访问节点到未访问节点的连接
			main_line.default_color = Color(0.7, 0.7, 0.7, 0.5)  # 浅灰色
			main_line.width = 2.0
			flow_line.visible = false
		else:
			# 未访问节点之间的连接
			main_line.default_color = Color(0.3, 0.3, 0.3, 0.3)  # 深灰色半透明
			main_line.width = 1.0
			flow_line.visible = false