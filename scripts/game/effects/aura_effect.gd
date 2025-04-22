extends GameEffect
class_name AuraEffect
## 光环效果
## 用于在一定范围内影响多个目标

# 光环半径
var aura_radius: float = 0.0

# 影响的目标列表
var affected_targets: Array = []

# 光环效果数据
var aura_effect_data: Dictionary = {}

# 上次更新时间
var last_update_time: float = 0.0

# 更新间隔
var update_interval: float = 0.5

# 初始化
func _init(effect_id: String = "", effect_name: String = "", effect_description: String = "",
		effect_duration: float = 0.0, aura_radius_param: float = 0.0,
		effect_source = null, effect_target = null, effect_params: Dictionary = {}):
	super._init(effect_id, effect_name, effect_description, effect_duration,
			EffectType.AURA, effect_source, effect_target, effect_params)

	aura_radius = aura_radius_param

	# 设置光环效果数据
	aura_effect_data = effect_params.get("aura_effect_data", {})

	# 设置标签
	if not tags.has("aura"):
		tags.append("aura")

	# 设置是否是减益光环
	var is_debuff = effect_params.get("is_debuff", false)
	if is_debuff:
		if not tags.has("debuff"):
			tags.append("debuff")
	else:
		if not tags.has("buff"):
			tags.append("buff")

	# 设置图标路径
	icon_path = _get_aura_icon_path(is_debuff)

	# 设置名称和描述
	if name.is_empty():
		name = is_debuff ? "减益光环" : "增益光环"

	if description.is_empty():
		description = _get_aura_description(aura_radius, is_debuff)

# 应用效果
func apply() -> bool:
	if not super.apply():
		return false

	# 立即更新一次光环
	_update_aura()

	return true

# 移除效果
func remove() -> bool:
	if not super.remove():
		return false

	# 移除所有受影响目标的效果
	_remove_all_aura_effects()

	return true

# 更新效果
func update(delta: float) -> bool:
	if not super.update(delta):
		return false

	# 更新上次更新时间
	last_update_time += delta

	# 检查是否到达更新间隔
	if last_update_time >= update_interval:
		# 重置上次更新时间
		last_update_time = 0.0

		# 更新光环
		_update_aura()

	return true

# 更新光环
func _update_aura() -> void:
	# 检查源是否有效
	if not source or not is_instance_valid(source):
		return

	# 获取源的位置
	var source_position = Vector2.ZERO
	if source is Node2D:
		source_position = source.global_position

	# 获取范围内的目标
	var targets_in_range = _get_targets_in_range(source_position, aura_radius)

	# 移除不再在范围内的目标的效果
	for target in affected_targets.duplicate():
		if not targets_in_range.has(target):
			_remove_aura_effect(target)
			affected_targets.erase(target)

	# 为新进入范围的目标添加效果
	for target in targets_in_range:
		if not affected_targets.has(target):
			_apply_aura_effect(target)
			affected_targets.append(target)

# 获取范围内的目标
func _get_targets_in_range(center: Vector2, radius: float) -> Array:
	var targets = []

	# 检查GameManager是否可用
	if not GameManager:
		return targets

	# 获取当前场景中的所有单位
	var units = []

	# 如果有战斗管理器，使用战斗管理器获取单位
	if GameManager.battle_manager:
		units = GameManager.battle_manager.get_all_units()
	else:
		# 否则，从当前场景中获取所有单位
		var scene_tree = Engine.get_main_loop()
		if scene_tree:
			var current_scene = scene_tree.current_scene
			if current_scene:
				# 获取所有可能的单位节点
				units = current_scene.get_tree().get_nodes_in_group("units")

	# 过滤在范围内的单位
	for unit in units:
		# 跳过源
		if unit == source:
			continue

		# 检查单位是否有效
		if not is_instance_valid(unit):
			continue

		# 检查单位是否是Node2D
		if not unit is Node2D:
			continue

		# 计算距离
		var distance = unit.global_position.distance_to(center)

		# 检查是否在范围内
		if distance <= radius:
			targets.append(unit)

	return targets

# 应用光环效果
func _apply_aura_effect(target) -> void:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return

	# 检查GameManager和GameEffectManager是否可用
	if not GameManager or not GameManager.game_effect_manager:
		return

	# 创建光环效果
	var aura_effect = GameManager.game_effect_manager.apply_effect(aura_effect_data, source, target)

	# 存储光环效果ID
	if aura_effect:
		target.set_meta("aura_effect_" + id, aura_effect.id)

	# 发送光环效果应用事件
	if EventBus:
		EventBus.emit_signal("aura_effect_applied", {
			"aura": self,
			"source": source,
			"target": target,
			"effect": aura_effect
		})

# 移除光环效果
func _remove_aura_effect(target) -> void:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return

	# 检查GameManager和GameEffectManager是否可用
	if not GameManager or not GameManager.game_effect_manager:
		return

	# 获取光环效果ID
	var aura_effect_id = target.get_meta("aura_effect_" + id, "")

	# 如果有效果ID，移除效果
	if not aura_effect_id.is_empty():
		GameManager.game_effect_manager.remove_effect(aura_effect_id)
		target.remove_meta("aura_effect_" + id)

	# 发送光环效果移除事件
	if EventBus:
		EventBus.emit_signal("aura_effect_removed", {
			"aura": self,
			"source": source,
			"target": target
		})

# 移除所有光环效果
func _remove_all_aura_effects() -> void:
	# 移除所有受影响目标的效果
	for target in affected_targets.duplicate():
		_remove_aura_effect(target)

	# 清空受影响目标列表
	affected_targets.clear()

# 获取光环图标路径
func _get_aura_icon_path(is_debuff: bool) -> String:
	if is_debuff:
		return "res://assets/icons/aura/debuff_aura.png"
	else:
		return "res://assets/icons/aura/buff_aura.png"

# 获取光环描述
func _get_aura_description(radius: float, is_debuff: bool) -> String:
	var desc = ""

	if is_debuff:
		desc = "在 " + str(radius) + " 范围内对敌人施加减益效果"
	else:
		desc = "在 " + str(radius) + " 范围内对友军施加增益效果"

	return desc

# 获取效果数据
func get_data() -> Dictionary:
	var data = super.get_data()
	data["aura_radius"] = aura_radius
	data["aura_effect_data"] = aura_effect_data.duplicate()
	data["update_interval"] = update_interval

	# 存储受影响目标的ID
	var affected_target_ids = []
	for target in affected_targets:
		if is_instance_valid(target) and target is Node:
			affected_target_ids.append(target.get_instance_id())

	data["affected_target_ids"] = affected_target_ids

	return data

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> AuraEffect:
	var effect = AuraEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("duration", 0.0),
		data.get("aura_radius", 0.0),
		source,
		target,
		data.get("params", {})
	)

	effect.aura_effect_data = data.get("aura_effect_data", {})
	effect.update_interval = data.get("update_interval", 0.5)

	return effect
