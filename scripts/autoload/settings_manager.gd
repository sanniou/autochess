extends "res://scripts/managers/core/base_manager.gd"
## 设置管理器
## 负责管理游戏设置的保存和加载

# 信号
signal settings_changed(settings: Dictionary)
signal setting_changed(section: String, key: String, value)

# 常量
const SETTINGS_FILE = "user://settings.json"

# 默认设置
const DEFAULT_SETTINGS = {
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 0.8
	},
	"display": {
		"fullscreen": false,
		"vsync": true,
		"resolution": "1280x720"
	},
	"game": {
		"difficulty": 1,  # 0: 简单, 1: 普通, 2: 困难, 3: 专家
		"language": 0,    # 0: 简体中文
		"auto_save": true,
		"show_tutorial": true
	},
	"controls": {
		"mouse_sensitivity": 0.5,
		"invert_y": false,
		"key_bindings": {}
	}
}

# 当前设置
var current_settings = {}

# 初始化
# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "SettingsManager"
	# 添加依赖
	add_dependency("AudioManager")

	# 原 _ready 函数的内容
	# 加载设置
	load_settings()

	# 应用设置
	apply_settings()

	# 加载设置
func load_settings() -> void:
	# 复制默认设置
	current_settings = DEFAULT_SETTINGS.duplicate(true)

	# 检查设置文件是否存在
	if FileAccess.file_exists(SETTINGS_FILE):
		# 打开文件
		var file = FileAccess.open(SETTINGS_FILE, FileAccess.READ)
		var content = file.get_as_text()
		file.close()

		# 解析JSON
		var json = JSON.new()
		var error = json.parse(content)

		if error == OK:
			var data = json.data

			# 合并设置
			_merge_settings(current_settings, data)
		else:
			GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("无法解析设置文件: " + json.get_error_message(), 1))

	# 发送设置变化信号
	settings_changed.emit(current_settings)

# 保存设置
func save_settings(settings: Dictionary = {}) -> void:
	# 如果提供了设置，则更新当前设置
	if not settings.is_empty():
		_merge_settings(current_settings, settings)

	# 转换为JSON
	var json_string = JSON.stringify(current_settings, "\t")

	# 保存到文件
	var file = FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	file.store_string(json_string)
	file.close()

	# 发送设置变化信号
	settings_changed.emit(current_settings)

# 应用设置
func apply_settings() -> void:
	# 应用音频设置
	
	var audio_manager = AudioManager
	audio_manager.set_master_volume(current_settings.audio.master_volume)
	audio_manager.set_music_volume(current_settings.audio.music_volume)
	audio_manager.set_sfx_volume(current_settings.audio.sfx_volume)

	# 应用显示设置
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if current_settings.display.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if current_settings.display.vsync else DisplayServer.VSYNC_DISABLED)

	# 应用分辨率
	var resolution = current_settings.display.resolution.split("x")
	if resolution.size() == 2:
		var width = resolution[0].to_int()
		var height = resolution[1].to_int()
		if width > 0 and height > 0:
			DisplayServer.window_set_size(Vector2i(width, height))

	# 应用语言设置
	# 使用EventBus代替LocalizationManager
	var language_codes = ["zh_CN"]
	if current_settings.game.language < language_codes.size():
		var language_code = language_codes[current_settings.game.language]
		GlobalEventBus.localization.dispatch_event(LocalizationEvents.LanguageChangedEvent.new(language_code))
		GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("通过EventBus设置语言: " + language_code, 0))

# 获取设置
func get_settings() -> Dictionary:
	return current_settings.duplicate(true)

# 获取特定设置
func get_setting(section: String, key: String, default_value = null):
	if current_settings.has(section) and current_settings[section].has(key):
		return current_settings[section][key]
	return default_value

# 设置特定设置
func set_setting(section: String, key: String, value) -> void:
	# 检查部分是否存在
	if not current_settings.has(section):
		current_settings[section] = {}

	# 更新设置
	current_settings[section][key] = value

	# 发送设置变化信号
	setting_changed.emit(section, key, value)

	# 保存设置
	save_settings()

# 重置设置
func reset_settings() -> void:
	# 恢复默认设置
	current_settings = DEFAULT_SETTINGS.duplicate(true)

	# 保存设置
	save_settings()

	# 应用设置
	apply_settings()

# 合并设置
func _merge_settings(target: Dictionary, source: Dictionary) -> void:
	for key in source:
		if target.has(key) and source[key] is Dictionary and target[key] is Dictionary:
			_merge_settings(target[key], source[key])
		else:
			target[key] = source[key]

