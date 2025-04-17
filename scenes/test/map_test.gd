extends Control
## 地图测试场景
## 用于测试地图生成和节点连接
# 配置管理器
var config_manager: ConfigManager

# 当前地图数据
var current_map_data = null

# 地图节点实例
var map_nodes = {}

# 地图连接实例
var map_connections = []

# 当前选中的节点
var selected_node = null

# 地图设置
var map_layers = 5
var map_difficulty = "normal"
var map_seed = 0

# 初始化
func _ready():
	config_manager = get_node("/root/GameManager/ConfigManager")
	
	# 连接信号
	EventBus.connect("map_node_selected", _on_map_node_selected)
	EventBus.connect("map_node_hovered", _on_map_node_hovered)
	
	# 初始化设置
	_initialize_settings()
	
	# 更新信息面板
	_update_info_panel()

# 初始化设置
func _initialize_settings() -> void:
	# 设置层数滑块
	$SettingsPanel/VBoxContainer/LayersSlider.value = map_layers
	$SettingsPanel/VBoxContainer/LayersValue.text = str(map_layers)
	
	# 设置难度选项
	var difficulty_index = 1  # 默认普通难度
	match map_difficulty:
		"easy": difficulty_index = 0
		"normal": difficulty_index = 1
		"hard": difficulty_index = 2
		"expert": difficulty_index = 3
	$SettingsPanel/VBoxContainer/DifficultyOption.selected = difficulty_index
	
	# 设置种子输入框
	if map_seed != 0:
		$SettingsPanel/VBoxContainer/SeedEdit.text = str(map_seed)

# 生成地图
func _generate_map() -> void:
	# 清除现有地图
	_clear_map()
	
	# 获取种子
	var seed_text = $SettingsPanel/VBoxContainer/SeedEdit.text
	if seed_text.is_empty():
		map_seed = randi()  # 随机种子
	else:
		map_seed = seed_text.to_int()
	
	# 设置随机种子
	seed(map_seed)
	
	# 创建地图模板
	var template = {
		"id": "test_map",
		"name": "测试地图",
		"layers": map_layers,
		"difficulty": map_difficulty
	}
	
	# 生成地图数据
	var map_manager = GameManager.map_manager
	var a = map_manager.map_generator
	current_map_data = map_manager.map_generator.generate_map(template)
	
	# 显示地图
	_display_map(current_map_data)
	
	# 更新信息面板
	_update_info_panel()

# 显示地图
func _display_map(map_data: Dictionary) -> void:
	# 获取地图容器
	var map_display = $MapContainer/MapDisplay
	
	# 设置地图容器大小
	var map_width = 1000
	var map_height = map_layers * 150
	map_display.custom_minimum_size = Vector2(map_width, map_height)
	
	# 创建节点
	for node in map_data.nodes:
		_create_map_node(node, map_display)
	
	# 创建连接
	for layer_connections in map_data.connections:
		for connection in layer_connections:
			_create_map_connection(connection, map_display)

# 创建地图节点
func _create_map_node(node_data: Dictionary, parent: Control) -> void:
	# 创建节点
	var node = ColorRect.new()
	node.name = "Node_" + node_data.id
	node.size = Vector2(50, 50)
	
	# 设置节点位置
	var x_pos = 100 + node_data.position * 800 / 10  # 假设位置范围是0-10
	var y_pos = 50 + node_data.layer * 150
	node.position = Vector2(x_pos - 25, y_pos - 25)  # 居中显示
	
	# 设置节点颜色
	var node_color = _get_node_color(node_data.type)
	node.color = node_color
	
	# 添加节点标签
	var label = Label.new()
	label.text = _get_node_type_name(node_data.type)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = node.size
	node.add_child(label)
	
	# 添加点击事件
	var button = Button.new()
	button.flat = true
	button.size = node.size
	button.pressed.connect(_on_node_button_pressed.bind(node_data))
	node.add_child(button)
	
	# 添加到父节点
	parent.add_child(node)
	
	# 保存节点实例
	map_nodes[node_data.id] = node

# 创建地图连接
func _create_map_connection(connection_data: Dictionary, parent: Control) -> void:
	# 获取起始节点
	var from_node = map_nodes.get(connection_data.from)
	if not from_node:
		return
	
	# 创建到每个目标节点的连接
	for to_id in connection_data.to:
		var to_node = map_nodes.get(to_id)
		if not to_node:
			continue
		
		# 创建连接线
		var line = Line2D.new()
		line.width = 2.0
		line.default_color = Color(0.7, 0.7, 0.7, 0.7)
		
		# 设置连接线的起点和终点
		var from_pos = from_node.position + from_node.size / 2
		var to_pos = to_node.position + to_node.size / 2
		line.points = [from_pos, to_pos]
		
		# 添加到父节点
		parent.add_child(line)
		
		# 保存连接实例
		map_connections.append(line)

# 清除地图
func _clear_map() -> void:
	# 清除节点
	for node_id in map_nodes:
		map_nodes[node_id].queue_free()
	map_nodes.clear()
	
	# 清除连接
	for connection in map_connections:
		connection.queue_free()
	map_connections.clear()
	
	# 清除地图数据
	current_map_data = null
	
	# 更新信息面板
	_update_info_panel()

# 更新信息面板
func _update_info_panel() -> void:
	var info_text = ""
	
	if current_map_data:
		info_text += "地图ID: " + current_map_data.template_id + "\n"
		info_text += "层数: " + str(current_map_data.layers) + "\n"
		info_text += "难度: " + current_map_data.difficulty + "\n"
		info_text += "节点数: " + str(current_map_data.nodes.size()) + "\n"
		info_text += "种子: " + str(map_seed) + "\n"
		
		# 添加节点类型统计
		var node_types = {}
		for node in current_map_data.nodes:
			if not node_types.has(node.type):
				node_types[node.type] = 0
			node_types[node.type] += 1
		
		info_text += "\n节点类型统计:\n"
		for type in node_types:
			info_text += "- " + _get_node_type_name(type) + ": " + str(node_types[type]) + "\n"
	else:
		info_text = "生成地图查看信息..."
	
	$InfoPanel/VBoxContainer/InfoContent.text = info_text

# 获取节点类型名称
func _get_node_type_name(node_type: String) -> String:
	var type_names = {
		"battle": "战斗",
		"elite_battle": "精英战斗",
		"boss": "Boss",
		"shop": "商店",
		"event": "事件",
		"treasure": "宝藏",
		"rest": "休息"
	}
	
	return type_names.get(node_type, node_type)

# 获取节点颜色
func _get_node_color(node_type: String) -> Color:
	var type_colors = {
		"battle": Color(0.8, 0.2, 0.2),  # 红色
		"elite_battle": Color(0.8, 0.0, 0.0),  # 深红色
		"boss": Color(0.5, 0.0, 0.0),  # 暗红色
		"shop": Color(0.2, 0.6, 0.8),  # 蓝色
		"event": Color(0.8, 0.8, 0.2),  # 黄色
		"treasure": Color(0.8, 0.6, 0.0),  # 金色
		"rest": Color(0.2, 0.8, 0.2)  # 绿色
	}
	
	return type_colors.get(node_type, Color(0.5, 0.5, 0.5))

# 层数滑块值变化处理
func _on_layers_slider_value_changed(value: float) -> void:
	map_layers = int(value)
	$SettingsPanel/VBoxContainer/LayersValue.text = str(map_layers)

# 难度选项选择处理
func _on_difficulty_option_item_selected(index: int) -> void:
	match index:
		0: map_difficulty = "easy"
		1: map_difficulty = "normal"
		2: map_difficulty = "hard"
		3: map_difficulty = "expert"

# 生成按钮处理
func _on_generate_button_pressed() -> void:
	_generate_map()

# 清除按钮处理
func _on_clear_button_pressed() -> void:
	_clear_map()

# 保存按钮处理
func _on_save_button_pressed() -> void:
	if not current_map_data:
		return
	
	# 创建保存对话框
	var dialog = FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.json", "JSON文件")
	dialog.title = "保存地图"
	dialog.current_path = "res://maps/test_map.json"
	dialog.size = Vector2(500, 400)
	
	# 连接信号
	dialog.file_selected.connect(_on_save_dialog_file_selected)
	
	# 显示对话框
	add_child(dialog)
	dialog.popup_centered()

# 保存对话框文件选择处理
func _on_save_dialog_file_selected(path: String) -> void:
	# 保存地图数据
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(current_map_data, "\t"))
	file.close()
	
	# 显示保存成功提示
	var info_dialog = AcceptDialog.new()
	info_dialog.title = "保存成功"
	info_dialog.dialog_text = "地图已保存到: " + path
	add_child(info_dialog)
	info_dialog.popup_centered()

# 加载按钮处理
func _on_load_button_pressed() -> void:
	# 创建加载对话框
	var dialog = FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.add_filter("*.json", "JSON文件")
	dialog.title = "加载地图"
	dialog.size = Vector2(500, 400)
	
	# 连接信号
	dialog.file_selected.connect(_on_load_dialog_file_selected)
	
	# 显示对话框
	add_child(dialog)
	dialog.popup_centered()

# 加载对话框文件选择处理
func _on_load_dialog_file_selected(path: String) -> void:
	# 加载地图数据
	var file = FileAccess.open(path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	# 解析JSON
	var json = JSON.new()
	var error = json.parse(json_text)
	if error == OK:
		# 清除现有地图
		_clear_map()
		
		# 设置地图数据
		current_map_data = json.data
		
		# 更新设置
		map_layers = current_map_data.layers
		map_difficulty = current_map_data.difficulty
		if current_map_data.has("generation_seed"):
			map_seed = current_map_data.generation_seed
		
		# 初始化设置
		_initialize_settings()
		
		# 显示地图
		_display_map(current_map_data)
		
		# 更新信息面板
		_update_info_panel()
	else:
		# 显示错误提示
		var error_dialog = AcceptDialog.new()
		error_dialog.title = "加载失败"
		error_dialog.dialog_text = "无法解析地图文件: " + json.get_error_message()
		add_child(error_dialog)
		error_dialog.popup_centered()

# 节点按钮点击处理
func _on_node_button_pressed(node_data: Dictionary) -> void:
	# 设置选中节点
	selected_node = node_data
	
	# 发送节点选择信号
	EventBus.map.emit_event("map_node_selected", [node_data])

# 地图节点选择事件处理
func _on_map_node_selected(node_data: Dictionary) -> void:
	# 高亮显示选中节点
	for node_id in map_nodes:
		var node = map_nodes[node_id]
		if node_id == node_data.id:
			node.modulate = Color(1.5, 1.5, 1.5)  # 高亮
		else:
			node.modulate = Color(1, 1, 1)  # 正常

# 地图节点悬停事件处理
func _on_map_node_hovered(node_data: Dictionary) -> void:
	# 显示节点信息
	pass

# 返回按钮处理
func _on_back_button_pressed() -> void:
	# 返回主菜单
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
