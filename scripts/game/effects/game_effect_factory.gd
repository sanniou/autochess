extends Node
class_name GameEffectFactory
## 游戏效果工厂
## 负责创建各种类型的游戏效果

# 效果类型映射
var effect_type_map = {
	# 状态效果
	"status": {
		"class": StatusEffect,
		"type": GameEffect.EffectType.STATUS
	},
	# 伤害效果
	"damage": {
		"class": DamageEffect,
		"type": GameEffect.EffectType.DAMAGE
	},
	# 治疗效果
	"heal": {
		"class": HealEffect,
		"type": GameEffect.EffectType.HEAL
	},
	# 属性修改效果
	"stat_mod": {
		"class": StatEffect,
		"type": GameEffect.EffectType.STAT_MOD
	},
	# 持续伤害效果
	"dot": {
		"class": DotEffect,
		"type": GameEffect.EffectType.DOT
	},
	# 持续治疗效果
	"hot": {
		"class": HotEffect,
		"type": GameEffect.EffectType.HOT
	},
	# 护盾效果
	"shield": {
		"class": ShieldEffect,
		"type": GameEffect.EffectType.SHIELD
	},
	# 光环效果
	"aura": {
		"class": AuraEffect,
		"type": GameEffect.EffectType.AURA
	},
	# 触发效果
	"trigger": {
		"class": TriggerEffect,
		"type": GameEffect.EffectType.TRIGGER
	},
	# 移动效果
	"movement": {
		"class": MovementEffect,
		"type": GameEffect.EffectType.MOVEMENT
	}
}

# 创建效果
func create_effect(effect_data: Dictionary, source = null, target = null) -> GameEffect:
	# 获取效果类型
	var effect_type_str = effect_data.get("effect_type", "")
	var effect_type_int = -1
	
	# 如果效果类型是字符串，转换为对应的类型
	if effect_type_str is String:
		if effect_type_map.has(effect_type_str):
			effect_type_int = effect_type_map[effect_type_str].type
		else:
			print("GameEffectFactory: 无效的效果类型字符串: " + effect_type_str)
			return null
	# 如果效果类型是整数，直接使用
	elif effect_type_str is int:
		effect_type_int = effect_type_str
	else:
		print("GameEffectFactory: 无效的效果类型: " + str(effect_type_str))
		return null
	
	# 根据效果类型创建对应的效果
	var effect = null
	
	match effect_type_int:
		GameEffect.EffectType.STATUS:
			effect = StatusEffect.new(
				effect_data.get("id", ""),
				effect_data.get("name", "状态效果"),
				effect_data.get("description", ""),
				effect_data.get("duration", 0.0),
				effect_data.get("status_type", 0),
				source,
				target,
				effect_data
			)
		
		GameEffect.EffectType.DAMAGE:
			effect = DamageEffect.new(
				effect_data.get("id", ""),
				effect_data.get("name", "伤害效果"),
				effect_data.get("description", ""),
				0.0,  # 伤害效果通常是瞬时的
				effect_data.get("value", 0.0),
				effect_data.get("damage_type", "physical"),
				source,
				target,
				effect_data
			)
		
		GameEffect.EffectType.HEAL:
			effect = HealEffect.new(
				effect_data.get("id", ""),
				effect_data.get("name", "治疗效果"),
				effect_data.get("description", ""),
				0.0,  # 治疗效果通常是瞬时的
				effect_data.get("value", 0.0),
				source,
				target,
				effect_data
			)
		
		GameEffect.EffectType.STAT_MOD:
			effect = StatEffect.new(
				effect_data.get("id", ""),
				effect_data.get("name", "属性修改效果"),
				effect_data.get("description", ""),
				effect_data.get("duration", 0.0),
				effect_data.get("stats", {}),
				effect_data.get("is_percentage", false),
				source,
				target,
				effect_data
			)
		
		GameEffect.EffectType.DOT:
			effect = DotEffect.new(
				effect_data.get("id", ""),
				effect_data.get("name", "持续伤害效果"),
				effect_data.get("description", ""),
				effect_data.get("duration", 0.0),
				effect_data.get("dot_type", 0),
				effect_data.get("damage_per_second", 0.0),
				effect_data.get("damage_type", "magical"),
				source,
				target,
				effect_data
			)
		
		GameEffect.EffectType.HOT:
			effect = HotEffect.new(
				effect_data.get("id", ""),
				effect_data.get("name", "持续治疗效果"),
				effect_data.get("description", ""),
				effect_data.get("duration", 0.0),
				effect_data.get("heal_per_second", 0.0),
				source,
				target,
				effect_data
			)
		
		GameEffect.EffectType.SHIELD:
			effect = ShieldEffect.new(
				effect_data.get("id", ""),
				effect_data.get("name", "护盾效果"),
				effect_data.get("description", ""),
				effect_data.get("duration", 0.0),
				effect_data.get("shield_amount", 0.0),
				source,
				target,
				effect_data
			)
		
		GameEffect.EffectType.AURA:
			effect = AuraEffect.new(
				effect_data.get("id", ""),
				effect_data.get("name", "光环效果"),
				effect_data.get("description", ""),
				effect_data.get("duration", 0.0),
				effect_data.get("aura_radius", 0.0),
				source,
				target,
				effect_data
			)
		
		GameEffect.EffectType.TRIGGER:
			effect = TriggerEffect.new(
				effect_data.get("id", ""),
				effect_data.get("name", "触发效果"),
				effect_data.get("description", ""),
				effect_data.get("duration", 0.0),
				effect_data.get("trigger_type", ""),
				source,
				target,
				effect_data
			)
		
		GameEffect.EffectType.MOVEMENT:
			effect = MovementEffect.new(
				effect_data.get("id", ""),
				effect_data.get("name", "移动效果"),
				effect_data.get("description", ""),
				effect_data.get("duration", 0.0),
				effect_data.get("movement_type", 0),
				effect_data.get("distance", 0.0),
				source,
				target,
				effect_data
			)
		
		_:
			# 如果是未知类型，创建基础效果
			effect = GameEffect.new(
				effect_data.get("id", ""),
				effect_data.get("name", "未知效果"),
				effect_data.get("description", ""),
				effect_data.get("duration", 0.0),
				effect_type_int,
				source,
				target,
				effect_data
			)
	
	return effect

# 从数据创建效果
func create_effect_from_data(data: Dictionary, source = null, target = null) -> GameEffect:
	# 检查效果类型
	var effect_type = data.get("effect_type", -1)
	
	# 根据效果类型创建相应的效果
	match effect_type:
		GameEffect.EffectType.STATUS:
			return StatusEffect.create_from_data(data, source, target)
		GameEffect.EffectType.DAMAGE:
			return DamageEffect.create_from_data(data, source, target)
		GameEffect.EffectType.HEAL:
			return HealEffect.create_from_data(data, source, target)
		GameEffect.EffectType.STAT_MOD:
			return StatEffect.create_from_data(data, source, target)
		GameEffect.EffectType.DOT:
			return DotEffect.create_from_data(data, source, target)
		GameEffect.EffectType.HOT:
			return HotEffect.create_from_data(data, source, target)
		GameEffect.EffectType.SHIELD:
			return ShieldEffect.create_from_data(data, source, target)
		GameEffect.EffectType.AURA:
			return AuraEffect.create_from_data(data, source, target)
		GameEffect.EffectType.TRIGGER:
			return TriggerEffect.create_from_data(data, source, target)
		GameEffect.EffectType.MOVEMENT:
			return MovementEffect.create_from_data(data, source, target)
		_:
			return GameEffect.create_from_data(data, source, target)

# 注册效果类型
func register_effect_type(type_name: String, effect_class, type_value: int) -> void:
	effect_type_map[type_name] = {
		"class": effect_class,
		"type": type_value
	}
