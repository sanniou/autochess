extends GameEffect
class_name DotEffect
## 持续伤害效果
## 用于对目标造成持续伤害

# DOT类型枚举
enum DotType {
	BURNING,    # 燃烧
	POISON,   # 中毒
	BLEEDING,   # 流血
	ACID,       # 酸蚀
	DECAY       # 腐蚀
}

# DOT类型
var dot_type: int = DotType.BURNING

# 每秒伤害值
var damage_per_second: float = 0.0

# 伤害类型
var damage_type: String = "magical"

# 上次伤害时间
var last_damage_time: float = 0.0

# 伤害间隔
var tick_interval: float = 1.0

# 初始化
func _init(effect_id: String = "", effect_name: String = "", effect_description: String = "",
		effect_duration: float = 0.0, dot_type_param: int = DotType.BURNING,
		damage_per_second_param: float = 0.0, damage_type_param: String = "magical",
		effect_source = null, effect_target = null, effect_params: Dictionary = {}):
	super._init(effect_id, effect_name, effect_description, effect_duration,
			EffectType.DOT, effect_source, effect_target, effect_params)

	dot_type = dot_type_param
	damage_per_second = damage_per_second_param
	damage_type = damage_type_param

	# 设置伤害间隔
	tick_interval = effect_params.get("tick_interval", 1.0)

	# 设置标签
	if not tags.has("dot"):
		tags.append("dot")
	if not tags.has("debuff"):
		tags.append("debuff")

	# 设置图标路径
	icon_path = _get_dot_icon_path(dot_type)

	# 设置名称和描述
	if name.is_empty():
		name = _get_dot_name(dot_type)

	if description.is_empty():
		description = _get_dot_description(dot_type, damage_per_second, damage_type)

# 应用效果
func apply() -> bool:
	if not super.apply():
		return false

	# 立即造成第一次伤害
	_apply_damage()

	return true

# 更新效果
func update(delta: float) -> bool:
	if not super.update(delta):
		return false

	# 更新上次伤害时间
	last_damage_time += delta

	# 检查是否到达伤害间隔
	if last_damage_time >= tick_interval:
		# 重置上次伤害时间
		last_damage_time = 0.0

		# 造成伤害
		_apply_damage()

	return true

# 应用伤害
func _apply_damage() -> void:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return

	# 检查目标是否可以受到伤害
	if not target.has_method("take_damage"):
		return

	# 计算本次伤害
	var damage = damage_per_second * tick_interval

	# 对目标造成伤害
	target.take_damage(damage, damage_type, source, false)

	# 应用额外效果
	_apply_additional_effects()

	# 发送持续伤害事件
	if EventBus:
		EventBus.emit_signal("dot_damage", {
			"source": source,
			"target": target,
			"value": damage,
			"type": damage_type,
			"dot_type": dot_type
		})

# 获取DOT图标路径
func _get_dot_icon_path(dot_type: int) -> String:
	match dot_type:
		DotType.BURNING:
			return "res://assets/icons/dot/burning.png"
		DotType.POISON:
			return "res://assets/icons/dot/poison.png"
		DotType.BLEEDING:
			return "res://assets/icons/dot/bleeding.png"
		DotType.ACID:
			return "res://assets/icons/dot/acid.png"
		DotType.DECAY:
			return "res://assets/icons/dot/decay.png"

	return ""

# 获取DOT名称
func _get_dot_name(dot_type: int) -> String:
	match dot_type:
		DotType.BURNING:
			return "燃烧"
		DotType.POISON:
			return "中毒"
		DotType.BLEEDING:
			return "流血"
		DotType.ACID:
			return "酸蚀"
		DotType.DECAY:
			return "腐蚀"

	return "未知DOT"

# 获取DOT描述
func _get_dot_description(dot_type: int, damage_per_second: float, damage_type: String) -> String:
	var desc = ""

	match dot_type:
		DotType.BURNING:
			desc = "燃烧，每秒受到 " + str(damage_per_second) + " 点火焰伤害"
		DotType.POISON:
			desc = "中毒，每秒受到 " + str(damage_per_second) + " 点毒素伤害"
		DotType.BLEEDING:
			desc = "流血，每秒受到 " + str(damage_per_second) + " 点物理伤害"
		DotType.ACID:
			desc = "酸蚀，每秒受到 " + str(damage_per_second) + " 点酸性伤害，并降低护甲"
		DotType.DECAY:
			desc = "腐蚀，每秒受到 " + str(damage_per_second) + " 点腐蚀伤害，并降低生命回复"
		_:
			desc = "每秒受到 " + str(damage_per_second) + " 点" + damage_type + "伤害"

	return desc

# 应用额外效果
func _apply_additional_effects() -> void:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return

	# 检查GameManager和GameEffectManager是否可用
	if not GameManager or not GameManager.game_effect_manager:
		return

	# 根据DOT类型应用不同的额外效果
	match dot_type:
		DotType.ACID:
			# 酸蚀效果：降低目标护甲
			_apply_armor_reduction()
		DotType.DECAY:
			# 腐蚀效果：降低目标生命回复
			_apply_healing_reduction()

# 应用护甲降低效果
func _apply_armor_reduction() -> void:
	# 检查目标是否有属性组件
	var attribute_component = null
	if target.has_method("get_component"):
		attribute_component = target.get_component("AttributeComponent")

	if not attribute_component:
		return

	# 计算护甲降低值（每次降低1点，最多降低5点）
	var armor_reduction = 1.0
	var current_armor = attribute_component.get_attribute("armor")
	var min_armor = current_armor - 5.0

	# 确保护甲不会降低到负值
	if current_armor > min_armor:
		# 创建护甲降低效果数据
		var effect_data = {
			"id": "acid_armor_reduction_" + str(target.get_instance_id()),
			"name": "酸蚀护甲降低",
			"description": "护甲降低 " + str(armor_reduction) + " 点",
			"duration": 5.0,  # 持续5秒
			"effect_type": GameManager.game_effect_manager.EffectType.STAT_MOD,
			"stats": {"armor": -armor_reduction},
			"is_percentage": false
		}

		# 应用效果
		GameManager.game_effect_manager.apply_effect(effect_data, source, target)

		# 创建视觉效果
		if GameManager.visual_manager:
			GameManager.visual_manager.create_floating_text(
				target.global_position,
				"-" + str(armor_reduction) + " 护甲",
				Color(0.8, 0.2, 0.8, 1.0)  # 紫色
			)

# 应用生命回复降低效果
func _apply_healing_reduction() -> void:
	# 检查目标是否有属性组件
	var attribute_component = null
	if target.has_method("get_component"):
		attribute_component = target.get_component("AttributeComponent")

	if not attribute_component:
		return

	# 创建生命回复降低效果数据（降低50%的生命回复）
	var effect_data = {
		"id": "decay_healing_reduction_" + str(target.get_instance_id()),
		"name": "腐蚀生命回复降低",
		"description": "生命回复降低50%",
		"duration": 5.0,  # 持续5秒
		"effect_type": GameManager.game_effect_manager.EffectType.STAT_MOD,
		"stats": {"healing_received": -0.5},
		"is_percentage": true
	}

	# 应用效果
	GameManager.game_effect_manager.apply_effect(effect_data, source, target)

	# 创建视觉效果
	if GameManager.visual_manager:
		GameManager.visual_manager.create_floating_text(
			target.global_position,
			"-50% 生命回复",
			Color(0.2, 0.8, 0.2, 1.0)  # 绿色
		)

# 获取效果数据
func get_data() -> Dictionary:
	var data = super.get_data()
	data["dot_type"] = dot_type
	data["damage_per_second"] = damage_per_second
	data["damage_type"] = damage_type
	data["tick_interval"] = tick_interval
	data["last_damage_time"] = last_damage_time
	return data

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> DotEffect:
	var effect = DotEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("duration", 0.0),
		data.get("dot_type", DotType.BURNING),
		data.get("damage_per_second", 0.0),
		data.get("damage_type", "magical"),
		source,
		target,
		data.get("params", {})
	)

	effect.last_damage_time = data.get("last_damage_time", 0.0)

	return effect
