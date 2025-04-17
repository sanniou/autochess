extends "res://scripts/managers/core/base_manager.gd"
class_name EffectManager
## 特效管理器
## 负责创建和管理游戏中的各种特效

# 特效类型枚举
enum EffectType {
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
	CHAIN                # 链式效果
}

# 特效场景路径
var effect_scenes = {
	EffectType.TELEPORT_DISAPPEAR: "res://effects/teleport_effect.tscn",
	EffectType.TELEPORT_APPEAR: "res://effects/teleport_effect.tscn",
	EffectType.DAMAGE: "res://effects/damage_effect.tscn",
	EffectType.HEAL: "res://effects/heal_effect.tscn",
	EffectType.BUFF: "res://effects/buff_effect.tscn",
	EffectType.DEBUFF: "res://effects/debuff_effect.tscn",
	EffectType.STUN: "res://effects/debuff_effect.tscn", # 使用debuff特效
	EffectType.LEVEL_UP: "res://effects/buff_effect.tscn", # 使用buff特效
	EffectType.DEATH: "res://effects/teleport_effect.tscn", # 使用传送消失特效
	EffectType.AREA_DAMAGE: "res://effects/area_damage_effect.tscn",
	EffectType.SUMMON: "res://effects/summon_effect.tscn",
	EffectType.CHAIN: "res://effects/damage_effect.tscn" # 使用伤害特效
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

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "EffectManager"

	# 预加载特效场景
	_preload_effect_scenes()

	print("特效管理器初始化完成")

# 预加载特效场景
func _preload_effect_scenes():
	for effect_type in effect_scenes:
		var scene_path = effect_scenes[effect_type]
		if ResourceLoader.exists(scene_path):
			var scene = load(scene_path)
			if scene:
				print("预加载特效场景: " + scene_path)

# 创建特效
func create_effect(effect_type: int, target: Node2D, params: Dictionary = {}):
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
		EffectType.TELEPORT_DISAPPEAR:
			if effect_instance.has_method("play_disappear_effect"):
				effect_instance.play_disappear_effect()

		EffectType.TELEPORT_APPEAR:
			if effect_instance.has_method("play_appear_effect"):
				effect_instance.play_appear_effect()

		EffectType.DAMAGE:
			if effect_instance.has_method("play_damage_effect"):
				var damage_type = params.get("damage_type", "magical")
				var color = effect_colors.get(damage_type, effect_colors["magical"])
				var damage_amount = params.get("damage_amount", 0.0)
				effect_instance.play_damage_effect(color, damage_amount)

		EffectType.HEAL:
			if effect_instance.has_method("play_heal_effect"):
				var heal_amount = params.get("heal_amount", 0.0)
				effect_instance.play_heal_effect(heal_amount)

		EffectType.BUFF:
			if effect_instance.has_method("play_buff_effect"):
				var buff_type = params.get("buff_type", "buff")
				var color = effect_colors.get(buff_type, effect_colors["buff"])
				effect_instance.play_buff_effect(color)

		EffectType.DEBUFF:
			if effect_instance.has_method("play_debuff_effect"):
				var debuff_type = params.get("debuff_type", "debuff")
				var color = effect_colors.get(debuff_type, effect_colors["debuff"])
				effect_instance.play_debuff_effect(color)

		EffectType.STUN:
			if effect_instance.has_method("play_debuff_effect"):
				var color = effect_colors["stun"]
				effect_instance.play_debuff_effect(color)

		EffectType.LEVEL_UP:
			if effect_instance.has_method("play_buff_effect"):
				var color = effect_colors["level_up"]
				effect_instance.play_buff_effect(color)

		EffectType.DEATH:
			if effect_instance.has_method("play_disappear_effect"):
				effect_instance.play_disappear_effect()

		EffectType.AREA_DAMAGE:
			if effect_instance.has_method("play_area_damage_effect"):
				var damage_type = params.get("damage_type", "magical")
				var color = effect_colors.get(damage_type, effect_colors["magical"])
				var radius = params.get("radius", 100.0)
				effect_instance.play_area_damage_effect(color, radius)

		EffectType.SUMMON:
			if effect_instance.has_method("play_summon_effect"):
				var summon_type = params.get("summon_type", "summon")
				var color = effect_colors.get(summon_type, Color(0.2, 0.8, 0.2, 0.8))
				effect_instance.play_summon_effect(color)

		EffectType.CHAIN:
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
	var i = 0
	while i < active_effects.size():
		var effect = active_effects[i]
		if not is_instance_valid(effect) or effect.is_queued_for_deletion():
			active_effects.remove_at(i)
		else:
			i += 1

# 获取特效颜色
func get_effect_color(effect_type: String) -> Color:
	return effect_colors.get(effect_type, Color(1, 1, 1, 1))

# 重置管理器
func reset() -> bool:
	# 清理所有活动特效
	for effect in active_effects:
		if is_instance_valid(effect) and not effect.is_queued_for_deletion():
			effect.queue_free()

	active_effects.clear()

	print("特效管理器已重置")
	return true
