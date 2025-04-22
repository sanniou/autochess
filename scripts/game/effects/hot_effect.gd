extends GameEffect
class_name HotEffect
## 持续治疗效果
## 用于对目标提供持续治疗

# 持续治疗类型枚举
enum HotType {
	REGENERATION,  # 生命再生，百分比回复
	HEALING_AURA,  # 治疗光环，回复固定数值
	BLESSING,      # 祝福，回复固定数值且间隔清除 debuff
	REJUVENATION,  # 回春，回复固定数值且生命值较低时加成提高
	LIFE_LINK      # 生命链接，与施法者建立生命链接，每秒恢复固定数值
}

# 持续治疗类型
var hot_type: int = HotType.REGENERATION

# 每秒治疗值
var heal_per_second: float = 0.0

# 上次治疗时间
var last_heal_time: float = 0.0

# 治疗间隔
var tick_interval: float = 1.0

# debuff 清除计数器
var debuff_clear_counter: int = 0

# 初始化
func _init(effect_id: String = "", effect_name: String = "", effect_description: String = "",
		effect_duration: float = 0.0, heal_per_second_param: float = 0.0,
		effect_source = null, effect_target = null, effect_params: Dictionary = {}):
	super._init(effect_id, effect_name, effect_description, effect_duration,
			EffectType.HOT, effect_source, effect_target, effect_params)

	heal_per_second = heal_per_second_param

	# 设置治疗类型
	hot_type = effect_params.get("hot_type", HotType.REGENERATION)

	# 设置治疗间隔
	tick_interval = effect_params.get("tick_interval", 1.0)

	# 设置标签
	if not tags.has("hot"):
		tags.append("hot")
	if not tags.has("buff"):
		tags.append("buff")

	# 设置图标路径
	icon_path = _get_hot_icon_path(hot_type)

	# 设置名称和描述
	if name.is_empty():
		name = _get_hot_name(hot_type)

	if description.is_empty():
		description = _get_hot_description(hot_type, heal_per_second)

# 应用效果
func apply() -> bool:
	if not super.apply():
		return false

	# 立即提供第一次治疗
	_apply_heal()

	return true

# 更新效果
func update(delta: float) -> bool:
	if not super.update(delta):
		return false

	# 更新上次治疗时间
	last_heal_time += delta

	# 检查是否到达治疗间隔
	if last_heal_time >= tick_interval:
		# 重置上次治疗时间
		last_heal_time = 0.0

		# 提供治疗
		_apply_heal()

	return true

# 应用治疗
func _apply_heal() -> void:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return

	# 检查目标是否可以被治疗
	if not target.has_method("heal"):
		return

	# 计算本次治疗
	var heal = _calculate_heal_amount()

	# 对目标进行治疗
	target.heal(heal, source, false)

	# 应用额外效果
	_apply_additional_effects(heal)

	# 发送持续治疗事件
	if EventBus:
		EventBus.emit_signal("hot_heal", {
			"source": source,
			"target": target,
			"value": heal
		})

# 计算治疗量
func _calculate_heal_amount() -> float:
	var heal = heal_per_second * tick_interval

	# 根据治疗类型计算不同的治疗量
	match hot_type:
		HotType.REGENERATION:
			# 生命再生，按百分比恢复最大生命值
			var attribute_component = null
			if target.has_method("get_component"):
				attribute_component = target.get_component("AttributeComponent")

			if attribute_component:
				var max_health = attribute_component.get_attribute("max_health")
				heal = max_health * (heal_per_second / 100.0) * tick_interval

		HotType.REJUVENATION:
			# 回春，生命值越低恢复效果越好
			var attribute_component = null
			if target.has_method("get_component"):
				attribute_component = target.get_component("AttributeComponent")

			if attribute_component:
				var current_health = attribute_component.get_attribute("health")
				var max_health = attribute_component.get_attribute("max_health")
				var health_percent = current_health / max_health

				# 生命值百分比越低，加成越高，最高加成0.5倍
				var bonus_multiplier = 1.0 + (1.0 - health_percent) * 0.5
				heal *= bonus_multiplier

		HotType.LIFE_LINK:
			# 生命链接，与施法者共享治疗效果
			# 如果施法者有效，则也对施法者进行治疗
			if source and is_instance_valid(source) and source.has_method("heal") and source != target:
				source.heal(heal * 0.5, source, false)  # 施法者获得50%的治疗量

	return heal

# 应用额外效果
func _apply_additional_effects(heal_amount: float) -> void:
	# 根据治疗类型应用不同的额外效果
	match hot_type:
		HotType.BLESSING:
			# 祝福，每3秒清除一个减益效果
			debuff_clear_counter += 1
			if debuff_clear_counter >= 3:
				debuff_clear_counter = 0
				_clear_one_debuff()

# 清除一个减益效果
func _clear_one_debuff() -> void:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return

	# 检查GameManager和GameEffectManager是否可用
	if not GameManager or not GameManager.game_effect_manager:
		return

	# 获取目标的所有效果
	var effects = GameManager.game_effect_manager.get_effects_on_target(target)

	# 过滤出减益效果
	var debuff_effects = []
	for effect in effects:
		if effect.tags.has("debuff"):
			debuff_effects.append(effect)

	# 如果有减益效果，随机移除一个
	if not debuff_effects.is_empty():
		var random_index = randi() % debuff_effects.size()
		var effect_to_remove = debuff_effects[random_index]

		# 移除效果
		GameManager.game_effect_manager.remove_effect(effect_to_remove.id)

		# 创建视觉效果
		if GameManager.visual_manager:
			GameManager.visual_manager.create_floating_text(
				target.global_position,
				"清除" + effect_to_remove.name,
				Color(0.2, 0.8, 0.8, 1.0)  # 青色
			)

# 获取HOT图标路径
func _get_hot_icon_path(hot_type: int) -> String:
	match hot_type:
		HotType.REGENERATION:
			return "res://assets/icons/hot/regeneration.png"
		HotType.HEALING_AURA:
			return "res://assets/icons/hot/healing_aura.png"
		HotType.BLESSING:
			return "res://assets/icons/hot/blessing.png"
		HotType.REJUVENATION:
			return "res://assets/icons/hot/rejuvenation.png"
		HotType.LIFE_LINK:
			return "res://assets/icons/hot/life_link.png"

	return "res://assets/icons/hot/regeneration.png"

# 获取HOT名称
func _get_hot_name(hot_type: int) -> String:
	match hot_type:
		HotType.REGENERATION:
			return "生命再生"
		HotType.HEALING_AURA:
			return "治疗光环"
		HotType.BLESSING:
			return "祝福"
		HotType.REJUVENATION:
			return "回春"
		HotType.LIFE_LINK:
			return "生命链接"

	return "生命恢复"

# 获取HOT描述
func _get_hot_description(hot_type: int, heal_amount: float) -> String:
	var desc = ""

	match hot_type:
		HotType.REGENERATION:
			desc = "生命再生，每秒恢复最大生命值的" + str(heal_amount) + "%"
		HotType.HEALING_AURA:
			desc = "治疗光环，每秒恢复 " + str(heal_amount) + " 点生命值"
		HotType.BLESSING:
			desc = "祝福，每秒恢复 " + str(heal_amount) + " 点生命值，并每3秒清除一个减益效果"
		HotType.REJUVENATION:
			desc = "回春，每秒恢复 " + str(heal_amount) + " 点生命值，生命值越低恢复效果越好"
		HotType.LIFE_LINK:
			desc = "生命链接，每秒恢复 " + str(heal_amount) + " 点生命值，并与施法者共享治疗效果"
		_:
			desc = "每秒恢复 " + str(heal_amount) + " 点生命值"

	return desc

# 获取效果数据
func get_data() -> Dictionary:
	var data = super.get_data()
	data["hot_type"] = hot_type
	data["heal_per_second"] = heal_per_second
	data["tick_interval"] = tick_interval
	data["last_heal_time"] = last_heal_time
	data["debuff_clear_counter"] = debuff_clear_counter
	return data

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> HotEffect:
	# 准备参数
	var params = data.get("params", {}).duplicate()

	# 添加治疗类型参数
	params["hot_type"] = data.get("hot_type", HotType.REGENERATION)

	var effect = HotEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("duration", 0.0),
		data.get("heal_per_second", 0.0),
		source,
		target,
		params
	)

	effect.last_heal_time = data.get("last_heal_time", 0.0)
	effect.debuff_clear_counter = data.get("debuff_clear_counter", 0)

	return effect
