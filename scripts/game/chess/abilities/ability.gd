extends Resource
class_name Ability
## 技能基类
## 定义技能的基本属性和行为

# 引入效果类型枚举
# 游戏效果类型
const EffectType = preload("res://scripts/game/effects/game_effect.gd").EffectType
# 状态效果类型
const StatusType = preload("res://scripts/game/effects/status_effect.gd").StatusType
# 持续伤害类型
const DotType = preload("res://scripts/game/effects/dot_effect.gd").DotType
# 持续治疗类型
const HotType = preload("res://scripts/game/effects/hot_effect.gd").HotType
# 护盾类型
const ShieldType = preload("res://scripts/game/effects/shield_effect.gd").ShieldType
# 光环类型
const AuraType = preload("res://scripts/game/effects/aura_effect.gd").AuraType
# 移动类型
const MovementType = preload("res://scripts/game/effects/movement_effect.gd").MovementType
# 视觉效果类型
const VisualEffectType = preload("res://scripts/game/effects/game_effect_manager.gd").VisualEffectType

# 技能属性
var id: String = ""                # 技能ID
var name: String = ""              # 技能名称
var description: String = ""       # 技能描述
var icon: Texture2D = null         # 技能图标
var cooldown: float = 10.0         # 技能冷却时间
var mana_cost: float = 100.0       # 技能法力消耗
var damage: float = 0.0            # 技能伤害
var range: float = 0.0             # 技能范围
var duration: float = 0.0          # 技能持续时间
var target_type: String = "enemy"  # 技能目标类型(enemy/ally/self/area)
var target_strategy: String = "nearest" # 目标选择策略(nearest/furthest/lowest_health/highest_health/random/clustered)
var max_targets: int = 1           # 最大目标数量
var min_range: float = 0.0         # 最小范围
var effects: Array = []            # 技能效果列表
var damage_type: String = "magical" # 伤害类型(physical/magical/true/fire/ice/lightning/poison)

# 技能所有者
var owner: ChessPieceEntity = null

# 初始化技能
func initialize(ability_data: Dictionary, owner_piece: ChessPieceEntity) -> void:
	# 设置技能属性
	id = ability_data.get("id", "")
	name = ability_data.get("name", "")
	description = ability_data.get("description", "")
	cooldown = ability_data.get("cooldown", 10.0)
	mana_cost = ability_data.get("mana_cost", 100.0)
	damage = ability_data.get("damage", 0.0)
	range = ability_data.get("range", 0.0)
	duration = ability_data.get("duration", 0.0)
	target_type = ability_data.get("target_type", "enemy")
	target_strategy = ability_data.get("target_strategy", "nearest")
	max_targets = ability_data.get("max_targets", 1)
	min_range = ability_data.get("min_range", 0.0)
	damage_type = ability_data.get("damage_type", "magical")

	# 设置所有者
	owner = owner_piece

	# 加载技能图标
	var icon_path = ability_data.get("icon", "")
	if icon_path and ResourceLoader.exists(icon_path):
		icon = load(icon_path)

	# 加载技能效果
	var effect_data = ability_data.get("effects", [])
	for effect in effect_data:
		# 直接存储效果数据，在应用时再创建GameEffect
		effects.append(effect.duplicate())

# 激活技能
func activate(target = null) -> bool:
	# 检查是否可以激活
	if not can_activate():
		return false

	# 消耗法力
	if not owner.spend_mana(mana_cost):
		return false

	# 执行技能效果
	_execute_effect(target)

	# 设置冷却
	owner.current_cooldown = cooldown

	return true

# 检查是否可以激活
func can_activate() -> bool:
	if owner == null:
		return false

	if owner.current_state == StateMachineComponent.ChessState.DEAD:
		return false

	if owner.current_mana < mana_cost:
		return false

	if owner.current_cooldown > 0:
		return false

	return true

# 获取技能目标
func get_target() -> ChessPieceEntity:
	if owner == null:
		return null

	# 使用目标选择器选择目标
	var selector = TargetSelector.new(
		owner,
		TargetSelector.strategy_from_string(target_strategy),
		TargetSelector.target_type_from_string(target_type),
		range,
		min_range,
		1  # 只选择一个目标
	)

	var targets = selector.select_targets()
	if targets.size() > 0:
		return targets[0]

	return null

# 获取多个目标
func get_multiple_targets(count: int = 0) -> Array:
	if owner == null:
		return []

	# 使用目标选择器选择目标
	var selector = TargetSelector.new(
		owner,
		TargetSelector.strategy_from_string(target_strategy),
		TargetSelector.target_type_from_string(target_type),
		range,
		min_range,
		count if count > 0 else max_targets
	)

	return selector.select_targets()



# 执行技能效果（子类重写）
func _execute_effect(target = null) -> void:
	# 如果没有指定目标，查找目标
	if target == null and target_type != "area":
		target = get_target()

	# 如果是区域技能，获取多个目标
	var targets = []
	if target_type == "area":
		targets = get_multiple_targets()
	else:
		if target:
			targets = [target]

	# 如果没有目标，返回
	if targets.size() == 0 and target_type != "self":
		return

	# 如果是自身技能，添加自身为目标
	if target_type == "self":
		targets = [owner]

	# 应用效果
	for targetn in targets:
		_apply_effects(targetn)

	# 播放技能特效
	_play_ability_effect(targets)

# 应用效果
func _apply_effects(target: ChessPieceEntity) -> void:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return

	# 检查GameEffectManager是否可用
	if not GameManager or not GameManager.game_effect_manager:
		# 如果没有效果管理器，直接造成伤害
		if damage > 0:
			target.take_damage(damage, damage_type, owner)
		return

	# 如果没有自定义效果，使用默认效果
	if effects.size() == 0:
		# 创建伤害效果参数
		var params = {
			"id": "ability_" + id + "_damage",
			"name": name + "伤害",
			"description": "造成" + str(damage) + "点" + damage_type + "伤害",
			"value": damage,
			"damage_type": damage_type
		}

		# 使用游戏效果管理器创建效果
		GameManager.game_effect_manager.create_damage_effect(owner, target, damage, damage_type, params)
	else:
		# 应用自定义效果
		for effect_data in effects:
			# 创建效果
			_create_effect_from_data(effect_data, owner, target)

# 播放技能特效
func _play_ability_effect(targets: Array) -> void:
	# 播放技能音效
	_play_ability_sound()

	# 播放技能视觉效果
	for target in targets:
		_play_target_effect(target)

	# 播放技能施法者效果
	_play_caster_effect()

# 播放技能音效
func _play_ability_sound() -> void:
	# 使用事件总线播放音效
	EventBus.audio.emit_event("play_sound", ["ability_cast", owner.global_position])

# 播放目标效果
func _play_target_effect(target: ChessPieceEntity) -> void:
	if not target or not is_instance_valid(target):
		return

	# 创建视觉特效参数
	var params = {}

	# 设置颜色
	if GameManager and GameManager.game_effect_manager:
		params["color"] = GameManager.game_effect_manager.get_effect_color(damage_type)
	elif GameManager and GameManager.visual_manager:
		params["color"] = Color(0.2, 0.2, 0.8, 0.8) # 蓝色默认值
	else:
		params["color"] = Color(0.2, 0.2, 0.8, 0.8) # 蓝色默认值

	# 设置其他参数
	params["duration"] = 1.0
	params["damage_type"] = damage_type
	params["damage_amount"] = damage

	# 使用特效管理器创建特效
	if GameManager and GameManager.game_effect_manager:
		GameManager.game_effect_manager.create_visual_effect(
			GameManager.game_effect_manager.VisualEffectType.DAMAGE,
			target,
			params
		)
	# 如果没有效果管理器，使用视觉管理器
	elif GameManager and GameManager.visual_manager:
		GameManager.visual_manager.create_damage_number(
			target.global_position,
			damage,
			false,
			{"damage_type": damage_type}
		)

# 播放施法者效果
func _play_caster_effect() -> void:
	if not owner or not is_instance_valid(owner):
		return

	# 创建视觉特效参数
	var params = {
		"color": Color(0.8, 0.2, 0.8, 0.5),  # 紫色
		"duration": 1.0,
		"buff_type": "ability_cast"
	}

	# 使用特效管理器创建特效
	if GameManager and GameManager.game_effect_manager:
		GameManager.game_effect_manager.create_visual_effect(
			GameManager.game_effect_manager.VisualEffectType.BUFF,
			owner,
			params
		)
	# 如果没有效果管理器，使用视觉管理器
	elif GameManager and GameManager.visual_manager:
		GameManager.visual_manager.create_combined_effect(
			owner.global_position,
			"buff_ability_cast",
			params
		)

# 从效果数据创建效果
func _create_effect_from_data(effect_data: Dictionary, source: ChessPieceEntity, target: ChessPieceEntity) -> void:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return

	# 检查GameEffectManager是否可用
	if not GameManager or not GameManager.game_effect_manager:
		return

	# 获取效果类型
	var effect_type_str = effect_data.get("type", "damage")

	# 根据效果类型创建相应的效果
	match effect_type_str:
		"damage":
			# 创建伤害效果
			var damage_value = effect_data.get("value", 0.0)
			var damage_type = effect_data.get("damage_type", "magical")

			# 准备完整的效果数据
			var complete_effect_data = effect_data.duplicate()
			complete_effect_data["effect_type"] = EffectType.DAMAGE
			complete_effect_data["value"] = damage_value
			complete_effect_data["damage_type"] = damage_type
			complete_effect_data["tags"] = ["damage"]

			# 使用游戏效果管理器创建效果
			GameManager.game_effect_manager.apply_effect(complete_effect_data, source, target)

		"heal":
			# 创建治疗效果
			var heal_value = effect_data.get("value", 0.0)

			# 准备完整的效果数据
			var complete_effect_data = effect_data.duplicate()
			complete_effect_data["effect_type"] = EffectType.HEAL
			complete_effect_data["value"] = heal_value
			complete_effect_data["tags"] = ["heal"]

			# 使用游戏效果管理器创建效果
			GameManager.game_effect_manager.apply_effect(complete_effect_data, source, target)

		"buff", "stat_mod":
			# 创建属性修改效果
			var stats = {}
			var buff_type = effect_data.get("buff_type", "attack")
			var buff_value = effect_data.get("value", 0.0)
			var duration = effect_data.get("duration", 0.0)

			# 根据增益类型设置效果
			match buff_type:
				"attack":
					stats["attack_damage"] = buff_value
				"defense":
					stats["armor"] = buff_value
				"speed":
					stats["attack_speed"] = buff_value
				"health":
					stats["health"] = buff_value

			# 准备完整的效果数据
			var complete_effect_data = effect_data.duplicate()
			complete_effect_data["effect_type"] = EffectType.STAT_MOD
			complete_effect_data["stats"] = stats
			complete_effect_data["duration"] = duration
			complete_effect_data["is_debuff"] = false
			complete_effect_data["tags"] = ["buff"]

			# 使用游戏效果管理器创建效果
			GameManager.game_effect_manager.apply_effect(complete_effect_data, source, target)

		"debuff", "stat_decrease":
			# 创建属性减益效果
			var stats = {}
			var stat_type = effect_data.get("debuff_type", "attack")
			var stat_value = -effect_data.get("value", 0.0)  # 负值表示减益
			var duration = effect_data.get("duration", 0.0)

			# 根据减益类型设置效果
			match stat_type:
				"attack":
					stats["attack_damage"] = stat_value
				"defense":
					stats["armor"] = stat_value
				"speed":
					stats["attack_speed"] = stat_value
				"health":
					stats["health"] = stat_value

			# 准备完整的效果数据
			var complete_effect_data = effect_data.duplicate()
			complete_effect_data["effect_type"] = EffectType.STAT_MOD
			complete_effect_data["stats"] = stats
			complete_effect_data["duration"] = duration
			complete_effect_data["is_debuff"] = true
			complete_effect_data["tags"] = ["debuff"]

			# 使用游戏效果管理器创建效果
			GameManager.game_effect_manager.apply_effect(complete_effect_data, source, target)

		"status", "control":
			# 创建状态效果
			var status_type_str = effect_data.get("status_type", "stun")
			var duration = effect_data.get("duration", 0.0)

			# 将状态类型字符串转换为枚举值
			var status_type = StatusType.STUN  # 默认为眩晕
			match status_type_str:
				"stun":
					status_type = StatusType.STUN
				"silence":
					status_type = StatusType.SILENCE
				"root":
					status_type = StatusType.ROOT
				"disarm":
					status_type = StatusType.DISARM
				#"fear":
					#status_type = StatusType.FEAR
				"taunt":
					status_type = StatusType.TAUNT

			# 准备完整的效果数据
			var complete_effect_data = effect_data.duplicate()
			complete_effect_data["effect_type"] = EffectType.STATUS
			complete_effect_data["status_type"] = status_type
			complete_effect_data["duration"] = duration

			# 使用游戏效果管理器创建效果
			GameManager.game_effect_manager.apply_effect(complete_effect_data, source, target)

		"dot":
			# 创建持续伤害效果
			var dot_type_str = effect_data.get("dot_type", "poison")
			var damage_per_second = effect_data.get("value", 0.0)
			var duration = effect_data.get("duration", 0.0)
			var damage_type = effect_data.get("damage_type", "magical")

			# 将DOT类型字符串转换为枚举值
			var dot_type = DotType.POISON  # 默认为毒素
			match dot_type_str:
				"poison":
					dot_type = DotType.POISON
				"burn":
					dot_type = DotType.BURNING
				#"bleed":
					#dot_type = DotType.BLEED
				"acid":
					dot_type = DotType.ACID
				"decay":
					dot_type = DotType.DECAY

			# 准备完整的效果数据
			var complete_effect_data = effect_data.duplicate()
			complete_effect_data["effect_type"] = EffectType.DOT
			complete_effect_data["dot_type"] = dot_type
			complete_effect_data["damage_per_second"] = damage_per_second
			complete_effect_data["duration"] = duration
			complete_effect_data["damage_type"] = damage_type
			complete_effect_data["tags"] = ["dot", "debuff"]

			# 使用游戏效果管理器创建效果
			GameManager.game_effect_manager.apply_effect(complete_effect_data, source, target)

		"hot":
			# 创建持续治疗效果
			var hot_type_str = effect_data.get("hot_type", "regeneration")
			var heal_per_second = effect_data.get("value", 0.0)
			var duration = effect_data.get("duration", 0.0)

			# 将HOT类型字符串转换为枚举值
			var hot_type = HotType.REGENERATION  # 默认为再生
			match hot_type_str:
				"regeneration":
					hot_type = HotType.REGENERATION
				"healing_aura":
					hot_type = HotType.HEALING_AURA
				"blessing":
					hot_type = HotType.BLESSING
				"life_bloom":
					hot_type = HotType.LIFE_LINK
				"rejuvenation":
					hot_type = HotType.REJUVENATION

			# 准备完整的效果数据
			var complete_effect_data = effect_data.duplicate()
			complete_effect_data["effect_type"] = EffectType.HOT
			complete_effect_data["hot_type"] = hot_type
			complete_effect_data["heal_per_second"] = heal_per_second
			complete_effect_data["duration"] = duration
			complete_effect_data["tags"] = ["hot", "buff"]

			# 使用游戏效果管理器创建效果
			GameManager.game_effect_manager.apply_effect(complete_effect_data, source, target)

		"shield":
			# 创建护盾效果
			var shield_type_str = effect_data.get("shield_type", "normal")
			var shield_amount = effect_data.get("value", 0.0)
			var duration = effect_data.get("duration", 0.0)

			# 将护盾类型字符串转换为枚举值
			var shield_type = ShieldType.NORMAL  # 默认为普通护盾
			match shield_type_str:
				"normal":
					shield_type = ShieldType.NORMAL
				"magic":
					shield_type = ShieldType.MAGIC
				"physical":
					shield_type = ShieldType.PHYSICAL
				"reflect":
					shield_type = ShieldType.REFLECT
				#"absorb":
					#shield_type = ShieldType.ABSORB
				#"thorns":
					#shield_type = ShieldType.THORNS

			# 准备完整的效果数据
			var complete_effect_data = effect_data.duplicate()
			complete_effect_data["effect_type"] = EffectType.SHIELD
			complete_effect_data["shield_type"] = shield_type
			complete_effect_data["shield_amount"] = shield_amount
			complete_effect_data["duration"] = duration
			complete_effect_data["tags"] = ["shield", "buff"]

			# 使用游戏效果管理器创建效果
			GameManager.game_effect_manager.apply_effect(complete_effect_data, source, target)

		"visual":
			# 创建视觉效果
			var visual_type = effect_data.get("visual_type", "particle")
			var visual_path = effect_data.get("visual_path", "")
			var duration = effect_data.get("duration", 1.0)

			# 创建视觉效果参数
			var visual_params = {
				"duration": duration,
				"path": visual_path,
				"type": visual_type
			}

			# 合并原始参数
			for key in effect_data:
				if key != "type" and key != "visual_type" and key != "visual_path" and key != "duration":
					visual_params[key] = effect_data[key]

			# 使用视觉管理器创建效果
			if GameManager.visual_manager:
				GameManager.visual_manager.create_combined_effect(
					target.global_position,
					visual_type,
					visual_params
				)

		"sound":
			# 播放音效
			var sound_path = effect_data.get("sound_path", "")
			if sound_path and EventBus and EventBus.audio:
				EventBus.audio.emit_event("play_sound", [sound_path, target.global_position])

		"aura":
			# 创建光环效果
			var aura_type_str = effect_data.get("aura_type", "buff")
			var radius = effect_data.get("radius", 300.0)
			var duration = effect_data.get("duration", 0.0)
			var aura_effect_data = effect_data.get("effect_data", {})

			# 将光环类型字符串转换为枚举值
			var aura_type = AuraType.BUFF  # 默认为增益光环
			match aura_type_str:
				"buff":
					aura_type = AuraType.BUFF
				"debuff":
					aura_type = AuraType.DEBUFF
				"damage":
					aura_type = AuraType.DAMAGE
				"heal":
					aura_type = AuraType.HEALING
				"protection":
					aura_type = AuraType.PROTECTION

			# 准备完整的效果数据
			var complete_effect_data = effect_data.duplicate()
			complete_effect_data["effect_type"] = EffectType.AURA
			complete_effect_data["aura_type"] = aura_type
			complete_effect_data["radius"] = radius
			complete_effect_data["duration"] = duration
			complete_effect_data["effect_data"] = aura_effect_data
			complete_effect_data["update_interval"] = effect_data.get("update_interval", 0.5)

			# 设置效果标识和名称
			if not complete_effect_data.has("id"):
				complete_effect_data["id"] = "ability_" + id + "_aura"

			if not complete_effect_data.has("name"):
				complete_effect_data["name"] = name + "光环"

			if not complete_effect_data.has("description"):
				complete_effect_data["description"] = "创建一个" + complete_effect_data["name"]

			# 使用游戏效果管理器创建效果
			GameManager.game_effect_manager.apply_effect(complete_effect_data, source, target)

		"movement":
			# 创建移动效果
			var movement_type_str = effect_data.get("movement_type", "push")
			var distance = effect_data.get("distance", 1.0)
			var speed = effect_data.get("speed", 1.0)

			# 将移动类型字符串转换为枚举值
			var movement_type = MovementType.PUSH  # 默认为推动
			match movement_type_str:
				"push":
					movement_type = MovementType.PUSH
				"pull":
					movement_type = MovementType.PULL
				"teleport":
					movement_type = MovementType.TELEPORT
				"jump":
					movement_type = MovementType.JUMP
				"dash":
					movement_type = MovementType.DASH

			# 准备完整的效果数据
			var complete_effect_data = effect_data.duplicate()
			complete_effect_data["effect_type"] = EffectType.MOVEMENT
			complete_effect_data["movement_type"] = movement_type
			complete_effect_data["distance"] = distance
			complete_effect_data["speed"] = speed

			# 使用游戏效果管理器创建效果
			GameManager.game_effect_manager.apply_effect(complete_effect_data, source, target)
