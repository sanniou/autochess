extends GameEffect
class_name HealEffect
## 治疗效果
## 用于恢复目标的生命值

# 治疗值
var heal_value: float = 0.0

# 是否暴击
var is_critical: bool = false

# 暴击倍率
var critical_multiplier: float = 1.5

# 初始化
func _init(effect_id: String = "", effect_name: String = "", effect_description: String = "",
		effect_duration: float = 0.0, heal_value_param: float = 0.0,
		effect_source = null, effect_target = null, effect_params: Dictionary = {}):
	super._init(effect_id, effect_name, effect_description, effect_duration,
			EffectType.HEAL, effect_source, effect_target, effect_params)
	
	heal_value = heal_value_param
	
	# 设置标签
	if not tags.has("heal"):
		tags.append("heal")
	
	# 设置是否暴击
	is_critical = effect_params.get("is_critical", false)
	
	# 设置暴击倍率
	critical_multiplier = effect_params.get("critical_multiplier", 1.5)
	
	# 如果是暴击，增加治疗量
	if is_critical:
		heal_value *= critical_multiplier
	
	# 设置图标路径
	icon_path = "res://assets/icons/heal/heal.png"
	
	# 设置名称和描述
	if name.is_empty():
		name = "治疗"
	
	if description.is_empty():
		description = _get_heal_description(heal_value, is_critical)

# 应用效果
func apply() -> bool:
	if not super.apply():
		return false
	
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return false
	
	# 检查目标是否可以被治疗
	if not target.has_method("heal"):
		return false
	
	# 对目标进行治疗
	target.heal(heal_value, source, is_critical)
	
	# 发送治疗事件
	GlobalEventBus.battle.dispatch_event(BattleEvents.HealReceivedEvent.new(source,target,heal_value,is_critical))	
	return true

# 获取治疗描述
func _get_heal_description(heal_value: float, is_critical: bool) -> String:
	var desc = "恢复 " + str(heal_value) + " 点生命值"
	
	if is_critical:
		desc += "（暴击！）"
	
	return desc

# 获取效果数据
func get_data() -> Dictionary:
	var data = super.get_data()
	data["heal_value"] = heal_value
	data["is_critical"] = is_critical
	data["critical_multiplier"] = critical_multiplier
	return data

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> HealEffect:
	return HealEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("duration", 0.0),
		data.get("heal_value", 0.0),
		source,
		target,
		data.get("params", {})
	)
