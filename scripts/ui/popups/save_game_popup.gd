extends BaseControlPopup
class_name SaveGamePopup
## 保存游戏弹窗
## 用于保存游戏存档

# 信号
signal save_completed(save_name: String)

# 存档管理器引用
var save_manager = null

# 初始化
func _initialize() -> void:
	# 获取存档管理器
	save_manager = SaveManager

	# 连接按钮信号
	if has_node("Panel/ButtonContainer/SaveButton"):
		get_node("Panel/ButtonContainer/SaveButton").pressed.connect(_on_save_button_pressed)

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

	# 添加新存档选项
	save_list.add_item(tr("ui.save.new_game"), null, true)

	# 添加自动存档选项
	save_list.add_item(tr("ui.save.autosave"), null, true)

	# 获取存档列表
	var saves = save_manager.get_save_list()

	# 添加存档项
	for save_info in saves:
		var save_name = save_info.name

		# 跳过自动存档
		if save_name == "autosave":
			continue

		var save_date = save_info.date
		var save_text = save_name + " (" + save_date + ")"

		save_list.add_item(save_text, null, true)

	# 默认选择第一项
	if save_list.item_count > 0:
		save_list.select(0)
		_on_save_list_item_selected(0)

# 更新按钮状态
func _update_button_states() -> void:
	# 获取存档列表
	var save_list = get_node_or_null("Panel/SaveList")
	if save_list == null:
		return

	# 获取选中的存档索引
	var selected_idx = save_list.get_selected_items()
	var has_selection = selected_idx.size() > 0

	# 更新保存按钮状态
	if has_node("Panel/ButtonContainer/SaveButton"):
		get_node("Panel/ButtonContainer/SaveButton").disabled = !has_selection

# 存档列表项选择处理
func _on_save_list_item_selected(_index: int) -> void:
	# 更新按钮状态
	_update_button_states()

# 存档列表项激活处理（双击）
func _on_save_list_item_activated(_index: int) -> void:
	# 直接保存到选中的存档
	_on_save_button_pressed()

# 保存按钮点击处理
func _on_save_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")

	# 获取存档列表
	var save_list = get_node_or_null("Panel/SaveList")
	if save_list == null:
		return

	# 获取选中的存档索引
	var selected_idx = save_list.get_selected_items()
	if selected_idx.size() == 0:
		return

	var index = selected_idx[0]
	var save_name = ""

	# 处理不同的选项
	if index == 0:
		# 新存档
		save_name = save_manager.create_new_save_slot()
	elif index == 1:
		# 自动存档
		save_name = "autosave"
	else:
		# 现有存档
		var save_text = save_list.get_item_text(index)
		save_name = save_text.split(" (")[0]

	# 如果是现有存档，显示确认对话框
	if index > 1:
		var message = tr("ui.save.overwrite_message").format({"save_name": save_name})
		var popup = GameManager.ui_manager.show_popup("confirm_dialog_popup", {
			"title": tr("ui.save.overwrite_title"),
			"message": message,
			"confirm_text": tr("ui.save.overwrite_confirm"),
			"cancel_text": tr("ui.save.overwrite_cancel")
		})

		# 连接确认信号
		if popup and popup.has_signal("confirmed"):
			popup.confirmed.connect(func(): _perform_save(save_name))
	else:
		# 直接保存
		_perform_save(save_name)

# 执行保存
func _perform_save(save_name: String) -> void:
	# 保存游戏
	var success = save_manager.save_game(save_name)

	if success:
		# 显示成功提示
		EventBus.ui.emit_event("show_toast", [tr("ui.save.save_success"), 2.0])

		# 发送保存完成信号
		save_completed.emit(save_name)

		# 关闭弹窗
		close_popup()
	else:
		# 显示失败提示
		EventBus.ui.emit_event("show_toast", [tr("ui.save.save_failed"), 2.0])

# 取消按钮点击处理
func _on_cancel_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")

	# 关闭弹窗
	close_popup()
