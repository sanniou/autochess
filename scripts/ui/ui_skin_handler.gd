extends Node
class_name UISkinHandler
## UI皮肤处理器
## 负责处理UI皮肤的应用和预览

# 当前皮肤ID
var current_skin_id: String = "default"
# 原始主题
var original_theme: Theme = null

# 初始化
func _ready() -> void:
	# 保存原始主题
	if get_parent() and get_parent().theme:
		original_theme = get_parent().theme
	
	# 连接事件
	_connect_signals()
	
	# 应用当前皮肤
	_apply_current_skin()

# 连接信号
func _connect_signals() -> void:
	# 监听皮肤变更事件
	GlobalEventBus.skin.add_class_listener(SkinEvents.UISkinAppliedEvent, _on_ui_skin_applied)
	GlobalEventBus.skin.add_class_listener(SkinEvents.UISkinPreviewEvent, _on_ui_skin_preview)

# 应用当前皮肤
func _apply_current_skin() -> void:
	# 获取当前选中的皮肤
	current_skin_id = GameManager.skin_manager.get_selected_skin_id("ui")
	
	# 应用皮肤
	_apply_skin(current_skin_id)

# 应用皮肤
func _apply_skin(skin_id: String) -> void:
	# 获取皮肤数据
	var skin_model = GameManager.skin_manager.get_skin_data(skin_id, "ui")
	if skin_model == null:
		push_error("无法加载UI皮肤: " + skin_id)
		return
	
	# 获取UI主题和颜色方案
	var theme_path = skin_model.get_theme_path()
	var color_scheme = skin_model.get_color_scheme()
	
	# 应用主题和颜色
	_apply_theme(theme_path)
	_apply_color_scheme(color_scheme)

# 应用主题
func _apply_theme(theme_path: String) -> void:
	# 检查父节点
	if not get_parent():
		push_error("UI皮肤处理器没有父节点")
		return
	
	# 加载主题
	var theme = load(theme_path)
	
	if theme == null:
		push_error("无法加载主题: " + theme_path)
		return
	
	# 应用主题
	get_parent().theme = theme

# 应用颜色方案
func _apply_color_scheme(color_scheme: Dictionary) -> void:
	# 检查父节点
	if not get_parent():
		push_error("UI皮肤处理器没有父节点")
		return
	
	# 获取主题
	var theme = get_parent().theme
	if theme == null:
		push_error("UI没有主题")
		return
	
	# 应用颜色
	for color_name in color_scheme:
		var color_value = Color(color_scheme[color_name])
		
		# 设置主题颜色
		match color_name:
			"background":
				_set_theme_color(theme, "background", color_value)
			"panel":
				_set_theme_color(theme, "panel", color_value)
			"text":
				_set_theme_color(theme, "font_color", color_value)
			"primary":
				_set_theme_color(theme, "primary", color_value)
			"secondary":
				_set_theme_color(theme, "secondary", color_value)
			"success":
				_set_theme_color(theme, "success", color_value)
			"warning":
				_set_theme_color(theme, "warning", color_value)
			"danger":
				_set_theme_color(theme, "danger", color_value)

# 设置主题颜色
func _set_theme_color(theme: Theme, color_name: String, color_value: Color) -> void:
	# 设置面板颜色
	if color_name == "panel":
		theme.set_color("panel_bg", "Panel", color_value)
	
	# 设置按钮颜色
	if color_name == "primary":
		theme.set_color("font_color", "Button", color_value)
	
	# 设置标签颜色
	if color_name == "text":
		theme.set_color("font_color", "Label", color_value)
	
	# 设置进度条颜色
	if color_name == "primary":
		theme.set_color("progress_bar_fill", "ProgressBar", color_value)
	
	# 设置滑块颜色
	if color_name == "primary":
		theme.set_color("slider_grab", "Slider", color_value)

# UI皮肤应用事件处理
func _on_ui_skin_applied(event: SkinEvents.UISkinAppliedEvent) -> void:
	# 更新当前皮肤ID
	current_skin_id = event.skin_id
	
	# 应用主题和颜色
	_apply_theme(event.theme_path)
	_apply_color_scheme(event.color_scheme)

# UI皮肤预览事件处理
func _on_ui_skin_preview(event: SkinEvents.UISkinPreviewEvent) -> void:
	# 获取皮肤数据
	var skin_model = GameManager.skin_manager.get_skin_data(event.skin_id, "ui")
	if skin_model == null:
		push_error("无法加载UI皮肤预览: " + event.skin_id)
		return
	
	# 获取UI主题和颜色方案
	var theme_path = skin_model.get_theme_path()
	var color_scheme = skin_model.get_color_scheme()
	
	# 临时应用主题和颜色
	_apply_theme(theme_path)
	_apply_color_scheme(color_scheme)
	
	# 延迟恢复原来的皮肤
	await get_tree().create_timer(2.0).timeout
	_apply_skin(current_skin_id)

# 清理
func _exit_tree() -> void:
	# 断开事件连接
	GlobalEventBus.skin.remove_class_listener(SkinEvents.UISkinAppliedEvent, _on_ui_skin_applied)
	GlobalEventBus.skin.remove_class_listener(SkinEvents.UISkinPreviewEvent, _on_ui_skin_preview)
	
	# 恢复原始主题
	if get_parent() and original_theme:
		get_parent().theme = original_theme
