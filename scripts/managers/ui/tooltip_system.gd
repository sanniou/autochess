extends Node
class_name TooltipSystem
## 工具提示系统
## 负责管理游戏中的工具提示

# 信号
signal tooltip_shown(control: Control)
signal tooltip_hidden(control: Control)

# 常量
const TOOLTIP_DELAY = 0.5  # 显示延迟时间
const TOOLTIP_OFFSET = Vector2(10, 10)  # 提示框偏移量

# 当前工具提示
var current_tooltip: Control = null

# 当前目标控件
var current_target: Control = null

# 显示延迟计时器
var delay_timer: Timer = null

# 鼠标位置
var mouse_position: Vector2 = Vector2.ZERO

# 初始化
func _ready() -> void:
	# 创建延迟计时器
	delay_timer = Timer.new()
	delay_timer.one_shot = true
	delay_timer.timeout.connect(_on_delay_timer_timeout)
	add_child(delay_timer)
	
	# 连接信号
	get_viewport().gui_focus_changed.connect(_on_gui_focus_changed)

# 处理输入事件
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_position = event.position
		
		if current_tooltip and is_instance_valid(current_tooltip):
			_update_tooltip_position()

# 注册控件
func register_control(control: Control, tooltip_text: String = "", tooltip_builder: Callable = Callable()) -> void:
	if not is_instance_valid(control):
		return
	
	# 设置控件元数据
	control.set_meta("has_tooltip", true)
	
	if not tooltip_text.is_empty():
		control.set_meta("tooltip_text", tooltip_text)
	
	if tooltip_builder.is_valid():
		control.set_meta("tooltip_builder", tooltip_builder)
	
	# 连接信号
	if not control.mouse_entered.is_connected(_on_control_mouse_entered):
		control.mouse_entered.connect(_on_control_mouse_entered.bind(control))
	
	if not control.mouse_exited.is_connected(_on_control_mouse_exited):
		control.mouse_exited.connect(_on_control_mouse_exited.bind(control))

# 注销控件
func unregister_control(control: Control) -> void:
	if not is_instance_valid(control):
		return
	
	# 移除控件元数据
	if control.has_meta("has_tooltip"):
		control.remove_meta("has_tooltip")
	
	if control.has_meta("tooltip_text"):
		control.remove_meta("tooltip_text")
	
	if control.has_meta("tooltip_builder"):
		control.remove_meta("tooltip_builder")
	
	# 断开信号
	if control.mouse_entered.is_connected(_on_control_mouse_entered):
		control.mouse_entered.disconnect(_on_control_mouse_entered)
	
	if control.mouse_exited.is_connected(_on_control_mouse_exited):
		control.mouse_exited.disconnect(_on_control_mouse_exited)

# 更新工具提示文本
func update_tooltip_text(control: Control, tooltip_text: String) -> void:
	if not is_instance_valid(control):
		return
	
	control.set_meta("tooltip_text", tooltip_text)
	
	# 如果当前显示的是这个控件的提示，更新提示内容
	if current_target == control and current_tooltip and is_instance_valid(current_tooltip):
		var label = current_tooltip.get_node("MarginContainer/Label")
		if label:
			label.text = tooltip_text

# 显示工具提示
func show_tooltip(control: Control) -> void:
	if not is_instance_valid(control):
		return
	
	# 隐藏当前提示
	hide_tooltip()
	
	# 设置当前目标
	current_target = control
	
	# 启动延迟计时器
	delay_timer.start(TOOLTIP_DELAY)

# 隐藏工具提示
func hide_tooltip() -> void:
	# 停止计时器
	delay_timer.stop()
	
	# 隐藏当前提示
	if current_tooltip and is_instance_valid(current_tooltip):
		current_tooltip.queue_free()
		current_tooltip = null
		
		# 发送信号
		if current_target and is_instance_valid(current_target):
			tooltip_hidden.emit(current_target)
	
	current_target = null

# 创建工具提示
func _create_tooltip() -> void:
	if not current_target or not is_instance_valid(current_target):
		return
	
	# 检查是否有自定义构建器
	if current_target.has_meta("tooltip_builder"):
		var builder = current_target.get_meta("tooltip_builder")
		if builder is Callable:
			current_tooltip = builder.call()
			if current_tooltip:
				_setup_tooltip()
				return
	
	# 检查是否有提示文本
	if current_target.has_meta("tooltip_text"):
		var tooltip_text = current_target.get_meta("tooltip_text")
		if tooltip_text is String and not tooltip_text.is_empty():
			current_tooltip = _create_default_tooltip(tooltip_text)
			_setup_tooltip()
			return
	
	# 使用控件的默认提示文本
	if not current_target.tooltip_text.is_empty():
		current_tooltip = _create_default_tooltip(current_target.tooltip_text)
		_setup_tooltip()

# 设置工具提示
func _setup_tooltip() -> void:
	if not current_tooltip or not is_instance_valid(current_tooltip):
		return
	
	# 添加到场景
	add_child(current_tooltip)
	
	# 设置位置
	_update_tooltip_position()
	
	# 发送信号
	tooltip_shown.emit(current_target)

# 更新工具提示位置
func _update_tooltip_position() -> void:
	if not current_tooltip or not is_instance_valid(current_tooltip):
		return
	
	# 计算位置
	var position = mouse_position + TOOLTIP_OFFSET
	
	# 确保提示框不超出屏幕
	var viewport_size = get_viewport().size
	var tooltip_size = current_tooltip.size
	
	if position.x + tooltip_size.x > viewport_size.x:
		position.x = viewport_size.x - tooltip_size.x
	
	if position.y + tooltip_size.y > viewport_size.y:
		position.y = viewport_size.y - tooltip_size.y
	
	current_tooltip.position = position

# 创建默认工具提示
func _create_default_tooltip(text: String) -> Control:
	var tooltip = Panel.new()
	tooltip.name = "Tooltip"
	
	# 设置样式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.border_color = Color(0.5, 0.5, 0.5, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	
	tooltip.add_theme_stylebox_override("panel", style)
	
	# 创建边距容器
	var margin = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	
	# 创建标签
	var label = Label.new()
	label.name = "Label"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# 添加到容器
	margin.add_child(label)
	tooltip.add_child(margin)
	
	return tooltip

# 延迟计时器超时处理
func _on_delay_timer_timeout() -> void:
	_create_tooltip()

# 控件鼠标进入处理
func _on_control_mouse_entered(control: Control) -> void:
	show_tooltip(control)

# 控件鼠标离开处理
func _on_control_mouse_exited(control: Control) -> void:
	if current_target == control:
		hide_tooltip()

# GUI焦点变化处理
func _on_gui_focus_changed(control: Control) -> void:
	if current_target and current_target != control:
		hide_tooltip()
