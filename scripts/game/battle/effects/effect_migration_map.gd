extends Resource
class_name EffectMigrationMap
## 效果迁移映射
## 用于将旧效果系统的类型映射到新效果系统的类型

# 效果类型映射
static var TYPE_MAP = {
	# 基础效果类型映射
	"BaseEffect": "BattleEffect",
	"StatEffect": "StatEffect",
	"StatusEffect": "StatusEffect",
	"DamageEffect": "DamageEffect",
	"HealEffect": "HealEffect",
	"DotEffect": "DotEffect",
	"BuffEffect": "StatEffect",  # BuffEffect 映射到 StatEffect
	"DebuffEffect": "StatEffect", # DebuffEffect 映射到 StatEffect
	"SoundEffect": "SoundEffect",
	"VisualEffect": "VisualEffect",
	"MovementEffect": "MovementEffect"
}

# 效果类型枚举映射
static var ENUM_MAP = {
	# 旧系统 BaseEffect.EffectType -> 新系统 BattleEffect.EffectType
	"BaseEffect.EffectType.STAT": "BattleEffect.EffectType.STAT_MOD",
	"BaseEffect.EffectType.STATUS": "BattleEffect.EffectType.STATUS",
	"BaseEffect.EffectType.DAMAGE": "BattleEffect.EffectType.DAMAGE",
	"BaseEffect.EffectType.HEAL": "BattleEffect.EffectType.HEAL",
	"BaseEffect.EffectType.DOT": "BattleEffect.EffectType.DOT",
	"BaseEffect.EffectType.VISUAL": "BattleEffect.EffectType.VISUAL",
	"BaseEffect.EffectType.SOUND": "BattleEffect.EffectType.SOUND",
	"BaseEffect.EffectType.MOVEMENT": "BattleEffect.EffectType.MOVEMENT"
}

# 状态类型枚举映射
static var STATUS_TYPE_MAP = {
	# 旧系统 StatusEffect.StatusType -> 新系统 StatusEffect.StatusType
	"StatusEffect.StatusType.STUN": "StatusEffect.StatusType.STUN",
	"StatusEffect.StatusType.SILENCE": "StatusEffect.StatusType.SILENCE",
	"StatusEffect.StatusType.DISARM": "StatusEffect.StatusType.DISARM",
	"StatusEffect.StatusType.ROOT": "StatusEffect.StatusType.ROOT",
	"StatusEffect.StatusType.TAUNT": "StatusEffect.StatusType.TAUNT",
	"StatusEffect.StatusType.FROZEN": "StatusEffect.StatusType.FROZEN"
}

# DOT类型枚举映射
static var DOT_TYPE_MAP = {
	# 旧系统 DotEffect.DotType -> 新系统 DotEffect.DotType
	"DotEffect.DotType.BURNING": "DotEffect.DotType.BURNING",
	"DotEffect.DotType.POISONED": "DotEffect.DotType.POISONED",
	"DotEffect.DotType.BLEEDING": "DotEffect.DotType.BLEEDING"
}

# 增益类型映射到属性字典
static var BUFF_TYPE_MAP = {
	# 旧系统 BuffEffect.BuffType -> 新系统属性字典
	"BuffEffect.BuffType.ATTACK": {"attack_damage": 10.0},
	"BuffEffect.BuffType.DEFENSE": {"armor": 5.0, "magic_resist": 5.0},
	"BuffEffect.BuffType.SPEED": {"attack_speed": 0.2, "move_speed": 20.0},
	"BuffEffect.BuffType.HEALTH": {"max_health": 50.0},
	"BuffEffect.BuffType.SPELL": {"spell_power": 10.0},
	"BuffEffect.BuffType.CRIT": {"crit_chance": 0.1, "crit_damage": 0.2}
}

# 将旧效果转换为新效果
static func convert_effect(old_effect, source = null, target = null) -> BattleEffect:
	var new_effect = null
	
	# 根据旧效果类型创建对应的新效果
	if old_effect is StatEffect:
		new_effect = convert_stat_effect(old_effect, source, target)
	elif old_effect is StatusEffect:
		new_effect = convert_status_effect(old_effect, source, target)
	elif old_effect is DamageEffect:
		new_effect = convert_damage_effect(old_effect, source, target)
	elif old_effect is HealEffect:
		new_effect = convert_heal_effect(old_effect, source, target)
	elif old_effect is DotEffect:
		new_effect = convert_dot_effect(old_effect, source, target)
	elif old_effect is BuffEffect:
		new_effect = convert_buff_effect(old_effect, source, target)
	else:
		# 默认创建基础效果
		new_effect = BattleEffect.new(
			old_effect.id,
			old_effect.name,
			old_effect.description,
			old_effect.duration,
			BattleEffect.EffectType.STATUS,
			source,
			target,
			{}
		)
	
	return new_effect

# 转换属性效果
static func convert_stat_effect(old_effect: StatEffect, source = null, target = null) -> StatEffect:
	return StatEffect.new(
		old_effect.id,
		old_effect.name,
		old_effect.description,
		old_effect.duration,
		old_effect.stats,
		false,  # 是否百分比
		source,
		target,
		{}
	)

# 转换状态效果
static func convert_status_effect(old_effect: StatusEffect, source = null, target = null) -> StatusEffect:
	return StatusEffect.new(
		old_effect.id,
		old_effect.name,
		old_effect.description,
		old_effect.duration,
		old_effect.status_type,
		source,
		target,
		{
			"immunity_time": old_effect.immunity_time,
			"stackable": old_effect.is_stackable,
			"stack_count": old_effect.stack_count
		}
	)

# 转换伤害效果
static func convert_damage_effect(old_effect: DamageEffect, source = null, target = null) -> BattleEffect:
	# 创建伤害效果数据
	var effect_data = {
		"id": old_effect.id,
		"name": old_effect.name,
		"description": old_effect.description,
		"effect_type": BattleEffect.EffectType.DAMAGE,
		"damage_type": old_effect.damage_type,
		"value": old_effect.value,
		"is_critical": old_effect.is_critical,
		"is_dodgeable": old_effect.is_dodgeable
	}
	
	# 使用效果工厂创建效果
	return GameManager.battle_manager.effect_manager.effect_factory.create_effect(effect_data, source, target)

# 转换治疗效果
static func convert_heal_effect(old_effect: HealEffect, source = null, target = null) -> BattleEffect:
	# 创建治疗效果数据
	var effect_data = {
		"id": old_effect.id,
		"name": old_effect.name,
		"description": old_effect.description,
		"effect_type": BattleEffect.EffectType.HEAL,
		"value": old_effect.value
	}
	
	# 使用效果工厂创建效果
	return GameManager.battle_manager.effect_manager.effect_factory.create_effect(effect_data, source, target)

# 转换持续伤害效果
static func convert_dot_effect(old_effect: DotEffect, source = null, target = null) -> DotEffect:
	return DotEffect.new(
		old_effect.id,
		old_effect.name,
		old_effect.description,
		old_effect.duration,
		old_effect.dot_type,
		old_effect.value,  # damage_per_second
		old_effect.damage_type,
		source,
		target,
		{
			"tick_interval": old_effect.tick_interval
		}
	)

# 转换增益效果
static func convert_buff_effect(old_effect: BuffEffect, source = null, target = null) -> StatEffect:
	# 根据增益类型创建属性字典
	var stats = {}
	
	match old_effect.buff_type:
		BuffEffect.BuffType.ATTACK:
			stats["attack_damage"] = old_effect.value
		BuffEffect.BuffType.DEFENSE:
			stats["armor"] = old_effect.value
			stats["magic_resist"] = old_effect.value
		BuffEffect.BuffType.SPEED:
			stats["attack_speed"] = old_effect.value
			stats["move_speed"] = old_effect.value * 10.0
		BuffEffect.BuffType.HEALTH:
			stats["max_health"] = old_effect.value
		BuffEffect.BuffType.SPELL:
			stats["spell_power"] = old_effect.value
		BuffEffect.BuffType.CRIT:
			stats["crit_chance"] = old_effect.value
			stats["crit_damage"] = old_effect.value * 0.5
	
	return StatEffect.new(
		old_effect.id,
		old_effect.name,
		old_effect.description,
		old_effect.duration,
		stats,
		false,  # 是否百分比
		source,
		target,
		{}
	)
