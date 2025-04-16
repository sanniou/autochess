extends Control
class_name BaseHUD
## 基础HUD类
## 所有HUD组件的基类，提供通用功能

# 信号
signal hud_initialized
signal hud_updated

# HUD状态
var is_initialized: bool = false
var is_visible: bool = true

# 引用
@onready var game_manager = get_node_or_null("/root/GameManager")
@onready var config_manager = get_node_or_null("/root/ConfigManager")
@onready var localization_manager = get_node_or_null("/root/LocalizationManager")
@onready var font_manager = get_node_or_null("/root/FontManager")

# 工具类
@onready var text_utils = load("res://scripts/ui/text_utils.gd")
@onready var ui_utils = load("res://scripts/ui/ui_utils.gd")

# 初始化
func _ready() -> void:
	# 连接信号
	EventBus.game_paused.connect(_on_game_paused)

	# 初始化HUD
	_initialize()

# 初始化HUD
func _initialize() -> void:
	# 子类应该重写此方法
	is_initialized = true

	# 发送初始化信号
	hud_initialized.emit()

# 更新HUD
func update_hud() -> void:
	# 子类应该重写此方法

	# 发送更新信号
	hud_updated.emit()

# 显示HUD
func show_hud() -> void:
	is_visible = true
	visible = true

# 隐藏HUD
func hide_hud() -> void:
	is_visible = false
	visible = false

# 切换HUD可见性
func toggle_hud() -> void:
	is_visible = !is_visible
	visible = is_visible

# 游戏暂停处理
func _on_game_paused(paused: bool) -> void:
	# 子类可以重写此方法
	pass

# 获取本地化文本
func tr(key: String, params: Array = []) -> String:
	if text_utils:
		return text_utils.tr(key, params)
	return localization_manager.tr(key, params)

# 播放UI音效
func play_ui_sound(sound_name: String) -> void:
	AudioManager.play_ui_sound(sound_name)
