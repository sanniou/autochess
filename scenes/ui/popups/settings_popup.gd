extends Window
## 设置弹窗
## 管理游戏设置

# 设置数据
var settings_data = {
	"difficulty": 1,
	"language": "zh_CN",
	"master_volume": 1.0,
	"music_volume": 1.0,
	"sfx_volume": 1.0,
	"mute": false,
	"fullscreen": false,
	"vsync": true,
	"resolution": Vector2i(1920, 1080)
}

# 原始设置数据
var original_settings = {}

# 初始化
func _ready():
	# 加载当前设置
	_load_settings()
	
	# 保存原始设置
	original_settings = settings_data.duplicate(true)
	
	# 更新UI
	_update_ui()

# 加载设置
func _load_settings():
	# 从配置管理器加载设置
	var config = ConfigManager.get_config("settings")
	if config:
		settings_data = config.duplicate(true)

# 保存设置
func _save_settings():
	# 保存到配置管理器
	ConfigManager.set_config("settings", settings_data)
	ConfigManager.save_config()

# 更新UI
func _update_ui():
	# 更新难度选项
	var difficulty_option = $MarginContainer/VBoxContainer/TabContainer/游戏/VBoxContainer/DifficultyContainer/DifficultyOption
	difficulty_option.selected = settings_data.difficulty
	
	# 更新语言选项
	var language_option = $MarginContainer/VBoxContainer/TabContainer/游戏/VBoxContainer/LanguageContainer/LanguageOption
	match settings_data.language:
		"zh_CN":
			language_option.selected = 0
	
	# 更新音量滑块
	var master_volume_slider = $MarginContainer/VBoxContainer/TabContainer/音频/VBoxContainer/MasterVolumeContainer/MasterVolumeSlider
	master_volume_slider.value = settings_data.master_volume
	
	var music_volume_slider = $MarginContainer/VBoxContainer/TabContainer/音频/VBoxContainer/MusicVolumeContainer/MusicVolumeSlider
	music_volume_slider.value = settings_data.music_volume
	
	var sfx_volume_slider = $MarginContainer/VBoxContainer/TabContainer/音频/VBoxContainer/SFXVolumeContainer/SFXVolumeSlider
	sfx_volume_slider.value = settings_data.sfx_volume
	
	# 更新静音复选框
	var mute_check_box = $MarginContainer/VBoxContainer/TabContainer/音频/VBoxContainer/MuteContainer/MuteCheckBox
	mute_check_box.button_pressed = settings_data.mute
	
	# 更新全屏复选框
	var fullscreen_check_box = $MarginContainer/VBoxContainer/TabContainer/图形/VBoxContainer/FullscreenContainer/FullscreenCheckBox
	fullscreen_check_box.button_pressed = settings_data.fullscreen
	
	# 更新垂直同步复选框
	var vsync_check_box = $MarginContainer/VBoxContainer/TabContainer/图形/VBoxContainer/VSyncContainer/VSyncCheckBox
	vsync_check_box.button_pressed = settings_data.vsync
	
	# 更新分辨率选项
	var resolution_option = $MarginContainer/VBoxContainer/TabContainer/图形/VBoxContainer/ResolutionContainer/ResolutionOption
	match settings_data.resolution:
		Vector2i(1280, 720):
			resolution_option.selected = 0
		Vector2i(1920, 1080):
			resolution_option.selected = 1
		Vector2i(2560, 1440):
			resolution_option.selected = 2

# 应用设置
func _apply_settings():
	# 应用难度设置
	GameManager.difficulty_level = settings_data.difficulty
	
	# 应用语言设置
	TranslationServer.set_locale(settings_data.language)
	EventBus.localization.emit_event("language_changed", [settings_data.language])
	
	# 应用音频设置
	GameManager.audio_manager.set_master_volume(settings_data.master_volume)
	GameManager.audio_manager.set_music_volume(settings_data.music_volume)
	GameManager.audio_manager.set_sfx_volume(settings_data.sfx_volume)
	GameManager.audio_manager.set_mute(settings_data.mute)
	
	# 应用图形设置
	if settings_data.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings_data.vsync else DisplayServer.VSYNC_DISABLED)
	
	DisplayServer.window_set_size(settings_data.resolution)
	
	# 保存设置
	_save_settings()

# 关闭请求处理
func _on_close_requested():
	hide()

# 难度选项选择处理
func _on_difficulty_option_item_selected(index):
	settings_data.difficulty = index

# 语言选项选择处理
func _on_language_option_item_selected(index):
	match index:
		0:
			settings_data.language = "zh_CN"

# 主音量滑块值变化处理
func _on_master_volume_slider_value_changed(value):
	settings_data.master_volume = value

# 音乐音量滑块值变化处理
func _on_music_volume_slider_value_changed(value):
	settings_data.music_volume = value

# 音效音量滑块值变化处理
func _on_sfx_volume_slider_value_changed(value):
	settings_data.sfx_volume = value

# 静音复选框切换处理
func _on_mute_check_box_toggled(button_pressed):
	settings_data.mute = button_pressed

# 全屏复选框切换处理
func _on_fullscreen_check_box_toggled(button_pressed):
	settings_data.fullscreen = button_pressed

# 垂直同步复选框切换处理
func _on_v_sync_check_box_toggled(button_pressed):
	settings_data.vsync = button_pressed

# 分辨率选项选择处理
func _on_resolution_option_item_selected(index):
	match index:
		0:
			settings_data.resolution = Vector2i(1280, 720)
		1:
			settings_data.resolution = Vector2i(1920, 1080)
		2:
			settings_data.resolution = Vector2i(2560, 1440)

# 应用按钮点击处理
func _on_apply_button_pressed():
	_apply_settings()
	hide()

# 取消按钮点击处理
func _on_cancel_button_pressed():
	# 恢复原始设置
	settings_data = original_settings.duplicate(true)
	hide()
