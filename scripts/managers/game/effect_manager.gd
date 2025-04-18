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
	VisualEffectType.TELEPORT_DISAPPEAR: "res://scripts/game/effects/visuals/teleport_effect.tscn",
	VisualEffectType.TELEPORT_APPEAR: "res://scripts/game/effects/visuals/teleport_effect.tscn",
	VisualEffectType.DAMAGE: "res://scripts/game/effects/visuals/damage_visual.tscn",
	VisualEffectType.HEAL: "res://scripts/game/effects/visuals/heal_visual.tscn",
	VisualEffectType.BUFF: "res://scripts/game/effects/visuals/buff_visual.tscn",
	VisualEffectType.DEBUFF: "res://scripts/game/effects/visuals/debuff_visual.tscn",
	VisualEffectType.STUN: "res://scripts/game/effects/visuals/debuff_visual.tscn", # 使用debuff特效
	VisualEffectType.LEVEL_UP: "res://scripts/game/effects/visuals/buff_visual.tscn", # 使用buff特效
	VisualEffectType.DEATH: "res://scripts/game/effects/visuals/teleport_effect.tscn", # 使用传送消失特效
	VisualEffectType.AREA_DAMAGE: "res://scripts/game/effects/visuals/area_damage_visual.tscn",
	VisualEffectType.SUMMON: "res://scripts/game/effects/visuals/summon_visual.tscn",
	VisualEffectType.CHAIN: "res://scripts/game/effects/visuals/damage_visual.tscn", # 使用伤害特效
	VisualEffectType.DOT: "res://scripts/game/effects/visuals/debuff_visual.tscn" # 使用减益特效
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

# 重置管理器
func reset() -> bool:
	# 清理所有活动特效
	for effect in active_effects:
		if is_instance_valid(effect) and not effect.is_queued_for_deletion():
			effect.queue_free()

	active_effects.clear()

	# 清理所有逻辑效果
	for effect_id in active_logical_effects:
		var effect = active_logical_effects[effect_id]
		effect.remove()

	active_logical_effects.clear()

	print("特效管理器已重置")
	return true

# 战斗结束处理
func _on_battle_ended(winner_team: int) -> void:
	# 重置管理器
	reset()

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

# 移除效果
func remove_effect(effect_id: String) -> void:
	# 检查效果是否存在
	if not active_logical_effects.has(effect_id):
		return

	# 获取效果
	var effect = active_logical_effects[effect_id]

	# 移除效果
	effect.remove()

	# 从活动效果列表中移除
	active_logical_effects.erase(effect_id)

# 创建并添加效果
func create_and_add_effect(effect_type: int, source = null, target = null, params: Dictionary = {}) -> BaseEffect:
	# 根据效果类型创建不同的效果
	var effect = null

	match effect_type:
		BaseEffect.EffectType.STAT:
			# 创建属性效果
			effect = StatEffect.new(
				params.get("id", ""),
				params.get("name", ""),
				params.get("description", ""),
				params.get("duration", 0.0),
				params.get("stats", {}),
				source,
				target,
				params.get("is_debuff", false)
			)

		BaseEffect.EffectType.STATUS:
			# 创建状态效果
			effect = StatusEffect.new(
				params.get("id", ""),
				params.get("name", ""),
				params.get("description", ""),
				params.get("duration", 0.0),
				params.get("status_type", StatusEffect.StatusType.STUN),
				source,
				target
			)

		BaseEffect.EffectType.DAMAGE:
			# 创建伤害效果
			effect = DamageEffect.new(
				params.get("id", ""),
				params.get("name", ""),
				params.get("description", ""),
				params.get("value", 0.0),
				params.get("damage_type", "magical"),
				source,
				target
			)

			# 设置暴击和闪避
			if effect:
				effect.is_critical = params.get("is_critical", false)
				effect.is_dodgeable = params.get("is_dodgeable", true)

		BaseEffect.EffectType.HEAL:
			# 创建治疗效果
			effect = HealEffect.new(
				params.get("id", ""),
				params.get("name", ""),
				params.get("description", ""),
				params.get("value", 0.0),
				source,
				target
			)

		BaseEffect.EffectType.DOT:
			# 创建持续伤害效果
			effect = DotEffect.new(
				params.get("id", ""),
				params.get("name", ""),
				params.get("description", ""),
				params.get("duration", 0.0),
				params.get("value", 0.0),
				params.get("damage_type", "magical"),
				params.get("dot_type", DotEffect.DotType.BURNING),
				source,
				target
			)

			# 设置伤害间隔
			if effect:
				effect.tick_interval = params.get("tick_interval", 1.0)

		BaseEffect.EffectType.VISUAL:
			# 创建视觉效果
			effect = VisualEffect.new(
				params.get("id", ""),
				params.get("name", ""),
				params.get("description", ""),
				params.get("duration", 1.0),
				params.get("visual_type", VisualEffect.VisualType.PARTICLE),
				params.get("visual_path", ""),
				source,
				target
			)

		BaseEffect.EffectType.MOVEMENT:
			# 创建移动效果
			effect = MovementEffect.new(
				params.get("id", ""),
				params.get("name", ""),
				params.get("description", ""),
				params.get("movement_type", MovementEffect.MovementType.KNOCKBACK),
				params.get("distance", 1.0),
				source,
				target
			)

		BaseEffect.EffectType.SOUND:
			# 创建音效效果
			effect = SoundEffect.new(
				params.get("id", ""),
				params.get("name", ""),
				params.get("description", ""),
				params.get("sound_path", ""),
				source,
				target
			)

	# 如果创建了效果，添加到管理器
	if effect:
		add_effect(effect)

	return effect
