extends "res://scripts/managers/core/base_manager.gd"
class_name EffectManager
## 特效管理器
## 负责创建和管理游戏中的各种特效

# 视觉特效类型枚举
enum VisualEffectType {
	TELEPORT_DISAPPEAR,  # 传送消失
	TELEPORT_APPEAR,     # 传送出现
	DAMAGE,              # 伤害
	HEAL,                # 治疗
	BUFF,                # 增益
	DEBUFF,              # 减益
	STUN,                # 眩晕
	LEVEL_UP,            # 升级
	DEATH,               # 死亡
	AREA_DAMAGE,         # 区域伤害
	SUMMON,              # 召唤
	CHAIN,               # 链式效果
	DOT                  # 持续伤害
}

# 特效场景路径
var effect_scenes = {
	VisualEffectType.TELEPORT_DISAPPEAR: "res://scenes/effects/teleport_effect_visual.tscn",
	VisualEffectType.TELEPORT_APPEAR: "res://scenes/effects/teleport_effect_visual.tscn",
	VisualEffectType.DAMAGE: "res://scenes/effects/damage_effect_visual.tscn",
	VisualEffectType.HEAL: "res://scenes/effects/heal_effect_visual.tscn",
	VisualEffectType.BUFF: "res://scenes/effects/buff_effect_visual.tscn",
	VisualEffectType.DEBUFF: "res://scenes/effects/debuff_effect_visual.tscn",
	VisualEffectType.STUN: "res://scenes/effects/debuff_effect_visual.tscn", # 使用debuff特效
	VisualEffectType.LEVEL_UP: "res://scenes/effects/buff_effect_visual.tscn", # 使用buff特效
	VisualEffectType.DEATH: "res://scenes/effects/teleport_effect_visual.tscn", # 使用传送消失特效
	VisualEffectType.AREA_DAMAGE: "res://scenes/effects/area_damage_effect_visual.tscn",
	VisualEffectType.SUMMON: "res://scenes/effects/summon_effect_visual.tscn",
	VisualEffectType.CHAIN: "res://scenes/effects/damage_effect_visual.tscn", # 使用伤害特效
	VisualEffectType.DOT: "res://scenes/effects/debuff_effect_visual.tscn" # 使用减益特效
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

# 当前活动的特效
var active_effects = []

# 当前活动的逻辑效果
var active_logical_effects = {}  # 效果ID -> 效果对象

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "EffectManager"

	# 预加载特效场景
	_preload_effect_scenes()

	# 连接信号
	EventBus.battle.connect_event("battle_ended", _on_battle_ended)

	print("特效管理器初始化完成")

# 预加载特效场景
func _preload_effect_scenes():
	for effect_type in effect_scenes:
		var scene_path = effect_scenes[effect_type]
		if ResourceLoader.exists(scene_path):
			var scene = load(scene_path)
			if scene:
				print("预加载特效场景: " + scene_path)

# 创建视觉特效
func create_visual_effect(effect_type: VisualEffectType, target: Node2D, params: Dictionary = {}):
	# 检查特效类型是否有效
	if not effect_scenes.has(effect_type):
		print("无效的特效类型: " + str(effect_type))
		return null

	# 获取特效场景路径
	var scene_path = effect_scenes[effect_type]

	# 检查场景是否存在
	if not ResourceLoader.exists(scene_path):
		print("特效场景不存在: " + scene_path)
		return null

	# 加载特效场景
	var effect_scene = load(scene_path)
	if not effect_scene:
		print("无法加载特效场景: " + scene_path)
		return null

	# 实例化特效
	var effect_instance = effect_scene.instantiate()
	if not effect_instance:
		print("无法实例化特效场景: " + scene_path)
		return null

	# 添加到目标
	target.add_child(effect_instance)

	# 设置特效参数
	match effect_type:
		VisualEffectType.TELEPORT_DISAPPEAR:
			if effect_instance.has_method("play_disappear_effect"):
				effect_instance.play_disappear_effect()

		VisualEffectType.TELEPORT_APPEAR:
			if effect_instance.has_method("play_appear_effect"):
				effect_instance.play_appear_effect()

		VisualEffectType.DAMAGE:
			if effect_instance.has_method("play_damage_effect"):
				var damage_type = params.get("damage_type", "magical")
				var color = effect_colors.get(damage_type, effect_colors["magical"])
				var damage_amount = params.get("damage_amount", 0.0)
				effect_instance.play_damage_effect(color, damage_amount)

		VisualEffectType.HEAL:
			if effect_instance.has_method("play_heal_effect"):
				var heal_amount = params.get("heal_amount", 0.0)
				effect_instance.play_heal_effect(heal_amount)

		VisualEffectType.BUFF:
			if effect_instance.has_method("play_buff_effect"):
				var buff_type = params.get("buff_type", "buff")
				var color = effect_colors.get(buff_type, effect_colors["buff"])
				effect_instance.play_buff_effect(color)

		VisualEffectType.DEBUFF:
			if effect_instance.has_method("play_debuff_effect"):
				var debuff_type = params.get("debuff_type", "debuff")
				var color = effect_colors.get(debuff_type, effect_colors["debuff"])
				effect_instance.play_debuff_effect(color)

		VisualEffectType.STUN:
			if effect_instance.has_method("play_debuff_effect"):
				var color = effect_colors["stun"]
				effect_instance.play_debuff_effect(color)

		VisualEffectType.LEVEL_UP:
			if effect_instance.has_method("play_buff_effect"):
				var color = effect_colors["level_up"]
				effect_instance.play_buff_effect(color)

		VisualEffectType.DEATH:
			if effect_instance.has_method("play_disappear_effect"):
				effect_instance.play_disappear_effect()

		VisualEffectType.AREA_DAMAGE:
			if effect_instance.has_method("play_area_damage_effect"):
				var damage_type = params.get("damage_type", "magical")
				var color = effect_colors.get(damage_type, effect_colors["magical"])
				var radius = params.get("radius", 100.0)
				effect_instance.play_area_damage_effect(color, radius)

		VisualEffectType.SUMMON:
			if effect_instance.has_method("play_summon_effect"):
				var summon_type = params.get("summon_type", "summon")
				var color = effect_colors.get(summon_type, Color(0.2, 0.8, 0.2, 0.8))
				effect_instance.play_summon_effect(color)

		VisualEffectType.CHAIN:
			if effect_instance.has_method("play_damage_effect"):
				var damage_type = params.get("damage_type", "magical")
				var color = effect_colors.get(damage_type, effect_colors["magical"])
				var damage_amount = params.get("damage_amount", 0.0)
				effect_instance.play_damage_effect(color, damage_amount)

	# 添加到活动特效列表
	active_effects.append(effect_instance)

	# 返回特效实例
	return effect_instance

# 清理完成的特效
func _process(delta):
	# 清理视觉特效
	var i = 0
	while i < active_effects.size():
		var effect = active_effects[i]
		if not is_instance_valid(effect) or effect.is_queued_for_deletion():
			active_effects.remove_at(i)
		else:
			i += 1

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
func add_effect(effect: BaseEffect) -> void:
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
	# 使用战斗管理器的效果管理器创建效果
	if GameManager.battle_manager and GameManager.battle_manager.effect_manager:
		# 创建效果数据
		var effect_data = {}

		match effect_type:
			BaseEffect.EffectType.STAT:
				# 创建增益效果数据
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

				# 创建效果数据
				effect_data = {
					"effect_type": BattleEffect.EffectType.STAT_MOD,
					"name": "增益: " + buff_type,
					"description": "增加" + buff_type + "属性" + str(buff_value),
					"duration": duration,
					"stats": stats,
					"is_percentage": false,
					"tags": ["buff"]
				}

				# 创建视觉效果
				create_visual_effect(VisualEffectType.BUFF, target, {
					"color": get_effect_color(buff_type),
					"duration": duration
				})

			BaseEffect.EffectType.STATUS:
				# 创建状态效果数据
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

				# 创建效果数据
				effect_data = {
					"effect_type": BattleEffect.EffectType.STATUS,
					"name": "状态: " + status_type,
					"description": "施加" + status_type + "状态",
					"duration": duration,
					"status_type": status_type_value,
					"tags": ["status", "debuff"]
				}

				# 创建视觉效果
				create_visual_effect(VisualEffectType.STUN, target, {
					"color": get_effect_color(status_type),
					"duration": duration
				})

			BaseEffect.EffectType.DOT:
				# 创建持续伤害效果数据
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

				# 创建效果数据
				effect_data = {
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

				# 创建视觉效果
				create_visual_effect(VisualEffectType.DOT, target, {
					"color": get_effect_color(damage_type),
					"duration": duration,
					"dot_type": dot_type
				})

			BaseEffect.EffectType.DAMAGE:
				# 创建伤害效果数据
				var damage_value = params.get("value", 10.0)
				var damage_type = params.get("damage_type", "magical")
				var is_critical = params.get("is_critical", false)
				var is_dodgeable = params.get("is_dodgeable", true)

				# 创建效果数据
				effect_data = {
					"effect_type": BattleEffect.EffectType.DAMAGE,
					"name": "伤害: " + damage_type,
					"description": "造成" + str(damage_value) + "点" + damage_type + "伤害",
					"value": damage_value,
					"damage_type": damage_type,
					"is_critical": is_critical,
					"is_dodgeable": is_dodgeable,
					"tags": ["damage"]
				}

				# 创建视觉效果
				create_visual_effect(VisualEffectType.DAMAGE, target, {
					"damage_type": damage_type,
					"damage_amount": damage_value
				})

			BaseEffect.EffectType.HEAL:
				# 创建治疗效果数据
				var heal_value = params.get("value", 10.0)

				# 创建效果数据
				effect_data = {
					"effect_type": BattleEffect.EffectType.HEAL,
					"name": "治疗",
					"description": "恢复" + str(heal_value) + "点生命值",
					"value": heal_value,
					"tags": ["heal"]
				}

				# 创建视觉效果
				create_visual_effect(VisualEffectType.HEAL, target, {
					"heal_amount": heal_value
				})

		# 应用效果
		if not effect_data.is_empty():
			return GameManager.battle_manager.effect_manager.apply_effect(effect_data, null, target)

	# 如果不能使用新系统，使用旧系统
	return create_and_add_effect(effect_type, null, target, params)

# 移除效果
func remove_effect(effect_id_or_effect) -> void:
	# 如果是效果对象
	if effect_id_or_effect is BattleEffect:
		# 使用战斗管理器的效果管理器移除效果
		if GameManager.battle_manager and GameManager.battle_manager.effect_manager:
			GameManager.battle_manager.effect_manager.remove_effect(effect_id_or_effect)
			return

	# 如果是效果 ID
	if effect_id_or_effect is String:
		# 检查效果是否存在
		if not active_logical_effects.has(effect_id_or_effect):
			return

		# 获取效果
		var effect = active_logical_effects[effect_id_or_effect]

		# 如果是新效果系统的效果
		if effect is BattleEffect:
			# 使用战斗管理器的效果管理器移除效果
			if GameManager.battle_manager and GameManager.battle_manager.effect_manager:
				GameManager.battle_manager.effect_manager.remove_effect(effect)
				# 从活动效果列表中移除
				active_logical_effects.erase(effect_id_or_effect)
			return

		# 如果是旧效果系统的效果
		if effect is BaseEffect:
			# 移除效果
			effect.remove()

			# 从活动效果列表中移除
			active_logical_effects.erase(effect_id_or_effect)

# 创建并添加效果
func create_and_add_effect(effect_type: int, source = null, target = null, params: Dictionary = {}) -> BaseEffect:
	# 尝试使用新的效果系统
	if GameManager.battle_manager and GameManager.battle_manager.effect_manager:
		# 迁移效果数据
		var migrated_data = EffectMigrationTool.migrate_effect_data(params)
		migrated_data["effect_type"] = EffectMigrationTool._convert_effect_type(effect_type)

		# 使用战斗管理器的效果管理器创建效果
		var battle_effect = GameManager.battle_manager.effect_manager.apply_effect(migrated_data, source, target)
		if battle_effect:
			return battle_effect

	# 如果不能使用新系统，使用旧系统
	# 注意：这部分代码应该不会被执行，因为我们已经完全迁移到新系统
	print("WARNING: 尝试使用旧效果系统，这不应该发生")
	return null

# 重写重置方法
func _do_reset() -> void:
	# 清理所有活动特效
	for effect in active_effects:
		if is_instance_valid(effect) and not effect.is_queued_for_deletion():
			effect.queue_free()

	active_effects.clear()

	# 清理所有逻辑效果
	for effect_id in active_logical_effects:
		var effect = active_logical_effects[effect_id]
		if effect is BaseEffect:
			effect.remove()
		elif effect is BattleEffect:
			if GameManager.battle_manager and GameManager.battle_manager.effect_manager:
				GameManager.battle_manager.effect_manager.remove_effect(effect)

	active_logical_effects.clear()

	# 重置战斗管理器的效果管理器
	if GameManager.battle_manager and GameManager.battle_manager.effect_manager:
		GameManager.battle_manager.effect_manager.remove_all_battle_effects()

	_log_info("特效管理器重置完成")

# 重写清理方法
func _do_cleanup() -> void:
	# 断开事件连接
	EventBus.battle.disconnect_event("battle_ended", _on_battle_ended)

	# 清理所有活动特效
	for effect in active_effects:
		if is_instance_valid(effect) and not effect.is_queued_for_deletion():
			effect.queue_free()

	active_effects.clear()

	# 清理所有逻辑效果
	for effect_id in active_logical_effects:
		var effect = active_logical_effects[effect_id]
		if effect is BaseEffect:
			effect.remove()
		elif effect is BattleEffect:
			if GameManager.battle_manager and GameManager.battle_manager.effect_manager:
				GameManager.battle_manager.effect_manager.remove_effect(effect)

	active_logical_effects.clear()

	# 清理战斗管理器的效果管理器
	if GameManager.battle_manager and GameManager.battle_manager.effect_manager:
		GameManager.battle_manager.effect_manager.remove_all_battle_effects()

	_log_info("特效管理器清理完成")
