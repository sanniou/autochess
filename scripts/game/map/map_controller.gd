extends Node
class_name MapController
## 地图控制器
## 管理地图的生成、加载和交互

# 控制器信号
signal map_loaded(map_data)
signal map_cleared
signal node_selected(node_data)
signal node_visited(node_data)
signal node_hovered(node_data)
signal node_unhovered(node_data)

# 组件引用
@export var generator_path: NodePath
@export var renderer_path: NodePath

var generator: MapGenerator
var renderer: MapRenderer

# 当前地图
var current_map: MapData = null
var current_node_id: String = ""

func _ready() -> void:
	# 获取组件引用
	if not generator_path.is_empty():
		generator = get_node(generator_path)

	if not renderer_path.is_empty():
		renderer = get_node(renderer_path)

		# 连接渲染器信号
		if renderer:
			renderer.node_clicked.connect(_on_renderer_node_clicked)
			renderer.node_hovered.connect(_on_renderer_node_hovered)
			renderer.node_unhovered.connect(_on_renderer_node_unhovered)

## 生成地图
func generate_map(template_id: String, seed_value: int = -1) -> void:
	if not generator:
		push_error("无法生成地图：缺少生成器")
		return

	# 生成地图
	var map_data = generator.generate_map(template_id, seed_value)

	if map_data:
		# 加载生成的地图
		load_map_data(map_data)
	else:
		push_error("生成地图失败")

## 加载地图数据
func load_map_data(map_data: MapData) -> void:
	# 清除当前地图
	clear_map()

	# 设置当前地图
	current_map = map_data

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
func clear_map() -> void:
	# 清除当前地图
	current_map = null
	current_node_id = ""

	# 清除渲染器
	if renderer:
		renderer.clear_map()

	# 发送信号
	map_cleared.emit()

## 设置当前节点
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

## 选择节点
func select_node(node_id: String) -> void:
	if not current_map:
		return

	var node = current_map.get_node_by_id(node_id)
	if not node:
		return

	# 检查节点是否可到达
	if not _is_node_reachable(node_id):
		return

	# 更新渲染器
	if renderer:
		renderer.select_node(node_id)

	# 发送信号
	node_selected.emit(node)

## 访问节点
func visit_node(node_id: String) -> void:
	if not current_map:
		return

	var node = current_map.get_node_by_id(node_id)
	if not node:
		return

	# 检查节点是否可到达
	if not _is_node_reachable(node_id):
		return

	# 标记节点为已访问
	node.visited = true

	# 更新当前节点
	set_current_node(node_id)

	# 更新渲染器
	if renderer and renderer.node_instances.has(node_id):
		renderer.node_instances[node_id].set_visited(true)

	# 发送信号
	node_visited.emit(node)

## 检查节点是否可到达
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

## 渲染器节点点击事件处理
func _on_renderer_node_clicked(node: MapNode) -> void:
	select_node(node.id)

## 渲染器节点悬停事件处理
func _on_renderer_node_hovered(node: MapNode) -> void:
	node_hovered.emit(node)

## 渲染器节点取消悬停事件处理
func _on_renderer_node_unhovered(node: MapNode) -> void:
	node_unhovered.emit(node)
