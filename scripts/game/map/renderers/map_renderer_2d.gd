extends MapRenderer
class_name MapRenderer2D
## 2D地图渲染器
## 在2D空间中渲染地图，支持缩放、平移和主题，模拟现代地图软件体验

# 渲染设置
@export var node_size: Vector2 = Vector2(80, 80)
@export var layer_height: float = 150.0
@export var horizontal_spacing: float = 120.0

# 缩放设置
@export var min_zoom: float = 0.3
@export var max_zoom: float = 2.5
@export var zoom_step: float = 0.1
@export var initial_zoom: float = 1.0

# 视图设置
@export var focus_margin: float = 200.0  # 聚焦时的边距
@export var auto_center_on_current: bool = true  # 自动居中到当前节点
@export var show_only_reachable_area: bool = true  # 只显示可到达区域
@export var smooth_camera_speed: float = 4.0  # 相机平滑移动速度

# 组件引用
var camera: Camera2D
var map_viewport: SubViewport
var map_content: Node2D

# 主题管理器
var theme_manager: MapThemeManager

# 缓存
var _node_positions: Dictionary = {}
var _connection_points: Dictionary = {}
var _path_cache: Dictionary = {}
var _visible_nodes: Array = []  # 当前视图中可见的节点

# 动画设置
var use_animations: bool = true
var animation_speed: float = 1.0

# 拖动状态
var _is_dragging: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_start_camera_pos: Vector2 = Vector2.ZERO
var _drag_enabled: bool = true  # 是否启用拖拽
var _drag_button: int = MOUSE_BUTTON_LEFT  # 拖拽使用的鼠标按钮
var _drag_inertia: Vector2 = Vector2.ZERO  # 拖拽惯性
var _drag_inertia_enabled: bool = true  # 是否启用拖拽惯性
var _last_drag_pos: Vector2 = Vector2.ZERO  # 上一次拖拽位置
var _last_drag_time: float = 0.0  # 上一次拖拽时间

# 当前主题
var current_theme: MapTheme = null
func _ready() -> void:
	# 获取组件引用
	camera = $MapViewportContainer/MapViewport/MapCamera
	map_viewport = $MapViewportContainer/MapViewport
	map_content = %MapContent

	# 确保 SubViewport 大小正确
	if map_viewport:
		map_viewport.size = $MapViewportContainer.size

	if not camera:
		push_error("MapRenderer2D: 缺少相机组件")
	else:
		# 设置初始缩放
		camera.zoom = Vector2(initial_zoom, initial_zoom)
		# 启用相机平滑
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = smooth_camera_speed

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

	# 连接缩放控制按钮
	$ZoomControls/ZoomIn.pressed.connect(_on_zoom_in_pressed)
	$ZoomControls/ZoomOut.pressed.connect(_on_zoom_out_pressed)
	$ZoomControls/ZoomReset.pressed.connect(_on_zoom_reset_pressed)

	# 连接中心按钮
	if has_node("MapControls/CenterButton"):
		$MapControls/CenterButton.pressed.connect(_on_center_button_pressed)

	# 连接切换可到达区域按钮
	if has_node("MapControls/ToggleReachableButton"):
		$MapControls/ToggleReachableButton.toggled.connect(_on_toggle_reachable_button_toggled)

	# 连接全局事件总线
	GlobalEventBus.ui.add_class_listener(ThemeEvents.MapThemeChangedEvent, _on_map_theme_changed)

	# 连接窗口大小变化事件
	get_tree().root.size_changed.connect(_on_window_size_changed)

	# 连接输入事件
	set_process_input(true)
	set_process(true)  # 启用_process处理

	print("MapRenderer2D 初始化完成")

## 处理每帧更新
func _process(delta: float) -> void:
	# 处理拖拽惯性
	if not _is_dragging and _drag_inertia.length() > 0.1 and camera:
		camera.position -= _drag_inertia * delta
		_drag_inertia = _drag_inertia.lerp(Vector2.ZERO, 5 * delta)

		# 确保相机在边界内
		_clamp_camera_position()

	# 更新可见节点
	_update_visible_nodes()

## 处理输入事件
func _input(event: InputEvent) -> void:
	# 检查事件是否在地图视口内
	if event is InputEventMouse:
		var viewport_rect = $MapViewportContainer.get_global_rect()
		if not viewport_rect.has_point(event.position):
			return

	# 处理鼠标滚轮缩放
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			# 缩放时保持鼠标位置不变
			_zoom_at_point(_zoom_in, event.position)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			# 缩放时保持鼠标位置不变
			_zoom_at_point(_zoom_out, event.position)
			get_viewport().set_input_as_handled()
		# 处理鼠标拖动 - 使用左键拖动，更符合现代地图软件
		elif event.button_index == _drag_button:
			if event.pressed:
				_start_drag(event.position)
			else:
				_end_drag(event.position)

	# 处理鼠标移动
	elif event is InputEventMouseMotion:
		if _is_dragging:
			_update_drag(event.position)
		elif _drag_inertia_enabled and not _is_dragging:
			# 更新拖拽惯性计算的参考点
			var current_time = Time.get_ticks_msec() / 1000.0
			var time_delta = current_time - _last_drag_time
			if time_delta > 0:
				_last_drag_pos = event.position
				_last_drag_time = current_time
## 开始拖动
func _start_drag(position: Vector2) -> void:
	if not _drag_enabled or not camera:
		return

	_is_dragging = true
	_drag_start_pos = position
	_last_drag_pos = position
	_last_drag_time = Time.get_ticks_msec() / 1000.0
	_drag_inertia = Vector2.ZERO

	# 记录相机的起始位置
	_drag_start_camera_pos = camera.position

	# 改变鼠标光标
	Input.set_default_cursor_shape(Input.CURSOR_DRAG)

## 更新拖动
func _update_drag(position: Vector2) -> void:
	if not _is_dragging or not camera:
		return

	# 计算拖拽位移 - 反转方向使其符合直觉（拖向右边，地图向右移动）
	var delta = (position - _drag_start_pos)
	delta = delta / camera.zoom

	# 移动相机
	var new_pos = _drag_start_camera_pos - delta

	# 计算拖拽速度，用于惯性
	var current_time = Time.get_ticks_msec() / 1000.0
	var time_delta = current_time - _last_drag_time
	if time_delta > 0:
		var inertia_factor = 0.3  # 正值，因为我们已经反转了方向
		_drag_inertia = (position - _last_drag_pos) / time_delta * inertia_factor / camera.zoom
		_last_drag_pos = position
		_last_drag_time = current_time

	# 应用新位置到相机
	camera.position = new_pos

	# 确保相机在边界内
	_clamp_camera_position()

## 结束拖动
func _end_drag(_position: Vector2 = Vector2.ZERO) -> void:
	if not _is_dragging:
		return

	_is_dragging = false

	# 恢复鼠标光标
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

## 在指定点缩放
func _zoom_at_point(zoom_function: Callable, _point: Vector2) -> void:
	if not camera or not map_viewport:
		return

	# 将屏幕坐标转换为视口坐标
	var viewport_container = $MapViewportContainer
	var local_point = viewport_container.get_local_mouse_position()
	var viewport_size = Vector2(map_viewport.size)
	var container_size = Vector2(viewport_container.size)
	var viewport_point = local_point * viewport_size / container_size

	# 记录缩放前的世界坐标
	var prev_zoom = camera.zoom
	var world_pos = camera.position + (viewport_point - viewport_size / 2) / prev_zoom

	# 执行缩放
	zoom_function.call()

	# 计算缩放后的位置调整
	var new_world_pos = camera.position + (viewport_point - viewport_size / 2) / camera.zoom
	var world_offset = world_pos - new_world_pos

	# 应用位置调整，保持鼠标下方的点不变
	camera.position += world_offset

	# 确保相机在边界内
	_clamp_camera_position()

## 限制相机位置在边界内
func _clamp_camera_position() -> void:
	if not camera or not map_content:
		return

	# 获取地图内容的边界
	var map_rect = Rect2(Vector2.ZERO, map_content.get_viewport_rect().size)
	if map_rect.size == Vector2.ZERO:
		return

	# 获取视口大小
	var viewport_size = map_viewport.size

	# 计算相机可见区域的一半（考虑缩放）
	var half_viewport = Vector2(viewport_size) / (2 * camera.zoom)

	# 计算边界
	var min_x = map_rect.position.x + half_viewport.x
	var max_x = map_rect.end.x - half_viewport.x
	var min_y = map_rect.position.y + half_viewport.y
	var max_y = map_rect.end.y - half_viewport.y

	# 确保边界有效（如果地图小于视口）
	if min_x > max_x:
		var mid_x = (map_rect.position.x + map_rect.end.x) / 2
		min_x = max_x
		max_x = mid_x

	if min_y > max_y:
		var mid_y = (map_rect.position.y + map_rect.end.y) / 2
		min_y = max_y
		max_y = mid_y

	# 应用边界限制
	camera.position.x = clamp(camera.position.x, min_x, max_x)
	camera.position.y = clamp(camera.position.y, min_y, max_y)
## 居中到当前节点
func _center_on_current_node() -> void:
	if not camera or not current_player_node:
		return

	var node_pos = _node_positions.get(current_player_node.id, Vector2.ZERO)
	if node_pos == Vector2.ZERO:
		return

	# 使用动画平滑移动到节点位置
	if use_animations:
		var tween = create_tween()
		tween.tween_property(camera, "position", node_pos, 0.5 * animation_speed)
	else:
		camera.position = node_pos

	# 确保相机在边界内
	_clamp_camera_position()

## 居中按钮点击处理
func _on_center_button_pressed() -> void:
	_center_on_current_node()

## 切换可到达区域按钮处理
func _on_toggle_reachable_button_toggled(button_pressed: bool) -> void:
	show_only_reachable_area = button_pressed
	_update_visible_nodes()

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
	# 在视图中心缩放
	var viewport_center = map_viewport.size / 2
	_zoom_at_point(_zoom_in, viewport_center)

func _on_zoom_out_pressed() -> void:
	# 在视图中心缩放
	var viewport_center = map_viewport.size / 2
	_zoom_at_point(_zoom_out, viewport_center)

func _on_zoom_reset_pressed() -> void:
	if not camera:
		return

	# 保存当前位置
	# 不需要额外的计算，直接重置缩放

	# 设置为初始缩放
	camera.zoom = Vector2(initial_zoom, initial_zoom)

	# 确保相机在边界内
	_clamp_camera_position()

func _set_camera_zoom(zoom_level: float) -> void:
	if not camera:
		return

	if use_animations:
		# 使用动画缩放
		var tween = create_tween()
		tween.tween_property(camera, "zoom", Vector2(zoom_level, zoom_level), 0.2 * animation_speed)
	else:
		camera.zoom = Vector2(zoom_level, zoom_level)

## 更新相机限制
func _update_camera_limits() -> void:
	if not camera or not map_content:
		return

	# 获取地图内容的边界
	var map_rect = Rect2(Vector2.ZERO, map_content.custom_minimum_size)

	# 设置相机限制
	camera.limit_left = int(map_rect.position.x)
	camera.limit_right = int(map_rect.end.x)
	camera.limit_top = int(map_rect.position.y)
	camera.limit_bottom = int(map_rect.end.y)
## 应用当前主题
func _apply_current_theme() -> void:
	if not theme_manager:
		return

	# 获取当前主题
	current_theme = theme_manager.get_current_theme()
	if not current_theme:
		return

	# 应用背景颜色
	var background = $Background
	if background:
		var style = background.get_theme_stylebox("panel")
		if style is StyleBoxFlat:
			style.bg_color = current_theme.background_color

## 主题变更处理
func _on_theme_changed(theme: MapTheme) -> void:
	current_theme = theme
	_apply_current_theme()

	# 更新所有节点和连接的主题
	for node_id in node_instances:
		node_instances[node_id].apply_theme(current_theme)

	for connection_id in connection_instances:
		connection_instances[connection_id].apply_theme(current_theme)

## 地图主题变更事件处理
func _on_map_theme_changed(event) -> void:
	if theme_manager:
		theme_manager.set_theme_by_id(event.theme_id)

## 清除地图
func clear_map() -> void:
	# 清除节点实例
	for node_id in node_instances:
		var node_instance = node_instances[node_id]
		if is_instance_valid(node_instance):
			node_instance.queue_free()

	# 清除连接实例
	for connection_id in connection_instances:
		var connection_instance = connection_instances[connection_id]
		if is_instance_valid(connection_instance):
			connection_instance.queue_free()

	# 清除字典
	node_instances.clear()
	connection_instances.clear()

	# 清除缓存
	_node_positions.clear()
	_connection_points.clear()
	_path_cache.clear()
	_visible_nodes.clear()

## 渲染地图
func render_map() -> void:
	if not map_data or not map_content or not node_scene or not connection_scene:
		push_error("无法渲染地图：缺少必要的组件")
		return

	# 清除现有地图
	clear_map()

	# 清除缓存
	_node_positions.clear()
	_connection_points.clear()
	_path_cache.clear()
	_visible_nodes.clear()

	# 计算地图尺寸
	var map_width = 0
	var map_height = map_data.layers * layer_height

	for layer in range(map_data.layers):
		var layer_nodes = map_data.get_nodes_by_layer(layer)
		map_width = max(map_width, layer_nodes.size() * horizontal_spacing)

	# 设置地图内容大小
	var padding = 300  # 边距
	map_content.custom_minimum_size = Vector2(map_width + padding, map_height + padding)

	# 更新地图信息
	_update_map_info()

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

	# 设置相机位置 - 聚焦到当前节点
	if camera and current_player_node:
		var node_pos = _node_positions.get(current_player_node.id, Vector2.ZERO)
		if node_pos != Vector2.ZERO:
			camera.position = node_pos
		else:
			camera.position = Vector2(map_viewport.size) / 2
	else:
		if camera:
			camera.position = Vector2(map_viewport.size) / 2

	# 确保 SubViewport 大小正确
	map_viewport.size = $MapViewportContainer.size

	# 确保相机在边界内
	_clamp_camera_position()

	# 更新可见节点
	_update_visible_nodes()

	print("地图渲染完成，节点: ", node_instances.size(), ", 连接: ", connection_instances.size())
## 更新可见节点
## 根据当前视图和可到达性更新节点的可见性
func _update_visible_nodes() -> void:
	if not map_data or not camera:
		return

	_visible_nodes.clear()

	# 计算相机可见区域
	var viewport_size = map_viewport.size
	var view_rect = Rect2(
		camera.position - Vector2(viewport_size) / (2 * camera.zoom),
		Vector2(viewport_size) / camera.zoom
	)

	# 扩展视图区域，包含边缘
	view_rect = view_rect.grow(node_size.x * 2)

	# 如果启用了只显示可到达区域，获取可到达节点
	var reachable_nodes = []
	if show_only_reachable_area and current_player_node:
		reachable_nodes = map_data.get_reachable_nodes(current_player_node.id)
		# 始终包含当前节点
		if not reachable_nodes.has(current_player_node):
			reachable_nodes.append(current_player_node)

	# 遍历所有节点，更新可见性
	for node_id in node_instances:
		var node_instance = node_instances[node_id]
		var node_data = map_data.get_node_by_id(node_id)
		var node_pos = _node_positions.get(node_id, Vector2.ZERO)

		# 检查节点是否在视图内
		var is_in_view = view_rect.has_point(node_pos)

		# 检查节点是否可到达（如果启用了只显示可到达区域）
		var is_reachable = true
		if show_only_reachable_area:
			is_reachable = false
			for reachable_node in reachable_nodes:
				if reachable_node.id == node_id:
					is_reachable = true
					break

		# 更新节点可见性
		var should_be_visible = is_in_view and (not show_only_reachable_area or is_reachable)

		# 特殊情况：当前节点和已访问节点始终可见（如果在视图内）
		if (node_data == current_player_node or node_data.visited) and is_in_view:
			should_be_visible = true

		# 应用可见性
		if should_be_visible:
			node_instance.visible = true
			_visible_nodes.append(node_id)
		else:
			# 使用淡出动画隐藏节点
			if use_animations and node_instance.visible:
				var tween = create_tween()
				tween.tween_property(node_instance, "modulate:a", 0.0, 0.3 * animation_speed)
				# 使用弱引用避免回调时节点已被销毁的问题
				var node_instance_ref = weakref(node_instance)
				tween.tween_callback(func():
					var node = node_instance_ref.get_ref()
					if node:
						node.visible = false
				)
			else:
				node_instance.visible = false

	# 更新连接可见性
	for connection_id in connection_instances:
		var connection_instance = connection_instances[connection_id]
		var connection_data = map_data.get_connection_by_id(connection_id)

		# 检查连接的两端节点是否可见
		var from_visible = _visible_nodes.has(connection_data.from_node_id)
		var to_visible = _visible_nodes.has(connection_data.to_node_id)

		# 只有当两端节点都可见时，连接才可见
		var should_be_visible = from_visible and to_visible

		# 应用可见性
		if should_be_visible:
			connection_instance.visible = true
		else:
			# 使用淡出动画隐藏连接
			if use_animations and connection_instance.visible:
				var tween = create_tween()
				tween.tween_property(connection_instance, "modulate:a", 0.0, 0.3 * animation_speed)
				# 使用弱引用避免回调时节点已被销毁的问题
				var connection_instance_ref = weakref(connection_instance)
				tween.tween_callback(func():
					var conn = connection_instance_ref.get_ref()
					if conn:
						conn.visible = false
				)
			else:
				connection_instance.visible = false
## 渲染节点
func _render_node(node: MapNode) -> void:
	if not node_scene:
		return

	# 实例化节点场景
	var node_instance = node_scene.instantiate()
	map_content.add_child(node_instance)

	# 计算节点位置
	var x_pos = node.x_position * horizontal_spacing
	var y_pos = node.layer * layer_height
	var node_pos = Vector2(x_pos, y_pos)

	# 设置节点位置
	node_instance.position = node_pos

	# 保存节点位置到缓存
	_node_positions[node.id] = node_pos

	# 设置节点数据
	node_instance.set_node_data(node)

	# 应用主题
	if current_theme:
		node_instance.apply_theme(current_theme)

	# 连接信号
	node_instance.node_clicked.connect(_on_node_clicked.bind(node.id))
	node_instance.node_hovered.connect(_on_node_hovered.bind(node.id))
	node_instance.node_unhovered.connect(_on_node_unhovered.bind(node.id))

	# 保存节点实例
	node_instances[node.id] = node_instance

## 渲染连接
func _render_connection(connection: MapConnection) -> void:
	if not connection_scene or not map_data:
		return

	# 获取连接的两端节点
	var from_node = map_data.get_node_by_id(connection.from_node_id)
	var to_node = map_data.get_node_by_id(connection.to_node_id)

	if not from_node or not to_node:
		push_error("无法渲染连接：找不到节点")
		return

	# 计算节点位置
	var from_x = from_node.x_position * horizontal_spacing
	var from_y = from_node.layer * layer_height
	var to_x = to_node.x_position * horizontal_spacing
	var to_y = to_node.layer * layer_height

	var from_pos = Vector2(from_x, from_y)
	var to_pos = Vector2(to_x, to_y)

	# 保存连接点到缓存
	var connection_key = connection.from_node_id + "_to_" + connection.to_node_id
	_connection_points[connection_key] = {
		"from": from_pos,
		"to": to_pos
	}

	# 实例化连接场景
	var connection_instance = connection_scene.instantiate()
	map_content.add_child(connection_instance)

	# 确保连接在节点下方
	connection_instance.z_index = -1

	# 设置连接数据
	connection_instance.set_connection_data(connection)
	connection_instance.set_points(from_pos, to_pos)

	# 应用主题
	if current_theme:
		connection_instance.apply_theme(current_theme)

	# 保存连接实例
	connection_instances[connection.id] = connection_instance

## 高亮路径
func highlight_path(path_nodes: Array) -> void:
	if path_nodes.size() < 2:
		return

	# 清除现有高亮
	clear_path_highlights()

	# 高亮路径上的连接
	for i in range(path_nodes.size() - 1):
		var from_id = path_nodes[i]
		var to_id = path_nodes[i + 1]

		# 查找连接
		var connection_id = _find_connection_id(from_id, to_id)
		if connection_id.is_empty():
			continue

		var connection_instance = connection_instances.get(connection_id)
		if connection_instance:
			connection_instance.highlight(true)

## 清除路径高亮
func clear_path_highlights() -> void:
	for connection_id in connection_instances:
		var connection_instance = connection_instances[connection_id]
		if connection_instance:
			connection_instance.highlight(false)

## 查找连接ID
func _find_connection_id(from_node_id: String, to_node_id: String) -> String:
	if not map_data:
		return ""

	# 查找直接连接
	for connection in map_data.connections:
		if (connection.from_node_id == from_node_id and connection.to_node_id == to_node_id) or \
		   (connection.from_node_id == to_node_id and connection.to_node_id == from_node_id):
			return connection.id

	return ""
## 设置当前玩家节点
func set_current_player_node(node_id: String) -> void:
	if not map_data:
		return

	var node = map_data.get_node_by_id(node_id)
	if not node:
		return

	# 更新当前节点
	current_player_node = node

	# 更新节点状态
	for id in node_instances:
		var node_instance = node_instances[id]
		node_instance.set_current(id == node_id)

	# 更新可到达节点
	_update_reachable_nodes()

	# 更新地图信息
	_update_map_info()

	# 如果启用了自动居中，居中到当前节点
	if auto_center_on_current:
		_center_on_current_node()

## 选择节点
func select_node(node_id: String) -> void:
	if not map_data:
		return

	var node = map_data.get_node_by_id(node_id)
	if not node:
		return

	# 更新选中节点
	selected_node = node

	# 更新节点状态
	for id in node_instances:
		var node_instance = node_instances[id]
		node_instance.set_selected(id == node_id)

	# 发送信号
	node_clicked.emit(node)

## 更新节点状态
func update_node_state(node_id: String, visited: bool) -> void:
	if not map_data:
		return

	var node = map_data.get_node_by_id(node_id)
	if not node:
		return

	# 更新节点数据
	node.visited = visited

	# 更新节点实例
	var node_instance = node_instances.get(node_id)
	if node_instance:
		node_instance.set_visited(visited)

	# 更新可见节点
	_update_visible_nodes()

	# 更新地图信息
	_update_map_info()

## 节点点击事件处理
func _on_node_clicked(node_id: String) -> void:
	if not map_data:
		return

	var node = map_data.get_node_by_id(node_id)
	if not node:
		return

	# 发送信号
	node_clicked.emit(node)

## 节点悬停事件处理
func _on_node_hovered(node_id: String) -> void:
	if not map_data:
		return

	var node = map_data.get_node_by_id(node_id)
	if not node:
		return

	# 发送信号
	node_hovered.emit(node)

## 节点取消悬停事件处理
func _on_node_unhovered(node_id: String) -> void:
	if not map_data:
		return

	var node = map_data.get_node_by_id(node_id)
	if not node:
		return

	# 发送信号
	node_unhovered.emit(node)

## 更新地图信息
func _update_map_info() -> void:
	if not map_data:
		return

	# 获取地图信息标签
	var map_info_label = $MapInfo
	if not map_info_label:
		return

	# 构建地图信息文本
	var info_text = "地图信息:\n"
	info_text += "模板: " + map_data.template_id + "\n"
	info_text += "层数: " + str(map_data.layers) + "\n"
	info_text += "节点: " + str(map_data.nodes.size()) + "\n"
	info_text += "连接: " + str(map_data.connections.size()) + "\n"

	# 如果有当前节点，显示当前节点信息
	if current_player_node:
		info_text += "\n当前节点: " + current_player_node.id + "\n"
		info_text += "类型: " + current_player_node.type + "\n"
		info_text += "层级: " + str(current_player_node.layer) + "\n"

		# 显示可到达节点数量
		var reachable_nodes = map_data.get_reachable_nodes(current_player_node.id)
		info_text += "可到达: " + str(reachable_nodes.size()) + " 个节点\n"

	# 更新标签文本
	map_info_label.text = info_text

## 设置拖拽启用状态
func set_drag_enabled(enabled: bool) -> void:
	_drag_enabled = enabled

## 设置动画启用状态
func set_animations_enabled(enabled: bool) -> void:
	use_animations = enabled

## 设置动画速度
func set_animation_speed(speed: float) -> void:
	animation_speed = speed

## 设置自动居中状态
func set_auto_center_enabled(enabled: bool) -> void:
	auto_center_on_current = enabled

## 设置只显示可到达区域状态
func set_show_only_reachable(enabled: bool) -> void:
	show_only_reachable_area = enabled

	# 更新UI按钮状态
	if has_node("MapControls/ToggleReachableButton"):
		$MapControls/ToggleReachableButton.button_pressed = enabled

	# 更新可见节点
	_update_visible_nodes()

## 窗口大小变化处理
func _on_window_size_changed() -> void:
	# 更新 SubViewport 大小
	if map_viewport and has_node("MapViewportContainer"):
		map_viewport.size = $MapViewportContainer.size

	# 更新相机限制
	_clamp_camera_position()

	# 更新可见节点
	_update_visible_nodes()
