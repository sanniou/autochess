extends Node
class_name ThemeManager
## 主题样式管理器
## 负责管理游戏中的UI主题和样式

# 信号
signal theme_changed(theme_name: String)

# 常量
const DEFAULT_THEME = "default"
const THEME_PATH = "res://themes/"

# 当前主题
var current_theme: String = DEFAULT_THEME

# 主题缓存
var theme_cache: Dictionary = {}

# 引用
@onready var config_manager = get_node("/root/ConfigManager")

# 初始化
func _ready() -> void:
	# 加载默认主题
	load_theme(DEFAULT_THEME)
	
	# 连接信号
	EventBus.theme_changed.connect(_on_theme_changed)

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
		EventBus.debug_message.emit("主题不存在: " + theme_path, 1)
		return
	
	# 加载主题
	var theme = ResourceLoader.load(theme_path)
	if theme == null:
		EventBus.debug_message.emit("无法加载主题: " + theme_path, 1)
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

# 获取主题对象
func get_theme_object(theme_name: String = "") -> Theme:
	if theme_name.is_empty():
		theme_name = current_theme
	
	if theme_cache.has(theme_name):
		return theme_cache[theme_name]
	
	return null

# 创建默认主题
func create_default_theme() -> Theme:
	var theme = Theme.new()
	
	# 设置默认字体
	var default_font = FontFile.new()
	theme.default_font = default_font
	theme.default_font_size = 16
	
	# 设置按钮样式
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.2, 0.2, 1.0)
	button_style.border_width_left = 2
	button_style.border_width_top = 2
	button_style.border_width_right = 2
	button_style.border_width_bottom = 2
	button_style.border_color = Color(0.8, 0.8, 0.8, 1.0)
	button_style.corner_radius_top_left = 4
	button_style.corner_radius_top_right = 4
	button_style.corner_radius_bottom_left = 4
	button_style.corner_radius_bottom_right = 4
	
	theme.set_stylebox("normal", "Button", button_style)
	
	# 设置面板样式
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(0.5, 0.5, 0.5, 1.0)
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	
	theme.set_stylebox("panel", "Panel", panel_style)
	
	return theme

# 保存主题
func save_theme(theme_name: String, theme: Theme) -> void:
	# 构建主题路径
	var theme_path = THEME_PATH + theme_name + ".tres"
	
	# 保存主题
	var err = ResourceSaver.save(theme, theme_path)
	if err != OK:
		EventBus.debug_message.emit("无法保存主题: " + theme_path + ", 错误: " + str(err), 1)
		return
	
	# 缓存主题
	theme_cache[theme_name] = theme
