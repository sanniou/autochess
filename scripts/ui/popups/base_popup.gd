extends Window
class_name BasePopup
## 基础弹窗类
## 所有弹窗的基类，提供通用功能

# 信号
signal popup_initialized
signal popup_closed

# 弹窗数据
var popup_data: Dictionary = {}

# 引用
@onready var game_manager = get_node("/root/GameManager")
@onready var config_manager = get_node("/root/ConfigManager")
@onready var localization_manager = get_node("/root/LocalizationManager")

# 初始化
func _ready() -> void:
	# 设置弹窗属性
	exclusive = true
	transient = true
	unresizable = true
	
	# 连接信号
	close_requested.connect(_on_close_requested)
	
	# 初始化弹窗
	_initialize()

# 初始化弹窗
func _initialize() -> void:
	# 子类应该重写此方法
	
	# 发送初始化信号
	popup_initialized.emit()

# 设置弹窗数据
func set_popup_data(data: Dictionary) -> void:
	popup_data = data
	_update_popup()

# 更新弹窗
func _update_popup() -> void:
	# 子类应该重写此方法
	pass

# 关闭弹窗
func close_popup() -> void:
	hide()
	
	# 发送关闭信号
	popup_closed.emit()

# 关闭请求处理
func _on_close_requested() -> void:
	close_popup()

# 获取本地化文本
func tr(key: String, params: Array = []) -> String:
	return localization_manager.tr(key, params)

# 播放UI音效
func play_ui_sound(sound_name: String) -> void:
	AudioManager.play_ui_sound(sound_name)
