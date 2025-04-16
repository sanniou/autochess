extends Resource
class_name Ability
## 技能基类
## 定义技能的基本属性和行为

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

# 技能所有者
var owner: ChessPiece = null

# 初始化技能
func initialize(ability_data: Dictionary, owner_piece: ChessPiece) -> void:
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

	# 设置所有者
	owner = owner_piece

	# 加载技能图标
	var icon_path = ability_data.get("icon", "")
	if icon_path and ResourceLoader.exists(icon_path):
		icon = load(icon_path)

	# 加载技能效果
	var effect_data = ability_data.get("effects", [])
	for effect in effect_data:
		var new_effect = AbilityEffect.create(effect, owner, null)
		if new_effect:
			effects.append(new_effect)

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

	if owner.current_state == ChessPiece.ChessState.DEAD:
		return false

	if owner.current_mana < mana_cost:
		return false

	if owner.current_cooldown > 0:
		return false

	return true

# 获取技能目标
func get_target() -> ChessPiece:
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
	for target in targets:
		_apply_effects(target)

	# 播放技能特效
	_play_ability_effect(targets)

# 应用效果
func _apply_effects(target: ChessPiece) -> void:
	# 如果没有自定义效果，使用默认效果
	if effects.size() == 0:
		# 创建默认伤害效果
		var damage_effect = DamageEffect.new(
			AbilityEffect.EffectType.DAMAGE,
			damage,
			0.0,
			0.0,
			owner,
			target
		)

		# 应用效果
		damage_effect.apply()
	else:
		# 应用自定义效果
		for effect in effects:
			# 创建效果副本
			var effect_copy = effect.duplicate()

			# 设置目标
			effect_copy.target = target

			# 应用效果
			effect_copy.apply()

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
	# 获取音频管理器
	var audio_manager = owner.get_node_or_null("/root/AudioManager")
	if audio_manager:
		# 播放技能音效
		audio_manager.play_sound("ability_cast.ogg")

# 播放目标效果
func _play_target_effect(target: ChessPiece) -> void:
	if not target or not is_instance_valid(target):
		return

	# 创建特效
	var effect = ColorRect.new()
	effect.color = Color(0.8, 0.2, 0.8, 0.5)  # 紫色
	effect.size = Vector2(40, 40)
	effect.position = Vector2(-20, -20)

	# 添加到目标
	target.add_child(effect)

	# 创建消失动画
	var tween = target.create_tween()
	tween.tween_property(effect, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(effect.queue_free)

# 播放施法者效果
func _play_caster_effect() -> void:
	if not owner or not is_instance_valid(owner):
		return

	# 创建特效
	var effect = ColorRect.new()
	effect.color = Color(0.2, 0.8, 0.8, 0.5)  # 青色
	effect.size = Vector2(60, 60)
	effect.position = Vector2(-30, -30)

	# 添加到施法者
	owner.add_child(effect)

	# 创建消失动画
	var tween = owner.create_tween()
	tween.tween_property(effect, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(effect.queue_free)
