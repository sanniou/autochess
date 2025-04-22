extends BaseControlPopup
class_name SaveSelectPopup
## 存档选择弹窗
## 用于选择游戏存档

# 信号
signal save_selected(save_name: String)

# 存档管理器引用
var save_manager = null

# 选中的存档
var selected_save: String = ""

# 初始化
func _initialize() -> void:
	# 获取存档管理器
	save_manager = SaveManager
	
	# 连接按钮信号
	if has_node("Panel/ButtonContainer/LoadButton"):
		get_node("Panel/ButtonContainer/LoadButton").pressed.connect(_on_load_button_pressed)
	
	if has_node("Panel/ButtonContainer/DeleteButton"):
		get_node("Panel/ButtonContainer/DeleteButton").pressed.connect(_on_delete_button_pressed)
	
	if has_node("Panel/ButtonContainer/CancelButton"):
		get_node("Panel/ButtonContainer/CancelButton").pressed.connect(_on_cancel_button_pressed)
	
	# 连接列表信号
	if has_node("Panel/SaveList"):
		var save_list = get_node("Panel/SaveList")
		save_list.item_selected.connect(_on_save_list_item_selected)
		save_list.item_activated.connect(_on_save_list_item_activated)
	
	# 加载存档列表
	_load_save_list()
	
	# 调用父类方法
	super._initialize()

# 更新弹窗
func _update_popup() -> void:
	# 设置标题
	if has_node("Panel/TitleLabel"):
		get_node("Panel/TitleLabel").text = popup_data.get("title", tr("ui.save.title"))
	
	# 加载存档列表
	_load_save_list()

# 加载存档列表
func _load_save_list() -> void:
	if save_manager == null:
		return
	
	# 获取存档列表容器
	var save_list = get_node_or_null("Panel/SaveList")
	if save_list == null:
		return
	
	# 清空列表
	save_list.clear()
	
	# 获取存档列表
	var saves = save_manager.get_save_list()
	
	# 添加存档项
	for save_info in saves:
		var save_name = save_info.name
		var save_date = save_info.date
		var save_text = save_name + " (" + save_date + ")"
		
		save_list.add_item(save_text, null, true)
	
	# 更新按钮状态
	_update_button_states()

# 更新按钮状态
func _update_button_states() -> void:
	# 获取存档列表
	var save_list = get_node_or_null("Panel/SaveList")
	if save_list == null:
		return
	
	# 获取选中的存档索引
	var selected_idx = save_list.get_selected_items()
	var has_selection = selected_idx.size() > 0
	
	# 更新加载按钮状态
	if has_node("Panel/ButtonContainer/LoadButton"):
		get_node("Panel/ButtonContainer/LoadButton").disabled = !has_selection
	
	# 更新删除按钮状态
	if has_node("Panel/ButtonContainer/DeleteButton"):
		get_node("Panel/ButtonContainer/DeleteButton").disabled = !has_selection

# 存档列表项选择处理
func _on_save_list_item_selected(index: int) -> void:
	# 获取存档列表
	var save_list = get_node_or_null("Panel/SaveList")
	if save_list == null:
		return
	
	# 获取选中的存档名称
	var save_text = save_list.get_item_text(index)
	selected_save = save_text.split(" (")[0]
	
	# 更新按钮状态
	_update_button_states()

# 存档列表项激活处理（双击）
func _on_save_list_item_activated(index: int) -> void:
	# 直接加载选中的存档
	_on_load_button_pressed()

# 加载按钮点击处理
func _on_load_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 检查是否有选中的存档
	if selected_save.is_empty():
		return
	
	# 发送存档选择信号
	save_selected.emit(selected_save)
	
	# 关闭弹窗
	close_popup()

# 删除按钮点击处理
func _on_delete_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 检查是否有选中的存档
	if selected_save.is_empty():
		return
	
	# 显示确认对话框
	var popup = GameManager.ui_manager.show_popup("confirm_dialog_popup", {
		"title": tr("ui.save.delete_title"),
		"message": tr("ui.save.delete_message", selected_save),
		"confirm_text": tr("ui.save.delete_confirm"),
		"cancel_text": tr("ui.save.delete_cancel")
	})
	
	# 连接确认信号
	if popup and popup.has_signal("confirmed"):
		popup.confirmed.connect(_on_delete_confirmed)

# 删除确认处理
func _on_delete_confirmed() -> void:
	# 删除存档
	var success = save_manager.delete_save(selected_save)
	
	if success:
		# 显示成功提示
		EventBus.ui.emit_event("show_toast", [tr("ui.save.delete_success"), 2.0])
		
		# 重新加载存档列表
		_load_save_list()
	else:
		# 显示失败提示
		EventBus.ui.emit_event("show_toast", [tr("ui.save.delete_failed"), 2.0])

# 取消按钮点击处理
func _on_cancel_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 关闭弹窗
	close_popup()
