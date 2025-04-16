extends BasePopup
class_name SaveGamePopup
## 存档游戏弹窗
## 用于保存游戏存档

# 信号
signal save_completed(save_name: String)

# 存档管理器引用
var save_manager = null

# 初始化
func _initialize() -> void:
	# 获取存档管理器
	save_manager = get_node("/root/SaveManager")
	
	# 连接按钮信号
	if has_node("SaveButton"):
		get_node("SaveButton").pressed.connect(_on_save_button_pressed)
	
	if has_node("CancelButton"):
		get_node("CancelButton").pressed.connect(_on_cancel_button_pressed)
	
	# 加载存档列表
	_load_save_list()
	
	# 调用父类方法
	super._initialize()

# 更新弹窗
func _update_popup() -> void:
	# 设置标题
	title = tr("ui.save.title")
	
	# 加载存档列表
	_load_save_list()

# 加载存档列表
func _load_save_list() -> void:
	if save_manager == null:
		return
	
	# 获取存档列表容器
	var save_list = get_node_or_null("SaveList")
	if save_list == null:
		return
	
	# 清空列表
	save_list.clear()
	
	# 获取存档列表
	var saves = save_manager.get_save_list()
	
	# 添加新存档选项
	save_list.add_item(tr("ui.save.new_game"), null, true)
	
	# 添加自动存档选项
	save_list.add_item(tr("ui.save.autosave"), null, true)
	
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
	
	# 默认选择第一项
	if save_list.get_item_count() > 0:
		save_list.select(0)
	
	# 更新按钮状态
	_update_button_states()

# 更新按钮状态
func _update_button_states() -> void:
	# 获取存档列表
	var save_list = get_node_or_null("SaveList")
	if save_list == null:
		return
	
	# 获取选中的存档索引
	var selected_idx = save_list.get_selected_items()
	var has_selection = selected_idx.size() > 0
	
	# 更新保存按钮状态
	if has_node("SaveButton"):
		get_node("SaveButton").disabled = !has_selection

# 存档列表项选择处理
func _on_save_list_item_selected(index: int) -> void:
	# 更新按钮状态
	_update_button_states()

# 保存按钮点击处理
func _on_save_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 获取存档列表
	var save_list = get_node_or_null("SaveList")
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
	
	# 如果是覆盖现有存档，显示确认对话框
	if index > 0:
		var popup = game_manager.ui_manager.show_popup("confirm_dialog", {
			"title": tr("ui.save.overwrite_title"),
			"message": tr("ui.save.overwrite_message"),
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
		EventBus.show_toast.emit(tr("ui.save.save_success"), 2.0)
		
		# 发送保存完成信号
		save_completed.emit(save_name)
		
		# 关闭弹窗
		close_popup()
	else:
		# 显示失败提示
		EventBus.show_toast.emit(tr("ui.save.save_failed"), 2.0)

# 取消按钮点击处理
func _on_cancel_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 关闭弹窗
	close_popup()
