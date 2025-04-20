extends Control
class_name LabeledSliderComponent
## 带标签的滑动条组件
## 提供统一的滑动条样式和行为

# 信号
signal value_changed(value: float)

# 标签文本
@export var label_text: String = "滑动条":
	set(value):
		label_text = value
		_update_label()

# 最小值
@export var min_value: float = 0:
	set(value):
		min_value = value
		_update_slider_range()

# 最大值
@export var max_value: float = 100:
	set(value):
		max_value = value
		_update_slider_range()

# 步长
@export var step: float = 1:
	set(value):
		step = value
		_update_slider_step()

# 当前值
@export var value: float = 50:
	set(value):
		value = value
		_update_slider_value()

# 是否显示值
@export var show_value: bool = true:
	set(value):
		show_value = value
		_update_value_label()

# 值的格式
@export var value_format: String = "%.0f":
	set(value):
		value_format = value
		_update_value_label()

# 值的后缀
@export var value_suffix: String = "":
	set(value):
		value_suffix = value
		_update_value_label()

# 节点引用
@onready var label = $VBoxContainer/Label
@onready var slider = $VBoxContainer/HBoxContainer/Slider
@onready var value_label = $VBoxContainer/HBoxContainer/ValueLabel

# 初始化
func _ready() -> void:
	# 连接滑动条信号
	if slider:
		slider.value_changed.connect(_on_slider_value_changed)
	
	# 更新UI
	_update_label()
	_update_slider_range()
	_update_slider_step()
	_update_slider_value()
	_update_value_label()

# 更新标签
func _update_label() -> void:
	if label:
		label.text = label_text

# 更新滑动条范围
func _update_slider_range() -> void:
	if slider:
		slider.min_value = min_value
		slider.max_value = max_value

# 更新滑动条步长
func _update_slider_step() -> void:
	if slider:
		slider.step = step

# 更新滑动条值
func _update_slider_value() -> void:
	if slider:
		slider.value = value

# 更新值标签
func _update_value_label() -> void:
	if value_label:
		value_label.visible = show_value
		if show_value:
			value_label.text = value_format % value + value_suffix

# 滑动条值变化处理
func _on_slider_value_changed(new_value: float) -> void:
	value = new_value
	_update_value_label()
	value_changed.emit(new_value)
