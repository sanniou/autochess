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
var source: ChessPieceEntity = null      # 效果来源
var target: ChessPieceEntity = null      # 效果目标

# 初始化
func _init(p_type: int = EffectType.DAMAGE, p_value: float = 0.0, p_duration: float = 0.0,
		p_delay: float = 0.0, p_source: ChessPieceEntity = null, p_target: ChessPieceEntity = null) -> void:
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
static func create(effect_data: Dictionary, source: ChessPieceEntity, target: ChessPieceEntity) -> AbilityEffect:
	# 获取效果类型
	var effect_type = effect_data.get("type", "damage")

	# 创建对应类型的效果
	var effect = AbilityEffect.new()
	effect.source = source
	effect.target = target
	effect.value = effect_data.get("value", 0.0)
	effect.duration = effect_data.get("duration", 0.0)
	effect.delay = effect_data.get("delay", 0.0)

	# 创建并应用新的效果系统效果
	var base_effect = null

	match effect_type:
		"damage":
			# 设置效果类型
			effect.type = EffectType.DAMAGE

			# 创建伤害效果
			base_effect = DamageEffect.new(
				effect_data.get("id", ""),
				effect_data.get("name", "伤害"),
				effect_data.get("description", "造成伤害"),
				effect_data.get("value", 0.0),
				effect_data.get("damage_type", "magical"),
				source,
				target
			)

			# 设置暴击和闪避
			base_effect.is_critical = effect_data.get("is_critical", false)
			base_effect.is_dodgeable = effect_data.get("is_dodgeable", true)

		"heal":
			# 设置效果类型
			effect.type = EffectType.HEAL

			# 创建治疗效果
			base_effect = HealEffect.new(
				effect_data.get("id", ""),
				effect_data.get("name", "治疗"),
				effect_data.get("description", "恢复生命值"),
				effect_data.get("value", 0.0),
				source,
				target
			)

		"buff":
			# 设置效果类型
			effect.type = EffectType.BUFF

			# 确定增益类型
			var buff_type = BuffEffect.BuffType.ATTACK
			var buff_type_str = effect_data.get("buff_type", "attack")

			match buff_type_str:
				"attack":
					buff_type = BuffEffect.BuffType.ATTACK
				"defense":
					buff_type = BuffEffect.BuffType.DEFENSE
				"speed":
					buff_type = BuffEffect.BuffType.SPEED
				"health":
					buff_type = BuffEffect.BuffType.HEALTH
				"spell_power":
					buff_type = BuffEffect.BuffType.SPELL
				"crit":
					buff_type = BuffEffect.BuffType.CRIT

			# 创建增益效果
			base_effect = BuffEffect.new(
				effect_data.get("id", ""),
				effect_data.get("name", buff_type_str.capitalize() + " Buff"),
				effect_data.get("description", "提升" + buff_type_str + "属性"),
				effect_data.get("duration", 0.0),
				effect_data.get("value", 0.0),
				buff_type,
				source,
				target
			)

		"debuff":
			# 设置效果类型
			effect.type = EffectType.DEBUFF

			# 确定减益类型
			var debuff_type = DebuffEffect.DebuffType.ATTACK
			var debuff_type_str = effect_data.get("debuff_type", "attack")

			match debuff_type_str:
				"attack":
					debuff_type = DebuffEffect.DebuffType.ATTACK
				"defense":
					debuff_type = DebuffEffect.DebuffType.DEFENSE
				"speed":
					debuff_type = DebuffEffect.DebuffType.SPEED
				"health":
					debuff_type = DebuffEffect.DebuffType.HEALTH
				"spell_power":
					debuff_type = DebuffEffect.DebuffType.SPELL
				"crit":
					debuff_type = DebuffEffect.DebuffType.CRIT

			# 创建减益效果
			base_effect = DebuffEffect.new(
				effect_data.get("id", ""),
				effect_data.get("name", debuff_type_str.capitalize() + " Debuff"),
				effect_data.get("description", "降低" + debuff_type_str + "属性"),
				effect_data.get("duration", 0.0),
				effect_data.get("value", 0.0),
				debuff_type,
				source,
				target
			)

		"control":
			# 设置效果类型
			effect.type = EffectType.CONTROL

			# 确定控制类型
			var status_type = StatusEffect.StatusType.STUN
			var control_type_str = effect_data.get("control_type", "stun")

			match control_type_str:
				"stun":
					status_type = StatusEffect.StatusType.STUN
				"silence":
					status_type = StatusEffect.StatusType.SILENCE
				"disarm":
					status_type = StatusEffect.StatusType.DISARM
				"root":
					status_type = StatusEffect.StatusType.ROOT
				"taunt":
					status_type = StatusEffect.StatusType.TAUNT
				"frozen":
					status_type = StatusEffect.StatusType.FROZEN

			# 创建状态效果
			base_effect = StatusEffect.new(
				effect_data.get("id", ""),
				effect_data.get("name", control_type_str.capitalize()),
				effect_data.get("description", "控制目标"),
				effect_data.get("duration", 0.0),
				status_type,
				source,
				target
			)

		"dot":
			# 设置效果类型
			effect.type = EffectType.DAMAGE

			# 确定持续伤害类型
			var dot_type = DotEffect.DotType.BURNING
			var dot_type_str = effect_data.get("dot_type", "burning")

			match dot_type_str:
				"burning":
					dot_type = DotEffect.DotType.BURNING
				"poisoned":
					dot_type = DotEffect.DotType.POISONED
				"bleeding":
					dot_type = DotEffect.DotType.BLEEDING

			# 创建持续伤害效果
			base_effect = DotEffect.new(
				effect_data.get("id", ""),
				effect_data.get("name", dot_type_str.capitalize()),
				effect_data.get("description", "每秒造成伤害"),
				effect_data.get("duration", 0.0),
				effect_data.get("damage_per_second", 0.0),
				effect_data.get("damage_type", "magical"),
				dot_type,
				source,
				target
			)

			# 设置伤害间隔
			base_effect.tick_interval = effect_data.get("tick_interval", 1.0)

		"movement":
			# 设置效果类型
			effect.type = EffectType.MOVEMENT

			# 确定移动类型
			var movement_type = MovementEffect.MovementType.KNOCKBACK
			var movement_type_str = effect_data.get("movement_type", "knockback")

			match movement_type_str:
				"knockback":
					movement_type = MovementEffect.MovementType.KNOCKBACK
				"pull":
					movement_type = MovementEffect.MovementType.PULL
				"teleport":
					movement_type = MovementEffect.MovementType.TELEPORT
				"swap":
					movement_type = MovementEffect.MovementType.SWAP

			# 创建移动效果
			base_effect = MovementEffect.new(
				effect_data.get("id", ""),
				effect_data.get("name", movement_type_str.capitalize()),
				effect_data.get("description", "移动目标"),
				movement_type,
				effect_data.get("distance", 1.0),
				source,
				target
			)

		"visual":
			# 设置效果类型
			effect.type = EffectType.VISUAL

			# 确定视觉效果类型
			var visual_type = VisualEffect.VisualType.PARTICLE
			var visual_type_str = effect_data.get("visual_type", "particle")

			match visual_type_str:
				"particle":
					visual_type = VisualEffect.VisualType.PARTICLE
				"sprite":
					visual_type = VisualEffect.VisualType.SPRITE
				"animation":
					visual_type = VisualEffect.VisualType.ANIMATION
				_:
					visual_type = VisualEffect.VisualType.DEFAULT

			# 创建视觉效果
			base_effect = VisualEffect.new(
				effect_data.get("id", ""),
				effect_data.get("name", "视觉效果"),
				effect_data.get("description", "显示视觉效果"),
				effect_data.get("duration", 1.0),
				visual_type,
				effect_data.get("visual_path", ""),
				source,
				target
			)

		"sound":
			# 设置效果类型
			effect.type = EffectType.SOUND

			# 创建音效效果
			base_effect = SoundEffect.new(
				effect_data.get("id", ""),
				effect_data.get("name", "音效"),
				effect_data.get("description", "播放音效"),
				effect_data.get("sound_path", ""),
				source,
				target
			)

		_:
			# 其他类型暂时保持原来的实现
			effect.type = EffectType.DAMAGE

	# 如果创建了新的效果对象，应用它
	if base_effect and target:
		target.add_effect(base_effect)

	return effect
