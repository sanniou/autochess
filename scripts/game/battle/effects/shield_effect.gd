extends BattleEffect
class_name ShieldEffect
## 护盾效果
## 为目标提供伤害吸收护盾

# 护盾类型枚举
enum ShieldType {
	NORMAL,     # 普通护盾
	MAGIC,      # 魔法护盾
	PHYSICAL,   # 物理护盾
	ELEMENTAL,  # 元素护盾
	REFLECT     # 反射护盾
}

# 护盾效果属性
var shield_type: int = ShieldType.NORMAL
var shield_amount: float = 0.0
var remaining_shield: float = 0.0
var damage_reduction: float = 0.0  # 伤害减免百分比
var reflect_percent: float = 0.0   # 伤害反射百分比
var shield_visual: Node2D = null

# 初始化
func _init(effect_id: String = "", effect_name: String = "", effect_description: String = "", 
		effect_duration: float = 0.0, shield_type_value: int = ShieldType.NORMAL, 
		shield_amount_value: float = 0.0, effect_source = null, effect_target = null, 
		effect_params: Dictionary = {}):
	super._init(effect_id, effect_name, effect_description, effect_duration, 
			EffectType.SHIELD, effect_source, effect_target, effect_params)
	
	shield_type = shield_type_value
	shield_amount = shield_amount_value
	remaining_shield = shield_amount
	
	# 设置伤害减免和反射
	if effect_params.has("damage_reduction"):
		damage_reduction = effect_params.damage_reduction
	
	if effect_params.has("reflect_percent"):
		reflect_percent = effect_params.reflect_percent
	
	# 设置图标路径
	icon_path = _get_shield_icon_path(shield_type)
	
	# 设置名称和描述
	if name.is_empty():
		name = _get_shield_name(shield_type)
	
	if description.is_empty():
		description = _generate_shield_description()

# 应用效果
func apply() -> bool:
	if not super.apply():
		return false
	
	if not target or not is_instance_valid(target):
		return false
	
	# 创建护盾视觉效果
	_create_shield_visual()
	
	# 连接伤害事件
	EventBus.battle.connect_event("damage_dealt", _on_damage_dealt)
	
	return true

# 移除效果
func remove() -> bool:
	if not super.remove():
		return false
	
	# 移除护盾视觉效果
	_remove_shield_visual()
	
	# 断开伤害事件
	EventBus.battle.disconnect_event("damage_dealt", _on_damage_dealt)
	
	return true

# 更新效果
func update(delta: float) -> bool:
	if not super.update(delta):
		return false
	
	# 如果护盾已经耗尽，移除效果
	if remaining_shield <= 0:
		expire()
		return false
	
	# 更新护盾视觉效果
	_update_shield_visual()
	
	return true

# 伤害事件处理
func _on_damage_dealt(source, damage_target, damage_amount: float, damage_type: String) -> void:
	# 检查目标是否是护盾持有者
	if not target or not is_instance_valid(target) or damage_target != target:
		return
	
	# 检查护盾是否可以吸收该类型的伤害
	if not _can_absorb_damage(damage_type):
		return
	
	# 计算护盾吸收的伤害
	var damage_to_absorb = damage_amount
	
	# 应用伤害减免
	if damage_reduction > 0:
		damage_to_absorb *= (1.0 - damage_reduction)
	
	# 计算护盾吸收后的剩余伤害
	var absorbed_damage = min(remaining_shield, damage_to_absorb)
	var remaining_damage = damage_to_absorb - absorbed_damage
	
	# 更新护盾值
	remaining_shield -= absorbed_damage
	
	# 发送护盾吸收事件
	EventBus.battle.emit_event("shield_absorbed", [target, absorbed_damage, self])
	
	# 如果有伤害反射，反射部分伤害
	if reflect_percent > 0 and source and is_instance_valid(source):
		var reflect_damage = absorbed_damage * reflect_percent
		
		# 应用反射伤害
		var battle_manager = GameManager.battle_manager
		if battle_manager:
			battle_manager.apply_damage(target, source, reflect_damage, "reflected")
		
		# 发送伤害反射事件
		EventBus.battle.emit_event("damage_reflected", [target, source, reflect_damage])
	
	# 如果护盾已经耗尽，移除效果
	if remaining_shield <= 0:
		expire()
	
	# 更新护盾视觉效果
	_update_shield_visual()

# 检查是否可以吸收伤害
func _can_absorb_damage(damage_type: String) -> bool:
	match shield_type:
		ShieldType.NORMAL:
			# 普通护盾可以吸收所有类型的伤害
			return true
		
		ShieldType.MAGIC:
			# 魔法护盾只能吸收魔法和元素伤害
			return damage_type == "magical" or damage_type == "fire" or damage_type == "ice" or damage_type == "lightning" or damage_type == "poison"
		
		ShieldType.PHYSICAL:
			# 物理护盾只能吸收物理伤害
			return damage_type == "physical" or damage_type == "bleeding"
		
		ShieldType.ELEMENTAL:
			# 元素护盾只能吸收元素伤害
			return damage_type == "fire" or damage_type == "ice" or damage_type == "lightning" or damage_type == "poison"
		
		ShieldType.REFLECT:
			# 反射护盾可以吸收所有类型的伤害
			return true
	
	return false

# 创建护盾视觉效果
func _create_shield_visual() -> void:
	if not target or not is_instance_valid(target):
		return
	
	# 加载护盾视觉效果场景
	var shield_scene = load("res://scenes/effects/shield_effect_visual.tscn")
	if shield_scene:
		shield_visual = shield_scene.instantiate()
		target.add_child(shield_visual)
		
		# 设置护盾视觉效果参数
		if shield_visual.has_method("initialize"):
			shield_visual.initialize(self)
		
		# 设置护盾颜色
		_set_shield_color()

# 移除护盾视觉效果
func _remove_shield_visual() -> void:
	if shield_visual and is_instance_valid(shield_visual):
		shield_visual.queue_free()
		shield_visual = null

# 更新护盾视觉效果
func _update_shield_visual() -> void:
	if not shield_visual or not is_instance_valid(shield_visual):
		return
	
	# 更新护盾视觉效果
	if shield_visual.has_method("update_shield"):
		shield_visual.update_shield(remaining_shield / shield_amount)

# 设置护盾颜色
func _set_shield_color() -> void:
	if not shield_visual or not is_instance_valid(shield_visual):
		return
	
	var shield_color = Color.WHITE
	
	match shield_type:
		ShieldType.NORMAL:
			shield_color = Color(0.5, 0.5, 1.0, 0.5)  # 蓝色
		ShieldType.MAGIC:
			shield_color = Color(0.5, 0.0, 1.0, 0.5)  # 紫色
		ShieldType.PHYSICAL:
			shield_color = Color(1.0, 0.5, 0.0, 0.5)  # 橙色
		ShieldType.ELEMENTAL:
			shield_color = Color(0.0, 1.0, 0.5, 0.5)  # 绿色
		ShieldType.REFLECT:
			shield_color = Color(1.0, 1.0, 0.0, 0.5)  # 黄色
	
	# 设置护盾颜色
	if shield_visual.has_method("set_color"):
		shield_visual.set_color(shield_color)

# 获取护盾类型图标路径
func _get_shield_icon_path(shield_type: int) -> String:
	match shield_type:
		ShieldType.NORMAL:
			return "res://assets/icons/effects/shield_normal.png"
		ShieldType.MAGIC:
			return "res://assets/icons/effects/shield_magic.png"
		ShieldType.PHYSICAL:
			return "res://assets/icons/effects/shield_physical.png"
		ShieldType.ELEMENTAL:
			return "res://assets/icons/effects/shield_elemental.png"
		ShieldType.REFLECT:
			return "res://assets/icons/effects/shield_reflect.png"
	
	return ""

# 获取护盾类型名称
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
	
	return "未知护盾"

# 生成护盾描述
func _generate_shield_description() -> String:
	var desc = "提供"
	
	match shield_type:
		ShieldType.NORMAL:
			desc += "护盾，可吸收所有类型的伤害"
		ShieldType.MAGIC:
			desc += "魔法护盾，可吸收魔法和元素伤害"
		ShieldType.PHYSICAL:
			desc += "物理护盾，可吸收物理伤害"
		ShieldType.ELEMENTAL:
			desc += "元素护盾，可吸收元素伤害"
		ShieldType.REFLECT:
			desc += "反射护盾，可吸收所有类型的伤害并反射部分伤害"
	
	desc += "，护盾值：" + str(shield_amount)
	
	if damage_reduction > 0:
		desc += "，减免" + str(int(damage_reduction * 100)) + "%伤害"
	
	if reflect_percent > 0:
		desc += "，反射" + str(int(reflect_percent * 100)) + "%伤害"
	
	return desc

# 获取效果数据
func get_data() -> Dictionary:
	var data = super.get_data()
	data["shield_type"] = shield_type
	data["shield_amount"] = shield_amount
	data["remaining_shield"] = remaining_shield
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
		data.get("shield_type", ShieldType.NORMAL),
		data.get("shield_amount", 0.0),
		source,
		target,
		{
			"damage_reduction": data.get("damage_reduction", 0.0),
			"reflect_percent": data.get("reflect_percent", 0.0)
		}
	)
	
	# 设置剩余护盾值
	if data.has("remaining_shield"):
		effect.remaining_shield = data.remaining_shield
	
	return effect
