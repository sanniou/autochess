extends MapRenderer
class_name MapRenderer2D
## 2D地图渲染器
## 在2D空间中渲染地图

# MapConfig类已经是全局类，不需要再次导入

# 渲染设置
@export var node_size: Vector2 = Vector2(80, 80)
@export var layer_height: float = 150.0
@export var horizontal_spacing: float = 120.0

## 渲染地图
func render_map() -> void:
	if not map_data or not container or not node_scene or not connection_scene:
		push_error("无法渲染地图：缺少必要的组件")
		return

	# 清除现有地图
	clear_map()

	# 计算地图尺寸
	var map_width = 0
	var map_height = map_data.layers * layer_height

	for layer in range(map_data.layers):
		var layer_nodes = map_data.get_nodes_by_layer(layer)
		map_width = max(map_width, layer_nodes.size() * horizontal_spacing)

	# 设置容器大小
	container.custom_minimum_size = Vector2(map_width, map_height)

	# 渲染连接
	for connection in map_data.connections:
		_render_connection(connection)

	# 渲染节点
	for node in map_data.nodes:
		_render_node(node)

	# 更新可到达节点
	_update_reachable_nodes()

## 渲染节点
func _render_node(node: MapNode) -> void:
	if not node_scene:
		return

	# 实例化节点场景
	var node_instance = node_scene.instantiate()
	container.add_child(node_instance)

	# 设置节点数据
	# 使用MapConfig获取节点类型配置
	var config = {}
	if map_data and map_data.has_meta("config"):
		var map_config = map_data.get_meta("config")
		if map_config and map_config is MapConfig:
			config = map_config.get_node_type(node.type)

	node_instance.setup(node, config)

	# 设置节点位置
	var layer_nodes = map_data.get_nodes_by_layer(node.layer)
	var layer_width = layer_nodes.size() * horizontal_spacing
	var x_offset = (container.size.x - layer_width) / 2 + horizontal_spacing / 2
	var x_pos = x_offset + node.position * horizontal_spacing
	var y_pos = node.layer * layer_height + layer_height / 2

	node_instance.position = Vector2(x_pos, y_pos) - node_size / 2

	# 连接信号
	node_instance.node_clicked.connect(_on_node_clicked.bind(node.id))
	node_instance.node_hovered.connect(_on_node_hovered.bind(node.id))
	node_instance.node_unhovered.connect(_on_node_unhovered.bind(node.id))

	# 保存节点实例
	node_instances[node.id] = node_instance

	# 设置节点状态
	if node == selected_node:
		node_instance.set_selected(true)

	if node == current_player_node:
		node_instance.set_current(true)

## 渲染连接
func _render_connection(connection: MapConnection) -> void:
	if not connection_scene:
		return

	# 获取连接的节点
	var from_node = map_data.get_node_by_id(connection.from_node_id)
	var to_node = map_data.get_node_by_id(connection.to_node_id)

	if not from_node or not to_node:
		return

	# 实例化连接场景
	var connection_instance = connection_scene.instantiate()
	container.add_child(connection_instance)

	# 设置连接数据
	var connection_type = "standard"
	if connection.has_property("type"):
		connection_type = connection.get_property("type")

	# 使用MapConfig获取连接类型配置
	var config = {}
	if map_data and map_data.has_meta("config"):
		var map_config = map_data.get_meta("config")
		if map_config and map_config is MapConfig:
			config = map_config.get_connection_type(connection_type)

	connection_instance.setup(connection, config)

	# 计算连接的起点和终点
	var from_layer_nodes = map_data.get_nodes_by_layer(from_node.layer)
	var to_layer_nodes = map_data.get_nodes_by_layer(to_node.layer)

	var from_layer_width = from_layer_nodes.size() * horizontal_spacing
	var to_layer_width = to_layer_nodes.size() * horizontal_spacing

	var from_x_offset = (container.size.x - from_layer_width) / 2 + horizontal_spacing / 2
	var to_x_offset = (container.size.x - to_layer_width) / 2 + horizontal_spacing / 2

	var from_x = from_x_offset + from_node.position * horizontal_spacing
	var from_y = from_node.layer * layer_height + layer_height / 2

	var to_x = to_x_offset + to_node.position * horizontal_spacing
	var to_y = to_node.layer * layer_height + layer_height / 2

	# 设置连接的起点和终点
	connection_instance.set_points(Vector2(from_x, from_y), Vector2(to_x, to_y))

	# 保存连接实例
	connection_instances[connection.id] = connection_instance

## 高亮路径
## 高亮显示路径上的所有连接
func highlight_path(path: Array) -> void:
	if path.size() < 2:
		return

	# 清除现有高亮
	clear_path_highlights()

	# 高亮路径上的每一段连接
	for i in range(path.size() - 1):
		var from_id = path[i]
		var to_id = path[i + 1]

		# 查找连接
		for connection_id in connection_instances:
			var connection = connection_instances[connection_id]
			var connection_data = map_data.get_connection_by_id(connection_id)

			if connection_data.from_node_id == from_id and connection_data.to_node_id == to_id:
				# 高亮连接
				if connection.has_method("highlight"):
					connection.highlight(true)
				break

## 清除路径高亮
## 清除所有高亮的路径
func clear_path_highlights() -> void:
	# 重置所有连接的高亮状态
	for connection_id in connection_instances:
		var connection = connection_instances[connection_id]
		if connection.has_method("highlight"):
			connection.highlight(false)
