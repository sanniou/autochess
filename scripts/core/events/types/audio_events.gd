extends RefCounted
class_name AudioEvents
## 音频事件类型
## 定义与音频系统相关的事件

## 播放音效事件
class PlaySoundEvent extends Event:
	## 音效ID
	var sound_id: String
	
	## 音量
	var volume: float
	
	## 音高
	var pitch: float
	
	## 初始化
	func _init(p_sound_id: String, p_volume: float = 1.0, p_pitch: float = 1.0):
		sound_id = p_sound_id
		volume = p_volume
		pitch = p_pitch
	
	## 获取事件类型
	func get_type() -> String:
		return "audio.play_sound"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "PlaySoundEvent[sound_id=%s, volume=%.1f, pitch=%.1f]" % [
			sound_id, volume, pitch
		]
	
	## 克隆事件
	func clone() -> Event:
		var event = PlaySoundEvent.new(sound_id, volume, pitch)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 播放音乐事件
class PlayMusicEvent extends Event:
	## 音乐ID
	var music_id: String
	
	## 音量
	var volume: float
	
	## 淡入时间
	var fade_in: float
	
	## 初始化
	func _init(p_music_id: String, p_volume: float = 1.0, p_fade_in: float = 0.0):
		music_id = p_music_id
		volume = p_volume
		fade_in = p_fade_in
	
	## 获取事件类型
	func get_type() -> String:
		return "audio.play_music"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "PlayMusicEvent[music_id=%s, volume=%.1f, fade_in=%.1f]" % [
			music_id, volume, fade_in
		]
	
	## 克隆事件
	func clone() -> Event:
		var event = PlayMusicEvent.new(music_id, volume, fade_in)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 停止音乐事件
class StopMusicEvent extends Event:
	## 淡出时间
	var fade_out: float
	
	## 初始化
	func _init(p_fade_out: float = 0.0):
		fade_out = p_fade_out
	
	## 获取事件类型
	func get_type() -> String:
		return "audio.stop_music"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "StopMusicEvent[fade_out=%.1f]" % [fade_out]
	
	## 克隆事件
	func clone() -> Event:
		var event = StopMusicEvent.new(fade_out)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 设置音量事件
class SetVolumeEvent extends Event:
	## 音频类型
	var audio_type: String
	
	## 音量
	var volume: float
	
	## 初始化
	func _init(p_audio_type: String, p_volume: float):
		audio_type = p_audio_type
		volume = p_volume
	
	## 获取事件类型
	func get_type() -> String:
		return "audio.set_volume"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "SetVolumeEvent[audio_type=%s, volume=%.1f]" % [
			audio_type, volume
		]
	
	## 克隆事件
	func clone() -> Event:
		var event = SetVolumeEvent.new(audio_type, volume)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event
