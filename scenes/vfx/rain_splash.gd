extends Node2D
## 雨滴溅落特效
## 显示雨滴落地时的溅落效果

# 初始化
func _ready():
	# 连接粒子完成信号
	$Particles.finished.connect(_on_particles_finished)

# 播放特效
func play() -> void:
	# 显示特效
	visible = true
	
	# 发射粒子
	$Particles.emitting = true
	
	# 播放音效
	_play_sound()

# 播放音效
func _play_sound() -> void:
	# 获取音频管理器
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		# 随机选择一个溅落音效
		var sound_index = randi() % 3 + 1
		var sound_name = "rain_splash" + str(sound_index) + ".ogg"
		
		# 播放音效
		audio_manager.play_sfx(sound_name, {
			"volume": randf_range(0.1, 0.3),
			"pitch_scale": randf_range(0.8, 1.2)
		})

# 粒子完成处理
func _on_particles_finished() -> void:
	# 隐藏特效
	visible = false
