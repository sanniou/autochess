extends Control
class_name PerformanceOverlay
## 性能监控叠加层
## 用于显示性能数据

# 引用
@onready var fps_label = $VBoxContainer/FpsContainer/FpsLabel
@onready var memory_label = $VBoxContainer/MemoryContainer/MemoryLabel
@onready var objects_label = $VBoxContainer/ObjectsContainer/ObjectsLabel
@onready var draw_calls_label = $VBoxContainer/DrawCallsContainer/DrawCallsLabel
@onready var fps_graph = $VBoxContainer/GraphContainer/FpsGraph
@onready var memory_graph = $VBoxContainer/GraphContainer/MemoryGraph
@onready var toggle_button = $ToggleButton
@onready var details_panel = $DetailsPanel
@onready var details_text = $DetailsPanel/ScrollContainer/DetailsText

# 性能监控器
var performance_monitor: PerformanceMonitor = null

# 显示设置
var display_settings = {
	"show_fps": true,
	"show_memory": true,
	"show_objects": true,
	"show_draw_calls": true,
	"show_graphs": true,
	"update_interval": 0.5,  # 更新间隔（秒）
	"graph_width": 200,      # 图表宽度
	"graph_height": 50,      # 图表高度
	"fps_color": Color(0, 1, 0),  # 帧率颜色
	"memory_color": Color(1, 0.5, 0),  # 内存颜色
	"background_color": Color(0, 0, 0, 0.5),  # 背景颜色
	"text_color": Color(1, 1, 1),  # 文本颜色
	"warning_color": Color(1, 0.5, 0),  # 警告颜色
	"error_color": Color(1, 0, 0)  # 错误颜色
}

# 计时器
var _update_timer = 0.0

# 初始化
func _ready() -> void:
	# 获取性能监控器
	performance_monitor = get_node_or_null("/root/PerformanceMonitor")
	if not performance_monitor:
		# 创建一个新的性能监控器
		performance_monitor = PerformanceMonitor.new()
		add_child(performance_monitor)
	
	# 连接信号
	performance_monitor.performance_data_updated.connect(_on_performance_data_updated)
	performance_monitor.performance_warning.connect(_on_performance_warning)
	
	# 设置初始可见性
	_update_visibility()
	
	# 设置背景颜色
	self_modulate = display_settings.background_color
	
	# 设置文本颜色
	fps_label.add_theme_color_override("font_color", display_settings.text_color)
	memory_label.add_theme_color_override("font_color", display_settings.text_color)
	objects_label.add_theme_color_override("font_color", display_settings.text_color)
	draw_calls_label.add_theme_color_override("font_color", display_settings.text_color)
	
	# 初始化图表
	_initialize_graphs()
	
	# 设置切换按钮
	toggle_button.pressed.connect(_on_toggle_button_pressed)
	
	# 初始隐藏详情面板
	details_panel.visible = false

# 处理
func _process(delta: float) -> void:
	# 更新计时器
	_update_timer += delta
	
	# 检查是否需要更新UI
	if _update_timer >= display_settings.update_interval:
		_update_timer = 0.0
		_update_ui()

## 初始化图表
func _initialize_graphs() -> void:
	# 设置FPS图表
	fps_graph.custom_minimum_size = Vector2(display_settings.graph_width, display_settings.graph_height)
	fps_graph.color = display_settings.fps_color
	
	# 设置内存图表
	memory_graph.custom_minimum_size = Vector2(display_settings.graph_width, display_settings.graph_height)
	memory_graph.color = display_settings.memory_color

## 更新UI
func _update_ui() -> void:
	if not performance_monitor:
		return
	
	var data = performance_monitor.get_performance_data()
	
	# 更新标签
	if display_settings.show_fps:
		fps_label.text = "FPS: " + str(int(data.fps))
		
		# 根据帧率设置颜色
		if data.fps < 30:
			fps_label.add_theme_color_override("font_color", display_settings.error_color)
		elif data.fps < 50:
			fps_label.add_theme_color_override("font_color", display_settings.warning_color)
		else:
			fps_label.add_theme_color_override("font_color", display_settings.text_color)
	
	if display_settings.show_memory:
		memory_label.text = "内存: " + str(int(data.memory_total)) + " MB"
		
		# 根据内存使用设置颜色
		if data.memory_total > 1024:
			memory_label.add_theme_color_override("font_color", display_settings.error_color)
		elif data.memory_total > 512:
			memory_label.add_theme_color_override("font_color", display_settings.warning_color)
		else:
			memory_label.add_theme_color_override("font_color", display_settings.text_color)
	
	if display_settings.show_objects:
		objects_label.text = "对象: " + str(data.objects) + " / 节点: " + str(data.nodes)
	
	if display_settings.show_draw_calls:
		draw_calls_label.text = "绘制调用: " + str(data.draw_calls)
	
	# 更新图表
	if display_settings.show_graphs:
		_update_graphs()

## 更新图表
func _update_graphs() -> void:
	if not performance_monitor:
		return
	
	var history = performance_monitor.get_performance_history()
	
	# 更新FPS图表
	fps_graph.values = history.fps
	fps_graph.queue_redraw()
	
	# 更新内存图表
	memory_graph.values = history.memory_total
	memory_graph.queue_redraw()

## 更新可见性
func _update_visibility() -> void:
	# 更新标签可见性
	$VBoxContainer/FpsContainer.visible = display_settings.show_fps
	$VBoxContainer/MemoryContainer.visible = display_settings.show_memory
	$VBoxContainer/ObjectsContainer.visible = display_settings.show_objects
	$VBoxContainer/DrawCallsContainer.visible = display_settings.show_draw_calls
	
	# 更新图表可见性
	$VBoxContainer/GraphContainer.visible = display_settings.show_graphs

## 显示详情面板
func show_details() -> void:
	if not performance_monitor:
		return
	
	# 获取性能报告
	var report = performance_monitor.get_performance_report()
	
	# 更新详情文本
	details_text.text = report
	
	# 显示详情面板
	details_panel.visible = true

## 隐藏详情面板
func hide_details() -> void:
	details_panel.visible = false

## 切换详情面板
func toggle_details() -> void:
	if details_panel.visible:
		hide_details()
	else:
		show_details()

## 设置显示设置
func set_display_setting(name: String, value: Variant) -> void:
	if display_settings.has(name):
		display_settings[name] = value
		_update_visibility()

## 性能数据更新处理
func _on_performance_data_updated(data: Dictionary) -> void:
	# 这里可以处理性能数据更新事件
	pass

## 性能警告处理
func _on_performance_warning(message: String, level: int) -> void:
	# 这里可以处理性能警告事件
	# 例如，显示一个临时的警告消息
	var warning_label = Label.new()
	warning_label.text = message
	
	match level:
		0:  # 信息
			warning_label.add_theme_color_override("font_color", display_settings.text_color)
		1:  # 警告
			warning_label.add_theme_color_override("font_color", display_settings.warning_color)
		2:  # 错误
			warning_label.add_theme_color_override("font_color", display_settings.error_color)
	
	add_child(warning_label)
	warning_label.position = Vector2(10, 10)
	
	# 创建一个定时器，在一段时间后移除警告
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(func(): warning_label.queue_free())

## 切换按钮处理
func _on_toggle_button_pressed() -> void:
	toggle_details()

## 图表类
class PerformanceGraph extends Control:
	var values = []
	var color = Color(1, 1, 1)
	var min_value = 0
	var max_value = 100
	
	func _draw() -> void:
		if values.is_empty():
			return
		
		var rect = Rect2(Vector2.ZERO, size)
		
		# 绘制背景
		draw_rect(rect, Color(0, 0, 0, 0.2))
		
		# 计算最大值和最小值
		var current_max = max_value
		var current_min = min_value
		
		for value in values:
			if value > current_max:
				current_max = value
			if value < current_min and value > 0:
				current_min = value
		
		# 确保有一个合理的范围
		if current_max <= current_min:
			current_max = current_min + 1
		
		# 绘制图表
		var point_count = values.size()
		var point_width = size.x / (point_count - 1) if point_count > 1 else size.x
		
		for i in range(point_count - 1):
			var value1 = values[i]
			var value2 = values[i + 1]
			
			# 计算高度
			var height1 = remap(value1, current_min, current_max, 0, size.y)
			var height2 = remap(value2, current_min, current_max, 0, size.y)
			
			# 计算点坐标
			var point1 = Vector2(i * point_width, size.y - height1)
			var point2 = Vector2((i + 1) * point_width, size.y - height2)
			
			# 绘制线段
			draw_line(point1, point2, color, 2.0)
		
		# 绘制当前值
		var current_value = values[values.size() - 1]
		var value_text = str(int(current_value))
		var font = get_theme_font("font")
		var font_size = get_theme_font_size("font_size")
		
		if font:
			var text_size = font.get_string_size(value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			draw_string(font, Vector2(size.x - text_size.x - 5, 15), value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
