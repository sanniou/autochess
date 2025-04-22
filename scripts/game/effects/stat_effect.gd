extends GameEffect
class_name StatEffect
## 属性修改效果
## 用于修改目标的属性

# 属性修改值
var stats: Dictionary = {}

# 是否是百分比修改
var is_percentage: bool = false

# 是否是减益效果
var is_debuff: bool = false

# 初始化
func _init(effect_id: String = "", effect_name: String = "", effect_description: String = "",
		effect_duration: float = 0.0, stats_param: Dictionary = {}, is_percentage_param: bool = false,
		effect_source = null, effect_target = null, effect_params: Dictionary = {}):
	super._init(effect_id, effect_name, effect_description, effect_duration,
			EffectType.STAT_MOD, effect_source, effect_target, effect_params)
	
	stats = stats_param
	is_percentage = is_percentage_param
	
	# 设置是否是减益效果
	is_debuff = effect_params.get("is_debuff", false)
	
	# 设置标签
	if is_debuff:
		if not tags.has("debuff"):
			tags.append("debuff")
	else:
		if not tags.has("buff"):
			tags.append("buff")
	
	# 设置图标路径
	icon_path = _get_stat_icon_path(is_debuff)
	
	# 设置名称和描述
	if name.is_empty():
		name = is_debuff ? "减益效果" : "增益效果"
	
	if description.is_empty():
		description = _get_stat_description(stats, is_percentage, is_debuff)

# 应用效果
func apply() -> bool:
	if not super.apply():
		return false
	
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return false
	
	# 检查目标是否可以修改属性
	if not target.has_method("modify_stat"):
		return false
	
	# 修改目标的属性
	for stat_name in stats:
		var value = stats[stat_name]
		target.modify_stat(stat_name, value, is_percentage)
	
	# 发送属性修改事件
	if EventBus:
		EventBus.emit_signal("stat_modified", {
			"source": source,
			"target": target,
			"stats": stats,
			"is_percentage": is_percentage,
			"is_debuff": is_debuff
		})
	
	return true

# 移除效果
func remove() -> bool:
	if not super.remove():
		return false
	
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return false
	
	# 检查目标是否可以修改属性
	if not target.has_method("modify_stat"):
		return false
	
	# 恢复目标的属性
	for stat_name in stats:
		var value = -stats[stat_name]  # 取反值
		target.modify_stat(stat_name, value, is_percentage)
	
	return true

# 获取属性图标路径
func _get_stat_icon_path(is_debuff: bool) -> String:
	if is_debuff:
		return "res://assets/icons/stats/debuff.png"
	else:
		return "res://assets/icons/stats/buff.png"

# 获取属性描述
func _get_stat_description(stats: Dictionary, is_percentage: bool, is_debuff: bool) -> String:
	var desc = ""
	var prefix = is_debuff ? "降低" : "提高"
	var suffix = is_percentage ? "%" : ""
	
	for stat_name in stats:
		var value = stats[stat_name]
		var stat_display_name = _get_stat_display_name(stat_name)
		
		if desc.length() > 0:
			desc += "，"
		
		desc += prefix + " " + stat_display_name + " " + str(abs(value)) + suffix
	
	return desc

# 获取属性显示名称
func _get_stat_display_name(stat_name: String) -> String:
	match stat_name:
		"health":
			return "生命值"
		"max_health":
			return "最大生命值"
		"mana":
			return "魔法值"
		"max_mana":
			return "最大魔法值"
		"attack":
			return "攻击力"
		"defense":
			return "防御力"
		"magic_attack":
			return "魔法攻击"
		"magic_defense":
			return "魔法防御"
		"speed":
			return "速度"
		"critical_chance":
			return "暴击率"
		"critical_damage":
			return "暴击伤害"
		"dodge":
			return "闪避率"
		"accuracy":
			return "命中率"
		"cooldown_reduction":
			return "冷却缩减"
		"damage_reduction":
			return "伤害减免"
		"healing_bonus":
			return "治疗加成"
	
	return stat_name

# 获取效果数据
func get_data() -> Dictionary:
	var data = super.get_data()
	data["stats"] = stats.duplicate()
	data["is_percentage"] = is_percentage
	data["is_debuff"] = is_debuff
	return data

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> StatEffect:
	return StatEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("duration", 0.0),
		data.get("stats", {}),
		data.get("is_percentage", false),
		source,
		target,
		data.get("params", {})
	)
