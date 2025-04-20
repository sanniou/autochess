extends BattleEffect
class_name SoundEffect
## 声音效果
## 用于播放声音效果

# 声音类型枚举
enum SoundType {
	ATTACK,     # 攻击声音
	ABILITY,    # 技能声音
	DAMAGE,     # 受伤声音
	DEATH,      # 死亡声音
	HEAL,       # 治疗声音
	BUFF,       # 增益声音
	DEBUFF,     # 减益声音
	MOVEMENT,   # 移动声音
	AMBIENT,    # 环境声音
	UI          # 界面声音
}

# 声音效果属性
var sound_type: int = SoundType.ATTACK
var sound_path: String = ""
var volume_db: float = 0.0
var pitch_scale: float = 1.0
var audio_player: AudioStreamPlayer2D = null

# 初始化
func _init(effect_id: String = "", effect_name: String = "", effect_description: String = "", 
		sound_type_value: int = SoundType.ATTACK, sound_path_value: String = "",
		effect_source = null, effect_target = null, effect_params: Dictionary = {}):
	super._init(effect_id, effect_name, effect_description, 0.0, 
			EffectType.SOUND, effect_source, effect_target, effect_params)
	
	sound_type = sound_type_value
	sound_path = sound_path_value
	
	# 设置音量和音调
	if effect_params.has("volume_db"):
		volume_db = effect_params.volume_db
	
	if effect_params.has("pitch_scale"):
		pitch_scale = effect_params.pitch_scale
	
	# 如果没有指定声音路径，使用默认路径
	if sound_path.is_empty():
		sound_path = _get_default_sound_path(sound_type)
	
	# 设置图标路径
	icon_path = _get_sound_icon_path(sound_type)
	
	# 设置名称和描述
	if name.is_empty():
		name = _get_sound_name(sound_type)
	
	if description.is_empty():
		description = _get_sound_description(sound_type)

# 应用效果
func apply() -> bool:
	if not super.apply():
		return false
	
	# 播放声音
	_play_sound()
	
	# 声音效果是一次性的，应用后立即过期
	expire()
	
	return true

# 移除效果
func remove() -> bool:
	if not super.remove():
		return false
	
	# 停止声音
	_stop_sound()
	
	return true

# 播放声音
func _play_sound() -> void:
	# 检查声音路径
	if sound_path.is_empty():
		return
	
	# 加载声音资源
	var sound_resource = load(sound_path)
	if not sound_resource:
		return
	
	# 创建音频播放器
	audio_player = AudioStreamPlayer2D.new()
	
	# 设置音频流
	audio_player.stream = sound_resource
	
	# 设置音量和音调
	audio_player.volume_db = volume_db
	audio_player.pitch_scale = pitch_scale
	
	# 设置位置
	if target and is_instance_valid(target):
		audio_player.global_position = target.global_position
	elif source and is_instance_valid(source):
		audio_player.global_position = source.global_position
	
	# 添加到场景树
	if target and is_instance_valid(target):
		target.add_child(audio_player)
	elif source and is_instance_valid(source):
		source.add_child(audio_player)
	else:
		var scene_root = Engine.get_main_loop().current_scene
		scene_root.add_child(audio_player)
	
	# 播放声音
	audio_player.play()
	
	# 连接播放完成信号
	audio_player.finished.connect(_on_audio_finished)

# 停止声音
func _stop_sound() -> void:
	if audio_player and is_instance_valid(audio_player):
		audio_player.stop()
		audio_player.queue_free()
		audio_player = null

# 音频播放完成回调
func _on_audio_finished() -> void:
	if audio_player and is_instance_valid(audio_player):
		audio_player.queue_free()
		audio_player = null

# 获取默认声音路径
func _get_default_sound_path(sound_type: int) -> String:
	match sound_type:
		SoundType.ATTACK:
			return "res://assets/sounds/effects/attack.wav"
		SoundType.ABILITY:
			return "res://assets/sounds/effects/ability.wav"
		SoundType.DAMAGE:
			return "res://assets/sounds/effects/damage.wav"
		SoundType.DEATH:
			return "res://assets/sounds/effects/death.wav"
		SoundType.HEAL:
			return "res://assets/sounds/effects/heal.wav"
		SoundType.BUFF:
			return "res://assets/sounds/effects/buff.wav"
		SoundType.DEBUFF:
			return "res://assets/sounds/effects/debuff.wav"
		SoundType.MOVEMENT:
			return "res://assets/sounds/effects/movement.wav"
		SoundType.AMBIENT:
			return "res://assets/sounds/effects/ambient.wav"
		SoundType.UI:
			return "res://assets/sounds/effects/ui.wav"
	
	return ""

# 获取声音类型图标路径
func _get_sound_icon_path(sound_type: int) -> String:
	match sound_type:
		SoundType.ATTACK:
			return "res://assets/icons/effects/sound_attack.png"
		SoundType.ABILITY:
			return "res://assets/icons/effects/sound_ability.png"
		SoundType.DAMAGE:
			return "res://assets/icons/effects/sound_damage.png"
		SoundType.DEATH:
			return "res://assets/icons/effects/sound_death.png"
		SoundType.HEAL:
			return "res://assets/icons/effects/sound_heal.png"
		SoundType.BUFF:
			return "res://assets/icons/effects/sound_buff.png"
		SoundType.DEBUFF:
			return "res://assets/icons/effects/sound_debuff.png"
		SoundType.MOVEMENT:
			return "res://assets/icons/effects/sound_movement.png"
		SoundType.AMBIENT:
			return "res://assets/icons/effects/sound_ambient.png"
		SoundType.UI:
			return "res://assets/icons/effects/sound_ui.png"
	
	return ""

# 获取声音类型名称
func _get_sound_name(sound_type: int) -> String:
	match sound_type:
		SoundType.ATTACK:
			return "攻击音效"
		SoundType.ABILITY:
			return "技能音效"
		SoundType.DAMAGE:
			return "受伤音效"
		SoundType.DEATH:
			return "死亡音效"
		SoundType.HEAL:
			return "治疗音效"
		SoundType.BUFF:
			return "增益音效"
		SoundType.DEBUFF:
			return "减益音效"
		SoundType.MOVEMENT:
			return "移动音效"
		SoundType.AMBIENT:
			return "环境音效"
		SoundType.UI:
			return "界面音效"
	
	return "未知音效"

# 获取声音类型描述
func _get_sound_description(sound_type: int) -> String:
	match sound_type:
		SoundType.ATTACK:
			return "播放攻击音效"
		SoundType.ABILITY:
			return "播放技能音效"
		SoundType.DAMAGE:
			return "播放受伤音效"
		SoundType.DEATH:
			return "播放死亡音效"
		SoundType.HEAL:
			return "播放治疗音效"
		SoundType.BUFF:
			return "播放增益音效"
		SoundType.DEBUFF:
			return "播放减益音效"
		SoundType.MOVEMENT:
			return "播放移动音效"
		SoundType.AMBIENT:
			return "播放环境音效"
		SoundType.UI:
			return "播放界面音效"
	
	return "播放未知音效"

# 获取效果数据
func get_data() -> Dictionary:
	var data = super.get_data()
	data["sound_type"] = sound_type
	data["sound_path"] = sound_path
	data["volume_db"] = volume_db
	data["pitch_scale"] = pitch_scale
	return data

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> SoundEffect:
	return SoundEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("sound_type", SoundType.ATTACK),
		data.get("sound_path", ""),
		source,
		target,
		{
			"volume_db": data.get("volume_db", 0.0),
			"pitch_scale": data.get("pitch_scale", 1.0)
		}
	)
