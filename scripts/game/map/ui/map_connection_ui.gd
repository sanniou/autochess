extends Control
class_name MapConnectionUI
## 地图连接UI
## 表示地图上两个节点之间的连接

# 连接数据
var connection_data: MapConnection = null
var connection_type_config: ConnectionType = null

# 连接组件引用
@onready var line = $Line2D

# 连接状态
var is_traversable: bool = true
var is_highlighted: bool = false

# 连接颜色
var default_color: Color = Color(0.7, 0.7, 0.7, 0.7)
var highlighted_color: Color = Color(1.0, 1.0, 1.0, 1.0)
var untraversable_color: Color = Color(0.5, 0.5, 0.5, 0.5)

func _ready() -> void:
	# 初始化线条
	line.width = 2.0
	line.default_color = default_color

## 设置连接数据
func setup(connection: MapConnection, type_config: ConnectionType) -> void:
	connection_data = connection
	connection_type_config = type_config
	
	# 设置连接状态
	is_traversable = connection.traversable
	
	# 设置连接颜色
	var color_str = type_config.color
	default_color = Color(color_str)
	
	# 更新外观
	_update_appearance()

## 设置连接的起点和终点
func set_points(from_point: Vector2, to_point: Vector2) -> void:
	line.clear_points()
	
	# 添加起点和终点
	line.add_point(from_point)
	
	# 如果是跨多层的连接，添加中间点使连接呈曲线
	if abs(to_point.y - from_point.y) > 150:
		var mid_y = (from_point.y + to_point.y) / 2
		var mid_point1 = Vector2(from_point.x, mid_y)
		var mid_point2 = Vector2(to_point.x, mid_y)
		
		line.add_point(mid_point1)
		line.add_point(mid_point2)
	
	line.add_point(to_point)

## 设置连接是否可通行
func set_traversable(traversable: bool) -> void:
	is_traversable = traversable
	_update_appearance()

## 设置连接是否高亮
func set_highlighted(highlighted: bool) -> void:
	is_highlighted = highlighted
	_update_appearance()

## 更新连接外观
func _update_appearance() -> void:
	if is_highlighted:
		line.default_color = highlighted_color
	elif not is_traversable:
		line.default_color = untraversable_color
	else:
		line.default_color = default_color
