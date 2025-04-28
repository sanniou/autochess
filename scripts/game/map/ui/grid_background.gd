extends Control
class_name GridBackground
## 网格背景
## 用于绘制地图背景网格

# 网格设置
@export var grid_size: float = 50.0
@export var grid_color: Color = Color(0.2, 0.2, 0.2, 0.2)
@export var draw_grid: bool = true

# 相机引用
var camera: Camera2D

func _ready() -> void:
	# 确保控件接收绘制调用
	set_process(true)

## 设置相机引用
func set_camera(p_camera: Camera2D) -> void:
	camera = p_camera

## 设置网格颜色
func set_grid_color(color: Color) -> void:
	grid_color = color
	queue_redraw()

## 绘制背景网格
func _draw() -> void:
	if not draw_grid:
		return
		
	# 获取视口大小
	var size = get_size()
	
	# 计算网格线数量
	var h_lines = int(size.y / grid_size) + 1
	var v_lines = int(size.x / grid_size) + 1
	
	# 如果有相机，调整网格位置
	var offset = Vector2.ZERO
	if camera:
		offset = camera.position - size / 2
		offset = Vector2(fmod(offset.x, grid_size), fmod(offset.y, grid_size))
	
	# 绘制水平线
	for i in range(h_lines):
		var y = i * grid_size - offset.y
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_color)
	
	# 绘制垂直线
	for i in range(v_lines):
		var x = i * grid_size - offset.x
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color)

## 处理重绘
func _process(_delta: float) -> void:
	if draw_grid:
		queue_redraw()
