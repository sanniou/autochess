extends Node
## 通用工具类
## 提供文本处理、UI创建和其他通用功能
## 使用单例模式实现，避免静态方法和全局变量

# 文本截断模式
enum TruncateMode {
	NONE,       # 不截断
	END,        # 在末尾截断
	MIDDLE,     # 在中间截断
	START       # 在开头截断
}

# 文本对齐方式
enum TextAlignment {
	LEFT,       # 左对齐
	CENTER,     # 居中对齐
	RIGHT       # 右对齐
}

# 文本方向
enum TextDirection {
	LTR,        # 从左到右
	RTL         # 从右到左
}

# 引用
var localization_manager = null
var font_manager = null

# 初始化状态
var _initialized: bool = false

## 初始化
func _ready() -> void:
	# 初始化工具类
	initialize()

## 初始化
func initialize() -> void:
	if _initialized:
		return

	# 尝试获取单例
	localization_manager = get_node_or_null("/root/LocalizationManager")

	font_manager = get_node_or_null("/root/FontManager")

	_initialized = true
	GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("Utils 初始化完成", 0))

#region 文本工具函数

## 获取本地化文本
func translate(key: String, params: Array = []) -> String:
	# 如果有本地化管理器，使用它
	if localization_manager and localization_manager.has_method("translate"):
		return localization_manager.translate(key, params)

	# 如果没有本地化管理器，直接返回原始文本
	return key

## 截断文本
func truncate_text(text: String, max_length: int, mode: int = TruncateMode.END, ellipsis: String = "...") -> String:
	if text.length() <= max_length:
		return text

	match mode:
		TruncateMode.END:
			return text.substr(0, max_length - ellipsis.length()) + ellipsis
		TruncateMode.MIDDLE:
			var half_length = (max_length - ellipsis.length()) / 2
			return text.substr(0, half_length) + ellipsis + text.substr(text.length() - half_length)
		TruncateMode.START:
			return ellipsis + text.substr(text.length() - (max_length - ellipsis.length()))
		_:
			return text

## 获取文本宽度
func get_text_width(text: String, font: Font = null, font_size: int = 16) -> float:
	if font == null and font_manager:
		font = font_manager.get_font()

	if font == null:
		return text.length() * font_size * 0.5

	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

## 获取文本高度
func get_text_height(text: String, font: Font = null, font_size: int = 16, width: float = -1) -> float:
	if font == null and font_manager:
		font = font_manager.get_font()

	if font == null:
		return font_size

	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size).y

## 自动调整文本大小以适应容器
func auto_fit_text(label: Label, min_size: int = 10, max_size: int = 32, step: int = 2) -> void:
	if label == null:
		return

	var original_text = label.text
	var container_width = label.size.x
	var container_height = label.size.y
	var font = label.get_theme_font("font")

	if font == null and font_manager:
		font = font_manager.get_font()

	if font == null:
		return

	var current_size = max_size
	while current_size >= min_size:
		var text_size = font.get_string_size(original_text, HORIZONTAL_ALIGNMENT_LEFT, -1, current_size)

		if text_size.x <= container_width and text_size.y <= container_height:
			label.add_theme_font_size_override("font_size", current_size)
			return

		current_size -= step

	# 如果无法适应，使用最小字体大小
	label.add_theme_font_size_override("font_size", min_size)

## 格式化数字（添加千位分隔符）
func format_number(number: float, decimals: int = 0) -> String:
	var result = ""
	var str_number = str(snappedf(number, pow(0.1, decimals)))

	# 分离整数部分和小数部分
	var parts = str_number.split(".")
	var int_part = parts[0]
	var dec_part = parts[1] if parts.size() > 1 else ""

	# 处理负号
	var negative = false
	if int_part.begins_with("-"):
		negative = true
		int_part = int_part.substr(1)

	# 添加千位分隔符
	var i = int_part.length() - 3
	while i > 0:
		result = "," + int_part.substr(i, 3) + result
		i -= 3
	result = int_part.substr(0, i + 3) + result

	# 添加小数部分
	if decimals > 0:
		result += "."
		# 确保小数部分有正确的位数
		while dec_part.length() < decimals:
			dec_part += "0"
		result += dec_part.substr(0, decimals)

	# 添加负号
	if negative:
		result = "-" + result

	return result

## 格式化时间（将秒转换为时:分:秒格式）
func format_time(seconds: float) -> String:
	var hours = int(seconds / 3600)
	var remainder = int(seconds) % 3600
	var minutes = remainder / 60
	var secs = remainder % 60

	if hours > 0:
		return str(hours) + ":" + str(minutes).pad_zeros(2) + ":" + str(secs).pad_zeros(2)
	else:
		return str(minutes).pad_zeros(2) + ":" + str(secs).pad_zeros(2)

## 格式化日期时间
func format_datetime(unix_time: int) -> String:
	var datetime = Time.get_datetime_dict_from_unix_time(unix_time)
	var year_str = str(datetime.year).pad_zeros(4)
	var month_str = str(datetime.month).pad_zeros(2)
	var day_str = str(datetime.day).pad_zeros(2)
	var hour_str = str(datetime.hour).pad_zeros(2)
	var minute_str = str(datetime.minute).pad_zeros(2)
	var second_str = str(datetime.second).pad_zeros(2)
	return year_str + "-" + month_str + "-" + day_str + " " + hour_str + ":" + minute_str + ":" + second_str

## 获取文本的显示宽度（考虑不同字符宽度）
func get_display_width(text: String, font: Font = null, font_size: int = 16) -> float:
	if font == null and font_manager:
		font = font_manager.get_font()

	if font == null:
		# 如果没有字体，使用估计值
		var width = 0.0
		for c in text:
			# 中文字符和全角符号通常是英文字符的两倍宽
			if (c.unicode_at(0) >= 0x4E00 and c.unicode_at(0) <= 0x9FFF) or (c.unicode_at(0) >= 0xFF00 and c.unicode_at(0) <= 0xFFEF):    # 中文字符范围和全角符号范围
				width += font_size
			else:
				width += font_size * 0.5
		return width

	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

## 检查文本是否包含中文字符
func contains_chinese(text: String) -> bool:
	for c in text:
		if c.unicode_at(0) >= 0x4E00 and c.unicode_at(0) <= 0x9FFF:
			return true
	return false

## 检查文本是否包含日文字符
func contains_japanese(text: String) -> bool:
	for c in text:
		# 平假名、片假名和日文汉字范围
		if (c.unicode_at(0) >= 0x3040 and c.unicode_at(0) <= 0x309F) or (c.unicode_at(0) >= 0x30A0 and c.unicode_at(0) <= 0x30FF) or (c.unicode_at(0) >= 0x4E00 and c.unicode_at(0) <= 0x9FFF):    # 平假名、片假名和汉字
			return true
	return false

## 检查文本是否包含韩文字符
func contains_korean(text: String) -> bool:
	for c in text:
		# 韩文字符范围
		if (c.unicode_at(0) >= 0xAC00 and c.unicode_at(0) <= 0xD7A3) or (c.unicode_at(0) >= 0x1100 and c.unicode_at(0) <= 0x11FF):    # 韩文音节和韩文字母
			return true
	return false

## 检测文本语言
func detect_text_language(text: String) -> String:
	if contains_chinese(text):
		return "zh_CN"
	if contains_japanese(text):
		return "ja_JP"
	if contains_korean(text):
		return "ko_KR"
	return "en_US"  # 默认为英文

## 设置文本方向
func set_text_direction(control: Control, direction: int = TextDirection.LTR) -> void:
	if control is Label or control is RichTextLabel:
		match direction:
			TextDirection.RTL:
				control.text_direction = TextServer.DIRECTION_RTL
			_:
				control.text_direction = TextServer.DIRECTION_LTR

#endregion

#region UI工具函数

## 创建标签
func create_label(text: String, font_size: int = 16, color: Color = Color.WHITE, alignment: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment

	# 应用字体
	if font_manager:
		font_manager.apply_font_to_label(label)

	return label

## 创建带有自动换行的标签
func create_autowrap_label(text: String, font_size: int = 16, color: Color = Color.WHITE, alignment: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	if font_manager:
		font_manager.apply_font_to_label(label)

	return label

## 创建按钮
func create_button(text: String, font_size: int = 16, color: Color = Color.WHITE, size: Vector2 = Vector2(120, 40)) -> Button:
	var button = Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", color)
	button.custom_minimum_size = size

	# 应用字体
	if font_manager:
		font_manager.apply_font_to_button(button)

	return button

## 创建图标按钮
func create_icon_button(icon_path: String, size: Vector2 = Vector2(40, 40)) -> Button:
	var button = Button.new()
	button.custom_minimum_size = size

	if ResourceLoader.exists(icon_path):
		var texture = load(icon_path)
		button.icon = texture

	return button

## 创建面板
func create_panel(size: Vector2 = Vector2(200, 200), color: Color = Color(0.2, 0.2, 0.2, 0.8)) -> Panel:
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

## 创建分隔线
func create_separator(horizontal: bool = true, color: Color = Color(0.5, 0.5, 0.5, 1.0), thickness: int = 1) -> Control:
	var separator = Control.new()

	if horizontal:
		separator.custom_minimum_size = Vector2(0, thickness)
	else:
		separator.custom_minimum_size = Vector2(thickness, 0)

	var style = StyleBoxFlat.new()
	style.bg_color = color

	separator.add_theme_stylebox_override("panel", style)

	return separator

## 创建滚动容器
func create_scroll_container(size: Vector2 = Vector2(200, 200)) -> ScrollContainer:
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	return scroll

## 创建网格容器
func create_grid_container(columns: int = 3, h_separation: int = 10, v_separation: int = 10) -> GridContainer:
	var grid = GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", h_separation)
	grid.add_theme_constant_override("v_separation", v_separation)

	return grid

## 创建水平容器
func create_hbox_container(separation: int = 10) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", separation)

	return hbox

## 创建垂直容器
func create_vbox_container(separation: int = 10) -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", separation)

	return vbox

## 创建进度条
func create_progress_bar(value: float = 0.0, max_value: float = 100.0, size: Vector2 = Vector2(200, 20), color: Color = Color(0.2, 0.6, 0.2, 1.0)) -> ProgressBar:
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

## 创建纹理矩形
func create_texture_rect(texture_path: String, size: Vector2 = Vector2(100, 100), expand_mode: int = TextureRect.EXPAND_IGNORE_SIZE) -> TextureRect:
	var texture_rect = TextureRect.new()
	texture_rect.custom_minimum_size = size
	texture_rect.expand_mode = expand_mode
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	if ResourceLoader.exists(texture_path):
		var texture = load(texture_path)
		texture_rect.texture = texture

	return texture_rect

## 创建富文本标签
func create_rich_text_label(bbcode_text: String, size: Vector2 = Vector2(200, 100)) -> RichTextLabel:
	var rich_text = RichTextLabel.new()
	rich_text.custom_minimum_size = size
	rich_text.bbcode_enabled = true
	rich_text.text = bbcode_text

	# 应用字体
	if font_manager:
		font_manager.apply_font_to_rich_text_label(rich_text)

	return rich_text

## 创建带有自动换行的富文本标签
func create_autowrap_rich_text_label(bbcode_text: String, font_size: int = 16) -> RichTextLabel:
	var rich_text = RichTextLabel.new()
	rich_text.bbcode_enabled = true
	rich_text.text = bbcode_text
	rich_text.add_theme_font_size_override("normal_font_size", font_size)
	rich_text.fit_content = true
	rich_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	if font_manager:
		font_manager.apply_font_to_rich_text_label(rich_text)

	return rich_text

## 创建行编辑
func create_line_edit(placeholder_text: String = "", size: Vector2 = Vector2(200, 30)) -> LineEdit:
	var line_edit = LineEdit.new()
	line_edit.custom_minimum_size = size
	line_edit.placeholder_text = placeholder_text

	return line_edit

## 创建复选框
func create_check_box(text: String, checked: bool = false) -> CheckBox:
	var check_box = CheckBox.new()
	check_box.text = text
	check_box.button_pressed = checked

	return check_box

## 创建选项按钮
func create_option_button(options: Array, selected_index: int = 0) -> OptionButton:
	var option_button = OptionButton.new()

	for i in range(options.size()):
		var option = options[i]
		option_button.add_item(option, i)

	if selected_index >= 0 and selected_index < options.size():
		option_button.select(selected_index)

	return option_button

## 创建滑块
func create_slider(value: float = 0.0, min_value: float = 0.0, max_value: float = 100.0, size: Vector2 = Vector2(200, 20), horizontal: bool = true) -> Slider:
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

## 创建旋转器
func create_spin_box(value: float = 0.0, min_value: float = 0.0, max_value: float = 100.0, step: float = 1.0) -> SpinBox:
	var spin_box = SpinBox.new()
	spin_box.min_value = min_value
	spin_box.max_value = max_value
	spin_box.value = value
	spin_box.step = step

	return spin_box

## 创建标签容器
func create_tab_container() -> TabContainer:
	var tab_container = TabContainer.new()

	return tab_container

## 创建颜色矩形
func create_color_rect(color: Color = Color.WHITE, size: Vector2 = Vector2(100, 100)) -> ColorRect:
	var color_rect = ColorRect.new()
	color_rect.custom_minimum_size = size
	color_rect.color = color

	return color_rect

## 设置控件锚点和边距
func set_anchors_and_margins(control: Control, preset: int, margins: Vector4 = Vector4(0, 0, 0, 0)) -> void:
	control.set_anchors_preset(preset)

	if preset == Control.PRESET_FULL_RECT:
		control.set_margin(SIDE_LEFT, margins.x)
		control.set_margin(SIDE_TOP, margins.y)
		control.set_margin(SIDE_RIGHT, margins.z)
		control.set_margin(SIDE_BOTTOM, margins.w)

## 设置控件提示
func set_tooltip(control: Control, tooltip_text: String) -> void:
	control.tooltip_text = tooltip_text

## 设置控件焦点模式
func set_focus_mode(control: Control, focus_mode: int) -> void:
	control.focus_mode = focus_mode

## 设置控件鼠标过滤模式
func set_mouse_filter(control: Control, mouse_filter: int) -> void:
	control.mouse_filter = mouse_filter

## 设置控件大小标志
func set_size_flags(control: Control, horizontal: int, vertical: int) -> void:
	control.size_flags_horizontal = horizontal
	control.size_flags_vertical = vertical

## 设置控件自定义最小大小
func set_custom_minimum_size(control: Control, size: Vector2) -> void:
	control.custom_minimum_size = size

#endregion
