extends BaseHUD
class_name DefaultHUD
## 默认HUD
## 所有场景共用的基础HUD，包含暂停按钮、设置按钮等

# 初始化
func _initialize() -> void:
	# 连接信号
	if has_node("PauseButton"):
		get_node("PauseButton").pressed.connect(_on_pause_button_pressed)
	
	if has_node("SettingsButton"):
		get_node("SettingsButton").pressed.connect(_on_settings_button_pressed)
	
	if has_node("HomeButton"):
		get_node("HomeButton").pressed.connect(_on_home_button_pressed)
	
	# 更新显示
	update_hud()
	
	# 调用父类方法
	super._initialize()

# 更新HUD
func update_hud() -> void:
	# 更新暂停按钮状态
	if has_node("PauseButton"):
		var pause_button = get_node("PauseButton")
		pause_button.text = tr("ui.hud.resume") if GameManager.is_paused else tr("ui.hud.pause")
	
	# 调用父类方法
	super.update_hud()

# 暂停按钮点击处理
func _on_pause_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 切换暂停状态
	if GameManager.is_paused:
		GameManager.resume_game()
	else:
		GameManager.pause_game()
	
	# 更新显示
	update_hud()

# 设置按钮点击处理
func _on_settings_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 暂停游戏
	GameManager.pause_game()
	
	# 显示设置对话框
	var popup = GameManager.ui_manager.show_popup("settings")
	
	# 连接关闭信号
	if popup and popup.has_signal("popup_hide"):
		popup.popup_hide.connect(func(): GameManager.resume_game())

# 主页按钮点击处理
func _on_home_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 暂停游戏
	GameManager.pause_game()
	
	# 显示确认对话框
	var popup = GameManager.ui_manager.show_popup("confirm_dialog", {
		"title": tr("ui.hud.home_title"),
		"message": tr("ui.hud.home_message"),
		"confirm_text": tr("ui.hud.home_confirm"),
		"cancel_text": tr("ui.hud.home_cancel")
	})
	
	# 连接确认信号
	if popup and popup.has_signal("confirmed"):
		popup.confirmed.connect(_on_home_confirmed)
	
	# 连接取消信号
	if popup and popup.has_signal("cancelled"):
		popup.cancelled.connect(func(): GameManager.resume_game())

# 主页确认处理
func _on_home_confirmed() -> void:
	# 触发自动存档
	GlobalEventBus.save.dispatch_event(SaveEvents.AutosaveTriggeredEvent.new())
	
	# 返回主菜单
	GameManager.change_state(GameManager.GameState.MAIN_MENU)

# 游戏暂停处理
func _on_game_paused(paused: bool) -> void:
	# 更新显示
	update_hud()
