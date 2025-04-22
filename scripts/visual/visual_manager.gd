extends Node
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

# 初始化
func _init() -> void:
	# 创建视觉渲染器
	visual_renderer = VisualRenderer.new()
	add_child(visual_renderer)
	
	# 创建视觉注册表
	visual_registry = VisualRegistry.new()
	add_child(visual_registry)

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

# 处理效果完成
func _on_effect_completed(effect_id: String) -> void:
	complete_effect(effect_id)
