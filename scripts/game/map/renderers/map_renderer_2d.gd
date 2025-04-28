extends MapRenderer
class_name MapRenderer2D
## 2D地图渲染器
## 在2D空间中渲染地图，支持缩放、平移和主题

# 渲染设置
@export var node_size: Vector2 = Vector2(80, 80)
@export var layer_height: float = 150.0
@export var horizontal_spacing: float = 120.0

# 缩放设置
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var zoom_step: float = 0.1
@export var initial_zoom: float = 1.0

# 相机引用
var camera: Camera2D

# 主题管理器
var theme_manager: MapThemeManager

# 缓存
var _node_positions: Dictionary = {}
var _connection_points: Dictionary = {}
var _path_cache: Dictionary = {}

# 动画设置
var use_animations: bool = true
var animation_speed: float = 1.0

# 背景网格
var grid_background: GridBackground

# 拖动状态
var _is_dragging: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_start_camera_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	# 设置容器
	if not container:
		container = $Container
		print("MapRenderer2D: 使用内部容器")

	# 获取相机引用
	camera = $MapCamera
	if not camera:
		push_error("MapRenderer2D: 缺少相机组件")
	else:
		# 设置初始缩放
		camera.zoom = Vector2(initial_zoom, initial_zoom)

	# 检查必要的组件
	if not node_scene:
		push_error("MapRenderer2D: 缺少节点场景")

	if not connection_scene:
		push_error("MapRenderer2D: 缺少连接场景")

	# 初始化主题管理器
	theme_manager = MapThemeManager.new()
	add_child(theme_manager)

	# 连接主题变更信号
	theme_manager.theme_changed.connect(_on_theme_changed)

	# 获取网格背景引用
	grid_background = $GridBackground
	if grid_background and camera:
		grid_background.set_camera(camera)

	# 连接缩放控制按钮
	$ZoomControls/ZoomIn.pressed.connect(_on_zoom_in_pressed)
	$ZoomControls/ZoomOut.pressed.connect(_on_zoom_out_pressed)
	$ZoomControls/ZoomReset.pressed.connect(_on_zoom_reset_pressed)

	# 连接全局事件总线
	GlobalEventBus.ui.add_class_listener(ThemeEvents.MapThemeChangedEvent, _on_map_theme_changed)

	# 连接输入事件
	set_process_input(true)

	print("MapRenderer2D 初始化完成")

## 处理输入事件
func _input(event: InputEvent) -> void:
	# 处理鼠标滚轮缩放
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_in()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_out()
			get_viewport().set_input_as_handled()
		# 处理鼠标拖动
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				_start_drag(event.position)
			else:
				_end_drag()

	# 处理鼠标移动
	if event is InputEventMouseMotion and _is_dragging and camera:
		_update_drag(event.position)

## 开始拖动
func _start_drag(position: Vector2) -> void:
	_is_dragging = true
	_drag_start_pos = position
	if camera:
		_drag_start_camera_pos = camera.position

## 更新拖动
func _update_drag(position: Vector2) -> void:
	if not _is_dragging or not camera:
		return

	var delta = (_drag_start_pos - position) / camera.zoom
	camera.position = _drag_start_camera_pos + delta

## 结束拖动
func _end_drag() -> void:
	_is_dragging = false

## 渲染地图
func render_map() -> void:
	if not map_data or not container or not node_scene or not connection_scene:
		push_error("无法渲染地图：缺少必要的组件")
		return

	# 清除现有地图
	clear_map()

	# 清除缓存
	_node_positions.clear()
	_connection_points.clear()
	_path_cache.clear()

	# 计算地图尺寸
	var map_width = 0
	var map_height = map_data.layers * layer_height

	for layer in range(map_data.layers):
		var layer_nodes = map_data.get_nodes_by_layer(layer)
		map_width = max(map_width, layer_nodes.size() * horizontal_spacing)

	# 设置容器大小
	container.custom_minimum_size = Vector2(map_width, map_height)

	# 更新相机限制
	_update_camera_limits()

	# 应用主题
	_apply_current_theme()

	# 先渲染连接，确保它们在节点下方
	print("渲染连接，总数: ", map_data.connections.size())
	for connection in map_data.connections:
		_render_connection(connection)

	# 然后渲染节点
	print("渲染节点，总数: ", map_data.nodes.size())
	for node in map_data.nodes:
		_render_node(node)

	# 更新可到达节点
	_update_reachable_nodes()

	# 重置相机位置
	if camera:
		camera.position = Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)

	print("地图渲染完成，节点: ", node_instances.size(), ", 连接: ", connection_instances.size())

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

	# 计算节点位置
	var position = _calculate_node_position(node)

	# 缓存节点位置
	_node_positions[node.id] = position

	# 设置节点位置
	node_instance.position = position - node_size / 2

	# 如果启用动画，添加出现动画
	if use_animations:
		node_instance.modulate.a = 0
		node_instance.scale = Vector2(0.8, 0.8)
		var tween = create_tween()
		tween.tween_property(node_instance, "modulate:a", 1.0, 0.3 * animation_speed)
		tween.parallel().tween_property(node_instance, "scale", Vector2(1, 1), 0.3 * animation_speed)

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

## 计算节点位置
## 根据节点的层级和位置计算其在地图上的坐标
func _calculate_node_position(node: MapNode) -> Vector2:
	# 检查缓存
	if _node_positions.has(node.id):
		return _node_positions[node.id]

	# 计算位置
	var layer_nodes = map_data.get_nodes_by_layer(node.layer)
	var layer_width = layer_nodes.size() * horizontal_spacing
	var x_offset = (container.size.x - layer_width) / 2 + horizontal_spacing / 2
	var x_pos = x_offset + node.position * horizontal_spacing
	var y_pos = node.layer * layer_height + layer_height / 2

	# 应用智能布局调整，避免节点重叠
	x_pos = _adjust_node_position_x(node, x_pos)

	return Vector2(x_pos, y_pos)

## 调整节点X坐标以避免重叠
func _adjust_node_position_x(node: MapNode, base_x: float) -> float:
	# 获取同层的其他节点
	var layer_nodes = map_data.get_nodes_by_layer(node.layer)

	# 如果只有一个节点或者是第一个节点，不需要调整
	if layer_nodes.size() <= 1 or node.position == 0:
		return base_x

	# 检查是否与前一个节点重叠
	var prev_node = null
	for n in layer_nodes:
		if n.position == node.position - 1:
			prev_node = n
			break

	if prev_node and _node_positions.has(prev_node.id):
		var prev_pos = _node_positions[prev_node.id]
		var min_distance = node_size.x + 10  # 最小间距

		if base_x - prev_pos.x < min_distance:
			# 调整位置以避免重叠
			return prev_pos.x + min_distance

	return base_x

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

	# 确保连接在节点下方
	connection_instance.z_index = -10

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
	var from_pos = _calculate_node_position(from_node)
	var to_pos = _calculate_node_position(to_node)

	# 缓存连接点
	var connection_key = connection.from_node_id + "_" + connection.to_node_id
	_connection_points[connection_key] = {
		"from": from_pos,
		"to": to_pos
	}

	# 设置连接的起点和终点
	connection_instance.set_points(from_pos, to_pos)

	# 连接信号
	if connection_instance.has_signal("connection_clicked"):
		connection_instance.connection_clicked.connect(_on_connection_clicked.bind(connection.id))

	# 如果启用动画，添加出现动画
	if use_animations:
		connection_instance.modulate.a = 0
		var tween = create_tween()
		tween.tween_property(connection_instance, "modulate:a", 1.0, 0.5 * animation_speed)

	# 保存连接实例
	connection_instances[connection.id] = connection_instance

## 连接点击处理
func _on_connection_clicked(connection_id: String) -> void:
	# 可以在这里处理连接点击事件
	print("连接被点击: ", connection_id)

	# 如果需要，可以发送信号
	# connection_clicked.emit(connection_id)

## 计算连接点
## 根据节点ID计算连接的起点和终点
func _calculate_connection_points(from_node_id: String, to_node_id: String) -> Dictionary:
	# 检查缓存
	var connection_key = from_node_id + "_" + to_node_id
	if _connection_points.has(connection_key):
		return _connection_points[connection_key]

	# 获取节点
	var from_node = map_data.get_node_by_id(from_node_id)
	var to_node = map_data.get_node_by_id(to_node_id)

	if not from_node or not to_node:
		return {"from": Vector2.ZERO, "to": Vector2.ZERO}

	# 计算位置
	var from_pos = _calculate_node_position(from_node)
	var to_pos = _calculate_node_position(to_node)

	# 缓存结果
	var result = {"from": from_pos, "to": to_pos}
	_connection_points[connection_key] = result

	return result

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
				if connection.has_method("set_highlighted"):
					if use_animations:
						# 使用动画高亮
						connection.set_highlighted(true)
					else:
						connection.set_highlighted(true)
				break

## 清除路径高亮
## 清除所有高亮的路径
func clear_path_highlights() -> void:
	# 重置所有连接的高亮状态
	for connection_id in connection_instances:
		var connection = connection_instances[connection_id]
		if connection.has_method("set_highlighted"):
			connection.set_highlighted(false)

## 更新相机限制
func _update_camera_limits() -> void:
	if not camera or not container:
		return

	# 设置相机限制
	var map_size = container.custom_minimum_size
	var viewport_size = get_viewport().size

	# 计算限制，确保地图不会超出视图
	var limit_left = 0
	var limit_right = max(map_size.x, viewport_size.x)
	var limit_top = 0
	var limit_bottom = max(map_size.y, viewport_size.y)

	# 应用限制
	camera.limit_left = limit_left
	camera.limit_right = limit_right
	camera.limit_top = limit_top
	camera.limit_bottom = limit_bottom

## 缩放处理
func _zoom_in() -> void:
	if not camera:
		return

	var new_zoom = min(camera.zoom.x + zoom_step, max_zoom)
	_set_camera_zoom(new_zoom)

func _zoom_out() -> void:
	if not camera:
		return

	var new_zoom = max(camera.zoom.x - zoom_step, min_zoom)
	_set_camera_zoom(new_zoom)

func _on_zoom_in_pressed() -> void:
	_zoom_in()

func _on_zoom_out_pressed() -> void:
	_zoom_out()

func _on_zoom_reset_pressed() -> void:
	if not camera:
		return

	_set_camera_zoom(initial_zoom)

func _set_camera_zoom(zoom_level: float) -> void:
	if not camera:
		return

	if use_animations:
		# 使用动画缩放
		var tween = create_tween()
		tween.tween_property(camera, "zoom", Vector2(zoom_level, zoom_level), 0.2 * animation_speed)
	else:
		camera.zoom = Vector2(zoom_level, zoom_level)

	# 更新相机限制
	_update_camera_limits()

## 应用当前主题
func _apply_current_theme() -> void:
	if not theme_manager:
		print("主题管理器未初始化")
		return

	var current_theme = theme_manager.get_current_theme()
	if not current_theme:
		print("当前主题为空")
		return

	print("应用主题: ", current_theme.id)

	# 应用背景颜色
	var background = $Background
	if background:
		var style = background.get_theme_stylebox("panel")
		if style is StyleBoxFlat:
			style.bg_color = current_theme.background_color

	# 设置网格颜色
	if grid_background:
		grid_background.set_grid_color(current_theme.grid_color)

	# 如果已有节点和连接实例，更新它们的颜色
	for node_id in node_instances:
		var node_instance = node_instances[node_id]
		var node_data = map_data.get_node_by_id(node_id)
		if node_data and node_instance.has_method("update_theme"):
			var color = Color.WHITE
			if current_theme.node_colors.has(node_data.type):
				color = Color(current_theme.node_colors[node_data.type])
			elif current_theme.node_colors.has("default"):
				color = Color(current_theme.node_colors["default"])
			node_instance.update_theme(color)

	for connection_id in connection_instances:
		var connection_instance = connection_instances[connection_id]
		var connection_data = map_data.get_connection_by_id(connection_id)
		if connection_data and connection_instance.has_method("update_theme"):
			var connection_type = "default"
			if connection_data.has_property("type"):
				connection_type = connection_data.get_property("type")

			var color = Color.WHITE
			if current_theme.connection_colors.has(connection_type):
				color = Color(current_theme.connection_colors[connection_type])
			elif current_theme.connection_colors.has("default"):
				color = Color(current_theme.connection_colors["default"])
			connection_instance.update_theme(color)

## 主题变更处理
func _on_theme_changed(theme_id: String) -> void:
	_apply_current_theme()

## 地图主题变更事件处理
func _on_map_theme_changed(event: ThemeEvents.MapThemeChangedEvent) -> void:
	# 更新节点颜色
	for node_id in node_instances:
		var node_instance = node_instances[node_id]
		var node_data = map_data.get_node_by_id(node_id)
		if node_data and node_instance.has_method("update_theme"):
			var color = Color.WHITE
			if event.node_colors.has(node_data.type):
				color = Color(event.node_colors[node_data.type])
			elif event.node_colors.has("default"):
				color = Color(event.node_colors["default"])
			node_instance.update_theme(color)

	# 更新连接颜色
	for connection_id in connection_instances:
		var connection_instance = connection_instances[connection_id]
		var connection_data = map_data.get_connection_by_id(connection_id)
		if connection_data and connection_instance.has_method("update_theme"):
			var connection_type = "default"
			if connection_data.has_property("type"):
				connection_type = connection_data.get_property("type")

			var color = Color.WHITE
			if event.connection_colors.has(connection_type):
				color = Color(event.connection_colors[connection_type])
			elif event.connection_colors.has("default"):
				color = Color(event.connection_colors["default"])
			connection_instance.update_theme(color)

	# 更新背景颜色
	var background = $Background
	if background:
		var style = background.get_theme_stylebox("panel")
		if style is StyleBoxFlat:
			if use_animations:
				# 使用动画更新背景颜色
				var tween = create_tween()
				tween.tween_method(
					func(value): style.bg_color = value,
					style.bg_color, event.background_color, 0.5 * animation_speed
				)
			else:
				style.bg_color = event.background_color

	# 更新网格颜色
	if grid_background:
		var grid_color = event.background_color.lightened(0.1)
		grid_color.a = 0.2
		grid_background.set_grid_color(grid_color)
