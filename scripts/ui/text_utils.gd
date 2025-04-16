extends Node
class_name TextUtils
## 文本工具类
## 提供文本处理和显示相关的工具函数

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
static var localization_manager = null
static var font_manager = null

## 初始化
static func initialize() -> void:
	# 尝试获取单例
	localization_manager = Engine.get_singleton("LocalizationManager")
	if not localization_manager:
		EventBus.debug_message.emit("无法获取LocalizationManager单例", 1)

	font_manager = Engine.get_singleton("FontManager")
	if not font_manager:
		EventBus.debug_message.emit("无法获取FontManager单例", 1)

## 获取本地化文本
static func translate(key: String, params: Array = []) -> String:
	# 如果有本地化管理器，使用它
	if localization_manager and localization_manager.has_method("translate"):
		return localization_manager.translate(key, params)

	# 如果没有本地化管理器，直接返回原始文本
	return key

## 截断文本
static func truncate_text(text: String, max_length: int, mode: int = TruncateMode.END, ellipsis: String = "...") -> String:
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
static func get_text_width(text: String, font: Font = null, font_size: int = 16) -> float:
	if font == null and font_manager:
		font = font_manager.get_font()

	if font == null:
		return text.length() * font_size * 0.5

	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

## 获取文本高度
static func get_text_height(text: String, font: Font = null, font_size: int = 16, width: float = -1) -> float:
	if font == null and font_manager:
		font = font_manager.get_font()

	if font == null:
		return font_size

	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size).y

## 自动调整文本大小以适应容器
static func auto_fit_text(label: Label, min_size: int = 10, max_size: int = 32, step: int = 2) -> void:
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

## 创建带有自动换行的标签
static func create_autowrap_label(text: String, font_size: int = 16, color: Color = Color.WHITE, alignment: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	if font_manager:
		font_manager.apply_font_to_label(label)

	return label

## 创建带有自动换行的富文本标签
static func create_autowrap_rich_text_label(bbcode_text: String, font_size: int = 16) -> RichTextLabel:
	var rich_text = RichTextLabel.new()
	rich_text.bbcode_enabled = true
	rich_text.text = bbcode_text
	rich_text.add_theme_font_size_override("normal_font_size", font_size)
	rich_text.fit_content = true
	rich_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	if font_manager:
		font_manager.apply_font_to_rich_text_label(rich_text)

	return rich_text

## 设置文本方向
static func set_text_direction(control: Control, direction: int = TextDirection.LTR) -> void:
	if control is Label or control is RichTextLabel:
		match direction:
			TextDirection.RTL:
				control.text_direction = TextServer.DIRECTION_RTL
			_:
				control.text_direction = TextServer.DIRECTION_LTR

## 格式化数字（添加千位分隔符）
static func format_number(number: float, decimals: int = 0) -> String:
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
static func format_time(seconds: float) -> String:
	var hours = int(seconds / 3600)
	var remainder = int(seconds) % 3600
	var minutes = remainder / 60
	var secs = remainder % 60

	if hours > 0:
		return str(hours) + ":" + str(minutes).pad_zeros(2) + ":" + str(secs).pad_zeros(2)
	else:
		return str(minutes).pad_zeros(2) + ":" + str(secs).pad_zeros(2)

## 格式化日期时间
static func format_datetime(unix_time: int) -> String:
	var datetime = Time.get_datetime_dict_from_unix_time(unix_time)
	var year_str = str(datetime.year).pad_zeros(4)
	var month_str = str(datetime.month).pad_zeros(2)
	var day_str = str(datetime.day).pad_zeros(2)
	var hour_str = str(datetime.hour).pad_zeros(2)
	var minute_str = str(datetime.minute).pad_zeros(2)
	var second_str = str(datetime.second).pad_zeros(2)
	return year_str + "-" + month_str + "-" + day_str + " " + hour_str + ":" + minute_str + ":" + second_str

## 获取文本的显示宽度（考虑不同字符宽度）
static func get_display_width(text: String, font: Font = null, font_size: int = 16) -> float:
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
static func contains_chinese(text: String) -> bool:
	for c in text:
		if c.unicode_at(0) >= 0x4E00 and c.unicode_at(0) <= 0x9FFF:
			return true
	return false

## 检查文本是否包含日文字符
static func contains_japanese(text: String) -> bool:
	for c in text:
		# 平假名、片假名和日文汉字范围
		if (c.unicode_at(0) >= 0x3040 and c.unicode_at(0) <= 0x309F) or (c.unicode_at(0) >= 0x30A0 and c.unicode_at(0) <= 0x30FF) or (c.unicode_at(0) >= 0x4E00 and c.unicode_at(0) <= 0x9FFF):    # 平假名、片假名和汉字
			return true
	return false

## 检查文本是否包含韩文字符
static func contains_korean(text: String) -> bool:
	for c in text:
		# 韩文字符范围
		if (c.unicode_at(0) >= 0xAC00 and c.unicode_at(0) <= 0xD7A3) or (c.unicode_at(0) >= 0x1100 and c.unicode_at(0) <= 0x11FF):    # 韩文音节和韩文字母
			return true
	return false

## 检测文本语言
static func detect_text_language(text: String) -> String:
	if contains_chinese(text):
		return "zh_CN"
	if contains_japanese(text):
		return "ja_JP"
	if contains_korean(text):
		return "ko_KR"
	return "en_US"  # 默认为英文
