extends Node
class_name UIUtils
## UI工具类
## 提供一些常用的UI操作函数

# 创建标签
static func create_label(text: String, font_size: int = 16, color: Color = Color.WHITE, alignment: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	
	return label

# 创建按钮
static func create_button(text: String, font_size: int = 16, color: Color = Color.WHITE, size: Vector2 = Vector2(120, 40)) -> Button:
	var button = Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", color)
	button.custom_minimum_size = size
	
	return button

# 创建图标按钮
static func create_icon_button(icon_path: String, size: Vector2 = Vector2(40, 40)) -> Button:
	var button = Button.new()
	button.custom_minimum_size = size
	
	if ResourceLoader.exists(icon_path):
		var texture = load(icon_path)
		button.icon = texture
	
	return button

# 创建面板
static func create_panel(size: Vector2 = Vector2(200, 200), color: Color = Color(0.2, 0.2, 0.2, 0.8)) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = size
	
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	
	panel.add_theme_stylebox_override("panel", style)
	
	return panel

# 创建分隔线
static func create_separator(horizontal: bool = true, color: Color = Color(0.5, 0.5, 0.5, 1.0), thickness: int = 1) -> Control:
	var separator = Control.new()
	
	if horizontal:
		separator.custom_minimum_size = Vector2(0, thickness)
	else:
		separator.custom_minimum_size = Vector2(thickness, 0)
	
	var style = StyleBoxFlat.new()
	style.bg_color = color
	
	separator.add_theme_stylebox_override("panel", style)
	
	return separator

# 创建滚动容器
static func create_scroll_container(size: Vector2 = Vector2(200, 200)) -> ScrollContainer:
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	
	return scroll

# 创建网格容器
static func create_grid_container(columns: int = 3, h_separation: int = 10, v_separation: int = 10) -> GridContainer:
	var grid = GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", h_separation)
	grid.add_theme_constant_override("v_separation", v_separation)
	
	return grid

# 创建水平容器
static func create_hbox_container(separation: int = 10) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", separation)
	
	return hbox

# 创建垂直容器
static func create_vbox_container(separation: int = 10) -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", separation)
	
	return vbox

# 创建进度条
static func create_progress_bar(value: float = 0.0, max_value: float = 100.0, size: Vector2 = Vector2(200, 20), color: Color = Color(0.2, 0.6, 0.2, 1.0)) -> ProgressBar:
	var progress = ProgressBar.new()
	progress.value = value
	progress.max_value = max_value
	progress.custom_minimum_size = size
	
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	
	progress.add_theme_stylebox_override("fill", style)
	
	return progress

# 创建纹理矩形
static func create_texture_rect(texture_path: String, size: Vector2 = Vector2(100, 100), expand_mode: int = TextureRect.EXPAND_IGNORE_SIZE) -> TextureRect:
	var texture_rect = TextureRect.new()
	texture_rect.custom_minimum_size = size
	texture_rect.expand_mode = expand_mode
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	if ResourceLoader.exists(texture_path):
		var texture = load(texture_path)
		texture_rect.texture = texture
	
	return texture_rect

# 创建富文本标签
static func create_rich_text_label(bbcode_text: String, size: Vector2 = Vector2(200, 100)) -> RichTextLabel:
	var rich_text = RichTextLabel.new()
	rich_text.custom_minimum_size = size
	rich_text.bbcode_enabled = true
	rich_text.text = bbcode_text
	
	return rich_text

# 创建行编辑
static func create_line_edit(placeholder_text: String = "", size: Vector2 = Vector2(200, 30)) -> LineEdit:
	var line_edit = LineEdit.new()
	line_edit.custom_minimum_size = size
	line_edit.placeholder_text = placeholder_text
	
	return line_edit

# 创建复选框
static func create_check_box(text: String, checked: bool = false) -> CheckBox:
	var check_box = CheckBox.new()
	check_box.text = text
	check_box.button_pressed = checked
	
	return check_box

# 创建选项按钮
static func create_option_button(options: Array, selected_index: int = 0) -> OptionButton:
	var option_button = OptionButton.new()
	
	for i in range(options.size()):
		var option = options[i]
		option_button.add_item(option, i)
	
	if selected_index >= 0 and selected_index < options.size():
		option_button.select(selected_index)
	
	return option_button

# 创建滑块
static func create_slider(value: float = 0.0, min_value: float = 0.0, max_value: float = 100.0, size: Vector2 = Vector2(200, 20), horizontal: bool = true) -> Slider:
	var slider
	
	if horizontal:
		slider = HSlider.new()
	else:
		slider = VSlider.new()
	
	slider.custom_minimum_size = size
	slider.min_value = min_value
	slider.max_value = max_value
	slider.value = value
	
	return slider

# 创建旋转器
static func create_spin_box(value: float = 0.0, min_value: float = 0.0, max_value: float = 100.0, step: float = 1.0) -> SpinBox:
	var spin_box = SpinBox.new()
	spin_box.min_value = min_value
	spin_box.max_value = max_value
	spin_box.value = value
	spin_box.step = step
	
	return spin_box

# 创建标签容器
static func create_tab_container() -> TabContainer:
	var tab_container = TabContainer.new()
	
	return tab_container

# 创建颜色矩形
static func create_color_rect(color: Color = Color.WHITE, size: Vector2 = Vector2(100, 100)) -> ColorRect:
	var color_rect = ColorRect.new()
	color_rect.custom_minimum_size = size
	color_rect.color = color
	
	return color_rect

# 设置控件锚点和边距
static func set_anchors_and_margins(control: Control, preset: int, margins: Vector4 = Vector4(0, 0, 0, 0)) -> void:
	control.set_anchors_preset(preset)
	
	if preset == Control.PRESET_FULL_RECT:
		control.set_margin(SIDE_LEFT, margins.x)
		control.set_margin(SIDE_TOP, margins.y)
		control.set_margin(SIDE_RIGHT, margins.z)
		control.set_margin(SIDE_BOTTOM, margins.w)

# 设置控件提示
static func set_tooltip(control: Control, tooltip_text: String) -> void:
	control.tooltip_text = tooltip_text

# 设置控件焦点模式
static func set_focus_mode(control: Control, focus_mode: int) -> void:
	control.focus_mode = focus_mode

# 设置控件鼠标过滤模式
static func set_mouse_filter(control: Control, mouse_filter: int) -> void:
	control.mouse_filter = mouse_filter

# 设置控件大小标志
static func set_size_flags(control: Control, horizontal: int, vertical: int) -> void:
	control.size_flags_horizontal = horizontal
	control.size_flags_vertical = vertical

# 设置控件自定义最小大小
static func set_custom_minimum_size(control: Control, size: Vector2) -> void:
	control.custom_minimum_size = size
