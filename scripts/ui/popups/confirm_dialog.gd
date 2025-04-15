extends BasePopup
class_name ConfirmDialog
## 确认对话框
## 用于显示需要用户确认的消息

# 信号
signal confirmed
signal cancelled

# 初始化
func _initialize() -> void:
	# 连接按钮信号
	if has_node("ButtonContainer/ConfirmButton"):
		get_node("ButtonContainer/ConfirmButton").pressed.connect(_on_confirm_button_pressed)
	
	if has_node("ButtonContainer/CancelButton"):
		get_node("ButtonContainer/CancelButton").pressed.connect(_on_cancel_button_pressed)
	
	# 调用父类方法
	super._initialize()

# 更新弹窗
func _update_popup() -> void:
	# 设置标题
	title = popup_data.get("title", tr("ui.dialog.confirm_title"))
	
	# 设置消息
	if has_node("MessageLabel"):
		get_node("MessageLabel").text = popup_data.get("message", "")
	
	# 设置按钮文本
	if has_node("ButtonContainer/ConfirmButton"):
		get_node("ButtonContainer/ConfirmButton").text = popup_data.get("confirm_text", tr("ui.dialog.confirm"))
	
	if has_node("ButtonContainer/CancelButton"):
		get_node("ButtonContainer/CancelButton").text = popup_data.get("cancel_text", tr("ui.dialog.cancel"))

# 确认按钮点击处理
func _on_confirm_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 发送确认信号
	confirmed.emit()
	
	# 关闭弹窗
	close_popup()

# 取消按钮点击处理
func _on_cancel_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 发送取消信号
	cancelled.emit()
	
	# 关闭弹窗
	close_popup()
