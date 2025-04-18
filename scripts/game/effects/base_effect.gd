extends Resource
class_name BaseEffect
## 基础效果类
## 所有效果的基类

# 效果类型枚举
enum EffectType {
	STAT,       # 属性效果（增加/减少属性）
	STATUS,     # 状态效果（眩晕、沉默等）
	DAMAGE,     # 伤害效果
	HEAL,       # 治疗效果
	DOT,        # 持续伤害效果
	VISUAL,     # 纯视觉效果
	SOUND       # 音效
}

# 基本属性
var id: String = ""                # 唯一标识符
var type: int = EffectType.STAT    # 效果类型
var name: String = ""              # 效果名称
var description: String = ""       # 效果描述
var duration: float = 0.0          # 持续时间（秒）
var value: float = 0.0             # 效果值
var source = null                  # 效果来源
var target = null                  # 效果目标
var is_debuff: bool = false        # 是否为减益效果
var icon: String = ""              # 效果图标
var visual_effect: String = ""     # 视觉效果资源路径
var sound_effect: String = ""      # 音效资源路径

# 初始化
func _init(p_id: String = "", p_type: int = EffectType.STAT, p_name: String = "",
		p_description: String = "", p_duration: float = 0.0, p_value: float = 0.0,
		p_source = null, p_target = null, p_is_debuff: bool = false) -> void:
	# 如果没有提供 ID，生成一个唯一的 ID
	if p_id.is_empty():
		id = "effect_" + str(randi()) + "_" + str(Time.get_ticks_msec())
	else:
		id = p_id

	type = p_type
	name = p_name
	description = p_description
	duration = p_duration
	value = p_value
	source = p_source
	target = p_target
	is_debuff = p_is_debuff

# 应用效果
func apply() -> void:
	# 基类不做任何事情，子类应该重写此方法
	pass

# 移除效果
func remove() -> void:
	# 基类不做任何事情，子类应该重写此方法
	pass

# 更新效果
func update(delta: float) -> bool:
	# 返回 true 表示效果仍然有效，false 表示效果已结束
	if duration > 0:
		duration -= delta
		return duration > 0
	return true

# 创建视觉效果
func create_visual_effect() -> Node:
	# 如果有视觉效果资源路径，加载并实例化
	if visual_effect and ResourceLoader.exists(visual_effect):
		var visual_scene = load(visual_effect)
		if visual_scene:
			var visual_instance = visual_scene.instantiate()
			return visual_instance
	return null

# 播放音效
func play_sound_effect() -> void:
	# 如果有音效资源路径，播放音效
	if sound_effect and target and is_instance_valid(target):
		# 获取音频管理器
		var audio_manager = null
		if Engine.has_singleton("AudioManager"):
			audio_manager = Engine.get_singleton("AudioManager")
		else:
			audio_manager = target.get_node_or_null("/root/AudioManager")

		# 播放音效
		if audio_manager and audio_manager.has_method("play_sound"):
			audio_manager.play_sound(sound_effect, target.global_position)

# 获取效果数据
func get_data() -> Dictionary:
	return {
		"id": id,
		"type": type,
		"name": name,
		"description": description,
		"duration": duration,
		"value": value,
		"is_debuff": is_debuff,
		"icon": icon,
		"visual_effect": visual_effect,
		"sound_effect": sound_effect
	}

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> BaseEffect:
	var effect = BaseEffect.new(
		data.get("id", ""),
		data.get("type", EffectType.STAT),
		data.get("name", ""),
		data.get("description", ""),
		data.get("duration", 0.0),
		data.get("value", 0.0),
		source,
		target,
		data.get("is_debuff", false)
	)

	effect.icon = data.get("icon", "")
	effect.visual_effect = data.get("visual_effect", "")
	effect.sound_effect = data.get("sound_effect", "")

	return effect

# 创建效果实例
static func create(effect_type: int, params: Dictionary = {}, source = null, target = null) -> BaseEffect:
	# 获取特效管理器
	var game_manager = Engine.get_singleton("GameManager")
	if not game_manager or not game_manager.effect_manager:
		# 如果没有特效管理器，直接创建基础效果
		return BaseEffect.new(
			params.get("id", ""),
			effect_type,
			params.get("name", ""),
			params.get("description", ""),
			params.get("duration", 0.0),
			params.get("value", 0.0),
			source,
			target,
			params.get("is_debuff", false)
		)

	# 使用特效管理器创建效果
	return game_manager.effect_manager.create_and_add_effect(effect_type, source, target, params)
