extends Node
class_name MapThemeManager
## 地图主题管理器
## 负责管理地图的主题和样式

# 信号
signal theme_changed(theme_id: String)

# 常量
const DEFAULT_THEME = "default"
const THEME_PATH = "res://resources/themes/map/"

# 当前主题
var current_theme: MapTheme = null

# 主题缓存
var theme_cache: Dictionary = {}

# 初始化
func _init() -> void:
	# 加载默认主题
	_load_default_themes()
	
	# 设置当前主题
	set_theme(DEFAULT_THEME)
	
	# 连接信号
	_connect_signals()

# 连接信号
func _connect_signals() -> void:
	# 监听主题变更事件
	GlobalEventBus.ui.add_class_listener(ThemeEvents.MapThemeChangedEvent, _on_map_theme_changed)
	GlobalEventBus.skin.add_class_listener(SkinEvents.UISkinAppliedEvent, _on_ui_skin_applied)

# 加载默认主题
func _load_default_themes() -> void:
	# 创建默认主题
	var default_theme = MapTheme.create_default()
	theme_cache[default_theme.id] = default_theme
	
	# 创建暗色主题
	var dark_theme = MapTheme.create_dark()
	theme_cache[dark_theme.id] = dark_theme
	
	# 创建亮色主题
	var light_theme = MapTheme.create_light()
	theme_cache[light_theme.id] = light_theme

# 加载主题
func load_theme(theme_id: String) -> MapTheme:
	# 检查主题缓存
	if theme_cache.has(theme_id):
		return theme_cache[theme_id]
	
	# 构建主题路径
	var theme_path = THEME_PATH + theme_id + ".tres"
	
	# 检查主题是否存在
	if not ResourceLoader.exists(theme_path):
		print("主题不存在: " + theme_path)
		return null
	
	# 加载主题
	var theme = ResourceLoader.load(theme_path)
	if theme == null:
		print("无法加载主题: " + theme_path)
		return null
	
	# 缓存主题
	theme_cache[theme_id] = theme
	
	return theme

# 设置主题
func set_theme(theme_id: String) -> void:
	# 加载主题
	var theme = load_theme(theme_id)
	if theme == null:
		print("无法设置主题: " + theme_id)
		return
	
	# 设置当前主题
	current_theme = theme
	
	# 发送主题变更事件
	GlobalEventBus.ui.dispatch_event(ThemeEvents.MapThemeChangedEvent.new(
		theme_id,
		theme.node_colors,
		theme.connection_colors,
		theme.background_color
	))
	
	# 发送信号
	theme_changed.emit(theme_id)

# 获取当前主题
func get_current_theme() -> MapTheme:
	return current_theme

# 获取主题
func get_theme(theme_id: String) -> MapTheme:
	return load_theme(theme_id)

# 创建主题
func create_theme(theme_id: String, theme_data: Dictionary) -> MapTheme:
	# 创建主题
	var theme = MapTheme.from_dict(theme_data)
	
	# 缓存主题
	theme_cache[theme_id] = theme
	
	return theme

# 保存主题
func save_theme(theme: MapTheme) -> void:
	# 构建主题路径
	var theme_path = THEME_PATH + theme.id + ".tres"
	
	# 保存主题
	var err = ResourceSaver.save(theme, theme_path)
	if err != OK:
		print("无法保存主题: " + theme_path + ", 错误: " + str(err))
		return
	
	# 缓存主题
	theme_cache[theme.id] = theme

# 主题变更事件处理
func _on_map_theme_changed(event: ThemeEvents.MapThemeChangedEvent) -> void:
	# 如果当前主题ID与事件主题ID相同，则不处理
	if current_theme != null and current_theme.id == event.theme_id:
		return
	
	# 设置主题
	set_theme(event.theme_id)

# UI皮肤应用事件处理
func _on_ui_skin_applied(event: SkinEvents.UISkinAppliedEvent) -> void:
	# 根据UI皮肤调整地图主题
	var skin_id = event.skin_id
	
	# 根据皮肤ID选择合适的地图主题
	var theme_id = DEFAULT_THEME
	
	if skin_id.begins_with("dark"):
		theme_id = "dark"
	elif skin_id.begins_with("light"):
		theme_id = "light"
	
	# 设置主题
	set_theme(theme_id)
