extends Control
class_name MapConnectionUI
## 地图连接UI
## 表示地图上两个节点之间的连接

# 信号
signal connection_clicked

# 连接数据
var connection_data: MapConnection = null
var connection_type_config: ConnectionType = null

# 连接组件引用
@onready var line = $Line2D
@onready var area = $Area2D
@onready var collision = $Area2D/CollisionShape2D

# 连接状态
var is_traversable: bool = true
var is_highlighted: bool = false
var is_hovered: bool = false

# 连接颜色
var default_color: Color = Color(0.7, 0.7, 0.7, 0.8)
var highlighted_color: Color = Color(1.0, 1.0, 1.0, 1.0)
var hovered_color: Color = Color(0.9, 0.9, 0.9, 0.9)
var untraversable_color: Color = Color(0.5, 0.5, 0.5, 0.5)

# 连接点
var from_point: Vector2
var to_point: Vector2

# 曲线设置
var curve_points: int = 24
var curve_width: float = 3.0
var curve_width_highlighted: float = 5.0

func _ready() -> void:
	# 初始化线条
	line.width = curve_width
	line.default_color = default_color
	line.antialiased = true
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND

	# 连接信号
	if area:
		area.mouse_entered.connect(_on_mouse_entered)
		area.mouse_exited.connect(_on_mouse_exited)
		area.input_event.connect(_on_input_event)

## 设置连接数据
func setup(connection: MapConnection, type_config = null) -> void:
	connection_data = connection
	connection_type_config = type_config

	# 设置连接状态
	is_traversable = connection.traversable

	# 设置连接颜色
	if type_config and type_config.has_method("get_color_object"):
		default_color = type_config.get_color_object()
	elif type_config and type_config is Dictionary and type_config.has("color"):
		var color_str = type_config.color
		default_color = Color(color_str)

	# 确保颜色有足够的不透明度
	if default_color.a < 0.8:
		default_color.a = 0.8

	# 设置高亮颜色
	highlighted_color = default_color.lightened(0.3)
	highlighted_color.a = 1.0

	# 设置悬停颜色
	hovered_color = default_color.lightened(0.2)
	hovered_color.a = 0.9

	# 设置不可通行颜色
	untraversable_color = default_color.darkened(0.3)
	untraversable_color.a = 0.5

	# 更新外观
	_update_appearance()

## 设置连接的起点和终点
func set_points(p_from_point: Vector2, p_to_point: Vector2) -> void:
	from_point = p_from_point
	to_point = p_to_point

	# 绘制曲线
	_draw_curve()

	# 更新碰撞区域
	_update_collision_shape()

## 绘制曲线
func _draw_curve() -> void:
	line.clear_points()

	# 计算控制点
	var mid_point = (from_point + to_point) / 2
	var direction = to_point - from_point
	var perpendicular = Vector2(-direction.y, direction.x).normalized() * 50

	# 如果是垂直连接，使用不同的控制点计算
	var is_vertical = abs(direction.y) > abs(direction.x)
	if is_vertical:
		# 垂直连接使用水平控制点
		var mid_y = (from_point.y + to_point.y) / 2
		var control1 = Vector2(from_point.x, mid_y)
		var control2 = Vector2(to_point.x, mid_y)

		# 绘制三次贝塞尔曲线
		_draw_cubic_bezier(from_point, control1, control2, to_point)
	else:
		# 水平连接使用弯曲控制点
		var control_point = mid_point + perpendicular * 0.5

		# 绘制二次贝塞尔曲线
		_draw_quadratic_bezier(from_point, control_point, to_point)

## 绘制二次贝塞尔曲线
func _draw_quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2) -> void:
	# 添加起点
	line.add_point(p0)

	# 添加中间点
	for i in range(1, curve_points):
		var t = float(i) / curve_points
		var q0 = p0.lerp(p1, t)
		var q1 = p1.lerp(p2, t)
		var point = q0.lerp(q1, t)
		line.add_point(point)

	# 添加终点
	line.add_point(p2)

## 绘制三次贝塞尔曲线
func _draw_cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> void:
	# 添加起点
	line.add_point(p0)

	# 添加中间点
	for i in range(1, curve_points):
		var t = float(i) / curve_points
		var q0 = p0.lerp(p1, t)
		var q1 = p1.lerp(p2, t)
		var q2 = p2.lerp(p3, t)

		var r0 = q0.lerp(q1, t)
		var r1 = q1.lerp(q2, t)

		var point = r0.lerp(r1, t)
		line.add_point(point)

	# 添加终点
	line.add_point(p3)

## 更新碰撞形状
func _update_collision_shape() -> void:
	if not collision:
		return

	# 创建一个矩形形状覆盖整个连接
	var rect = Rect2()
	rect = rect.expand(from_point)
	rect = rect.expand(to_point)

	# 扩大碰撞区域以便更容易点击
	rect = rect.grow(20)

	# 设置碰撞形状
	var shape = RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape

	# 设置碰撞形状位置
	collision.position = rect.position + rect.size / 2 - position

## 设置连接是否可通行
func set_traversable(traversable: bool) -> void:
	is_traversable = traversable
	_update_appearance()

## 设置连接是否高亮
func set_highlighted(highlighted: bool) -> void:
	is_highlighted = highlighted

	# 创建高亮动画
	var tween = create_tween()
	if highlighted:
		tween.tween_property(line, "width", curve_width_highlighted, 0.2)
		tween.parallel().tween_property(line, "default_color", highlighted_color, 0.2)
	else:
		tween.tween_property(line, "width", curve_width, 0.2)
		tween.parallel().tween_property(line, "default_color",
			hovered_color if is_hovered else default_color, 0.2)

	_update_appearance()

## 高亮连接（别名方法，用于兼容性）
func highlight(highlighted: bool, intensity: float = 1.0) -> void:
	set_highlighted(highlighted)

## 更新连接外观
func _update_appearance() -> void:
	if is_highlighted:
		line.default_color = highlighted_color
		line.width = curve_width_highlighted
	elif is_hovered:
		line.default_color = hovered_color
		line.width = curve_width * 1.5
	elif not is_traversable:
		line.default_color = untraversable_color
		line.width = curve_width
	else:
		line.default_color = default_color
		line.width = curve_width

## 更新主题
func update_theme(color: Color) -> void:
	default_color = color
	if default_color.a < 0.8:
		default_color.a = 0.8

	highlighted_color = color.lightened(0.3)
	highlighted_color.a = 1.0

	hovered_color = color.lightened(0.2)
	hovered_color.a = 0.9

	untraversable_color = color.darkened(0.3)
	untraversable_color.a = 0.5

	_update_appearance()

## 鼠标进入处理
func _on_mouse_entered() -> void:
	is_hovered = true
	_update_appearance()

## 鼠标离开处理
func _on_mouse_exited() -> void:
	is_hovered = false
	_update_appearance()

## 输入事件处理
func _on_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		connection_clicked.emit()
