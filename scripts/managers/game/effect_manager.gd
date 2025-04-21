extends "res://scripts/managers/core/base_manager.gd"
class_name EffectManager
## 效果管理器
## 专注于管理游戏中的逻辑效果，如伤害、治疗、状态效果等，不直接处理视觉表现

# 效果类型枚举
enum EffectType {
	STAT,      # 属性效果
	STATUS,    # 状态效果
	DOT,       # 持续伤害
	DAMAGE,    # 直接伤害
	HEAL,      # 治疗
	SPECIAL    # 特殊效果
}

# 视觉效果类型枚举
enum VisualEffectType {
	BUFF,               # 增益效果
	DEBUFF,             # 减益效果
	DAMAGE,             # 伤害效果
	HEAL,               # 治疗效果
	AREA_DAMAGE,        # 区域伤害
	CHAIN,              # 连锁效果
	SUMMON,             # 召唤效果
	TELEPORT_APPEAR,    # 传送出现
	TELEPORT_DISAPPEAR, # 传送消失
	JUMP,               # 跳跃效果
	DOT                 # 持续伤害效果
}

# 效果到视觉效果的映射
var effect_to_visual_map = {
	EffectType.STAT: "buff",
	EffectType.STATUS: "debuff",
	EffectType.DOT: "dot",
	EffectType.DAMAGE: "damage",
	EffectType.HEAL: "heal",
	EffectType.SPECIAL: "special"
}

# 特效颜色
var effect_colors = {
	"physical": Color(0.8, 0.2, 0.2, 0.8),  # 物理伤害 - 红色
	"magical": Color(0.2, 0.2, 0.8, 0.8),   # 魔法伤害 - 蓝色
	"true": Color(0.8, 0.8, 0.2, 0.8),      # 真实伤害 - 黄色
	"fire": Color(0.8, 0.4, 0.0, 0.8),      # 火焰伤害 - 橙色
	"ice": Color(0.0, 0.8, 0.8, 0.8),       # 冰冻伤害 - 青色
	"lightning": Color(0.8, 0.8, 0.0, 0.8), # 闪电伤害 - 黄色
	"poison": Color(0.0, 0.8, 0.0, 0.8),    # 毒素伤害 - 绿色
	"heal": Color(0.0, 0.8, 0.0, 0.8),      # 治疗 - 绿色
	"buff": Color(0.0, 0.8, 0.8, 0.8),      # 增益 - 青色
	"debuff": Color(0.8, 0.0, 0.8, 0.8),    # 减益 - 紫色
	"teleport": Color(0.8, 0.2, 0.8, 0.8),  # 传送 - 紫色
	"stun": Color(0.8, 0.8, 0.0, 0.8),      # 眩晕 - 黄色
	"level_up": Color(1.0, 0.8, 0.0, 0.8),  # 升级 - 金色
	"death": Color(0.3, 0.3, 0.3, 0.8)      # 死亡 - 灰色
}

# 视觉效果动画器引用
var visual_effect_animator: VisualEffectAnimator = null

# 当前活动的特效
var active_effects = []

# 当前活动的逻辑效果
var active_logical_effects = {}  # 效果ID -> 效果对象

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "EffectManager"

	# 获取视觉效果动画器
	_get_visual_effect_animator()

	# 连接信号
	EventBus.battle.connect_event("battle_ended", _on_battle_ended)

	_log_info("效果管理器初始化完成")

# 获取视觉效果动画器
func _get_visual_effect_animator() -> void:
	# 尝试从动画管理器获取视觉效果动画器
	if GameManager.animation_manager:
		visual_effect_animator = GameManager.animation_manager.get_effect_animator()
		if visual_effect_animator:
			_log_info("成功获取视觉效果动画器")
			return

	# 如果没有找到，在下一帧再次尝试
	_log_warning("无法获取视觉效果动画器，将在下一帧重试")
	call_deferred("_get_visual_effect_animator")



# 从效果类型创建视觉特效
## 将EffectType转换为VisualEffectType并创建视觉效果
func create_visual_effect_from_effect_type(effect_type: int, target: Node2D, params: Dictionary = {}) -> String:
	# 检查特效类型是否有效
	if not effect_to_visual_map.has(effect_type):
		_log_error("无效的效果类型: " + str(effect_type))
		return ""

	# 准备特效参数
	var effect_params = params.duplicate()

	# 根据效果类型选择视觉效果类型
	var visual_effect_type: int
	match effect_type:
		EffectType.STAT:
			visual_effect_type = VisualEffectType.BUFF
		EffectType.STATUS:
			visual_effect_type = VisualEffectType.DEBUFF
		EffectType.DOT:
			visual_effect_type = VisualEffectType.DOT
		EffectType.DAMAGE:
			visual_effect_type = VisualEffectType.DAMAGE
		EffectType.HEAL:
			visual_effect_type = VisualEffectType.HEAL
		EffectType.SPECIAL:
			# 特殊效果需要根据参数决定视觉效果类型
			if params.has("visual_effect_type"):
				visual_effect_type = params.visual_effect_type
			else:
				_log_error("特殊效果需要指定视觉效果类型")
				return ""
		_:
			_log_error("未知的效果类型: " + str(effect_type))
			return ""

	# 调用主要的视觉效果创建函数
	return create_visual_effect(visual_effect_type, target, effect_params)



# 清理完成的特效
func _process(delta):
	# 更新逻辑效果
	var effects_to_remove = []
	for effect_id in active_logical_effects:
		var effect = active_logical_effects[effect_id]
		if not effect.update(delta):
			effects_to_remove.append(effect_id)

	# 移除过期效果
	for effect_id in effects_to_remove:
		remove_effect(effect_id)

# 获取特效颜色
func get_effect_color(effect_type: String) -> Color:
	# 根据效果类型返回对应的颜色
	match effect_type:
		"fire", "burning":
			return effect_colors.get("fire", Color(0.8, 0.4, 0.0, 0.8))
		"ice", "frozen":
			return effect_colors.get("ice", Color(0.0, 0.8, 0.8, 0.8))
		"lightning":
			return effect_colors.get("lightning", Color(0.8, 0.8, 0.0, 0.8))
		"earth":
			return effect_colors.get("earth", Color(0.5, 0.3, 0.0, 0.8))
		"poison", "poisoned":
			return effect_colors.get("poison", Color(0.0, 0.8, 0.0, 0.8))
		"physical", "bleeding":
			return effect_colors.get("physical", Color(0.8, 0.2, 0.2, 0.8))
		"magical":
			return effect_colors.get("magical", Color(0.2, 0.2, 0.8, 0.8))
		"heal":
			return effect_colors.get("heal", Color(0.0, 0.8, 0.0, 0.8))
		"buff":
			return effect_colors.get("buff", Color(0.0, 0.8, 0.8, 0.8))
		"debuff":
			return effect_colors.get("debuff", Color(0.8, 0.0, 0.8, 0.8))
		"stun":
			return effect_colors.get("stun", Color(0.8, 0.8, 0.0, 0.8))
		"silence":
			return effect_colors.get("silence", Color(0.5, 0.5, 0.5, 0.8))
		"taunt":
			return effect_colors.get("taunt", Color(1.0, 0.4, 0.0, 0.8))
		"dodge":
			return effect_colors.get("dodge", Color(0.2, 0.8, 0.8, 0.8))
		"ability_cast":
			return effect_colors.get("magical", Color(0.8, 0.2, 0.8, 0.5))
		"level_up":
			return effect_colors.get("level_up", Color(1.0, 0.8, 0.0, 0.8))
		_:
			return effect_colors.get(effect_type, Color(1, 1, 1, 0.5))



# 战斗结束处理
func _on_battle_ended(winner_team: int) -> void:
	# 重置管理器
	_do_reset()

# 添加效果
func add_effect(effect: BattleEffect) -> void:
	# 检查效果是否有效
	if not effect or not effect.target or not is_instance_valid(effect.target):
		return

	# 应用效果
	effect.apply()

	# 如果效果有持续时间，添加到活动效果列表
	if effect.duration > 0:
		active_logical_effects[effect.id] = effect

# 创建效果
func create_effect(effect_type: int, target: Node2D, params: Dictionary = {}):
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		_log_error("创建效果失败：目标无效")
		return null

	# 创建效果数据
	var effect_data = _create_effect_data(effect_type, params)

	# 如果效果数据为空，返回空
	if effect_data.is_empty():
		_log_error("创建效果失败：无法生成效果数据")
		return null

	# 创建视觉效果
	_create_visual_effect_for_type(effect_type, target, params)

	# 应用效果
	return _apply_battle_effect(effect_data, null, target)

# 创建视觉效果
## 根据视觉效果类型创建相应的视觉效果
func create_visual_effect(visual_effect_type: int, target: Node2D, params: Dictionary = {}) -> String:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		_log_error("创建视觉效果失败：目标无效")
		return ""

	# 检查视觉效果动画器是否可用
	if not visual_effect_animator:
		_get_visual_effect_animator()
		if not visual_effect_animator:
			_log_error("无法获取视觉效果动画器")
			return ""

	# 准备视觉效果参数
	var visual_params = params.duplicate()

	# 根据视觉效果类型设置参数
	var visual_effect_name = ""

	match visual_effect_type:
		VisualEffectType.BUFF:
			visual_effect_name = "buff"
			if not visual_params.has("color"):
				visual_params["color"] = get_effect_color("buff")

		VisualEffectType.DEBUFF:
			visual_effect_name = "debuff"
			if not visual_params.has("color"):
				visual_params["color"] = get_effect_color("debuff")

		VisualEffectType.DAMAGE:
			visual_effect_name = visual_params.get("damage_type", "magical") + "_hit"
			if not visual_params.has("color"):
				visual_params["color"] = get_effect_color(visual_params.get("damage_type", "magical"))

		VisualEffectType.HEAL:
			visual_effect_name = "heal"
			if not visual_params.has("color"):
				visual_params["color"] = get_effect_color("heal")

		VisualEffectType.AREA_DAMAGE:
			visual_effect_name = "area_damage"
			if not visual_params.has("color"):
				visual_params["color"] = get_effect_color(visual_params.get("damage_type", "magical"))

		VisualEffectType.CHAIN:
			visual_effect_name = "chain"
			if not visual_params.has("color"):
				visual_params["color"] = get_effect_color(visual_params.get("damage_type", "magical"))

		VisualEffectType.SUMMON:
			visual_effect_name = "summon"
			if not visual_params.has("color"):
				visual_params["color"] = get_effect_color("magical")

		VisualEffectType.TELEPORT_APPEAR:
			visual_effect_name = "teleport_appear"
			if not visual_params.has("color"):
				visual_params["color"] = get_effect_color("magical")

		VisualEffectType.TELEPORT_DISAPPEAR:
			visual_effect_name = "teleport_disappear"
			if not visual_params.has("color"):
				visual_params["color"] = get_effect_color("magical")

		VisualEffectType.JUMP:
			visual_effect_name = "jump"
			if not visual_params.has("color"):
				visual_params["color"] = get_effect_color("physical")

		VisualEffectType.DOT:
			visual_effect_name = visual_params.get("dot_type", "burning")
			if not visual_params.has("color"):
				visual_params["color"] = get_effect_color(visual_params.get("dot_type", "burning"))

		_:
			_log_error("未知的视觉效果类型: " + str(visual_effect_type))
			return ""

	# 使用视觉效果动画器创建特效
	return visual_effect_animator.play_combined_effect(target.global_position, visual_effect_name, visual_params)

# 创建效果数据
func _create_effect_data(effect_type: int, params: Dictionary) -> Dictionary:
	var effect_data = {}

	match effect_type:
		EffectType.STAT:
			effect_data = _create_stat_effect_data(params)
		EffectType.STATUS:
			effect_data = _create_status_effect_data(params)
		EffectType.DOT:
			effect_data = _create_dot_effect_data(params)
		EffectType.DAMAGE:
			effect_data = _create_damage_effect_data(params)
		EffectType.HEAL:
			effect_data = _create_heal_effect_data(params)

	return effect_data

# 创建属性效果数据
func _create_stat_effect_data(params: Dictionary) -> Dictionary:
	# 获取参数
	var buff_type = params.get("buff_type", "attack")
	var buff_value = params.get("buff_value", 10.0)
	var duration = params.get("duration", 5.0)

	# 创建属性字典
	var stats = {}
	match buff_type:
		"attack":
			stats["attack_damage"] = buff_value
		"defense":
			stats["armor"] = buff_value
			stats["magic_resist"] = buff_value
		"speed":
			stats["attack_speed"] = buff_value
			stats["move_speed"] = buff_value * 10.0
		"health":
			stats["max_health"] = buff_value
		"spell":
			stats["spell_power"] = buff_value
		"crit":
			stats["crit_chance"] = buff_value
			stats["crit_damage"] = buff_value * 0.5

	# 返回效果数据
	return {
		"effect_type": BattleEffect.EffectType.STAT_MOD,
		"name": "增益: " + buff_type,
		"description": "增加" + buff_type + "属性" + str(buff_value),
		"duration": duration,
		"stats": stats,
		"is_percentage": false,
		"tags": ["buff"]
	}

# 创建状态效果数据
func _create_status_effect_data(params: Dictionary) -> Dictionary:
	# 获取参数
	var status_type = params.get("status_type", "stun")
	var duration = params.get("duration", 2.0)

	# 获取状态类型
	var status_type_value = StatusEffect.StatusType.STUN
	match status_type:
		"stun":
			status_type_value = StatusEffect.StatusType.STUN
		"silence":
			status_type_value = StatusEffect.StatusType.SILENCE
		"disarm":
			status_type_value = StatusEffect.StatusType.DISARM
		"root":
			status_type_value = StatusEffect.StatusType.ROOT
		"taunt":
			status_type_value = StatusEffect.StatusType.TAUNT
		"frozen":
			status_type_value = StatusEffect.StatusType.FROZEN

	# 返回效果数据
	return {
		"effect_type": BattleEffect.EffectType.STATUS,
		"name": "状态: " + status_type,
		"description": "施加" + status_type + "状态",
		"duration": duration,
		"status_type": status_type_value,
		"tags": ["status", "debuff"]
	}

# 创建持续伤害效果数据
func _create_dot_effect_data(params: Dictionary) -> Dictionary:
	# 获取参数
	var dot_type = params.get("dot_type", "burning")
	var damage_per_second = params.get("damage_per_second", 10.0)
	var duration = params.get("duration", 5.0)
	var damage_type = params.get("damage_type", "magical")

	# 获取DOT类型
	var dot_type_value = DotEffect.DotType.BURNING
	match dot_type:
		"burning":
			dot_type_value = DotEffect.DotType.BURNING
		"poisoned":
			dot_type_value = DotEffect.DotType.POISONED
		"bleeding":
			dot_type_value = DotEffect.DotType.BLEEDING

	# 返回效果数据
	return {
		"effect_type": BattleEffect.EffectType.DOT,
		"name": "持续伤害: " + dot_type,
		"description": "每秒造成" + str(damage_per_second) + "点" + damage_type + "伤害",
		"duration": duration,
		"dot_type": dot_type_value,
		"damage_per_second": damage_per_second,
		"damage_type": damage_type,
		"tick_interval": 1.0,
		"tags": ["dot", "debuff"]
	}

# 创建伤害效果数据
func _create_damage_effect_data(params: Dictionary) -> Dictionary:
	# 获取参数
	var damage_value = params.get("value", 10.0)
	var damage_type = params.get("damage_type", "magical")
	var is_critical = params.get("is_critical", false)
	var is_dodgeable = params.get("is_dodgeable", true)

	# 返回效果数据
	return {
		"effect_type": BattleEffect.EffectType.DAMAGE,
		"name": "伤害: " + damage_type,
		"description": "造成" + str(damage_value) + "点" + damage_type + "伤害",
		"value": damage_value,
		"damage_type": damage_type,
		"is_critical": is_critical,
		"is_dodgeable": is_dodgeable,
		"tags": ["damage"]
	}

# 创建治疗效果数据
func _create_heal_effect_data(params: Dictionary) -> Dictionary:
	# 获取参数
	var heal_value = params.get("value", 10.0)

	# 返回效果数据
	return {
		"effect_type": BattleEffect.EffectType.HEAL,
		"name": "治疗",
		"description": "恢复" + str(heal_value) + "点生命值",
		"value": heal_value,
		"tags": ["heal"]
	}

# 根据效果类型创建视觉效果
## 将效果类型转换为视觉效果类型并创建相应的视觉效果
func _create_visual_effect_for_type(effect_type: int, target: Node2D, params: Dictionary) -> void:
	# 直接使用新的适配器函数
	create_visual_effect_from_effect_type(effect_type, target, params)

# 应用战斗效果
func _apply_battle_effect(effect_data: Dictionary, source = null, target = null):
	# 检查战斗管理器是否可用
	if not GameManager.battle_manager or not GameManager.battle_manager.effect_manager:
		_log_error("应用效果失败：战斗管理器不可用")
		return null

	# 使用战斗管理器的效果管理器应用效果
	return GameManager.battle_manager.effect_manager.apply_effect(effect_data, source, target)

# 移除效果
func remove_effect(effect_id_or_effect) -> bool:
	# 如果是效果对象
	if effect_id_or_effect is BattleEffect:
		# 使用战斗管理器的效果管理器移除效果
		if GameManager.battle_manager and GameManager.battle_manager.effect_manager:
			return GameManager.battle_manager.effect_manager.remove_effect(effect_id_or_effect)
		return false

	# 如果是效果 ID
	if effect_id_or_effect is String:
		# 检查效果是否存在
		if not active_logical_effects.has(effect_id_or_effect):
			return false

		# 获取效果
		var effect = active_logical_effects[effect_id_or_effect]

		# 如果是效果对象
		if effect is BattleEffect:
			# 使用战斗管理器的效果管理器移除效果
			if GameManager.battle_manager and GameManager.battle_manager.effect_manager:
				var result = GameManager.battle_manager.effect_manager.remove_effect(effect)
				# 从活动效果列表中移除
				if result:
					active_logical_effects.erase(effect_id_or_effect)
				return result
		return false

	return false



# 重写重置方法
func _do_reset() -> void:
	# 清理所有逻辑效果
	for effect_id in active_logical_effects:
		var effect = active_logical_effects[effect_id]
		if effect is BattleEffect:
			remove_effect(effect)

	active_logical_effects.clear()

	# 重置战斗管理器的效果管理器
	if GameManager.battle_manager and GameManager.battle_manager.effect_manager:
		GameManager.battle_manager.effect_manager.remove_all_battle_effects()

	_log_info("效果管理器重置完成")

# 重写清理方法
func _do_cleanup() -> void:
	# 断开事件连接
	EventBus.battle.disconnect_event("battle_ended", _on_battle_ended)

	# 清理所有逻辑效果
	for effect_id in active_logical_effects:
		var effect = active_logical_effects[effect_id]
		if effect is BattleEffect:
			remove_effect(effect)

	active_logical_effects.clear()

	# 清理战斗管理器的效果管理器
	if GameManager.battle_manager and GameManager.battle_manager.effect_manager:
		GameManager.battle_manager.effect_manager.remove_all_battle_effects()

	_log_info("效果管理器清理完成")
