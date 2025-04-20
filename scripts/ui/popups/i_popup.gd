## 弹窗接口类
## 定义所有弹窗必须实现的方法和属性
class_name IPopup

# 信号
signal popup_initialized
signal popup_closed

# 弹窗数据
var popup_data: Dictionary = {}

# 初始化弹窗
func initialize() -> void:
	pass

# 设置弹窗数据
func set_popup_data(data: Dictionary) -> void:
	pass

# 更新弹窗
func update_popup() -> void:
	pass

# 显示弹窗
func show_popup() -> void:
	pass

# 关闭弹窗
func close_popup() -> void:
	pass

# 播放UI音效
func play_ui_sound(sound_name: String) -> void:
	pass
