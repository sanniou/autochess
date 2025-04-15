extends BaseHUD
class_name MainMenuHUD
## 主菜单HUD
## 显示主菜单相关信息，如游戏标题、版本等

# 存档管理器引用
var save_manager = null

# 初始化
func _initialize() -> void:
	# 获取存档管理器
	save_manager = get_node("/root/SaveManager")
	
	# 连接信号
	if has_node("StartButton"):
		get_node("StartButton").pressed.connect(_on_start_button_pressed)
	
	if has_node("ContinueButton"):
		get_node("ContinueButton").pressed.connect(_on_continue_button_pressed)
	
	if has_node("SettingsButton"):
		get_node("SettingsButton").pressed.connect(_on_settings_button_pressed)
	
	if has_node("QuitButton"):
		get_node("QuitButton").pressed.connect(_on_quit_button_pressed)
	
	# 检查存档
	_check_saves()
	
	# 更新显示
	update_hud()
	
	# 调用父类方法
	super._initialize()

# 更新HUD
func update_hud() -> void:
	# 更新游戏标题
	if has_node("TitleLabel"):
		var title_label = get_node("TitleLabel")
		title_label.text = tr("ui.main_menu.title")
	
	# 更新版本信息
	if has_node("VersionLabel"):
		var version_label = get_node("VersionLabel")
		version_label.text = tr("ui.main_menu.version", ["1.0.0"])
	
	# 调用父类方法
	super.update_hud()

# 检查存档
func _check_saves() -> void:
	if save_manager == null:
		return
	
	# 获取存档列表
	var saves = save_manager.get_save_list()
	
	# 更新继续按钮状态
	if has_node("ContinueButton"):
		var continue_button = get_node("ContinueButton")
		continue_button.disabled = saves.size() == 0

# 开始按钮点击处理
func _on_start_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 显示难度选择对话框
	var popup = game_manager.ui_manager.show_popup("difficulty_select")
	
	# 连接难度选择信号
	if popup and popup.has_signal("difficulty_selected"):
		popup.difficulty_selected.connect(_on_difficulty_selected)

# 继续按钮点击处理
func _on_continue_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 显示存档选择对话框
	var popup = game_manager.ui_manager.show_popup("save_select")
	
	# 连接存档选择信号
	if popup and popup.has_signal("save_selected"):
		popup.save_selected.connect(_on_save_selected)

# 设置按钮点击处理
func _on_settings_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 显示设置对话框
	game_manager.ui_manager.show_popup("settings")

# 退出按钮点击处理
func _on_quit_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 显示确认对话框
	var popup = game_manager.ui_manager.show_popup("confirm_dialog", {
		"title": tr("ui.main_menu.quit_title"),
		"message": tr("ui.main_menu.quit_message"),
		"confirm_text": tr("ui.main_menu.quit_confirm"),
		"cancel_text": tr("ui.main_menu.quit_cancel")
	})
	
	# 连接确认信号
	if popup and popup.has_signal("confirmed"):
		popup.confirmed.connect(_on_quit_confirmed)

# 难度选择处理
func _on_difficulty_selected(difficulty: int) -> void:
	# 开始新游戏
	game_manager.start_new_game(difficulty)

# 存档选择处理
func _on_save_selected(save_name: String) -> void:
	# 加载存档
	save_manager.load_game(save_name)

# 退出确认处理
func _on_quit_confirmed() -> void:
	# 退出游戏
	game_manager.quit_game()
