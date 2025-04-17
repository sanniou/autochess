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

	# 获取特效管理器
	var game_manager = source.get_node_or_null("/root/GameManager")
	if not game_manager or not game_manager.effect_manager:
		return null

	# 创建对应类型的效果
	var effect = null
	match effect_type:
		"damage":
			# 创建伤害特效
			var params = {
				"damage_type": effect_data.get("damage_type", "magical"),
				"damage_amount": effect_data.get("value", 0.0)
			}

			# 使用特效管理器创建特效
			game_manager.effect_manager.create_effect(game_manager.effect_manager.EffectType.DAMAGE, target, params)

			# 直接造成伤害
			target.take_damage(effect_data.get("value", 0.0), effect_data.get("damage_type", "magical"), source)

			# 创建一个空的效果对象作为占位符
			effect = AbilityEffect.new()

		"heal":
			# 创建治疗特效
			var params = {
				"heal_amount": effect_data.get("value", 0.0)
			}

			# 使用特效管理器创建特效
			game_manager.effect_manager.create_effect(game_manager.effect_manager.EffectType.HEAL, target, params)

			# 直接治疗
			target.heal(effect_data.get("value", 0.0))

			# 创建一个空的效果对象作为占位符
			effect = AbilityEffect.new()

		"buff":
			# 创建增益特效
			var params = {
				"buff_type": effect_data.get("buff_type", "attack")
			}

			# 使用特效管理器创建特效
			game_manager.effect_manager.create_effect(game_manager.effect_manager.EffectType.BUFF, target, params)

			# 创建一个空的效果对象作为占位符
			effect = AbilityEffect.new()
			effect.type = EffectType.BUFF
			effect.value = effect_data.get("value", 0.0)
			effect.duration = effect_data.get("duration", 0.0)
			effect.delay = effect_data.get("delay", 0.0)
			effect.source = source
			effect.target = target

		"debuff":
			# 创建减益特效
			var params = {
				"debuff_type": effect_data.get("debuff_type", "attack")
			}

			# 使用特效管理器创建特效
			game_manager.effect_manager.create_effect(game_manager.effect_manager.EffectType.DEBUFF, target, params)

			# 创建一个空的效果对象作为占位符
			effect = AbilityEffect.new()
			effect.type = EffectType.DEBUFF
			effect.value = effect_data.get("value", 0.0)
			effect.duration = effect_data.get("duration", 0.0)
			effect.delay = effect_data.get("delay", 0.0)
			effect.source = source
			effect.target = target

		"control":
			# 创建一个空的效果对象作为占位符
			effect = AbilityEffect.new()
			effect.type = EffectType.CONTROL
			effect.value = effect_data.get("value", 0.0)
			effect.duration = effect_data.get("duration", 0.0)
			effect.delay = effect_data.get("delay", 0.0)
			effect.source = source
			effect.target = target

		"movement":
			# 创建一个空的效果对象作为占位符
			effect = AbilityEffect.new()
			effect.type = EffectType.MOVEMENT
			effect.value = effect_data.get("value", 0.0)
			effect.duration = effect_data.get("duration", 0.0)
			effect.delay = effect_data.get("delay", 0.0)
			effect.source = source
			effect.target = target

		"visual":
			# 创建一个空的效果对象作为占位符
			effect = AbilityEffect.new()
			effect.type = EffectType.VISUAL
			effect.value = effect_data.get("value", 0.0)
			effect.duration = effect_data.get("duration", 0.0)
			effect.delay = effect_data.get("delay", 0.0)
			effect.source = source
			effect.target = target

		"sound":
			# 创建一个空的效果对象作为占位符
			effect = AbilityEffect.new()
			effect.type = EffectType.SOUND
			effect.value = effect_data.get("value", 0.0)
			effect.duration = effect_data.get("duration", 0.0)
			effect.delay = effect_data.get("delay", 0.0)
			effect.source = source
			effect.target = target

	return effect
