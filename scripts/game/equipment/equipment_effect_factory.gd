extends Node
class_name EquipmentEffectFactory
## 装备效果工厂
## 负责创建和管理各种装备效果

# 效果类型枚举
enum EffectType {
	STAT_BOOST,         # 属性提升
	ON_ATTACK,          # 攻击时触发
	ON_DAMAGED,         # 受伤时触发
	ON_ABILITY,         # 技能释放时触发
	ON_KILL,            # 击杀时触发
	ON_LOW_HEALTH,      # 低生命值时触发
	PERIODIC,           # 周期性触发
	AURA,               # 光环效果
	UNIQUE              # 唯一效果
}

# 效果子类型枚举
enum EffectSubType {
	DAMAGE,             # 伤害
	HEAL,               # 治疗
	CONTROL,            # 控制
	BUFF,               # 增益
	DEBUFF,             # 减益
	SUMMON,             # 召唤
	SPECIAL             # 特殊
}

# 创建效果
static func create_effect(effect_data: Dictionary) -> Dictionary:
	# 复制效果数据
	var effect = effect_data.duplicate(true)
	
	# 确保有必要的字段
	if not effect.has("id"):
		effect.id = "effect_" + str(randi())
	if not effect.has("description"):
		effect.description = "装备效果"
	
	return effect

# 创建属性提升效果
static func create_stat_boost_effect(stats: Dictionary, description: String = "") -> Dictionary:
	var effect = {
		"type": EffectType.STAT_BOOST,
		"subtype": EffectSubType.BUFF,
		"stats": stats,
		"description": description if description else "提升属性"
	}
	
	return create_effect(effect)

# 创建攻击触发效果
static func create_on_attack_effect(sub_type: int, chance: float, effect_data: Dictionary, description: String = "") -> Dictionary:
	var effect = {
		"type": EffectType.ON_ATTACK,
		"subtype": sub_type,
		"trigger": "attack",
		"chance": chance,
		"description": description if description else "攻击时触发效果"
	}
	
	# 合并效果数据
	for key in effect_data:
		effect[key] = effect_data[key]
	
	return create_effect(effect)

# 创建受伤触发效果
static func create_on_damaged_effect(sub_type: int, chance: float, effect_data: Dictionary, description: String = "") -> Dictionary:
	var effect = {
		"type": EffectType.ON_DAMAGED,
		"subtype": sub_type,
		"trigger": "take_damage",
		"chance": chance,
		"description": description if description else "受伤时触发效果"
	}
	
	# 合并效果数据
	for key in effect_data:
		effect[key] = effect_data[key]
	
	return create_effect(effect)

# 创建技能触发效果
static func create_on_ability_effect(sub_type: int, chance: float, effect_data: Dictionary, description: String = "") -> Dictionary:
	var effect = {
		"type": EffectType.ON_ABILITY,
		"subtype": sub_type,
		"trigger": "ability_cast",
		"chance": chance,
		"description": description if description else "技能释放时触发效果"
	}
	
	# 合并效果数据
	for key in effect_data:
		effect[key] = effect_data[key]
	
	return create_effect(effect)

# 创建击杀触发效果
static func create_on_kill_effect(sub_type: int, effect_data: Dictionary, description: String = "") -> Dictionary:
	var effect = {
		"type": EffectType.ON_KILL,
		"subtype": sub_type,
		"trigger": "kill",
		"description": description if description else "击杀时触发效果"
	}
	
	# 合并效果数据
	for key in effect_data:
		effect[key] = effect_data[key]
	
	return create_effect(effect)

# 创建低生命值触发效果
static func create_on_low_health_effect(sub_type: int, threshold: float, effect_data: Dictionary, description: String = "") -> Dictionary:
	var effect = {
		"type": EffectType.ON_LOW_HEALTH,
		"subtype": sub_type,
		"trigger": "health_percent",
		"threshold": threshold,
		"description": description if description else "生命值低于" + str(int(threshold * 100)) + "%时触发效果"
	}
	
	# 合并效果数据
	for key in effect_data:
		effect[key] = effect_data[key]
	
	return create_effect(effect)

# 创建周期性触发效果
static func create_periodic_effect(sub_type: int, interval: float, effect_data: Dictionary, description: String = "") -> Dictionary:
	var effect = {
		"type": EffectType.PERIODIC,
		"subtype": sub_type,
		"trigger": "periodic",
		"interval": interval,
		"description": description if description else "每" + str(interval) + "秒触发效果"
	}
	
	# 合并效果数据
	for key in effect_data:
		effect[key] = effect_data[key]
	
	return create_effect(effect)

# 创建光环效果
static func create_aura_effect(sub_type: int, radius: float, effect_data: Dictionary, description: String = "") -> Dictionary:
	var effect = {
		"type": EffectType.AURA,
		"subtype": sub_type,
		"trigger": "aura",
		"radius": radius,
		"description": description if description else "光环效果，影响半径" + str(radius) + "内的友军"
	}
	
	# 合并效果数据
	for key in effect_data:
		effect[key] = effect_data[key]
	
	return create_effect(effect)

# 创建唯一效果
static func create_unique_effect(effect_data: Dictionary, description: String = "") -> Dictionary:
	var effect = {
		"type": EffectType.UNIQUE,
		"subtype": EffectSubType.SPECIAL,
		"trigger": "unique",
		"description": description if description else "唯一效果"
	}
	
	# 合并效果数据
	for key in effect_data:
		effect[key] = effect_data[key]
	
	return create_effect(effect)

# 创建伤害效果
static func create_damage_effect(damage: float, damage_type: String = "physical", description: String = "") -> Dictionary:
	return {
		"effect": "damage",
		"damage": damage,
		"damage_type": damage_type,
		"description": description if description else "造成" + str(damage) + "点" + damage_type + "伤害"
	}

# 创建治疗效果
static func create_heal_effect(heal_amount: float, description: String = "") -> Dictionary:
	return {
		"effect": "heal",
		"heal": heal_amount,
		"description": description if description else "恢复" + str(heal_amount) + "点生命值"
	}

# 创建控制效果
static func create_control_effect(control_type: String, duration: float, description: String = "") -> Dictionary:
	return {
		"effect": control_type,
		"duration": duration,
		"description": description if description else control_type + "效果，持续" + str(duration) + "秒"
	}

# 创建增益效果
static func create_buff_effect(stats: Dictionary, duration: float, description: String = "") -> Dictionary:
	return {
		"effect": "buff",
		"stats": stats,
		"duration": duration,
		"description": description if description else "增益效果，持续" + str(duration) + "秒"
	}

# 创建减益效果
static func create_debuff_effect(stats: Dictionary, duration: float, description: String = "") -> Dictionary:
	return {
		"effect": "debuff",
		"stats": stats,
		"duration": duration,
		"description": description if description else "减益效果，持续" + str(duration) + "秒"
	}

# 创建召唤效果
static func create_summon_effect(summon_id: String, count: int = 1, duration: float = 0, description: String = "") -> Dictionary:
	return {
		"effect": "summon",
		"summon_id": summon_id,
		"count": count,
		"duration": duration,
		"description": description if description else "召唤" + str(count) + "个" + summon_id
	}

# 创建特殊效果
static func create_special_effect(effect_name: String, effect_data: Dictionary, description: String = "") -> Dictionary:
	var effect = {
		"effect": effect_name,
		"description": description if description else "特殊效果：" + effect_name
	}
	
	# 合并效果数据
	for key in effect_data:
		effect[key] = effect_data[key]
	
	return effect
