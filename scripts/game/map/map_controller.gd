extends Node
class_name MapController
## 地图控制器
## 管理地图的交互逻辑，连接数据层和视图层

# 控制器信号
signal map_loaded(map_data)
signal map_cleared
signal node_selected(node_data)
signal node_visited(node_data)
signal node_hovered(node_data)
signal node_unhovered(node_data)
signal path_highlighted(path_nodes)
signal path_highlight_cleared

# 组件引用
@export var generator_path: NodePath
@export var renderer_path: NodePath

var generator: MapGenerator
var renderer: MapRenderer

# 渲染器信号是否已连接
var _renderer_signals_connected: bool = false

# 当前地图
var current_map: MapData = null
var current_node_id: String = ""

# 路径查找缓存
var _path_cache: Dictionary = {}

func _ready() -> void:
	# 获取组件引用
	if not generator_path.is_empty():
		generator = get_node(generator_path)

	if not renderer_path.is_empty():
		var renderer_node = get_node(renderer_path)
		if renderer_node:
			set_renderer(renderer_node)

## 设置渲染器
## 设置控制器使用的渲染器并连接信号
func set_renderer(new_renderer: MapRenderer) -> void:
	# 如果已有渲染器，先断开信号
	if renderer and _renderer_signals_connected:
		_disconnect_renderer_signals()

	# 设置新的渲染器
	renderer = new_renderer

	# 连接渲染器信号（如果渲染器不为空）
	if renderer:
		_connect_renderer_signals()

		# 如果已有地图数据，立即加载到新渲染器
		if current_map:
			renderer.set_map_data(current_map)
			renderer.render_map()

			# 如果有当前节点，设置当前节点
			if not current_node_id.is_empty():
				renderer.set_current_player_node(current_node_id)

## 连接渲染器信号
func _connect_renderer_signals() -> void:
	if renderer and not _renderer_signals_connected:
		renderer.node_clicked.connect(_on_renderer_node_clicked)
		renderer.node_hovered.connect(_on_renderer_node_hovered)
		renderer.node_unhovered.connect(_on_renderer_node_unhovered)
		_renderer_signals_connected = true

## 断开渲染器信号
func _disconnect_renderer_signals() -> void:
	if renderer and _renderer_signals_connected:
		if renderer.node_clicked.is_connected(_on_renderer_node_clicked):
			renderer.node_clicked.disconnect(_on_renderer_node_clicked)
		if renderer.node_hovered.is_connected(_on_renderer_node_hovered):
			renderer.node_hovered.disconnect(_on_renderer_node_hovered)
		if renderer.node_unhovered.is_connected(_on_renderer_node_unhovered):
			renderer.node_unhovered.disconnect(_on_renderer_node_unhovered)
		_renderer_signals_connected = false

## 生成地图
## 使用生成器创建新地图
func generate_map(template_id: String, seed_value: int = -1) -> MapData:
	if not generator:
		push_error("无法生成地图：缺少生成器")
		return null

	# 生成地图
	var map_data = generator.generate_map(template_id, seed_value)

	if map_data:
		# 加载生成的地图
		load_map_data(map_data)
		return map_data
	else:
		push_error("生成地图失败")
		return null

## 加载地图数据
## 设置当前地图并通知渲染器
func load_map_data(map_data: MapData) -> void:
	# 清除当前地图
	clear_map()

	# 设置当前地图
	current_map = map_data

	# 确保索引是最新的
	current_map.rebuild_indices()

	# 清除路径缓存
	_path_cache.clear()

	# 渲染地图
	if renderer:
		renderer.set_map_data(current_map)
		renderer.render_map()

	# 设置初始节点
	var start_nodes = current_map.get_nodes_by_type("start")
	if not start_nodes.is_empty():
		set_current_node(start_nodes[0].id)

	# 发送信号
	map_loaded.emit(current_map)

## 加载地图文件
## 从文件加载地图数据
func load_map_file(file_path: String) -> void:
	if not FileAccess.file_exists(file_path):
		push_error("地图文件不存在: " + file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)

	if error != OK:
		push_error("解析地图文件失败: " + json.get_error_message())
		return

	var map_dict = json.data
	var map_data = MapData.from_dict(map_dict)

	if map_data:
		load_map_data(map_data)
	else:
		push_error("加载地图数据失败")

## 保存地图文件
## 将当前地图保存到文件
func save_map_file(file_path: String) -> void:
	if not current_map:
		push_error("没有地图可保存")
		return

	var map_dict = current_map.to_dict()
	var json_text = JSON.stringify(map_dict, "\t")

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(json_text)
	file.close()

## 清除地图
## 重置当前地图状态
func clear_map() -> void:
	# 清除当前地图
	current_map = null
	current_node_id = ""

	# 清除路径缓存
	_path_cache.clear()

	# 清除渲染器
	if renderer:
		renderer.clear_map()

	# 发送信号
	map_cleared.emit()

## 设置当前节点
## 更新当前选中的节点
func set_current_node(node_id: String) -> void:
	if not current_map:
		return

	var node = current_map.get_node_by_id(node_id)
	if not node:
		return

	# 更新当前节点
	current_node_id = node_id

	# 更新渲染器
	if renderer:
		renderer.set_current_player_node(node_id)

	# 清除路径缓存，因为当前节点已更改
	_path_cache.clear()

## 选择节点
## 处理节点选择逻辑
func select_node(node_id: String) -> bool:
	if not current_map:
		return false

	var node = current_map.get_node_by_id(node_id)
	if not node:
		return false

	# 检查节点是否可到达
	if not _is_node_reachable(node_id):
		return false

	# 更新渲染器
	if renderer:
		renderer.select_node(node_id)

	# 发送信号
	node_selected.emit(node)

	return true

## 访问节点
## 标记节点为已访问并更新状态
func visit_node(node_id: String) -> bool:
	if not current_map:
		return false

	var node = current_map.get_node_by_id(node_id)
	if not node:
		return false

	# 检查节点是否可到达
	if not _is_node_reachable(node_id):
		return false

	# 标记节点为已访问
	node.visited = true

	# 更新当前节点
	set_current_node(node_id)

	# 更新渲染器
	if renderer:
		renderer.update_node_state(node_id, true)

	# 发送信号
	node_visited.emit(node)

	return true

## 高亮路径
## 高亮从起点到终点的路径
func highlight_path(from_node_id: String, to_node_id: String) -> bool:
	if not current_map:
		return false

	# 获取路径
	var path = get_path_between_nodes(from_node_id, to_node_id)

	if path.is_empty():
		return false

	# 通知渲染器高亮路径
	if renderer:
		renderer.highlight_path(path)

	# 发送信号
	path_highlighted.emit(path)

	return true

## 清除路径高亮
## 清除所有高亮的路径
func clear_path_highlights() -> void:
	if renderer:
		renderer.clear_path_highlights()

	# 发送信号
	path_highlight_cleared.emit()

## 获取两个节点之间的路径
## 返回从起点到终点的路径（节点ID数组）
func get_path_between_nodes(from_node_id: String, to_node_id: String) -> Array:
	# 检查缓存
	var cache_key = from_node_id + "_to_" + to_node_id
	if _path_cache.has(cache_key):
		return _path_cache[cache_key]

	if not current_map:
		return []

	# 如果是直接连接，返回简单路径
	if current_map.has_connection_between_nodes(from_node_id, to_node_id):
		var path = [from_node_id, to_node_id]
		_path_cache[cache_key] = path
		return path

	# 否则使用寻路算法
	var path = _find_path(from_node_id, to_node_id)
	_path_cache[cache_key] = path
	return path

## 获取最佳路径
## 使用A*算法找到从起点到终点的最佳路径
func get_best_path_to_node(from_node_id: String, to_node_id: String) -> Array:
	return get_path_between_nodes(from_node_id, to_node_id)

## 检查节点是否可到达
## 检查从当前节点是否可以到达指定节点
func _is_node_reachable(node_id: String) -> bool:
	if not current_map or current_node_id.is_empty():
		return false

	# 如果是当前节点，则可到达
	if node_id == current_node_id:
		return true

	# 获取可到达的节点
	var reachable_nodes = current_map.get_reachable_nodes(current_node_id)

	# 检查目标节点是否在可到达列表中
	for node in reachable_nodes:
		if node.id == node_id:
			return true

	return false

## 寻找路径
## 使用广度优先搜索找到从起点到终点的路径
func _find_path(from_node_id: String, to_node_id: String) -> Array:
	if not current_map:
		return []

	# 初始化队列和访问记录
	var queue = []
	var visited = {}
	var parent = {}

	# 将起点加入队列
	queue.push_back(from_node_id)
	visited[from_node_id] = true

	# BFS遍历
	while not queue.is_empty():
		var current_id = queue.pop_front()

		# 如果到达目标，重建路径
		if current_id == to_node_id:
			return _reconstruct_path(parent, from_node_id, to_node_id)

		# 获取可达节点
		var reachable_nodes = current_map.get_reachable_nodes(current_id)

		# 遍历所有可达节点
		for node in reachable_nodes:
			if not visited.has(node.id):
				queue.push_back(node.id)
				visited[node.id] = true
				parent[node.id] = current_id

	# 如果没有找到路径，返回空数组
	return []

## 重建路径
## 从父节点记录中重建完整路径
func _reconstruct_path(parent: Dictionary, from_node_id: String, to_node_id: String) -> Array:
	var path = [to_node_id]
	var current_id = to_node_id

	while current_id != from_node_id:
		current_id = parent[current_id]
		path.push_front(current_id)

	return path

## 获取当前地图
## 返回当前加载的地图数据
func get_current_map() -> MapData:
	return current_map

## 获取当前节点
## 返回当前选中的节点
func get_current_node() -> MapNode:
	if not current_map or current_node_id.is_empty():
		return null
	return current_map.get_node_by_id(current_node_id)

## 获取可选节点
## 返回当前可以选择的所有节点
func get_selectable_nodes() -> Array[MapNode]:
	if not current_map or current_node_id.is_empty():
		return []
	return current_map.get_reachable_nodes(current_node_id)

## 渲染器节点点击事件处理
func _on_renderer_node_clicked(node: MapNode) -> void:
	select_node(node.id)

## 渲染器节点悬停事件处理
func _on_renderer_node_hovered(node: MapNode) -> void:
	# 如果节点可到达，高亮路径
	if _is_node_reachable(node.id):
		highlight_path(current_node_id, node.id)

	node_hovered.emit(node)

## 渲染器节点取消悬停事件处理
func _on_renderer_node_unhovered(node: MapNode) -> void:
	clear_path_highlights()
	node_unhovered.emit(node)
