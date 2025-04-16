extends BasePopup
class_name LoadGamePopup
## 加载游戏弹窗
## 用于加载游戏存档

# 信号
signal load_completed(save_name: String)

# 存档管理器引用
var save_manager = null

# 初始化
func _initialize() -> void:
	# 获取存档管理器
	save_manager = get_node("/root/SaveManager")
	
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
		get_node("Panel/TitleLabel").text = tr("ui.load.title")
	
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
	
	# 添加自动存档选项
	var autosave_info = save_manager.get_save_info("autosave")
	if autosave_info != null:
		var date_string = ""
		if autosave_info.has("timestamp"):
			var date = Time.get_datetime_dict_from_unix_time(autosave_info.timestamp)
			date_string = "%04d-%02d-%02d %02d:%02d" % [date.year, date.month, date.day, date.hour, date.minute]
		
		var autosave_text = tr("ui.save.autosave")
		if date_string != "":
			autosave_text += " (" + date_string + ")"
		
		save_list.add_item(autosave_text, null, true)
	
	# 添加存档项
	for save_info in saves:
		var save_name = save_info.name
		
		# 跳过自动存档
		if save_name == "autosave":
			continue
		
		# 格式化日期
		var date_string = ""
		if save_info.has("timestamp"):
			var date = Time.get_datetime_dict_from_unix_time(save_info.timestamp)
			date_string = "%04d-%02d-%02d %02d:%02d" % [date.year, date.month, date.day, date.hour, date.minute]
		
		# 格式化玩家等级和地图进度
		var level_string = ""
		if save_info.has("player_level"):
			level_string = tr("ui.save.level", [str(save_info.player_level)])
		
		var progress_string = ""
		if save_info.has("map_progress"):
			progress_string = tr("ui.save.progress", [str(save_info.map_progress)])
		
		# 格式化难度
		var difficulty_string = ""
		if save_info.has("difficulty"):
			var difficulty_names = {
				0: tr("ui.difficulty.easy"),
				1: tr("ui.difficulty.normal"),
				2: tr("ui.difficulty.hard"),
				3: tr("ui.difficulty.expert")
			}
			difficulty_string = difficulty_names.get(save_info.difficulty, "")
		
		# 构建显示文本
		var save_text = save_name
		if date_string != "":
			save_text += " (" + date_string + ")"
		if level_string != "":
			save_text += " - " + level_string
		if progress_string != "":
			save_text += " - " + progress_string
		if difficulty_string != "":
			save_text += " - " + difficulty_string
		
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
	# 更新按钮状态
	_update_button_states()

# 存档列表项激活处理（双击）
func _on_save_list_item_activated(index: int) -> void:
	# 直接加载选中的存档
	_load_selected_save()

# 加载按钮点击处理
func _on_load_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 加载选中的存档
	_load_selected_save()

# 删除按钮点击处理
func _on_delete_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 获取选中的存档
	var save_name = _get_selected_save_name()
	if save_name.is_empty():
		return
	
	# 显示确认对话框
	var popup = game_manager.ui_manager.show_popup("confirm_dialog", {
		"title": tr("ui.save.delete_title"),
		"message": tr("ui.save.delete_message", [save_name]),
		"confirm_text": tr("ui.save.delete_confirm"),
		"cancel_text": tr("ui.save.delete_cancel")
	})
	
	# 连接确认信号
	if popup and popup.has_signal("confirmed"):
		popup.confirmed.connect(func(): _delete_save(save_name))

# 获取选中的存档名称
func _get_selected_save_name() -> String:
	# 获取存档列表
	var save_list = get_node_or_null("Panel/SaveList")
	if save_list == null:
		return ""
	
	# 获取选中的存档索引
	var selected_idx = save_list.get_selected_items()
	if selected_idx.size() == 0:
		return ""
	
	var index = selected_idx[0]
	var save_text = save_list.get_item_text(index)
	
	# 处理自动存档
	if index == 0 and save_text.begins_with(tr("ui.save.autosave")):
		return "autosave"
	
	# 从文本中提取存档名称（去除日期和其他信息）
	return save_text.split(" (")[0]

# 加载选中的存档
func _load_selected_save() -> void:
	# 获取选中的存档名称
	var save_name = _get_selected_save_name()
	if save_name.is_empty():
		return
	
	# 加载存档
	var success = save_manager.load_game(save_name)
	
	if success:
		# 显示成功提示
		EventBus.show_toast.emit(tr("ui.save.load_success"), 2.0)
		
		# 发送加载完成信号
		load_completed.emit(save_name)
		
		# 关闭弹窗
		close_popup()
	else:
		# 显示失败提示
		EventBus.show_toast.emit(tr("ui.save.load_failed"), 2.0)

# 删除存档
func _delete_save(save_name: String) -> void:
	# 删除存档
	var success = save_manager.delete_save(save_name)
	
	if success:
		# 显示成功提示
		EventBus.show_toast.emit(tr("ui.save.delete_success"), 2.0)
		
		# 重新加载存档列表
		_load_save_list()
	else:
		# 显示失败提示
		EventBus.show_toast.emit(tr("ui.save.delete_failed"), 2.0)
