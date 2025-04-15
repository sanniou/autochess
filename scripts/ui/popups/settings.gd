extends BasePopup
class_name Settings
## 设置弹窗
## 用于调整游戏设置

# 设置管理器引用
var settings_manager = null

# 初始化
func _initialize() -> void:
	# 获取设置管理器
	settings_manager = get_node("/root/SettingsManager")
	
	# 连接按钮信号
	if has_node("TabContainer/Audio/MusicVolumeSlider"):
		get_node("TabContainer/Audio/MusicVolumeSlider").value_changed.connect(_on_music_volume_changed)
	
	if has_node("TabContainer/Audio/SfxVolumeSlider"):
		get_node("TabContainer/Audio/SfxVolumeSlider").value_changed.connect(_on_sfx_volume_changed)
	
	if has_node("TabContainer/Audio/UiVolumeSlider"):
		get_node("TabContainer/Audio/UiVolumeSlider").value_changed.connect(_on_ui_volume_changed)
	
	if has_node("TabContainer/Graphics/FullscreenCheckBox"):
		get_node("TabContainer/Graphics/FullscreenCheckBox").toggled.connect(_on_fullscreen_toggled)
	
	if has_node("TabContainer/Graphics/VsyncCheckBox"):
		get_node("TabContainer/Graphics/VsyncCheckBox").toggled.connect(_on_vsync_toggled)
	
	if has_node("TabContainer/Gameplay/LanguageOptionButton"):
		get_node("TabContainer/Gameplay/LanguageOptionButton").item_selected.connect(_on_language_selected)
	
	if has_node("SaveButton"):
		get_node("SaveButton").pressed.connect(_on_save_button_pressed)
	
	if has_node("CancelButton"):
		get_node("CancelButton").pressed.connect(_on_cancel_button_pressed)
	
	# 加载当前设置
	_load_current_settings()
	
	# 调用父类方法
	super._initialize()

# 更新弹窗
func _update_popup() -> void:
	# 设置标题
	title = tr("ui.settings.title")
	
	# 加载当前设置
	_load_current_settings()

# 加载当前设置
func _load_current_settings() -> void:
	if settings_manager == null:
		return
	
	# 加载音频设置
	if has_node("TabContainer/Audio/MusicVolumeSlider"):
		get_node("TabContainer/Audio/MusicVolumeSlider").value = settings_manager.get_setting("audio", "music_volume", 0.8) * 100
	
	if has_node("TabContainer/Audio/SfxVolumeSlider"):
		get_node("TabContainer/Audio/SfxVolumeSlider").value = settings_manager.get_setting("audio", "sfx_volume", 0.8) * 100
	
	if has_node("TabContainer/Audio/UiVolumeSlider"):
		get_node("TabContainer/Audio/UiVolumeSlider").value = settings_manager.get_setting("audio", "ui_volume", 0.8) * 100
	
	# 加载图形设置
	if has_node("TabContainer/Graphics/FullscreenCheckBox"):
		get_node("TabContainer/Graphics/FullscreenCheckBox").button_pressed = settings_manager.get_setting("graphics", "fullscreen", false)
	
	if has_node("TabContainer/Graphics/VsyncCheckBox"):
		get_node("TabContainer/Graphics/VsyncCheckBox").button_pressed = settings_manager.get_setting("graphics", "vsync", true)
	
	# 加载游戏设置
	if has_node("TabContainer/Gameplay/LanguageOptionButton"):
		var language_option = get_node("TabContainer/Gameplay/LanguageOptionButton")
		var current_language = settings_manager.get_setting("gameplay", "language", "zh_CN")
		
		# 查找当前语言的索引
		for i in range(language_option.get_item_count()):
			if language_option.get_item_id(i) == current_language:
				language_option.select(i)
				break

# 音乐音量变化处理
func _on_music_volume_changed(value: float) -> void:
	# 更新音乐音量
	AudioManager.set_music_volume(value / 100.0)
	
	# 播放测试音效
	if value > 0 and !AudioManager.is_music_playing():
		AudioManager.play_music("menu.ogg", false)

# 音效音量变化处理
func _on_sfx_volume_changed(value: float) -> void:
	# 更新音效音量
	AudioManager.set_sfx_volume(value / 100.0)
	
	# 播放测试音效
	if value > 0:
		AudioManager.play_sfx("button_hover.ogg")

# UI音量变化处理
func _on_ui_volume_changed(value: float) -> void:
	# 更新UI音量
	AudioManager.set_ui_volume(value / 100.0)
	
	# 播放测试音效
	if value > 0:
		AudioManager.play_ui_sound("button_click.ogg")

# 全屏切换处理
func _on_fullscreen_toggled(button_pressed: bool) -> void:
	# 更新全屏设置
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# 垂直同步切换处理
func _on_vsync_toggled(button_pressed: bool) -> void:
	# 更新垂直同步设置
	if button_pressed:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

# 语言选择处理
func _on_language_selected(index: int) -> void:
	# 获取语言选项
	var language_option = get_node("TabContainer/Gameplay/LanguageOptionButton")
	var language_code = language_option.get_item_id(index)
	
	# 更新语言设置
	LocalizationManager.set_language(language_code)

# 保存按钮点击处理
func _on_save_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 保存设置
	_save_settings()
	
	# 关闭弹窗
	close_popup()

# 取消按钮点击处理
func _on_cancel_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 恢复原始设置
	_restore_settings()
	
	# 关闭弹窗
	close_popup()

# 保存设置
func _save_settings() -> void:
	if settings_manager == null:
		return
	
	# 保存音频设置
	if has_node("TabContainer/Audio/MusicVolumeSlider"):
		settings_manager.set_setting("audio", "music_volume", get_node("TabContainer/Audio/MusicVolumeSlider").value / 100.0)
	
	if has_node("TabContainer/Audio/SfxVolumeSlider"):
		settings_manager.set_setting("audio", "sfx_volume", get_node("TabContainer/Audio/SfxVolumeSlider").value / 100.0)
	
	if has_node("TabContainer/Audio/UiVolumeSlider"):
		settings_manager.set_setting("audio", "ui_volume", get_node("TabContainer/Audio/UiVolumeSlider").value / 100.0)
	
	# 保存图形设置
	if has_node("TabContainer/Graphics/FullscreenCheckBox"):
		settings_manager.set_setting("graphics", "fullscreen", get_node("TabContainer/Graphics/FullscreenCheckBox").button_pressed)
	
	if has_node("TabContainer/Graphics/VsyncCheckBox"):
		settings_manager.set_setting("graphics", "vsync", get_node("TabContainer/Graphics/VsyncCheckBox").button_pressed)
	
	# 保存游戏设置
	if has_node("TabContainer/Gameplay/LanguageOptionButton"):
		var language_option = get_node("TabContainer/Gameplay/LanguageOptionButton")
		var selected_index = language_option.selected
		var language_code = language_option.get_item_id(selected_index)
		settings_manager.set_setting("gameplay", "language", language_code)
	
	# 保存设置到文件
	settings_manager.save_settings()

# 恢复原始设置
func _restore_settings() -> void:
	if settings_manager == null:
		return
	
	# 恢复音频设置
	var music_volume = settings_manager.get_setting("audio", "music_volume", 0.8)
	var sfx_volume = settings_manager.get_setting("audio", "sfx_volume", 0.8)
	var ui_volume = settings_manager.get_setting("audio", "ui_volume", 0.8)
	
	AudioManager.set_music_volume(music_volume)
	AudioManager.set_sfx_volume(sfx_volume)
	AudioManager.set_ui_volume(ui_volume)
	
	# 恢复图形设置
	var fullscreen = settings_manager.get_setting("graphics", "fullscreen", false)
	var vsync = settings_manager.get_setting("graphics", "vsync", true)
	
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	# 恢复游戏设置
	var language = settings_manager.get_setting("gameplay", "language", "zh_CN")
	LocalizationManager.set_language(language)
