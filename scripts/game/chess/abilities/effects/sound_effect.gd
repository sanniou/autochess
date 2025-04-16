extends AbilityEffect
class_name SoundEffect
## 音效效果
## 播放音效

# 音效路径
var sound_path: String = ""  # 音效资源路径

# 应用效果
func apply() -> void:
	# 播放音效
	_play_sound()

# 播放音效
func _play_sound() -> void:
	# 获取音频管理器
	var audio_manager = null
	if Engine.has_singleton("AudioManager"):
		audio_manager = Engine.get_singleton("AudioManager")
	else:
		audio_manager = target.get_node_or_null("/root/AudioManager") if target else null
	
	if audio_manager:
		# 使用音频管理器播放音效
		if sound_path:
			audio_manager.play_sound(sound_path)
		else:
			# 播放默认音效
			audio_manager.play_sound("ability_cast.ogg")
	else:
		# 如果没有音频管理器，直接创建音频播放器
		var audio_player = AudioStreamPlayer.new()
		
		# 加载音频
		if sound_path and ResourceLoader.exists(sound_path):
			var audio_stream = load(sound_path)
			if audio_stream:
				audio_player.stream = audio_stream
		
		# 如果没有有效的音频流，返回
		if not audio_player.stream:
			audio_player.queue_free()
			return
		
		# 添加到场景树
		if target and is_instance_valid(target):
			target.add_child(audio_player)
		else:
			var root = Engine.get_main_loop().root
			root.add_child(audio_player)
		
		# 播放音频
		audio_player.play()
		
		# 设置自动释放
		audio_player.finished.connect(audio_player.queue_free)
