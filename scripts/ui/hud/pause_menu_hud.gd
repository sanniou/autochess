extends BaseHUD
class_name PauseMenuHUD
## 暂停菜单HUD
## 显示暂停菜单相关信息和选项

# 存档管理器引用
var save_manager = null

# 初始化
func _initialize() -> void:
	# 获取存档管理器
	save_manager = SaveManager
	
	# 连接信号
	if has_node("ResumeButton"):
		get_node("ResumeButton").pressed.connect(_on_resume_button_pressed)
	
	if has_node("SaveButton"):
		get_node("SaveButton").pressed.connect(_on_save_button_pressed)
	
	if has_node("LoadButton"):
		get_node("LoadButton").pressed.connect(_on_load_button_pressed)
	
	if has_node("SettingsButton"):
		get_node("SettingsButton").pressed.connect(_on_settings_button_pressed)
	
	if has_node("MainMenuButton"):
		get_node("MainMenuButton").pressed.connect(_on_main_menu_button_pressed)
	
	if has_node("QuitButton"):
		get_node("QuitButton").pressed.connect(_on_quit_button_pressed)
	
	# 更新显示
	update_hud()
	
	# 调用父类方法
	super._initialize()

# 更新HUD
func update_hud() -> void:
	# 更新标题
	if has_node("TitleLabel"):
		var title_label = get_node("TitleLabel")
		title_label.text = tr("ui.pause_menu.title")
	
	# 调用父类方法
	super.update_hud()

# 恢复按钮点击处理
func _on_resume_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 恢复游戏
	GameManager.resume_game()

# 保存按钮点击处理
func _on_save_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 显示保存游戏对话框
	var popup = GameManager.ui_manager.show_popup("save_game_popup")
	
	# 连接保存完成信号
	if popup and popup.has_signal("save_completed"):
		popup.save_completed.connect(_on_save_completed)

# 加载按钮点击处理
func _on_load_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 显示加载游戏对话框
	var popup = GameManager.ui_manager.show_popup("load_game_popup")
	
	# 连接加载完成信号
	if popup and popup.has_signal("load_completed"):
		popup.load_completed.connect(_on_load_completed)

# 设置按钮点击处理
func _on_settings_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 显示设置对话框
	GameManager.ui_manager.show_popup("settings")

# 主菜单按钮点击处理
func _on_main_menu_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 显示确认对话框
	var popup = GameManager.ui_manager.show_popup("confirm_dialog", {
		"title": tr("ui.pause_menu.main_menu_title"),
		"message": tr("ui.pause_menu.main_menu_message"),
		"confirm_text": tr("ui.pause_menu.main_menu_confirm"),
		"cancel_text": tr("ui.pause_menu.main_menu_cancel")
	})
	
	# 连接确认信号
	if popup and popup.has_signal("confirmed"):
		popup.confirmed.connect(_on_main_menu_confirmed)

# 退出按钮点击处理
func _on_quit_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 显示确认对话框
	var popup = GameManager.ui_manager.show_popup("confirm_dialog", {
		"title": tr("ui.pause_menu.quit_title"),
		"message": tr("ui.pause_menu.quit_message"),
		"confirm_text": tr("ui.pause_menu.quit_confirm"),
		"cancel_text": tr("ui.pause_menu.quit_cancel")
	})
	
	# 连接确认信号
	if popup and popup.has_signal("confirmed"):
		popup.confirmed.connect(_on_quit_confirmed)

# 保存完成处理
func _on_save_completed(save_name: String) -> void:
	# 显示提示
	GlobalEventBus.ui.dispatch_event(UIEvents.ToastShownEvent.new(tr("ui.save.save_success"), 2.0))

# 加载完成处理
func _on_load_completed(save_name: String) -> void:
	# 恢复游戏
	GameManager.resume_game()
	
	# 加载存档
	GameManager.load_game(save_name)

# 主菜单确认处理
func _on_main_menu_confirmed() -> void:
	# 恢复游戏
	GameManager.resume_game()
	
	# 触发自动存档
	if save_manager:
		save_manager.trigger_autosave()
	
	# 返回主菜单
	GameManager.change_state(GameManager.GameState.MAIN_MENU)

# 退出确认处理
func _on_quit_confirmed() -> void:
	# 退出游戏
	GameManager.quit_game()
