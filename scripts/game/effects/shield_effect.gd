extends GameEffect
class_name ShieldEffect
## 护盾效果
## 用于为目标提供护盾

# 护盾值
var shield_amount: float = 0.0

# 当前护盾值
var current_shield: float = 0.0

# 伤害减免百分比
var damage_reduction: float = 0.0

# 伤害反弹百分比
var reflect_percent: float = 0.0

# 初始化
func _init(effect_id: String = "", effect_name: String = "", effect_description: String = "",
		effect_duration: float = 0.0, shield_amount_param: float = 0.0,
		effect_source = null, effect_target = null, effect_params: Dictionary = {}):
	super._init(effect_id, effect_name, effect_description, effect_duration,
			EffectType.SHIELD, effect_source, effect_target, effect_params)
	
	shield_amount = shield_amount_param
	current_shield = shield_amount
	
	# 设置伤害减免百分比
	damage_reduction = effect_params.get("damage_reduction", 0.0)
	
	# 设置伤害反弹百分比
	reflect_percent = effect_params.get("reflect_percent", 0.0)
	
	# 设置标签
	if not tags.has("shield"):
		tags.append("shield")
	if not tags.has("buff"):
		tags.append("buff")
	
	# 设置图标路径
	icon_path = "res://assets/icons/shield/shield.png"
	
	# 设置名称和描述
	if name.is_empty():
		name = "护盾"
	
	if description.is_empty():
		description = _get_shield_description(shield_amount, damage_reduction, reflect_percent)

# 应用效果
func apply() -> bool:
	if not super.apply():
		return false
	
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return false
	
	# 检查目标是否可以添加护盾
	if not target.has_method("add_shield"):
		return false
	
	# 为目标添加护盾
	target.add_shield(self)
	
	# 连接目标的伤害信号
	if target.has_signal("damage_received"):
		if not target.damage_received.is_connected(_on_target_damage_received):
			target.damage_received.connect(_on_target_damage_received)
	
	# 发送护盾添加事件
	if EventBus:
		EventBus.emit_signal("shield_added", {
			"source": source,
			"target": target,
			"shield": self,
			"amount": shield_amount
		})
	
	return true

# 移除效果
func remove() -> bool:
	if not super.remove():
		return false
	
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return false
	
	# 检查目标是否可以移除护盾
	if not target.has_method("remove_shield"):
		return false
	
	# 断开目标的伤害信号
	if target.has_signal("damage_received"):
		if target.damage_received.is_connected(_on_target_damage_received):
			target.damage_received.disconnect(_on_target_damage_received)
	
	# 从目标移除护盾
	target.remove_shield(self)
	
	# 发送护盾移除事件
	if EventBus:
		EventBus.emit_signal("shield_removed", {
			"source": source,
			"target": target,
			"shield": self,
			"remaining": current_shield
		})
	
	return true

# 处理目标受到伤害
func _on_target_damage_received(damage_info: Dictionary) -> void:
	# 检查护盾是否已经耗尽
	if current_shield <= 0:
		return
	
	# 获取伤害值
	var damage_value = damage_info.get("value", 0.0)
	
	# 应用伤害减免
	if damage_reduction > 0:
		damage_value *= (1.0 - damage_reduction)
	
	# 计算护盾吸收的伤害
	var absorbed_damage = min(current_shield, damage_value)
	
	# 更新当前护盾值
	current_shield -= absorbed_damage
	
	# 更新伤害值
	damage_info["value"] = damage_value - absorbed_damage
	
	# 应用伤害反弹
	if reflect_percent > 0 and damage_info.has("source") and is_instance_valid(damage_info.source):
		var reflect_damage = absorbed_damage * reflect_percent
		if reflect_damage > 0:
			# 对伤害来源造成反弹伤害
			if damage_info.source.has_method("take_damage"):
				damage_info.source.take_damage(reflect_damage, "reflected", target, false)
	
	# 发送护盾吸收事件
	if EventBus:
		EventBus.emit_signal("shield_absorbed", {
			"shield": self,
			"target": target,
			"absorbed": absorbed_damage,
			"remaining": current_shield
		})
	
	# 如果护盾已经耗尽，移除效果
	if current_shield <= 0:
		remove()

# 获取护盾描述
func _get_shield_description(shield_amount: float, damage_reduction: float, reflect_percent: float) -> String:
	var desc = "提供 " + str(shield_amount) + " 点护盾"
	
	if damage_reduction > 0:
		desc += "，减免 " + str(int(damage_reduction * 100)) + "% 伤害"
	
	if reflect_percent > 0:
		desc += "，反弹 " + str(int(reflect_percent * 100)) + "% 伤害"
	
	return desc

# 获取效果数据
func get_data() -> Dictionary:
	var data = super.get_data()
	data["shield_amount"] = shield_amount
	data["current_shield"] = current_shield
	data["damage_reduction"] = damage_reduction
	data["reflect_percent"] = reflect_percent
	return data

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> ShieldEffect:
	var effect = ShieldEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("duration", 0.0),
		data.get("shield_amount", 0.0),
		source,
		target,
		data.get("params", {})
	)
	
	effect.current_shield = data.get("current_shield", effect.shield_amount)
	effect.damage_reduction = data.get("damage_reduction", 0.0)
	effect.reflect_percent = data.get("reflect_percent", 0.0)
	
	return effect
