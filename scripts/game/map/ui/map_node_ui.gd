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
var is_hovering: bool = false

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
var hover_color_boost: float = 0.2

# 动画设置
var use_animations: bool = true
var animation_speed: float = 1.0
var current_tween = null

func _ready() -> void:
	# 连接信号
	button.pressed.connect(_on_button_pressed)
	button.mouse_entered.connect(_on_mouse_entered)
	button.mouse_exited.connect(_on_mouse_exited)

	# 初始化状态
	selection_indicator.visible = false
	current_indicator.visible = false
	visited_indicator.visible = false

	# 设置初始缩放
	pivot_offset = size / 2

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

	if use_animations:
		# 使用动画显示/隐藏选中指示器
		if current_tween:
			current_tween.kill()

		current_tween = create_tween()
		if selected:
			selection_indicator.visible = true
			selection_indicator.modulate.a = 0
			current_tween.tween_property(selection_indicator, "modulate:a", 1.0, 0.3 * animation_speed)
		else:
			current_tween.tween_property(selection_indicator, "modulate:a", 0.0, 0.3 * animation_speed)
			current_tween.tween_callback(func(): selection_indicator.visible = false)
	else:
		selection_indicator.visible = selected

	_update_appearance()

## 设置节点是否为当前节点
func set_current(current: bool) -> void:
	is_current = current

	if use_animations:
		# 使用动画显示/隐藏当前指示器
		if current_tween:
			current_tween.kill()

		current_tween = create_tween()
		if current:
			current_indicator.visible = true
			current_indicator.modulate.a = 0
			current_tween.tween_property(current_indicator, "modulate:a", 1.0, 0.3 * animation_speed)
		else:
			current_tween.tween_property(current_indicator, "modulate:a", 0.0, 0.3 * animation_speed)
			current_tween.tween_callback(func(): current_indicator.visible = false)
	else:
		current_indicator.visible = current

	_update_appearance()

## 设置节点是否可到达
func set_reachable(reachable: bool) -> void:
	is_reachable = reachable
	_update_appearance()

## 设置节点是否已访问
func set_visited(visited: bool) -> void:
	is_visited = visited

	if use_animations:
		# 使用动画显示/隐藏访问指示器
		if current_tween:
			current_tween.kill()

		current_tween = create_tween()
		if visited:
			visited_indicator.visible = true
			visited_indicator.modulate.a = 0
			current_tween.tween_property(visited_indicator, "modulate:a", 1.0, 0.3 * animation_speed)
		else:
			current_tween.tween_property(visited_indicator, "modulate:a", 0.0, 0.3 * animation_speed)
			current_tween.tween_callback(func(): visited_indicator.visible = false)
	else:
		visited_indicator.visible = visited

	_update_appearance()

## 更新节点外观
func _update_appearance() -> void:
	var target_color: Color

	if is_selected:
		target_color = selected_color
	elif is_current:
		target_color = current_color
	elif is_visited:
		target_color = visited_color
	elif is_reachable:
		target_color = reachable_color
	else:
		target_color = unreachable_color

	# 如果正在悬停，增加亮度
	if is_hovering and (is_reachable or is_current):
		target_color = target_color.lightened(hover_color_boost)

	if use_animations:
		# 使用动画更新颜色
		if current_tween:
			current_tween.kill()

		current_tween = create_tween()
		current_tween.tween_property(background, "color", target_color, 0.2 * animation_speed)
	else:
		background.color = target_color

	# 设置交互性
	button.disabled = not is_reachable and not is_current

## 更新主题
func update_theme(color: Color) -> void:
	default_color = color
	selected_color = color.lightened(0.5)
	current_color = Color(color.r, color.g * 1.2, color.b * 0.5)
	reachable_color = color.lightened(0.2)
	visited_color = color.darkened(0.3)
	unreachable_color = color.darkened(0.5)
	_update_appearance()

## 按钮点击处理
func _on_button_pressed() -> void:
	if use_animations:
		# 添加点击动画效果
		var click_tween = create_tween()
		click_tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.1 * animation_speed)
		click_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1 * animation_speed)

	node_clicked.emit()

## 鼠标进入处理
func _on_mouse_entered() -> void:
	is_hovering = true

	if not button.disabled:
		if use_animations:
			# 使用动画缩放
			var hover_tween = create_tween()
			hover_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.2 * animation_speed)
		else:
			scale = Vector2(1.1, 1.1)

	_update_appearance()
	node_hovered.emit()

## 鼠标退出处理
func _on_mouse_exited() -> void:
	is_hovering = false

	if use_animations:
		# 使用动画恢复缩放
		var exit_tween = create_tween()
		exit_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2 * animation_speed)
	else:
		scale = Vector2(1.0, 1.0)

	_update_appearance()
	node_unhovered.emit()
