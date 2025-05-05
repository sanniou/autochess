extends Control
## 地图测试场景
## 用于测试地图渲染器功能

# 组件引用
var map_renderer: MapRenderer2D
var map_generator: ProceduralMapGenerator
var current_map: MapData

func _ready() -> void:
	# 获取地图渲染器引用
	map_renderer = $MapRenderer2D
	
	# 创建地图生成器
	map_generator = ProceduralMapGenerator.new()
	add_child(map_generator)
	
	# 连接按钮信号
	$TestControls/GenerateMapButton.pressed.connect(_on_generate_map_button_pressed)
	$TestControls/ClearMapButton.pressed.connect(_on_clear_map_button_pressed)
	$TestControls/VisitRandomNodeButton.pressed.connect(_on_visit_random_node_button_pressed)
	
	# 连接地图渲染器信号
	map_renderer.node_clicked.connect(_on_node_clicked)
	map_renderer.node_hovered.connect(_on_node_hovered)
	map_renderer.node_unhovered.connect(_on_node_unhovered)
	
	print("地图测试场景初始化完成")

## 生成测试地图
func _on_generate_map_button_pressed() -> void:
	# 生成地图
	current_map = map_generator.generate_map("standard")
	
	if current_map:
		# 设置地图数据
		map_renderer.set_map_data(current_map)
		
		# 渲染地图
		map_renderer.render_map()
		
		# 设置初始节点
		var start_nodes = current_map.get_nodes_by_type("start")
		if not start_nodes.is_empty():
			map_renderer.set_current_player_node(start_nodes[0].id)
		
		print("生成测试地图成功")
	else:
		push_error("生成地图失败")

## 清除地图
func _on_clear_map_button_pressed() -> void:
	map_renderer.clear_map()
	current_map = null
	print("地图已清除")

## 访问随机节点
func _on_visit_random_node_button_pressed() -> void:
	if not current_map:
		push_error("没有地图数据")
		return
	
	# 获取当前节点
	var current_node_id = ""
	if map_renderer.current_player_node:
		current_node_id = map_renderer.current_player_node.id
	
	# 获取可到达节点
	var reachable_nodes = current_map.get_reachable_nodes(current_node_id)
	if reachable_nodes.is_empty():
		push_error("没有可到达的节点")
		return
	
	# 随机选择一个节点
	var random_node = reachable_nodes[randi() % reachable_nodes.size()]
	
	# 设置为当前节点
	map_renderer.set_current_player_node(random_node.id)
	
	# 标记为已访问
	map_renderer.update_node_state(random_node.id, true)
	
	print("访问节点: ", random_node.id)

## 节点点击事件处理
func _on_node_clicked(node: MapNode) -> void:
	print("点击节点: ", node.id)
	
	# 如果节点可到达，设置为当前节点并标记为已访问
	if current_map and map_renderer.current_player_node:
		var reachable_nodes = current_map.get_reachable_nodes(map_renderer.current_player_node.id)
		for reachable_node in reachable_nodes:
			if reachable_node.id == node.id:
				map_renderer.set_current_player_node(node.id)
				map_renderer.update_node_state(node.id, true)
				break

## 节点悬停事件处理
func _on_node_hovered(node: MapNode) -> void:
	print("悬停节点: ", node.id)
	
	# 如果节点可到达，高亮路径
	if current_map and map_renderer.current_player_node:
		var reachable_nodes = current_map.get_reachable_nodes(map_renderer.current_player_node.id)
		for reachable_node in reachable_nodes:
			if reachable_node.id == node.id:
				var path = current_map.find_path(map_renderer.current_player_node.id, node.id)
				map_renderer.highlight_path(path)
				break

## 节点取消悬停事件处理
func _on_node_unhovered(node: MapNode) -> void:
	print("取消悬停节点: ", node.id)
	
	# 清除路径高亮
	map_renderer.clear_path_highlights()
