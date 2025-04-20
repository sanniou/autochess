extends "res://scripts/managers/core/base_manager.gd"
class_name ThemeManager
## 主题样式管理器
## 负责管理游戏中的UI主题和样式

# 信号
signal theme_changed(theme_name: String)

# 常量
const DEFAULT_THEME = "default"
const THEME_PATH = "res://themes/"

# 主题类型
enum ThemeType { LIGHT, DARK, CUSTOM }

# 当前主题
var current_theme: String = DEFAULT_THEME

# 当前主题类型
var current_theme_type: ThemeType = ThemeType.LIGHT

# 主题缓存
var theme_cache: Dictionary = {}

# 主题颜色
var theme_colors: Dictionary = {
	"light": {
		"background": Color(0.95, 0.95, 0.95),
		"panel": Color(1, 1, 1),
		"text": Color(0.1, 0.1, 0.1),
		"primary": Color(0.2, 0.4, 0.8),
		"secondary": Color(0.5, 0.5, 0.5),
		"success": Color(0.2, 0.8, 0.2),
		"warning": Color(0.9, 0.7, 0.1),
		"danger": Color(0.8, 0.2, 0.2)
	},
	"dark": {
		"background": Color(0.15, 0.15, 0.15),
		"panel": Color(0.2, 0.2, 0.2),
		"text": Color(0.9, 0.9, 0.9),
		"primary": Color(0.3, 0.5, 0.9),
		"secondary": Color(0.6, 0.6, 0.6),
		"success": Color(0.3, 0.9, 0.3),
		"warning": Color(1, 0.8, 0.2),
		"danger": Color(0.9, 0.3, 0.3)
	}
}

# 主题字体大小
var theme_font_sizes: Dictionary = {
	"title": 24,
	"subtitle": 20,
	"body": 16,
	"small": 14,
	"tiny": 12
}

# 主题边距
var theme_margins: Dictionary = {
	"small": 5,
	"medium": 10,
	"large": 20
}

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "ThemeManager"

	# 加载默认主题
	load_theme(DEFAULT_THEME)

	# 连接信号
	EventBus.ui.connect_event("theme_changed", _on_theme_changed)

# 加载主题
func load_theme(theme_name: String) -> void:
	# 检查主题缓存
	if theme_cache.has(theme_name):
		_apply_theme(theme_cache[theme_name])
		current_theme = theme_name
		theme_changed.emit(theme_name)
		return

	# 构建主题路径
	var theme_path = THEME_PATH + theme_name + ".tres"

	# 检查主题是否存在
	if not ResourceLoader.exists(theme_path):
		EventBus.debug.emit_event("debug_message", ["主题不存在: " + theme_path, 1])
		return

	# 加载主题
	var theme = ResourceLoader.load(theme_path)
	if theme == null:
		EventBus.debug.emit_event("debug_message", ["无法加载主题: " + theme_path, 1])
		return

	# 缓存主题
	theme_cache[theme_name] = theme

	# 应用主题
	_apply_theme(theme)

	# 更新当前主题
	current_theme = theme_name

	# 发送信号
	theme_changed.emit(theme_name)

# 应用主题
func _apply_theme(theme: Theme) -> void:
	# 设置全局主题
	get_tree().root.theme = theme

# 主题变化处理
func _on_theme_changed(theme_name: String) -> void:
	load_theme(theme_name)

# 获取当前主题
func get_current_theme() -> String:
	return current_theme

# 获取当前主题类型
func get_current_theme_type() -> ThemeType:
	return current_theme_type

# 获取主题对象
func get_theme_object(theme_name: String = "") -> Theme:
	if theme_name.is_empty():
		theme_name = current_theme

	if theme_cache.has(theme_name):
		return theme_cache[theme_name]

	return null

# 获取颜色
func get_color(color_name: String) -> Color:
	var theme_key = "light" if current_theme_type == ThemeType.LIGHT else "dark"
	return theme_colors[theme_key].get(color_name, Color(1, 1, 1))

# 获取字体大小
func get_font_size(size_name: String) -> int:
	return theme_font_sizes.get(size_name, 16)

# 获取边距
func get_margin(margin_name: String) -> int:
	return theme_margins.get(margin_name, 10)

# 设置主题类型
func set_theme_type(theme_type: ThemeType) -> void:
	current_theme_type = theme_type
	_apply_theme_type()

	# 发送信号
	theme_changed.emit(current_theme)

# 应用主题类型
func _apply_theme_type() -> void:
	# 创建主题
	var theme = create_theme_from_type(current_theme_type)

	# 应用主题
	_apply_theme(theme)

# 根据主题类型创建主题
func create_theme_from_type(theme_type: ThemeType) -> Theme:
	var theme = Theme.new()

	# 获取主题颜色
	var colors = theme_colors["light"] if theme_type == ThemeType.LIGHT else theme_colors["dark"]

	# 设置默认字体
	theme.default_font_size = theme_font_sizes["body"]

	# 设置按钮样式
	var button_normal_style = StyleBoxFlat.new()
	button_normal_style.bg_color = colors["primary"]
	button_normal_style.border_width_left = 0
	button_normal_style.border_width_top = 0
	button_normal_style.border_width_right = 0
	button_normal_style.border_width_bottom = 0
	button_normal_style.corner_radius_top_left = 4
	button_normal_style.corner_radius_top_right = 4
	button_normal_style.corner_radius_bottom_left = 4
	button_normal_style.corner_radius_bottom_right = 4

	var button_hover_style = StyleBoxFlat.new()
	button_hover_style.bg_color = colors["primary"].lightened(0.1)
	button_hover_style.border_width_left = 0
	button_hover_style.border_width_top = 0
	button_hover_style.border_width_right = 0
	button_hover_style.border_width_bottom = 0
	button_hover_style.corner_radius_top_left = 4
	button_hover_style.corner_radius_top_right = 4
	button_hover_style.corner_radius_bottom_left = 4
	button_hover_style.corner_radius_bottom_right = 4

	var button_pressed_style = StyleBoxFlat.new()
	button_pressed_style.bg_color = colors["primary"].darkened(0.1)
	button_pressed_style.border_width_left = 0
	button_pressed_style.border_width_top = 0
	button_pressed_style.border_width_right = 0
	button_pressed_style.border_width_bottom = 0
	button_pressed_style.corner_radius_top_left = 4
	button_pressed_style.corner_radius_top_right = 4
	button_pressed_style.corner_radius_bottom_left = 4
	button_pressed_style.corner_radius_bottom_right = 4

	theme.set_stylebox("normal", "Button", button_normal_style)
	theme.set_stylebox("hover", "Button", button_hover_style)
	theme.set_stylebox("pressed", "Button", button_pressed_style)
	theme.set_color("font_color", "Button", colors["text"])
	theme.set_color("font_hover_color", "Button", colors["text"])
	theme.set_color("font_pressed_color", "Button", colors["text"])

	# 设置面板样式
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = colors["panel"]
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = colors["secondary"]
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4

	theme.set_stylebox("panel", "Panel", panel_style)

	# 设置标签样式
	theme.set_color("font_color", "Label", colors["text"])

	# 设置滑动条样式
	var slider_style = StyleBoxFlat.new()
	slider_style.bg_color = colors["secondary"]
	slider_style.corner_radius_top_left = 2
	slider_style.corner_radius_top_right = 2
	slider_style.corner_radius_bottom_left = 2
	slider_style.corner_radius_bottom_right = 2

	theme.set_stylebox("slider", "HSlider", slider_style)

	return theme

# 创建默认主题
func create_default_theme() -> Theme:
	return create_theme_from_type(ThemeType.LIGHT)

# 创建样式盒
func create_stylebox(color_name: String, corner_radius: int = 4, border_width: int = 0, border_color_name: String = "") -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	var theme_key = "light" if current_theme_type == ThemeType.LIGHT else "dark"
	var colors = theme_colors[theme_key]

	style.bg_color = colors.get(color_name, Color(1, 1, 1))

	# 设置圆角
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius

	# 设置边框
	if border_width > 0:
		style.border_width_left = border_width
		style.border_width_top = border_width
		style.border_width_right = border_width
		style.border_width_bottom = border_width

		if border_color_name != "":
			style.border_color = colors.get(border_color_name, Color(0.5, 0.5, 0.5))

	return style

# 应用主题到控件
func apply_theme_to_control(control: Control) -> void:
	# 根据控件类型应用不同的主题
	if control is Button:
		_apply_theme_to_button(control)
	elif control is Label:
		_apply_theme_to_label(control)
	elif control is Panel:
		_apply_theme_to_panel(control)
	elif control is LineEdit:
		_apply_theme_to_line_edit(control)
	elif control is TextEdit:
		_apply_theme_to_text_edit(control)
	elif control is OptionButton:
		_apply_theme_to_option_button(control)
	elif control is CheckBox:
		_apply_theme_to_check_box(control)
	elif control is HSlider:
		_apply_theme_to_slider(control)

	# 递归应用主题到子控件
	for child in control.get_children():
		if child is Control:
			apply_theme_to_control(child)

# 应用主题到按钮
func _apply_theme_to_button(button: Button) -> void:
	button.add_theme_color_override("font_color", get_color("text"))
	button.add_theme_color_override("font_hover_color", get_color("text"))
	button.add_theme_stylebox_override("normal", create_stylebox("primary"))
	button.add_theme_stylebox_override("hover", create_stylebox("primary", 4, 0, ""))
	button.add_theme_stylebox_override("pressed", create_stylebox("primary", 4, 0, ""))

# 应用主题到标签
func _apply_theme_to_label(label: Label) -> void:
	label.add_theme_color_override("font_color", get_color("text"))

# 应用主题到面板
func _apply_theme_to_panel(panel: Panel) -> void:
	panel.add_theme_stylebox_override("panel", create_stylebox("panel", 4, 1, "secondary"))

# 应用主题到行编辑
func _apply_theme_to_line_edit(line_edit: LineEdit) -> void:
	line_edit.add_theme_color_override("font_color", get_color("text"))
	line_edit.add_theme_stylebox_override("normal", create_stylebox("panel", 4, 1, "secondary"))

# 应用主题到文本编辑
func _apply_theme_to_text_edit(text_edit: TextEdit) -> void:
	text_edit.add_theme_color_override("font_color", get_color("text"))
	text_edit.add_theme_stylebox_override("normal", create_stylebox("panel", 4, 1, "secondary"))

# 应用主题到选项按钮
func _apply_theme_to_option_button(option_button: OptionButton) -> void:
	option_button.add_theme_color_override("font_color", get_color("text"))
	option_button.add_theme_stylebox_override("normal", create_stylebox("panel", 4, 1, "secondary"))

# 应用主题到复选框
func _apply_theme_to_check_box(check_box: CheckBox) -> void:
	check_box.add_theme_color_override("font_color", get_color("text"))

# 应用主题到滑动条
func _apply_theme_to_slider(slider: HSlider) -> void:
	slider.add_theme_stylebox_override("slider", create_stylebox("primary", 2))

# 保存主题
func save_theme(theme_name: String, theme: Theme) -> void:
	# 构建主题路径
	var theme_path = THEME_PATH + theme_name + ".tres"

	# 保存主题
	var err = ResourceSaver.save(theme, theme_path)
	if err != OK:
		EventBus.debug.emit_event("debug_message", ["无法保存主题: " + theme_path + ", 错误: " + str(err), 1])
		return

	# 缓存主题
	theme_cache[theme_name] = theme

# 记录错误信息
func _log_error(error_message: String) -> void:
	_error = error_message
	EventBus.debug.emit_event("debug_message", [error_message, 2])
	error_occurred.emit(error_message)

# 记录警告信息
func _log_warning(warning_message: String) -> void:
	EventBus.debug.emit_event("debug_message", [warning_message, 1])

# 记录信息
func _log_info(info_message: String) -> void:
	EventBus.debug.emit_event("debug_message", [info_message, 0])
