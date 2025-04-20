extends Window
class_name BaseWindowPopup
## 基于Window的弹窗基类
## 用于创建基于Window节点的弹窗

# 信号
signal popup_initialized
signal popup_closed

# 弹窗数据
var popup_data: Dictionary = {}

# 是否已初始化
var _initialized: bool = false

# 初始化
func _ready() -> void:
	# 设置窗口属性
	exclusive = true
	transient = true
	unresizable = true

	# 连接关闭信号
	close_requested.connect(_on_close_requested)
	
	# 初始化弹窗
	initialize()

# 初始化弹窗
func initialize() -> void:
	if _initialized:
		return
		
	_initialized = true
	
	# 设置默认样式
	_setup_default_style()
	
	# 子类应该重写此方法进行额外初始化
	_initialize()
	
	# 发送初始化信号
	popup_initialized.emit()

# 子类初始化方法
func _initialize() -> void:
	# 子类应该重写此方法
	pass

# 设置默认样式
func _setup_default_style() -> void:
	# 设置默认样式
	# 这里可以添加通用的样式设置
	pass

# 设置弹窗数据
func set_popup_data(data: Dictionary) -> void:
	popup_data = data
	update_popup()

# 更新弹窗
func update_popup() -> void:
	# 更新标题
	if popup_data.has("title"):
		title = popup_data.title
	
	# 子类应该重写此方法进行额外更新
	_update_popup()

# 子类更新方法
func _update_popup() -> void:
	# 子类应该重写此方法
	pass

# 显示弹窗
func show_popup() -> void:
	# 显示弹窗
	popup_centered()
	
	# 更新弹窗
	update_popup()

# 关闭弹窗
func close_popup() -> void:
	# 获取UI管理器
	var ui_manager = GameManager.ui_manager
	if ui_manager:
		ui_manager.close_popup(self)
	else:
		# 直接隐藏
		hide()
		popup_closed.emit()

# 关闭请求处理
func _on_close_requested() -> void:
	close_popup()

# 获取本地化文本
func tr2(key: String, params: Array = []) -> String:
	return GameManager.localization_manager.tr(key, params)

# 播放UI音效
func play_ui_sound(sound_name: String) -> void:
	AudioManager.play_ui_sound(sound_name)
