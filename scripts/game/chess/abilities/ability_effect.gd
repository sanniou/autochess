extends Resource
class_name AbilityEffect
## 技能效果基类
## 定义技能效果的基本属性和行为

# 效果类型
enum EffectType {
	DAMAGE,         # 伤害
	HEAL,           # 治疗
	BUFF,           # 增益
	DEBUFF,         # 减益
	CONTROL,        # 控制
	MOVEMENT,       # 移动
	SUMMON,         # 召唤
	VISUAL,         # 视觉效果
	SOUND           # 音效
}

# 效果属性
var type: int = EffectType.DAMAGE  # 效果类型
var value: float = 0.0             # 效果值
var duration: float = 0.0          # 持续时间
var delay: float = 0.0             # 延迟时间
var source: ChessPiece = null      # 效果来源
var target: ChessPiece = null      # 效果目标

# 初始化
func _init(p_type: int = EffectType.DAMAGE, p_value: float = 0.0, p_duration: float = 0.0, 
		p_delay: float = 0.0, p_source: ChessPiece = null, p_target: ChessPiece = null) -> void:
	type = p_type
	value = p_value
	duration = p_duration
	delay = p_delay
	source = p_source
	target = p_target

# 应用效果
func apply() -> void:
	# 基础实现，子类应该重写此方法
	pass

# 创建效果
static func create(effect_data: Dictionary, source: ChessPiece, target: ChessPiece) -> AbilityEffect:
	# 获取效果类型
	var effect_type = effect_data.get("type", "damage")
	
	# 创建对应类型的效果
	var effect = null
	match effect_type:
		"damage":
			effect = DamageEffect.new(
				EffectType.DAMAGE,
				effect_data.get("value", 0.0),
				effect_data.get("duration", 0.0),
				effect_data.get("delay", 0.0),
				source,
				target
			)
			effect.damage_type = effect_data.get("damage_type", "magical")
		
		"heal":
			effect = HealEffect.new(
				EffectType.HEAL,
				effect_data.get("value", 0.0),
				effect_data.get("duration", 0.0),
				effect_data.get("delay", 0.0),
				source,
				target
			)
		
		"buff":
			effect = BuffEffect.new(
				EffectType.BUFF,
				effect_data.get("value", 0.0),
				effect_data.get("duration", 0.0),
				effect_data.get("delay", 0.0),
				source,
				target
			)
			effect.buff_type = effect_data.get("buff_type", "attack")
		
		"debuff":
			effect = DebuffEffect.new(
				EffectType.DEBUFF,
				effect_data.get("value", 0.0),
				effect_data.get("duration", 0.0),
				effect_data.get("delay", 0.0),
				source,
				target
			)
			effect.debuff_type = effect_data.get("debuff_type", "attack")
		
		"control":
			effect = ControlEffect.new(
				EffectType.CONTROL,
				effect_data.get("value", 0.0),
				effect_data.get("duration", 0.0),
				effect_data.get("delay", 0.0),
				source,
				target
			)
			effect.control_type = effect_data.get("control_type", "stun")
		
		"movement":
			effect = MovementEffect.new(
				EffectType.MOVEMENT,
				effect_data.get("value", 0.0),
				effect_data.get("duration", 0.0),
				effect_data.get("delay", 0.0),
				source,
				target
			)
			effect.movement_type = effect_data.get("movement_type", "knockback")
			effect.distance = effect_data.get("distance", 1.0)
		
		"visual":
			effect = VisualEffect.new(
				EffectType.VISUAL,
				effect_data.get("value", 0.0),
				effect_data.get("duration", 0.0),
				effect_data.get("delay", 0.0),
				source,
				target
			)
			effect.visual_type = effect_data.get("visual_type", "particle")
			effect.visual_path = effect_data.get("visual_path", "")
		
		"sound":
			effect = SoundEffect.new(
				EffectType.SOUND,
				effect_data.get("value", 0.0),
				effect_data.get("duration", 0.0),
				effect_data.get("delay", 0.0),
				source,
				target
			)
			effect.sound_path = effect_data.get("sound_path", "")
	
	return effect
