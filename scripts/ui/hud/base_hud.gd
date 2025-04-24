extends Control
class_name BaseHUD
## 基础HUD类
## 所有HUD组件的基类，提供通用功能

# 信号
signal hud_initialized
signal hud_updated
signal hud_shown
signal hud_hidden
signal hud_input_event(event: InputEvent)

# HUD状态
var is_initialized: bool = false
var is_visible: bool = true
var is_active: bool = true
var is_interactive: bool = true
var hud_name: String = ""
var hud_type: String = "base"
var hud_priority: int = 0
var hud_data: Dictionary = {}

# 动画参数
var animation_speed: float = 1.0
var use_animations: bool = true
var current_animation: String = ""

# 工具类
@onready var utils = get_node_or_null("/root/Utils")

# 初始化
func _ready() -> void:
	# 设置HUD名称
	if hud_name.is_empty():
		hud_name = get_script().resource_path.get_file().get_basename()

	# 连接信号
	GlobalEventBus.game.add_listener("game_paused", _on_game_paused)
	GlobalEventBus.ui.add_listener("theme_changed", _on_theme_changed)
	GlobalEventBus.ui.add_listener("language_changed", _on_language_changed)
	GlobalEventBus.ui.add_listener("scale_changed", _on_scale_changed)

	# 初始化HUD
	_initialize()

# 输入事件处理
func _input(event: InputEvent) -> void:
	if is_active and is_interactive and is_visible:
		_process_input(event)
		hud_input_event.emit(event)

# 处理输入事件
func _process_input(event: InputEvent) -> void:
	# 子类可以重写此方法实现特定的输入处理
	pass

# 初始化HUD
func _initialize() -> void:
	# 子类应该重写此方法
	is_initialized = true

	# 应用当前主题
	_apply_theme()

	# 发送初始化信号
	hud_initialized.emit()

# 更新HUD
func update_hud() -> void:
	# 子类应该重写此方法

	# 发送更新信号
	hud_updated.emit()

# 显示HUD
func show_hud() -> void:
	if not is_visible:
		is_visible = true
		visible = true

		# 播放显示动画
		if use_animations:
			_play_show_animation()

		# 发送显示信号
		hud_shown.emit()

# 隐藏HUD
func hide_hud() -> void:
	if is_visible:
		is_visible = false

		# 播放隐藏动画
		if use_animations:
			_play_hide_animation()
		else:
			visible = false

		# 发送隐藏信号
		hud_hidden.emit()

# 切换HUD可见性
func toggle_hud() -> void:
	if is_visible:
		hide_hud()
	else:
		show_hud()

# 激活HUD
func activate() -> void:
	is_active = true

# 停用HUD
func deactivate() -> void:
	is_active = false

# 设置HUD数据
func set_hud_data(data: Dictionary) -> void:
	hud_data = data
	update_hud()

# 获取HUD数据
func get_hud_data() -> Dictionary:
	return hud_data

# 播放显示动画
func _play_show_animation() -> void:
	# 默认实现，子类可以重写
	modulate.a = 0
	visible = true

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3 / animation_speed).set_ease(Tween.EASE_OUT)

# 播放隐藏动画
func _play_hide_animation() -> void:
	# 默认实现，子类可以重写
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3 / animation_speed).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): visible = false)

# 应用主题
func _apply_theme() -> void:
	# 子类可以重写此方法实现特定的主题应用
	pass

# 游戏暂停处理
func _on_game_paused(paused: bool) -> void:
	# 子类可以重写此方法
	pass

# 主题变化处理
func _on_theme_changed() -> void:
	_apply_theme()

# 语言变化处理
func _on_language_changed() -> void:
	update_hud()

# 缩放变化处理
func _on_scale_changed(scale_factor: float) -> void:
	# 子类可以重写此方法
	pass

# 获取本地化文本
func chess_tr(key: String, params: Array = []) -> String:
	if utils:
		return utils.translate(key, params)
	return GameManager.localization_manager.translate(key, params)

# 播放UI音效
func play_ui_sound(sound_name: String) -> void:
	GameManager.audio_manager.play_ui_sound(sound_name)

# 创建标签
func create_label(text: String, font_size: int = 16, color: Color = Color.WHITE) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

# 创建按钮
func create_button(text: String, callback: Callable) -> Button:
	var button = Button.new()
	button.text = text
	button.pressed.connect(callback)
	return button

# 创建图标
func create_icon(texture_path: String, size: Vector2 = Vector2(32, 32)) -> TextureRect:
	var icon = TextureRect.new()
	icon.texture = load(texture_path)
	icon.custom_minimum_size = size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon
