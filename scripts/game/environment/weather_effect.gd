extends Node2D
class_name WeatherEffect
## 天气特效基类
## 所有天气特效的基类，提供基本功能

# 天气参数
var params = {
	"intensity": 1.0,       # 强度
	"duration": 0.0,        # 持续时间，0表示无限
	"area_rect": Rect2(),   # 影响区域
	"wind_direction": Vector2(0, 0),  # 风向
	"wind_strength": 0.0,   # 风力
	"sound_enabled": true,  # 是否启用声音
	"sound_volume": 0.8,    # 声音音量
	"affect_gameplay": true # 是否影响游戏玩法
}

# 粒子系统
var particles = null

# 音效播放器
var audio_player = null

# 初始化
func _ready():
	# 创建粒子系统
	_create_particles()
	
	# 创建音效播放器
	_create_audio_player()
	
	# 应用参数
	_apply_params()

# 初始化参数
func initialize(p_params: Dictionary) -> void:
	# 合并参数
	for key in p_params:
		params[key] = p_params[key]
	
	# 如果已经准备好，应用参数
	if is_inside_tree():
		_apply_params()

# 设置参数
func set_param(key: String, value) -> void:
	# 更新参数
	params[key] = value
	
	# 应用特定参数
	match key:
		"intensity":
			_set_intensity(value)
		"wind_direction":
			_set_wind_direction(value)
		"wind_strength":
			_set_wind_strength(value)
		"sound_enabled":
			_set_sound_enabled(value)
		"sound_volume":
			_set_sound_volume(value)

# 停止特效
func stop() -> void:
	# 停止粒子发射
	if particles:
		particles.emitting = false
	
	# 淡出音效
	if audio_player:
		var tween = create_tween()
		tween.tween_property(audio_player, "volume_db", -80.0, 1.0)
		tween.tween_callback(queue_free)
	else:
		# 如果没有音效，直接移除
		queue_free()

# 创建粒子系统
func _create_particles() -> void:
	# 子类实现
	pass

# 创建音效播放器
func _create_audio_player() -> void:
	# 创建音频播放器
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Weather"
	audio_player.volume_db = linear_to_db(params.sound_volume)
	add_child(audio_player)
	
	# 加载音频流
	var sound_path = _get_sound_path()
	if sound_path and FileAccess.file_exists(sound_path):
		var stream = load(sound_path)
		if stream:
			audio_player.stream = stream
			
			# 如果启用了声音，开始播放
			if params.sound_enabled:
				audio_player.play()

# 应用参数
func _apply_params() -> void:
	# 设置强度
	_set_intensity(params.intensity)
	
	# 设置风向和风力
	_set_wind_direction(params.wind_direction)
	_set_wind_strength(params.wind_strength)
	
	# 设置声音
	_set_sound_enabled(params.sound_enabled)
	_set_sound_volume(params.sound_volume)

# 设置强度
func _set_intensity(value: float) -> void:
	# 子类实现
	pass

# 设置风向
func _set_wind_direction(direction: Vector2) -> void:
	# 子类实现
	pass

# 设置风力
func _set_wind_strength(strength: float) -> void:
	# 子类实现
	pass

# 设置是否启用声音
func _set_sound_enabled(enabled: bool) -> void:
	if audio_player:
		if enabled:
			audio_player.play()
		else:
			audio_player.stop()

# 设置声音音量
func _set_sound_volume(volume: float) -> void:
	if audio_player:
		audio_player.volume_db = linear_to_db(volume)

# 获取音效路径
func _get_sound_path() -> String:
	# 子类实现
	return ""
