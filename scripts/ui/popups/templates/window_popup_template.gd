extends BaseWindowPopup
class_name WindowPopupTemplate
## 基于Window的弹窗模板
## 用于创建新的Window类型弹窗

# 初始化弹窗
func _initialize() -> void:
	# 连接按钮信号
	if has_node("MarginContainer/VBoxContainer/ButtonsContainer/ConfirmButton"):
		get_node("MarginContainer/VBoxContainer/ButtonsContainer/ConfirmButton").pressed.connect(_on_confirm_button_pressed)
	
	if has_node("MarginContainer/VBoxContainer/ButtonsContainer/CancelButton"):
		get_node("MarginContainer/VBoxContainer/ButtonsContainer/CancelButton").pressed.connect(_on_cancel_button_pressed)
	
	# 调用父类方法
	super._initialize()

# 更新弹窗
func _update_popup() -> void:
	# 设置标题
	title = popup_data.get("title", "弹窗标题")
	
	# 设置消息
	if has_node("MarginContainer/VBoxContainer/MessageLabel"):
		get_node("MarginContainer/VBoxContainer/MessageLabel").text = popup_data.get("message", "")
	
	# 设置按钮文本
	if has_node("MarginContainer/VBoxContainer/ButtonsContainer/ConfirmButton"):
		get_node("MarginContainer/VBoxContainer/ButtonsContainer/ConfirmButton").text = popup_data.get("confirm_text", "确定")
	
	if has_node("MarginContainer/VBoxContainer/ButtonsContainer/CancelButton"):
		get_node("MarginContainer/VBoxContainer/ButtonsContainer/CancelButton").text = popup_data.get("cancel_text", "取消")

# 确认按钮点击处理
func _on_confirm_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 处理确认逻辑
	# ...
	
	# 关闭弹窗
	close_popup()

# 取消按钮点击处理
func _on_cancel_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 关闭弹窗
	close_popup()
