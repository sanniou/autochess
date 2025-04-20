extends Button
class_name StandardButton
## 标准按钮组件
## 提供统一的按钮样式和行为

# 按钮类型
enum ButtonType { PRIMARY, SECONDARY, DANGER, SUCCESS }

# 当前按钮类型
@export var button_type: ButtonType = ButtonType.PRIMARY

# 是否播放音效
@export var play_sound: bool = true

# 初始化
func _ready() -> void:
	# 设置按钮样式
	_apply_style()
	
	# 连接信号
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)

# 应用样式
func _apply_style() -> void:
	match button_type:
		ButtonType.PRIMARY:
			add_theme_color_override("font_color", Color(1, 1, 1))
			add_theme_color_override("font_hover_color", Color(0.9, 0.9, 1))
			add_theme_stylebox_override("normal", _get_stylebox(Color(0.2, 0.4, 0.8)))
			add_theme_stylebox_override("hover", _get_stylebox(Color(0.3, 0.5, 0.9)))
			add_theme_stylebox_override("pressed", _get_stylebox(Color(0.1, 0.3, 0.7)))
		ButtonType.SECONDARY:
			add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
			add_theme_color_override("font_hover_color", Color(0.1, 0.1, 0.1))
			add_theme_stylebox_override("normal", _get_stylebox(Color(0.8, 0.8, 0.8)))
			add_theme_stylebox_override("hover", _get_stylebox(Color(0.9, 0.9, 0.9)))
			add_theme_stylebox_override("pressed", _get_stylebox(Color(0.7, 0.7, 0.7)))
		ButtonType.DANGER:
			add_theme_color_override("font_color", Color(1, 1, 1))
			add_theme_color_override("font_hover_color", Color(0.9, 0.9, 0.9))
			add_theme_stylebox_override("normal", _get_stylebox(Color(0.8, 0.2, 0.2)))
			add_theme_stylebox_override("hover", _get_stylebox(Color(0.9, 0.3, 0.3)))
			add_theme_stylebox_override("pressed", _get_stylebox(Color(0.7, 0.1, 0.1)))
		ButtonType.SUCCESS:
			add_theme_color_override("font_color", Color(1, 1, 1))
			add_theme_color_override("font_hover_color", Color(0.9, 0.9, 0.9))
			add_theme_stylebox_override("normal", _get_stylebox(Color(0.2, 0.8, 0.2)))
			add_theme_stylebox_override("hover", _get_stylebox(Color(0.3, 0.9, 0.3)))
			add_theme_stylebox_override("pressed", _get_stylebox(Color(0.1, 0.7, 0.1)))

# 获取样式盒
func _get_stylebox(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

# 鼠标进入处理
func _on_mouse_entered() -> void:
	if play_sound:
		AudioManager.play_ui_sound("button_hover.ogg")

# 鼠标退出处理
func _on_mouse_exited() -> void:
	pass

# 按钮点击处理
func _on_pressed() -> void:
	if play_sound:
		AudioManager.play_ui_sound("button_click.ogg")
