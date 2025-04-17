extends "res://scripts/managers/core/base_manager.gd"
## 字体管理器
## 负责管理游戏中的字体资源和文本样式

# 信号
signal font_loaded(font_name: String, font: Font)
signal default_font_changed(font_name: String)

# 字体类型
enum FontType {
	REGULAR,    # 常规字体
	BOLD,       # 粗体
	ITALIC,     # 斜体
	BOLD_ITALIC # 粗斜体
}

# 字体大小预设
enum FontSize {
	TINY,       # 极小 (10)
	SMALL,      # 小 (12)
	NORMAL,     # 正常 (16)
	MEDIUM,     # 中等 (20)
	LARGE,      # 大 (24)
	X_LARGE,    # 特大 (32)
	XX_LARGE    # 超大 (48)
}

# 字体大小映射
const FONT_SIZE_MAP = {
	FontSize.TINY: 10,
	FontSize.SMALL: 12,
	FontSize.NORMAL: 16,
	FontSize.MEDIUM: 20,
	FontSize.LARGE: 24,
	FontSize.X_LARGE: 32,
	FontSize.XX_LARGE: 48
}

# 字体路径
const FONT_PATH = "res://assets/fonts/"

# 默认字体
var default_font_regular: Font = null
var default_font_bold: Font = null
var default_font_italic: Font = null
var default_font_bold_italic: Font = null

# 字体缓存
var font_cache: Dictionary = {}

# 当前语言字体
var current_language_fonts: Dictionary = {}

# 引用
var resource_manager = null

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "FontManager"
	# 添加依赖
	add_dependency("ResourceManager")

	# 延迟初始化，确保其他单例已经准备好
	call_deferred("_deferred_init")

	# 调试信息
	EventBus.debug.emit_event("debug_message", ["字体管理器已创建", 0])

## 延迟初始化
func _deferred_init() -> void:
	# 获取引用
	resource_manager = get_node_or_null("/root/ResourceManager")

	# 连接信号
	EventBus.localization.connect_event("language_changed", _on_language_changed)
	EventBus.localization.connect_event("request_font", _on_request_font)
	EventBus.debug.emit_event("debug_message", ["字体管理器已连接到EventBus", 0])

	# 加载默认字体
	_load_default_fonts()

	# 标记初始化完成
	EventBus.debug.emit_event("debug_message", ["字体管理器初始化完成", 0])

## 加载默认字体
func _load_default_fonts() -> void:
	# 获取当前语言
	var language_code = "zh_CN" # 默认使用中文

	# 尝试通过EventBus获取当前语言代码
	EventBus.localization.emit_event("request_language_code", [])
	# 注意：这里我们使用默认值，因为这是异步请求
	# 当LocalizationManager响应请求时，它会发送language_changed信号
	# 我们在_on_language_changed方法中处理语言变化

	# 加载对应语言的字体
	_load_language_fonts(language_code)

	# 设置默认字体
	if current_language_fonts.has(FontType.REGULAR):
		default_font_regular = current_language_fonts[FontType.REGULAR]

	if current_language_fonts.has(FontType.BOLD):
		default_font_bold = current_language_fonts[FontType.BOLD]

	if current_language_fonts.has(FontType.ITALIC):
		default_font_italic = current_language_fonts[FontType.ITALIC]

	if current_language_fonts.has(FontType.BOLD_ITALIC):
		default_font_bold_italic = current_language_fonts[FontType.BOLD_ITALIC]

## 加载语言字体
func _load_language_fonts(language_code: String) -> void:
	# 清除当前语言字体
	current_language_fonts.clear()

	# 根据语言代码加载对应字体
	match language_code:
		"zh_CN":
			current_language_fonts[FontType.REGULAR] = load_font("NotoSansSC-Regular.ttf")
			current_language_fonts[FontType.BOLD] = load_font("NotoSansSC-Bold.ttf")
			current_language_fonts[FontType.ITALIC] = load_font("NotoSansSC-Regular.ttf") # 中文没有斜体，使用常规字体
			current_language_fonts[FontType.BOLD_ITALIC] = load_font("NotoSansSC-Bold.ttf") # 中文没有粗斜体，使用粗体
		"en_US":
			current_language_fonts[FontType.REGULAR] = load_font("NotoSans-Regular.ttf")
			current_language_fonts[FontType.BOLD] = load_font("NotoSans-Bold.ttf")
			current_language_fonts[FontType.ITALIC] = load_font("NotoSans-Italic.ttf")
			current_language_fonts[FontType.BOLD_ITALIC] = load_font("NotoSans-BoldItalic.ttf")
		"ja_JP":
			current_language_fonts[FontType.REGULAR] = load_font("NotoSansJP-Regular.ttf")
			current_language_fonts[FontType.BOLD] = load_font("NotoSansJP-Bold.ttf")
			current_language_fonts[FontType.ITALIC] = load_font("NotoSansJP-Regular.ttf") # 日语没有斜体，使用常规字体
			current_language_fonts[FontType.BOLD_ITALIC] = load_font("NotoSansJP-Bold.ttf") # 日语没有粗斜体，使用粗体
		"ko_KR":
			current_language_fonts[FontType.REGULAR] = load_font("NotoSansKR-Regular.ttf")
			current_language_fonts[FontType.BOLD] = load_font("NotoSansKR-Bold.ttf")
			current_language_fonts[FontType.ITALIC] = load_font("NotoSansKR-Regular.ttf") # 韩语没有斜体，使用常规字体
			current_language_fonts[FontType.BOLD_ITALIC] = load_font("NotoSansKR-Bold.ttf") # 韩语没有粗斜体，使用粗体
		"ru_RU":
			current_language_fonts[FontType.REGULAR] = load_font("NotoSans-Regular.ttf")
			current_language_fonts[FontType.BOLD] = load_font("NotoSans-Bold.ttf")
			current_language_fonts[FontType.ITALIC] = load_font("NotoSans-Italic.ttf")
			current_language_fonts[FontType.BOLD_ITALIC] = load_font("NotoSans-BoldItalic.ttf")
		"zh_TW":
			current_language_fonts[FontType.REGULAR] = load_font("NotoSansTC-Regular.ttf")
			current_language_fonts[FontType.BOLD] = load_font("NotoSansTC-Bold.ttf")
			current_language_fonts[FontType.ITALIC] = load_font("NotoSansTC-Regular.ttf") # 繁体中文没有斜体，使用常规字体
			current_language_fonts[FontType.BOLD_ITALIC] = load_font("NotoSansTC-Bold.ttf") # 繁体中文没有粗斜体，使用粗体
		_:
			# 默认使用英文字体
			current_language_fonts[FontType.REGULAR] = load_font("NotoSans-Regular.ttf")
			current_language_fonts[FontType.BOLD] = load_font("NotoSans-Bold.ttf")
			current_language_fonts[FontType.ITALIC] = load_font("NotoSans-Italic.ttf")
			current_language_fonts[FontType.BOLD_ITALIC] = load_font("NotoSans-BoldItalic.ttf")

## 加载字体
func load_font(font_name: String) -> Font:
	# 检查缓存
	if font_cache.has(font_name):
		return font_cache[font_name]

	# 构建字体路径
	var font_path = FONT_PATH + font_name

	# 检查字体文件是否存在
	if not FileAccess.file_exists(font_path):
		push_error("字体文件不存在: " + font_path)
		return null

	# 加载字体
	var font = FontFile.new()
	var err = font.load_dynamic_font(font_path)
	if err != OK:
		push_error("无法加载字体: " + font_path + ", 错误: " + str(err))
		return null

	# 缓存字体
	font_cache[font_name] = font

	# 发送字体加载信号
	font_loaded.emit(font_name, font)

	return font

## 获取字体
func get_font(font_type: int = FontType.REGULAR) -> Font:
	if current_language_fonts.has(font_type):
		return current_language_fonts[font_type]

	# 如果没有找到对应类型的字体，返回常规字体
	if current_language_fonts.has(FontType.REGULAR):
		return current_language_fonts[FontType.REGULAR]

	# 如果没有找到任何字体，返回默认字体
	return default_font_regular

## 获取字体大小
func get_font_size(size_preset: int = FontSize.NORMAL) -> int:
	if FONT_SIZE_MAP.has(size_preset):
		return FONT_SIZE_MAP[size_preset]

	# 如果没有找到对应的预设，返回正常大小
	return FONT_SIZE_MAP[FontSize.NORMAL]

## 应用字体到控件
func apply_font_to_control(control: Control, font_type: int = FontType.REGULAR, size_preset: int = FontSize.NORMAL) -> void:
	# 获取字体
	var font = get_font(font_type)
	if font == null:
		return

	# 获取字体大小
	var font_size = get_font_size(size_preset)

	# 应用字体
	control.add_theme_font_override("font", font)
	control.add_theme_font_size_override("font_size", font_size)

## 应用字体到标签
func apply_font_to_label(label: Label, font_type: int = FontType.REGULAR, size_preset: int = FontSize.NORMAL) -> void:
	apply_font_to_control(label, font_type, size_preset)

## 应用字体到按钮
func apply_font_to_button(button: Button, font_type: int = FontType.REGULAR, size_preset: int = FontSize.NORMAL) -> void:
	apply_font_to_control(button, font_type, size_preset)

## 应用字体到富文本标签
func apply_font_to_rich_text_label(rich_text: RichTextLabel, font_type: int = FontType.REGULAR, size_preset: int = FontSize.NORMAL) -> void:
	apply_font_to_control(rich_text, font_type, size_preset)

## 创建带字体的标签
func create_label(text: String, font_type: int = FontType.REGULAR, size_preset: int = FontSize.NORMAL, color: Color = Color.WHITE) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)

	# 应用字体
	apply_font_to_label(label, font_type, size_preset)

	return label

## 创建带字体的按钮
func create_button(text: String, font_type: int = FontType.REGULAR, size_preset: int = FontSize.NORMAL, color: Color = Color.WHITE) -> Button:
	var button = Button.new()
	button.text = text
	button.add_theme_color_override("font_color", color)

	# 应用字体
	apply_font_to_button(button, font_type, size_preset)

	return button

## 创建带字体的富文本标签
func create_rich_text_label(bbcode_text: String, font_type: int = FontType.REGULAR, size_preset: int = FontSize.NORMAL) -> RichTextLabel:
	var rich_text = RichTextLabel.new()
	rich_text.bbcode_enabled = true
	rich_text.text = bbcode_text

	# 应用字体
	apply_font_to_rich_text_label(rich_text, font_type, size_preset)

	return rich_text

## 处理语言变更
func _on_language_changed(language_code: String) -> void:
	# 加载新语言的字体
	_load_language_fonts(language_code)

	# 更新默认字体
	if current_language_fonts.has(FontType.REGULAR):
		default_font_regular = current_language_fonts[FontType.REGULAR]
		default_font_changed.emit("regular")

	if current_language_fonts.has(FontType.BOLD):
		default_font_bold = current_language_fonts[FontType.BOLD]
		default_font_changed.emit("bold")

	if current_language_fonts.has(FontType.ITALIC):
		default_font_italic = current_language_fonts[FontType.ITALIC]
		default_font_changed.emit("italic")

	if current_language_fonts.has(FontType.BOLD_ITALIC):
		default_font_bold_italic = current_language_fonts[FontType.BOLD_ITALIC]
		default_font_changed.emit("bold_italic")

## 处理字体请求
func _on_request_font(font_name: String) -> void:
	# 加载并返回请求的字体
	var font = load_font(font_name)
	if font:
		EventBus.localization.emit_event("font_loaded", [font_name, font])
	else:
		EventBus.debug.emit_event("debug_message", ["无法加载字体: " + font_name, 1])

## 确保初始化完成
func ensure_initialized() -> void:
	if not is_initialized():
		_deferred_init()

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
