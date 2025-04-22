extends GameEffect
class_name ShieldEffect
## 护盾效果
## 用于为目标提供护盾
# 护盾类型枚举
# 护盾持续分为固定时间或者固定数值两种方式
enum ShieldType {
	NORMAL,     # 普通护盾 普通护盾可以吸收所有类型的伤害
	MAGIC,      # 魔法护盾 魔法护盾只能吸收魔法和元素伤害
	PHYSICAL,   # 物理护盾 物理护盾只能吸收物理伤害
	ELEMENTAL,  # 元素护盾 元素护盾只能吸收元素伤害并免疫控制技能
	REFLECT     # 反射护盾 反射护盾可以吸收所有类型的伤害并反射部分伤害
}

# 护盾值
var shield_amount: float = 0.0

# 当前护盾值
var current_shield: float = 0.0

# 伤害减免百分比
var damage_reduction: float = 0.0

# 伤害反弹百分比
var reflect_percent: float = 0.0

# 护盾类型
var shield_type: int = ShieldType.NORMAL

# 初始化
func _init(effect_id: String = "", effect_name: String = "", effect_description: String = "",
		effect_duration: float = 0.0, shield_amount_param: float = 0.0,
		effect_source = null, effect_target = null, effect_params: Dictionary = {}):
	super._init(effect_id, effect_name, effect_description, effect_duration,
			EffectType.SHIELD, effect_source, effect_target, effect_params)

	shield_amount = shield_amount_param
	current_shield = shield_amount

	# 设置护盾类型
	shield_type = effect_params.get("shield_type", ShieldType.NORMAL)

	# 设置伤害减免百分比
	damage_reduction = effect_params.get("damage_reduction", 0.0)

	# 设置伤害反弹百分比
	reflect_percent = effect_params.get("reflect_percent", 0.0)
	# 如果是反射护盾但没有设置反弹百分比，设置默认值
	if shield_type == ShieldType.REFLECT and reflect_percent <= 0:
		reflect_percent = 0.3  # 默认30%反弹

	# 设置标签
	if not tags.has("shield"):
		tags.append("shield")
	if not tags.has("buff"):
		tags.append("buff")

	# 根据护盾类型添加特定标签
	match shield_type:
		ShieldType.MAGIC:
			if not tags.has("magic_shield"):
				tags.append("magic_shield")
		ShieldType.PHYSICAL:
			if not tags.has("physical_shield"):
				tags.append("physical_shield")
		ShieldType.ELEMENTAL:
			if not tags.has("elemental_shield"):
				tags.append("elemental_shield")
		ShieldType.REFLECT:
			if not tags.has("reflect_shield"):
				tags.append("reflect_shield")

	# 设置图标路径
	icon_path = _get_shield_icon_path(shield_type)

	# 设置名称和描述
	if name.is_empty():
		name = _get_shield_name(shield_type)

	if description.is_empty():
		description = _get_shield_description(shield_amount, damage_reduction, reflect_percent, shield_type)

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

	# 如果是元素护盾，连接控制效果信号
	if shield_type == ShieldType.ELEMENTAL:
		if target.has_signal("control_effect_received"):
			if not target.control_effect_received.is_connected(handle_control_effect):
				target.control_effect_received.connect(handle_control_effect)

	# 发送护盾添加事件
	if EventBus:
		EventBus.emit_signal("shield_added", {
			"source": source,
			"target": target,
			"shield": self,
			"amount": shield_amount,
			"shield_type": shield_type
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

	# 如果是元素护盾，断开控制效果信号
	if shield_type == ShieldType.ELEMENTAL:
		if target.has_signal("control_effect_received"):
			if target.control_effect_received.is_connected(handle_control_effect):
				target.control_effect_received.disconnect(handle_control_effect)

	# 从目标移除护盾
	target.remove_shield(self)

	# 发送护盾移除事件
	if EventBus:
		EventBus.emit_signal("shield_removed", {
			"source": source,
			"target": target,
			"shield": self,
			"remaining": current_shield,
			"shield_type": shield_type
		})

	return true

# 处理目标受到伤害
func _on_target_damage_received(damage_info: Dictionary) -> void:
	# 检查护盾是否已经耗尽
	if current_shield <= 0:
		return

	# 获取伤害值和伤害类型
	var damage_value = damage_info.get("value", 0.0)
	var damage_type = damage_info.get("type", "physical")

	# 检查该护盾是否能吸收这种类型的伤害
	if not _can_absorb_damage_type(damage_type):
		return

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
	if shield_type == ShieldType.REFLECT or reflect_percent > 0:
		if damage_info.has("source") and is_instance_valid(damage_info.source):
			var reflect_damage = absorbed_damage * reflect_percent
			if reflect_damage > 0:
				# 对伤害来源造成反弹伤害
				if damage_info.source.has_method("take_damage"):
					damage_info.source.take_damage(reflect_damage, "reflected", target, false)

				# 发送反弹伤害事件
				if EventBus:
					EventBus.emit_signal("shield_reflected", {
						"shield": self,
						"target": target,
						"source": damage_info.source,
						"value": reflect_damage
					})

	# 发送护盾吸收事件
	if EventBus:
		EventBus.emit_signal("shield_absorbed", {
			"shield": self,
			"target": target,
			"absorbed": absorbed_damage,
			"remaining": current_shield,
			"damage_type": damage_type
		})

	# 如果护盾已经耗尽，移除效果
	if current_shield <= 0:
		remove()

# 检查护盾是否能吸收指定类型的伤害
func _can_absorb_damage_type(damage_type: String) -> bool:
	match shield_type:
		ShieldType.NORMAL, ShieldType.REFLECT:
			# 普通护盾和反射护盾可以吸收所有类型的伤害
			return true
		ShieldType.MAGIC:
			# 魔法护盾只能吸收魔法和元素伤害
			return damage_type == "magical" or damage_type == "elemental" or damage_type.ends_with("_magic")
		ShieldType.PHYSICAL:
			# 物理护盾只能吸收物理伤害
			return damage_type == "physical" or damage_type == "blunt" or damage_type == "piercing" or damage_type == "slashing"
		ShieldType.ELEMENTAL:
			# 元素护盾只能吸收元素伤害
			return damage_type == "elemental" or damage_type == "fire" or damage_type == "ice" or damage_type == "lightning" or damage_type == "poison" or damage_type == "acid"
		_:
			return true

# 处理控制效果
func handle_control_effect(control_info: Dictionary) -> bool:
	# 如果是元素护盾，免疫控制效果
	if shield_type == ShieldType.ELEMENTAL and current_shield > 0:
		# 发送免疫控制事件
		if EventBus:
			EventBus.emit_signal("control_immunity", {
				"shield": self,
				"target": target,
				"control_type": control_info.get("type", "")
			})

		return true  # 免疫控制

	return false  # 不免疫控制

# 获取护盾图标路径
func _get_shield_icon_path(shield_type: int) -> String:
	match shield_type:
		ShieldType.NORMAL:
			return "res://assets/icons/shield/shield.png"
		ShieldType.MAGIC:
			return "res://assets/icons/shield/magic_shield.png"
		ShieldType.PHYSICAL:
			return "res://assets/icons/shield/physical_shield.png"
		ShieldType.ELEMENTAL:
			return "res://assets/icons/shield/elemental_shield.png"
		ShieldType.REFLECT:
			return "res://assets/icons/shield/reflect_shield.png"

	return "res://assets/icons/shield/shield.png"

# 获取护盾名称
func _get_shield_name(shield_type: int) -> String:
	match shield_type:
		ShieldType.NORMAL:
			return "护盾"
		ShieldType.MAGIC:
			return "魔法护盾"
		ShieldType.PHYSICAL:
			return "物理护盾"
		ShieldType.ELEMENTAL:
			return "元素护盾"
		ShieldType.REFLECT:
			return "反射护盾"

	return "护盾"

# 获取护盾描述
func _get_shield_description(shield_amount: float, damage_reduction: float, reflect_percent: float, shield_type: int = ShieldType.NORMAL) -> String:
	var desc = ""

	# 根据护盾类型生成基础描述
	match shield_type:
		ShieldType.NORMAL:
			desc = "提供 " + str(shield_amount) + " 点护盾，可吸收所有类型的伤害"
		ShieldType.MAGIC:
			desc = "提供 " + str(shield_amount) + " 点魔法护盾，只能吸收魔法和元素伤害"
		ShieldType.PHYSICAL:
			desc = "提供 " + str(shield_amount) + " 点物理护盾，只能吸收物理伤害"
		ShieldType.ELEMENTAL:
			desc = "提供 " + str(shield_amount) + " 点元素护盾，只能吸收元素伤害，并免疫控制技能"
		ShieldType.REFLECT:
			desc = "提供 " + str(shield_amount) + " 点反射护盾，可吸收所有类型的伤害"
		_:
			desc = "提供 " + str(shield_amount) + " 点护盾"

	# 添加伤害减免描述
	if damage_reduction > 0:
		desc += "，减免 " + str(int(damage_reduction * 100)) + "% 伤害"

	# 添加伤害反弹描述
	if reflect_percent > 0:
		desc += "，反弹 " + str(int(reflect_percent * 100)) + "% 伤害"

	# 添加持续方式描述
	if duration > 0:
		desc += "，持续 " + str(duration) + " 秒"
	else:
		desc += "，直到护盾被打破"

	return desc

# 获取效果数据
func get_data() -> Dictionary:
	var data = super.get_data()
	data["shield_amount"] = shield_amount
	data["current_shield"] = current_shield
	data["damage_reduction"] = damage_reduction
	data["reflect_percent"] = reflect_percent
	data["shield_type"] = shield_type
	return data

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> ShieldEffect:
	# 准备参数
	var params = data.get("params", {}).duplicate()

	# 添加护盾类型参数
	params["shield_type"] = data.get("shield_type", ShieldType.NORMAL)

	# 添加伤害减免参数
	params["damage_reduction"] = data.get("damage_reduction", 0.0)

	# 添加伤害反弹参数
	params["reflect_percent"] = data.get("reflect_percent", 0.0)

	var effect = ShieldEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("duration", 0.0),
		data.get("shield_amount", 0.0),
		source,
		target,
		params
	)

	effect.current_shield = data.get("current_shield", effect.shield_amount)

	return effect
