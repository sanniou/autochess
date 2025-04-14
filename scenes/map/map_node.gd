extends Control
## 地图节点
## 表示地图上的一个节点，可以是战斗、商店、事件等

# 节点数据
var node_data = {}

# 节点选择信号
signal node_selected(node_data)

func _ready():
	# 初始化节点
	pass

## 设置节点数据
func setup(data: Dictionary) -> void:
	node_data = data
	
	# 设置节点图标
	var icon_path = _get_icon_path(data.type)
	var icon = load(icon_path)
	if icon:
		$Icon.texture = icon
	
	# 设置节点标签
	$Label.text = _get_node_type_name(data.type)
	
	# 设置节点颜色
	var color = _get_node_color(data.type)
	modulate = color

## 设置节点状态
func set_state(is_current: bool, is_selectable: bool, is_visited: bool) -> void:
	if is_current:
		# 当前节点
		modulate = Color(1, 1, 0)  # 黄色
		$Button.disabled = true
	elif is_visited:
		# 已访问节点
		modulate = Color(0.5, 0.5, 0.5)  # 灰色
		$Button.disabled = true
	elif is_selectable:
		# 可选节点
		modulate = _get_node_color(node_data.type)
		$Button.disabled = false
	else:
		# 不可选节点
		modulate = Color(0.3, 0.3, 0.3, 0.5)  # 半透明灰色
		$Button.disabled = true

## 获取节点ID
func get_node_id() -> String:
	return node_data.id

## 获取节点图标路径
func _get_icon_path(node_type: String) -> String:
	var node_types = ConfigManager.map_nodes_config.node_types
	if node_types.has(node_type):
		return "res://assets/images/map/" + node_types[node_type].icon
	
	return "res://assets/images/map/node_battle.png"  # 默认图标

## 获取节点类型名称
func _get_node_type_name(node_type: String) -> String:
	var tr_key = "ui.map.node_" + node_type
	return LocalizationManager.tr(tr_key)

## 获取节点颜色
func _get_node_color(node_type: String) -> Color:
	var node_types = ConfigManager.map_nodes_config.node_types
	if node_types.has(node_type):
		return Color(node_types[node_type].color)
	
	return Color(1, 1, 1)  # 默认白色

## 按钮点击处理
func _on_button_pressed() -> void:
	AudioManager.play_ui_sound("button_click.ogg")
	node_selected.emit(node_data)
