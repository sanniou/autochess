extends Control
## 新地图系统测试场景

# 组件引用
@onready var map_container = $MapContainer
@onready var info_panel = $InfoPanel
@onready var node_info = $InfoPanel/NodeInfo
@onready var generate_button = $Controls/GenerateButton
@onready var template_option = $Controls/TemplateOption
@onready var seed_input = $Controls/SeedInput
@onready var difficulty_slider = $Controls/DifficultySlider

# 地图组件
var map_generator: ProceduralMapGenerator
var map_renderer: MapRenderer2D
var map_controller: MapController
var current_map: MapData

func _ready() -> void:
	# 初始化UI
	_setup_ui()

	# 创建地图组件
	_create_map_components()

	# 连接信号
	_connect_signals()

## 设置UI
func _setup_ui() -> void:
	# 设置模板选项
	template_option.clear()
	template_option.add_item("标准地图", 0)
	template_option.add_item("困难地图", 1)
	template_option.add_item("简单地图", 2)
	template_option.add_item("冒险地图", 3)

	# 设置种子输入
	seed_input.text = str(randi())

	# 设置难度滑块
	difficulty_slider.min_value = 1
	difficulty_slider.max_value = 3
	difficulty_slider.value = 1
	difficulty_slider.step = 1

## 创建地图组件
func _create_map_components() -> void:
	# 创建地图生成器
	map_generator = ProceduralMapGenerator.new()
	add_child(map_generator)

	# 创建地图渲染器
	var renderer_scene = preload("res://scenes/game/map/map_renderer_2d.tscn")
	map_renderer = renderer_scene.instantiate()
	map_renderer.container = map_container
	add_child(map_renderer)

	# 创建地图控制器
	map_controller = MapController.new()
	map_controller.generator = map_generator
	map_controller.renderer = map_renderer
	add_child(map_controller)

## 连接信号
func _connect_signals() -> void:
	# 连接UI信号
	generate_button.pressed.connect(_on_generate_button_pressed)

	# 连接地图控制器信号
	map_controller.node_selected.connect(_on_node_selected)
	map_controller.node_hovered.connect(_on_node_hovered)
	map_controller.node_unhovered.connect(_on_node_unhovered)
	map_controller.map_loaded.connect(_on_map_loaded)

## 生成地图
func _on_generate_button_pressed() -> void:
	# 获取模板ID
	var template_id = ""
	match template_option.selected:
		0: template_id = "standard"
		1: template_id = "hard"
		2: template_id = "easy"
		3: template_id = "adventure"

	# 获取种子值
	var seed_value = seed_input.text.to_int()

	# 获取难度
	var difficulty = difficulty_slider.value

	# 生成地图
	map_controller.generate_map(template_id, seed_value)

## 地图加载事件处理
func _on_map_loaded(map_data: MapData) -> void:
	current_map = map_data

	# 更新信息面板
	info_panel.visible = true
	node_info.text = "地图已加载\n"
	node_info.text += "模板: " + current_map.template_id + "\n"
	node_info.text += "种子: " + str(current_map.seed_value) + "\n"
	node_info.text += "难度: " + str(current_map.difficulty) + "\n"
	node_info.text += "层数: " + str(current_map.layers) + "\n"
	node_info.text += "节点数: " + str(current_map.nodes.size()) + "\n"
	node_info.text += "连接数: " + str(current_map.connections.size()) + "\n"

## 节点选择事件处理
func _on_node_selected(node: MapNode) -> void:
	# 更新节点信息
	node_info.text = "选中节点: " + node.id + "\n"
	node_info.text += "类型: " + node.type + "\n"
	node_info.text += "层级: " + str(node.layer) + "\n"
	node_info.text += "位置: " + str(node.position) + "\n"
	node_info.text += "已访问: " + str(node.visited) + "\n"

	# 显示节点属性
	node_info.text += "\n属性:\n"
	for key in node.properties:
		node_info.text += key + ": " + str(node.properties[key]) + "\n"

	# 显示节点奖励
	if not node.rewards.is_empty():
		node_info.text += "\n奖励:\n"
		for key in node.rewards:
			node_info.text += key + ": " + str(node.rewards[key]) + "\n"

	# 显示连接信息
	node_info.text += "\n连接到: " + str(node.connections_to) + "\n"
	node_info.text += "来自: " + str(node.connections_from) + "\n"

## 节点悬停事件处理
func _on_node_hovered(node: MapNode) -> void:
	# 更新节点信息
	node_info.text = "悬停节点: " + node.id + "\n"
	node_info.text += "类型: " + node.type + "\n"
	node_info.text += "层级: " + str(node.layer) + "\n"
	node_info.text += "位置: " + str(node.position) + "\n"

## 节点取消悬停事件处理
func _on_node_unhovered(node: MapNode) -> void:
	# 如果有选中的节点，显示选中节点的信息
	if map_controller.selected_node:
		_on_node_selected(map_controller.selected_node)
	else:
		# 否则显示地图信息
		_on_map_loaded(current_map)
