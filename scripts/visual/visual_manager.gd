extends "res://scripts/managers/core/base_manager.gd"
class_name VisualManager
## 视觉效果管理器
## 负责管理所有视觉效果

# 信号
signal effect_created(effect_id, effect_type, position)
signal effect_completed(effect_id)
signal effect_cancelled(effect_id)

# 效果ID计数器
var _effect_id_counter: int = 0

# 活动效果字典 {效果ID: 效果数据}
var _active_effects: Dictionary = {}

# 视觉渲染器
var visual_renderer = null

# 视觉注册表
var visual_registry = null

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "VisualManager"

	# 创建视觉渲染器
	visual_renderer = VisualRenderer.new()
	add_child(visual_renderer)

	# 创建视觉注册表
	visual_registry = VisualRegistry.new()
	add_child(visual_registry)

	# 连接战斗事件
	if EventBus:
		GlobalEventBus.battle.add_listener("battle_ended", on_battle_ended)

	_log_info("VisualManager 初始化完成")

# 创建效果
func create_effect(effect_type: String, position: Vector2, params: Dictionary = {}) -> String:
	# 生成效果ID
	var effect_id = _generate_effect_id()

	# 创建效果数据
	var effect_data = {
		"id": effect_id,
		"type": effect_type,
		"position": position,
		"params": params,
		"created_at": Time.get_ticks_msec(),
		"completed": false,
		"cancelled": false
	}

	# 添加到活动效果
	_active_effects[effect_id] = effect_data

	# 创建视觉效果
	visual_renderer.create_effect(effect_id, effect_type, position, params)

	# 发送效果创建信号
	effect_created.emit(effect_id, effect_type, position)

	return effect_id

# 取消效果
func cancel_effect(effect_id: String) -> bool:
	# 检查效果是否存在
	if not _active_effects.has(effect_id):
		return false

	# 获取效果数据
	var effect_data = _active_effects[effect_id]

	# 检查效果是否已完成或已取消
	if effect_data.completed or effect_data.cancelled:
		return false

	# 标记为已取消
	effect_data.cancelled = true

	# 取消视觉效果
	visual_renderer.cancel_effect(effect_id)

	# 发送效果取消信号
	effect_cancelled.emit(effect_id)

	# 移除效果数据
	_active_effects.erase(effect_id)

	return true

# 完成效果
func complete_effect(effect_id: String) -> bool:
	# 检查效果是否存在
	if not _active_effects.has(effect_id):
		return false

	# 获取效果数据
	var effect_data = _active_effects[effect_id]

	# 检查效果是否已完成或已取消
	if effect_data.completed or effect_data.cancelled:
		return false

	# 标记为已完成
	effect_data.completed = true

	# 发送效果完成信号
	effect_completed.emit(effect_id)

	# 移除效果数据
	_active_effects.erase(effect_id)

	return true

# 获取效果数据
func get_effect_data(effect_id: String) -> Dictionary:
	# 检查效果是否存在
	if not _active_effects.has(effect_id):
		return {}

	# 返回效果数据的副本
	return _active_effects[effect_id].duplicate()

# 获取所有活动效果
func get_active_effects() -> Array:
	return _active_effects.keys()

# 清理所有效果
func clear_all_effects() -> void:
	# 取消所有活动效果
	for effect_id in _active_effects.keys():
		cancel_effect(effect_id)

	# 清空活动效果字典
	_active_effects.clear()

# 创建粒子效果
func create_particle_effect(position: Vector2, particle_type: String, params: Dictionary = {}) -> String:
	# 设置效果类型
	var effect_type = "particle"

	# 设置粒子类型
	params["particle_type"] = particle_type

	# 创建效果
	return create_effect(effect_type, position, params)

# 创建精灵效果
func create_sprite_effect(position: Vector2, texture_path: String, params: Dictionary = {}) -> String:
	# 设置效果类型
	var effect_type = "sprite"

	# 设置纹理路径
	params["texture_path"] = texture_path

	# 创建效果
	return create_effect(effect_type, position, params)

# 创建动画效果
func create_animation_effect(position: Vector2, animation_name: String, params: Dictionary = {}) -> String:
	# 设置效果类型
	var effect_type = "animation"

	# 设置动画名称
	params["animation_name"] = animation_name

	# 创建效果
	return create_effect(effect_type, position, params)

# 创建着色器效果
func create_shader_effect(position: Vector2, shader_path: String, params: Dictionary = {}) -> String:
	# 设置效果类型
	var effect_type = "shader"

	# 设置着色器路径
	params["shader_path"] = shader_path

	# 创建效果
	return create_effect(effect_type, position, params)

# 创建组合效果
func create_combined_effect(position: Vector2, effect_name: String, params: Dictionary = {}) -> String:
	# 获取组合效果定义
	var effect_def = visual_registry.get_effect_definition(effect_name)
	if not effect_def:
		print("VisualManager: 未找到组合效果定义: " + effect_name)
		return ""

	# 设置效果类型
	var effect_type = "combined"

	# 设置组合效果名称
	params["effect_name"] = effect_name

	# 创建效果
	return create_effect(effect_type, position, params)

# 创建伤害数字效果
func create_damage_number(position: Vector2, value: float, is_critical: bool = false, params: Dictionary = {}) -> String:
	# 设置效果类型
	var effect_type = "damage_number"

	# 设置伤害值和是否暴击
	params["value"] = value
	params["is_critical"] = is_critical

	# 创建效果
	return create_effect(effect_type, position, params)

# 创建治疗数字效果
func create_heal_number(position: Vector2, value: float, is_critical: bool = false, params: Dictionary = {}) -> String:
	# 设置效果类型
	var effect_type = "heal_number"

	# 设置治疗值和是否暴击
	params["value"] = value
	params["is_critical"] = is_critical

	# 创建效果
	return create_effect(effect_type, position, params)

# 创建状态图标效果
func create_status_icon(position: Vector2, status_type: String, duration: float, params: Dictionary = {}) -> String:
	# 设置效果类型
	var effect_type = "status_icon"

	# 设置状态类型和持续时间
	params["status_type"] = status_type
	params["duration"] = duration

	# 创建效果
	return create_effect(effect_type, position, params)

# 生成效果ID
func _generate_effect_id() -> String:
	_effect_id_counter += 1
	return "effect_" + str(_effect_id_counter) + "_" + str(Time.get_ticks_msec())

# 为游戏效果创建视觉效果
func create_effect_for_game_effect(effect_type: int, target, params: Dictionary = {}) -> void:
	# 检查目标是否有效
	if not is_instance_valid(target):
		GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("VisualManager: 无法创建效果，目标无效", 1))
		return

	# 获取目标位置
	var position = Vector2.ZERO
	if target is Node2D:
		position = target.global_position
	elif target is Vector2:
		position = target

	# 根据效果类型创建不同的视觉效果
	match effect_type:
		0: # DAMAGE
			# 创建伤害效果
			if params.has("damage_amount"):
				create_damage_number(
					position,
					params.get("damage_amount", 0.0),
					params.get("is_critical", false),
					params
				)

			# 创建伤害视觉效果
			create_combined_effect(
				position,
				"damage_" + params.get("damage_type", "physical"),
				params
			)

		1: # HEAL
			# 创建治疗效果
			if params.has("heal_amount"):
				create_heal_number(
					position,
					params.get("heal_amount", 0.0),
					false,
					params
				)

			# 创建治疗视觉效果
			create_combined_effect(
				position,
				"heal",
				params
			)

		2: # BUFF
			# 创建增益效果
			create_combined_effect(
				position,
				"buff_" + params.get("buff_type", "generic"),
				params
			)

		3: # DEBUFF
			# 创建减益效果
			create_combined_effect(
				position,
				"debuff_" + params.get("debuff_type", "generic"),
				params
			)

		4: # CHAIN
			# 创建连锁效果
			if params.has("target_position"):
				create_effect(
					"chain",
					position,
					{
						"target_position": params.get("target_position"),
						"color": params.get("color", Color(0.8, 0.8, 0.0, 0.8)),
						"duration": params.get("duration", 0.5)
					}
				)

		5: # TELEPORT_APPEAR
			# 创建传送出现效果
			create_combined_effect(
				position,
				"teleport_appear",
				params
			)

		6: # TELEPORT_DISAPPEAR
			# 创建传送消失效果
			create_combined_effect(
				position,
				"teleport_disappear",
				params
			)

		7: # AREA_DAMAGE
			# 创建区域伤害效果
			create_combined_effect(
				position,
				"area_damage_" + params.get("damage_type", "generic"),
				params
			)

		8: # JUMP
			# 创建跳跃效果
			if params.has("target_position"):
				create_effect(
					"jump",
					position,
					{
						"target_position": params.get("target_position"),
						"height": params.get("height", 50.0),
						"duration": params.get("duration", 0.5)
					}
				)

# 清理所有效果（战斗生命周期方法）
func on_battle_ended() -> void:
	# 清理所有效果
	clear_all_effects()

	# 记录日志
	GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("VisualManager: 战斗结束，清理所有视觉效果", 0))

# 处理效果完成
func _on_effect_completed(effect_id: String) -> void:
	complete_effect(effect_id)

# 重写重置方法
func _do_reset() -> void:
	# 清理所有效果
	clear_all_effects()

	_log_info("VisualManager 已重置")

# 根据ID移除效果
func remove_effect_by_id(effect_id: String) -> bool:
	# 检查效果ID是否有效
	if effect_id.is_empty():
		return false

	# 如果效果ID在活动效果列表中，直接取消
	if _active_effects.has(effect_id):
		return cancel_effect(effect_id)

	# 如果不在活动效果列表中，尝试从渲染器中移除
	if visual_renderer:
		return visual_renderer.remove_effect_by_id(effect_id)

	return false

# 根据ID恢复效果
func resume_effect_by_id(effect_id: String) -> bool:
	# 检查效果ID是否有效
	if effect_id.is_empty():
		return false

	# 如果效果ID在活动效果列表中，尝试恢复
	if _active_effects.has(effect_id):
		# 获取效果数据
		var effect_data = _active_effects[effect_id]

		# 如果效果已经完成或取消，无法恢复
		if effect_data.completed or effect_data.cancelled:
			return false

		# 尝试从渲染器中恢复
		if visual_renderer:
			return visual_renderer.resume_effect(effect_id)

	return false

# 移除效果节点
func remove_effect(effect_node: Node) -> bool:
	# 检查节点是否有效
	if not effect_node or not is_instance_valid(effect_node):
		return false

	# 尝试从渲染器中移除
	if visual_renderer:
		return visual_renderer.remove_effect_node(effect_node)

	return false

# 重写清理方法
func _do_cleanup() -> void:
	# 清理所有效果
	clear_all_effects()

	# 断开所有信号连接
	if EventBus:
		GlobalEventBus.battle.remove_listener("battle_ended", on_battle_ended)

	# 清理渲染器和注册表
	if visual_renderer:
		visual_renderer.queue_free()
		visual_renderer = null

	if visual_registry:
		visual_registry.queue_free()
		visual_registry = null

	_log_info("VisualManager 已清理")
