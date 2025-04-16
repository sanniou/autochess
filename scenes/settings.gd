extends Control
## 设置界面
## 用于调整游戏设置

# 设置数据
var settings = {
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 0.8
	},
	"display": {
		"fullscreen": false,
		"vsync": true
	},
	"game": {
		"difficulty": 1,  # 0: 简单, 1: 普通, 2: 困难, 3: 专家
		"language": 0     # 0: 简体中文
	}
}

# 设置管理器
var settings_manager = null

# 音频管理器
var audio_manager = null

# 初始化
func _ready():
	# 获取管理器
	if has_node("/root/SettingsManager"):
		settings_manager = get_node("/root/SettingsManager")
	
	if has_node("/root/AudioManager"):
		audio_manager = get_node("/root/AudioManager")
	
	# 初始化界面
	_initialize_ui()
	
	# 加载设置
	_load_settings()
	
	# 播放背景音乐
	if audio_manager:
		audio_manager.play_music("settings.ogg")
	
	# 添加动画效果
	_add_animations()

# 初始化界面
func _initialize_ui() -> void:
	# 设置面板初始透明度
	$SettingsPanel.modulate.a = 0
	
	# 设置标题初始透明度
	$Title.modulate.a = 0

# 加载设置
func _load_settings() -> void:
	if settings_manager:
		settings = settings_manager.get_settings()
	
	# 更新UI
	_update_ui_from_settings()

# 更新UI
func _update_ui_from_settings() -> void:
	# 音频设置
	$SettingsPanel/SettingsContainer/AudioSettings/MasterVolumeContainer/MasterVolumeSlider.value = settings.audio.master_volume
	$SettingsPanel/SettingsContainer/AudioSettings/MusicVolumeContainer/MusicVolumeSlider.value = settings.audio.music_volume
	$SettingsPanel/SettingsContainer/AudioSettings/SFXVolumeContainer/SFXVolumeSlider.value = settings.audio.sfx_volume
	
	# 显示设置
	$SettingsPanel/SettingsContainer/DisplaySettings/FullscreenContainer/FullscreenCheckBox.button_pressed = settings.display.fullscreen
	$SettingsPanel/SettingsContainer/DisplaySettings/VSyncContainer/VSyncCheckBox.button_pressed = settings.display.vsync
	
	# 游戏设置
	$SettingsPanel/SettingsContainer/GameSettings/DifficultyContainer/DifficultyOption.selected = settings.game.difficulty
	$SettingsPanel/SettingsContainer/GameSettings/LanguageContainer/LanguageOption.selected = settings.game.language

# 保存设置
func _save_settings() -> void:
	if settings_manager:
		settings_manager.save_settings(settings)
	
	# 应用设置
	_apply_settings()

# 应用设置
func _apply_settings() -> void:
	# 应用音频设置
	if audio_manager:
		audio_manager.set_master_volume(settings.audio.master_volume)
		audio_manager.set_music_volume(settings.audio.music_volume)
		audio_manager.set_sfx_volume(settings.audio.sfx_volume)
	
	# 应用显示设置
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings.display.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings.display.vsync else DisplayServer.VSYNC_DISABLED)
	
	# 应用游戏设置
	if has_node("/root/GameManager"):
		var game_manager = get_node("/root/GameManager")
		game_manager.set_difficulty(settings.game.difficulty)
	
	if has_node("/root/LocalizationManager"):
		var localization_manager = get_node("/root/LocalizationManager")
		var language_codes = ["zh_CN"]
		if settings.game.language < language_codes.size():
			localization_manager.set_language(language_codes[settings.game.language])

# 重置设置
func _reset_settings() -> void:
	# 重置为默认设置
	settings = {
		"audio": {
			"master_volume": 1.0,
			"music_volume": 0.8,
			"sfx_volume": 0.8
		},
		"display": {
			"fullscreen": false,
			"vsync": true
		},
		"game": {
			"difficulty": 1,
			"language": 0
		}
	}
	
	# 更新UI
	_update_ui_from_settings()
	
	# 播放音效
	if audio_manager:
		audio_manager.play_ui_sound("button_click.ogg")

# 添加动画效果
func _add_animations() -> void:
	# 标题动画
	var title_tween = create_tween()
	title_tween.tween_property($Title, "modulate:a", 1.0, 0.5)
	
	# 设置面板动画
	var panel_tween = create_tween()
	panel_tween.tween_interval(0.3)  # 等待标题动画
	panel_tween.tween_property($SettingsPanel, "modulate:a", 1.0, 0.5)
	panel_tween.parallel().tween_property($SettingsPanel, "position:y", $SettingsPanel.position.y - 20, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

# 播放按钮音效
func _play_button_sound() -> void:
	if audio_manager:
		audio_manager.play_ui_sound("button_click.ogg")

# 主音量滑块值变化处理
func _on_master_volume_slider_value_changed(value: float) -> void:
	settings.audio.master_volume = value
	
	# 实时应用音量
	if audio_manager:
		audio_manager.set_master_volume(value)

# 音乐音量滑块值变化处理
func _on_music_volume_slider_value_changed(value: float) -> void:
	settings.audio.music_volume = value
	
	# 实时应用音量
	if audio_manager:
		audio_manager.set_music_volume(value)

# 音效音量滑块值变化处理
func _on_sfx_volume_slider_value_changed(value: float) -> void:
	settings.audio.sfx_volume = value
	
	# 实时应用音量
	if audio_manager:
		audio_manager.set_sfx_volume(value)
		
		# 播放测试音效
		audio_manager.play_ui_sound("button_click.ogg")

# 全屏复选框切换处理
func _on_fullscreen_check_box_toggled(button_pressed: bool) -> void:
	settings.display.fullscreen = button_pressed
	
	# 播放音效
	_play_button_sound()

# 垂直同步复选框切换处理
func _on_v_sync_check_box_toggled(button_pressed: bool) -> void:
	settings.display.vsync = button_pressed
	
	# 播放音效
	_play_button_sound()

# 难度选项选择处理
func _on_difficulty_option_item_selected(index: int) -> void:
	settings.game.difficulty = index
	
	# 播放音效
	_play_button_sound()

# 语言选项选择处理
func _on_language_option_item_selected(index: int) -> void:
	settings.game.language = index
	
	# 播放音效
	_play_button_sound()

# 应用按钮处理
func _on_apply_button_pressed() -> void:
	# 播放音效
	_play_button_sound()
	
	# 保存设置
	_save_settings()
	
	# 显示应用成功提示
	var dialog = AcceptDialog.new()
	dialog.title = "设置已应用"
	dialog.dialog_text = "设置已成功应用。"
	add_child(dialog)
	dialog.popup_centered()

# 重置按钮处理
func _on_reset_button_pressed() -> void:
	# 播放音效
	_play_button_sound()
	
	# 显示确认对话框
	var dialog = ConfirmationDialog.new()
	dialog.title = "重置设置"
	dialog.dialog_text = "确定要将所有设置重置为默认值吗？"
	dialog.confirmed.connect(_reset_settings)
	add_child(dialog)
	dialog.popup_centered()

# 返回按钮处理
func _on_back_button_pressed() -> void:
	# 播放音效
	_play_button_sound()
	
	# 创建过渡动画
	var transition = ColorRect.new()
	transition.color = Color(0, 0, 0, 0)
	transition.size = get_viewport_rect().size
	transition.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(transition)
	
	var tween = create_tween()
	tween.tween_property(transition, "color:a", 1.0, 0.5)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
