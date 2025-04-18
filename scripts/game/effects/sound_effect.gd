extends BaseEffect
class_name SoundEffect
## 音效效果类
## 播放音效

# 初始化
func _init(p_id: String = "", p_name: String = "", p_description: String = "",
		p_sound_path: String = "", p_source = null, p_target = null) -> void:
	super._init(p_id, BaseEffect.EffectType.SOUND, p_name, p_description, 
			0.0, 0.0, p_source, p_target, false)  # 音效效果默认为非减益
	sound_effect = p_sound_path

# 应用效果
func apply() -> void:
	# 播放音效
	play_sound_effect()
	
	# 发送效果应用信号
	EventBus.battle.emit_event("ability_effect_applied", [source, target, "sound", 0])

# 获取效果数据
func get_data() -> Dictionary:
	var data = super.get_data()
	return data

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> SoundEffect:
	return SoundEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("sound_effect", ""),
		source,
		target
	)
