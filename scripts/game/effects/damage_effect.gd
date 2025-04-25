extends GameEffect
class_name DamageEffect
## 伤害效果
## 用于对目标造成伤害

# 伤害值
var damage_value: float = 0.0

# 伤害类型
var damage_type: String = "physical"

# 是否暴击
var is_critical: bool = false

# 暴击倍率
var critical_multiplier: float = 1.5

# 初始化
func _init(effect_id: String = "", effect_name: String = "", effect_description: String = "",
		effect_duration: float = 0.0, damage_value_param: float = 0.0, damage_type_param: String = "physical",
		effect_source = null, effect_target = null, effect_params: Dictionary = {}):
	super._init(effect_id, effect_name, effect_description, effect_duration,
			EffectType.DAMAGE, effect_source, effect_target, effect_params)
	
	damage_value = damage_value_param
	damage_type = damage_type_param
	
	# 设置标签
	if not tags.has("damage"):
		tags.append("damage")
	
	# 设置是否暴击
	is_critical = effect_params.get("is_critical", false)
	
	# 设置暴击倍率
	critical_multiplier = effect_params.get("critical_multiplier", 1.5)
	
	# 如果是暴击，增加伤害
	if is_critical:
		damage_value *= critical_multiplier
	
	# 设置图标路径
	icon_path = _get_damage_icon_path(damage_type)
	
	# 设置名称和描述
	if name.is_empty():
		name = _get_damage_name(damage_type)
	
	if description.is_empty():
		description = _get_damage_description(damage_type, damage_value, is_critical)

# 应用效果
func apply() -> bool:
	if not super.apply():
		return false
	
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return false
	
	# 检查目标是否可以受到伤害
	if not target.has_method("take_damage"):
		return false
	
	# 对目标造成伤害
	target.take_damage(damage_value, damage_type, source, is_critical)
	
	# 发送伤害事件
	GlobalEventBus.battle.dispatch_event(BattleEvents.DamageDealtEvent.new(source,target,damage_value,damage_type,is_critical))
	return true

# 获取伤害图标路径
func _get_damage_icon_path(damage_type: String) -> String:
	match damage_type:
		"physical":
			return "res://assets/icons/damage/physical.png"
		"magical":
			return "res://assets/icons/damage/magical.png"
		"true":
			return "res://assets/icons/damage/true.png"
		"fire":
			return "res://assets/icons/damage/fire.png"
		"ice":
			return "res://assets/icons/damage/ice.png"
		"lightning":
			return "res://assets/icons/damage/lightning.png"
		"poison":
			return "res://assets/icons/damage/poison.png"
	
	return "res://assets/icons/damage/physical.png"

# 获取伤害名称
func _get_damage_name(damage_type: String) -> String:
	match damage_type:
		"physical":
			return "物理伤害"
		"magical":
			return "魔法伤害"
		"true":
			return "真实伤害"
		"fire":
			return "火焰伤害"
		"ice":
			return "冰霜伤害"
		"lightning":
			return "闪电伤害"
		"poison":
			return "毒素伤害"
	
	return "未知伤害"

# 获取伤害描述
func _get_damage_description(damage_type: String, damage_value: float, is_critical: bool) -> String:
	var desc = "造成 " + str(damage_value) + " 点" + _get_damage_name(damage_type)
	
	if is_critical:
		desc += "（暴击！）"
	
	return desc

# 获取效果数据
func get_data() -> Dictionary:
	var data = super.get_data()
	data["damage_value"] = damage_value
	data["damage_type"] = damage_type
	data["is_critical"] = is_critical
	data["critical_multiplier"] = critical_multiplier
	return data

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> DamageEffect:
	return DamageEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("duration", 0.0),
		data.get("damage_value", 0.0),
		data.get("damage_type", "physical"),
		source,
		target,
		data.get("params", {})
	)
