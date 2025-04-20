extends Control
class_name MapNodeUI
## 地图节点UI
## 表示地图上的一个可交互节点

# 节点信号
signal node_clicked
signal node_hovered
signal node_unhovered

# 节点数据
var node_data: MapNode = null
var node_type_config: NodeType = null

# 节点状态
var is_selected: bool = false
var is_current: bool = false
var is_reachable: bool = false
var is_visited: bool = false

# 节点组件引用
@onready var background = $Background
@onready var icon = $Icon
@onready var label = $Label
@onready var button = $Button
@onready var selection_indicator = $SelectionIndicator
@onready var current_indicator = $CurrentIndicator
@onready var visited_indicator = $VisitedIndicator

# 节点颜色
var default_color: Color = Color.WHITE
var selected_color: Color = Color(1.5, 1.5, 1.5)
var current_color: Color = Color(1.0, 1.0, 0.5)
var reachable_color: Color = Color(1.2, 1.2, 1.2)
var visited_color: Color = Color(0.7, 0.7, 0.7)
var unreachable_color: Color = Color(0.5, 0.5, 0.5)

func _ready() -> void:
	# 连接信号
	button.pressed.connect(_on_button_pressed)
	button.mouse_entered.connect(_on_mouse_entered)
	button.mouse_exited.connect(_on_mouse_exited)
	
	# 初始化状态
	selection_indicator.visible = false
	current_indicator.visible = false
	visited_indicator.visible = false

## 设置节点数据
func setup(node: MapNode, type_config: NodeType) -> void:
	node_data = node
	node_type_config = type_config
	
	# 设置节点类型
	var node_type = node.type
	
	# 设置节点图标
	var icon_path = type_config.icon
	if not icon_path.is_empty():
		var texture = load(icon_path)
		if texture:
			icon.texture = texture
	
	# 设置节点标签
	label.text = type_config.name
	
	# 设置节点颜色
	var color_str = type_config.color
	default_color = Color(color_str)
	background.color = default_color
	
	# 设置节点状态
	is_visited = node.visited
	_update_appearance()

## 设置节点是否被选中
func set_selected(selected: bool) -> void:
	is_selected = selected
	selection_indicator.visible = selected
	_update_appearance()

## 设置节点是否为当前节点
func set_current(current: bool) -> void:
	is_current = current
	current_indicator.visible = current
	_update_appearance()

## 设置节点是否可到达
func set_reachable(reachable: bool) -> void:
	is_reachable = reachable
	_update_appearance()

## 设置节点是否已访问
func set_visited(visited: bool) -> void:
	is_visited = visited
	visited_indicator.visible = visited
	_update_appearance()

## 更新节点外观
func _update_appearance() -> void:
	if is_selected:
		background.color = selected_color
	elif is_current:
		background.color = current_color
	elif is_visited:
		background.color = visited_color
	elif is_reachable:
		background.color = reachable_color
	else:
		background.color = unreachable_color
	
	# 设置交互性
	button.disabled = not is_reachable and not is_current

## 按钮点击处理
func _on_button_pressed() -> void:
	node_clicked.emit()

## 鼠标进入处理
func _on_mouse_entered() -> void:
	if not button.disabled:
		scale = Vector2(1.1, 1.1)
	node_hovered.emit()

## 鼠标退出处理
func _on_mouse_exited() -> void:
	scale = Vector2(1.0, 1.0)
	node_unhovered.emit()
