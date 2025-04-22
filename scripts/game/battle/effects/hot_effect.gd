# extends BattleEffect
# class_name HotEffect
# ## 持续治疗效果
# ## 用于对单位提供持续治疗

# # 持续治疗类型枚举
# enum HotType {
# 	REGENERATION,  # 生命再生
# 	HEALING_AURA,  # 治疗光环
# 	BLESSING,      # 祝福
# 	REJUVENATION,  # 回春
# 	LIFE_LINK      # 生命链接
# }

# # 持续治疗效果属性
# var hot_type: int = HotType.REGENERATION
# var heal_per_second: float = 0.0
# var tick_interval: float = 1.0  # 治疗间隔（秒）
# var tick_timer: float = 0.0     # 治疗计时器
# var total_healing: float = 0.0  # 总治疗量

# # 初始化
# func _init(effect_id: String = "", effect_name: String = "", effect_description: String = "",
# 		effect_duration: float = 0.0, hot_type_value: int = HotType.REGENERATION,
# 		heal_per_second_value: float = 0.0, effect_source = null, effect_target = null,
# 		effect_params: Dictionary = {}):
# 	super._init(effect_id, effect_name, effect_description, effect_duration,
# 			EffectType.HOT, effect_source, effect_target, effect_params)

# 	hot_type = hot_type_value
# 	heal_per_second = heal_per_second_value

# 	# 设置治疗间隔
# 	if effect_params.has("tick_interval"):
# 		tick_interval = effect_params.tick_interval

# 	# 设置图标路径
# 	icon_path = _get_hot_icon_path(hot_type)

# 	# 设置名称和描述
# 	if name.is_empty():
# 		name = _get_hot_name(hot_type)

# 	if description.is_empty():
# 		description = _generate_hot_description()

# # 应用效果
# func apply() -> bool:
# 	if not super.apply():
# 		return false

# 	if not target or not is_instance_valid(target):
# 		return false

# 	# 立即应用一次治疗
# 	_apply_healing_tick()

# 	# 重置计时器
# 	tick_timer = 0.0

# 	return true

# # 更新效果
# func update(delta: float) -> bool:
# 	if not super.update(delta):
# 		return false

# 	# 更新治疗计时器
# 	tick_timer += delta

# 	# 检查是否应该应用治疗
# 	if tick_timer >= tick_interval:
# 		_apply_healing_tick()
# 		tick_timer -= tick_interval

# 	return true

# # 应用治疗tick
# func _apply_healing_tick() -> void:
# 	if not target or not is_instance_valid(target) or target.current_state == target.ChessState.DEAD:
# 		return

# 	# 计算治疗量
# 	var heal_amount = heal_per_second * tick_interval

# 	# 根据叠加层数调整治疗量
# 	if is_stackable and stack_count > 1:
# 		heal_amount *= (1 + (stack_count - 1) * 0.5)  # 每层增加50%治疗

# 	# 应用治疗
# 	var battle_manager = GameManager.battle_manager
# 	if battle_manager:
# 		var actual_healing = battle_manager.apply_heal(source, target, heal_amount)
# 		total_healing += actual_healing

# 	# 触发治疗事件
# 	EventBus.battle.emit_event("hot_healing", [source, target, heal_amount, hot_type])

# 	# 创建治疗视觉效果
# 	_create_healing_visual(heal_amount)

# # 创建治疗视觉效果
# func _create_healing_visual(heal_amount: float) -> void:
# 	if not target or not is_instance_valid(target):
# 		return

# 	# 创建治疗数字
# 	var battle_manager = GameManager.battle_manager
# 	if battle_manager and battle_manager.has_method("create_floating_text"):
# 		battle_manager.create_floating_text(target.global_position, str(int(heal_amount)), Color(0, 1, 0))

# 	# 创建治疗粒子效果
# 	if GameManager and GameManager.game_effect_manager:
# 		GameManager.game_effect_manager.create_visual_effect(
# 			GameManager.game_effect_manager.VisualEffectType.HEAL,
# 			target,
# 			{
# 				"scale": Vector2(0.5, 0.5),
# 				"color": Color(0, 1, 0, 0.7),
# 				"heal_amount": heal_amount
# 			}
# 		)
# 	# 如果没有效果管理器，使用视觉管理器
# 	elif GameManager and GameManager.visual_manager:
# 		GameManager.visual_manager.create_heal_number(
# 			target.global_position,
# 			heal_amount,
# 			false,
# 			{"scale": Vector2(0.5, 0.5)}
# 		)

# # 获取持续治疗类型图标路径
# func _get_hot_icon_path(hot_type: int) -> String:
# 	match hot_type:
# 		HotType.REGENERATION:
# 			return "res://assets/icons/effects/hot_regeneration.png"
# 		HotType.HEALING_AURA:
# 			return "res://assets/icons/effects/hot_healing_aura.png"
# 		HotType.BLESSING:
# 			return "res://assets/icons/effects/hot_blessing.png"
# 		HotType.REJUVENATION:
# 			return "res://assets/icons/effects/hot_rejuvenation.png"
# 		HotType.LIFE_LINK:
# 			return "res://assets/icons/effects/hot_life_link.png"

# 	return ""

# # 获取持续治疗类型名称
# func _get_hot_name(hot_type: int) -> String:
# 	match hot_type:
# 		HotType.REGENERATION:
# 			return "生命再生"
# 		HotType.HEALING_AURA:
# 			return "治疗光环"
# 		HotType.BLESSING:
# 			return "祝福"
# 		HotType.REJUVENATION:
# 			return "回春"
# 		HotType.LIFE_LINK:
# 			return "生命链接"

# 	return "未知持续治疗效果"

# # 生成持续治疗描述
# func _generate_hot_description() -> String:
# 	var desc = ""

# 	match hot_type:
# 		HotType.REGENERATION:
# 			desc = "每秒恢复" + str(heal_per_second) + "点生命值"
# 		HotType.HEALING_AURA:
# 			desc = "处于光环中的单位每秒恢复" + str(heal_per_second) + "点生命值"
# 		HotType.BLESSING:
# 			desc = "受到祝福，每秒恢复" + str(heal_per_second) + "点生命值"
# 		HotType.REJUVENATION:
# 			desc = "回春效果，每秒恢复" + str(heal_per_second) + "点生命值"
# 		HotType.LIFE_LINK:
# 			desc = "与施法者建立生命链接，每秒恢复" + str(heal_per_second) + "点生命值"

# 	return desc

# # 获取持续治疗描述
# static func get_hot_description(hot_type: int) -> String:
# 	match hot_type:
# 		HotType.REGENERATION:
# 			return "持续恢复生命值"
# 		HotType.HEALING_AURA:
# 			return "处于光环中的单位持续恢复生命值"
# 		HotType.BLESSING:
# 			return "受到祝福，持续恢复生命值"
# 		HotType.REJUVENATION:
# 			return "回春效果，持续恢复生命值"
# 		HotType.LIFE_LINK:
# 			return "与施法者建立生命链接，持续恢复生命值"

# 	return "未知持续治疗效果"

# # 获取效果数据
# func get_data() -> Dictionary:
# 	var data = super.get_data()
# 	data["hot_type"] = hot_type
# 	data["heal_per_second"] = heal_per_second
# 	data["tick_interval"] = tick_interval
# 	data["total_healing"] = total_healing
# 	return data

# # 从数据创建效果
# static func create_from_data(data: Dictionary, source = null, target = null) -> HotEffect:
# 	return HotEffect.new(
# 		data.get("id", ""),
# 		data.get("name", ""),
# 		data.get("description", ""),
# 		data.get("duration", 0.0),
# 		data.get("hot_type", HotType.REGENERATION),
# 		data.get("heal_per_second", 0.0),
# 		source,
# 		target,
# 		{
# 			"tick_interval": data.get("tick_interval", 1.0)
# 		}
# 	)
