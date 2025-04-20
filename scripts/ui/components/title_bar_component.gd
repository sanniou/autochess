extends Control
class_name TitleBarComponent
## 标题栏组件
## 提供统一的标题栏样式和行为

# 信号
signal close_requested

# 标题
@export var title: String = "标题":
	set(value):
		title = value
		_update_title()

# 是否显示关闭按钮
@export var show_close_button: bool = true:
	set(value):
		show_close_button = value
		_update_close_button()

# 标题栏背景颜色
@export var background_color: Color = Color(0.2, 0.2, 0.2):
	set(value):
		background_color = value
		_update_background()

# 标题文本颜色
@export var text_color: Color = Color(1, 1, 1):
	set(value):
		text_color = value
		_update_text_color()

# 节点引用
@onready var background = $Background
@onready var title_label = $HBoxContainer/TitleLabel
@onready var close_button = $HBoxContainer/CloseButton

# 初始化
func _ready() -> void:
	# 连接关闭按钮信号
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	
	# 更新UI
	_update_title()
	_update_close_button()
	_update_background()
	_update_text_color()

# 更新标题
func _update_title() -> void:
	if title_label:
		title_label.text = title

# 更新关闭按钮
func _update_close_button() -> void:
	if close_button:
		close_button.visible = show_close_button

# 更新背景
func _update_background() -> void:
	if background:
		background.color = background_color

# 更新文本颜色
func _update_text_color() -> void:
	if title_label:
		title_label.add_theme_color_override("font_color", text_color)

# 关闭按钮点击处理
func _on_close_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 发送关闭请求信号
	close_requested.emit()
