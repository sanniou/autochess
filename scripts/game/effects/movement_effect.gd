extends GameEffect
class_name MovementEffect
## 移动效果
## 用于改变单位的位置

# 移动类型枚举
enum MovementType {
	PUSH,     # 推开
	PULL,     # 拉近
	TELEPORT, # 传送
	DASH,     # 冲刺
	JUMP,     # 跳跃
	KNOCKUP   # 击飞
}

# 移动类型
var movement_type: int = MovementType.PUSH

# 移动距离
var distance: float = 0.0

# 移动速度
var speed: float = 0.0

# 移动方向
var direction: Vector2 = Vector2.ZERO

# 目标位置
var target_position: Vector2 = Vector2.ZERO

# 是否正在移动
var is_moving: bool = false

# 已移动距离
var moved_distance: float = 0.0

# 初始位置
var initial_position: Vector2 = Vector2.ZERO

# 初始化
func _init(effect_id: String = "", effect_name: String = "", effect_description: String = "",
		effect_duration: float = 0.0, movement_type_param: int = MovementType.PUSH,
		distance_param: float = 0.0, effect_source = null, effect_target = null, effect_params: Dictionary = {}):
	super._init(effect_id, effect_name, effect_description, effect_duration,
			EffectType.MOVEMENT, effect_source, effect_target, effect_params)
	
	movement_type = movement_type_param
	distance = distance_param
	
	# 设置移动速度
	speed = effect_params.get("speed", 200.0)
	
	# 设置移动方向
	if effect_params.has("direction"):
		direction = effect_params.direction
	elif source and is_instance_valid(source) and source is Node2D and target and is_instance_valid(target) and target is Node2D:
		# 如果没有指定方向，根据源和目标计算方向
		match movement_type:
			MovementType.PUSH:
				# 推开：从源指向目标的方向
				direction = (target.global_position - source.global_position).normalized()
			MovementType.PULL:
				# 拉近：从目标指向源的方向
				direction = (source.global_position - target.global_position).normalized()
			_:
				# 其他类型：默认从源指向目标的方向
				direction = (target.global_position - source.global_position).normalized()
	
	# 设置目标位置
	if effect_params.has("target_position"):
		target_position = effect_params.target_position
	elif movement_type == MovementType.TELEPORT and effect_params.has("teleport_position"):
		target_position = effect_params.teleport_position
	
	# 设置标签
	if not tags.has("movement"):
		tags.append("movement")
	
	# 设置图标路径
	icon_path = _get_movement_icon_path(movement_type)
	
	# 设置名称和描述
	if name.is_empty():
		name = _get_movement_name(movement_type)
	
	if description.is_empty():
		description = _get_movement_description(movement_type, distance)

# 应用效果
func apply() -> bool:
	if not super.apply():
		return false
	
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return false
	
	# 检查目标是否是Node2D
	if not target is Node2D:
		return false
	
	# 保存初始位置
	initial_position = target.global_position
	
	# 根据移动类型执行不同的移动
	match movement_type:
		MovementType.PUSH, MovementType.PULL:
			# 推开或拉近：开始移动
			is_moving = true
		
		MovementType.TELEPORT:
			# 传送：立即移动到目标位置
			_teleport_to_target()
		
		MovementType.DASH:
			# 冲刺：开始移动
			is_moving = true
		
		MovementType.JUMP:
			# 跳跃：开始移动
			is_moving = true
		
		MovementType.KNOCKUP:
			# 击飞：开始移动
			is_moving = true
	
	# 发送移动开始事件
	if EventBus:
		EventBus.emit_signal("movement_started", {
			"source": source,
			"target": target,
			"movement_type": movement_type,
			"distance": distance,
			"direction": direction,
			"initial_position": initial_position
		})
	
	return true

# 更新效果
func update(delta: float) -> bool:
	if not super.update(delta):
		return false
	
	# 检查是否正在移动
	if not is_moving:
		return true
	
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		is_moving = false
		return false
	
	# 检查目标是否是Node2D
	if not target is Node2D:
		is_moving = false
		return false
	
	# 根据移动类型更新移动
	match movement_type:
		MovementType.PUSH, MovementType.PULL:
			_update_push_pull(delta)
		
		MovementType.DASH:
			_update_dash(delta)
		
		MovementType.JUMP:
			_update_jump(delta)
		
		MovementType.KNOCKUP:
			_update_knockup(delta)
	
	return true

# 移除效果
func remove() -> bool:
	if not super.remove():
		return false
	
	# 停止移动
	is_moving = false
	
	# 发送移动结束事件
	if EventBus and target and is_instance_valid(target):
		EventBus.emit_signal("movement_ended", {
			"source": source,
			"target": target,
			"movement_type": movement_type,
			"distance": moved_distance,
			"final_position": target.global_position
		})
	
	return true

# 更新推开或拉近
func _update_push_pull(delta: float) -> void:
	# 计算本帧移动距离
	var frame_distance = speed * delta
	
	# 更新已移动距离
	moved_distance += frame_distance
	
	# 检查是否达到总距离
	if moved_distance >= distance:
		# 移动到最终位置
		target.global_position = initial_position + direction * distance
		
		# 停止移动
		is_moving = false
		
		# 移除效果
		remove()
	else:
		# 移动目标
		target.global_position = initial_position + direction * moved_distance

# 更新冲刺
func _update_dash(delta: float) -> void:
	# 计算本帧移动距离
	var frame_distance = speed * delta
	
	# 更新已移动距离
	moved_distance += frame_distance
	
	# 检查是否达到总距离
	if moved_distance >= distance:
		# 移动到最终位置
		target.global_position = initial_position + direction * distance
		
		# 停止移动
		is_moving = false
		
		# 移除效果
		remove()
	else:
		# 移动目标
		target.global_position = initial_position + direction * moved_distance

# 更新跳跃
func _update_jump(delta: float) -> void:
	# 计算本帧移动距离
	var frame_distance = speed * delta
	
	# 更新已移动距离
	moved_distance += frame_distance
	
	# 计算跳跃进度
	var progress = moved_distance / distance
	
	# 检查是否完成跳跃
	if progress >= 1.0:
		# 移动到最终位置
		target.global_position = initial_position + direction * distance
		
		# 停止移动
		is_moving = false
		
		# 移除效果
		remove()
	else:
		# 计算水平位置
		var horizontal_position = initial_position + direction * moved_distance
		
		# 计算垂直位置（抛物线）
		var height = 50.0  # 跳跃高度
		var vertical_offset = height * sin(progress * PI)  # 使用正弦函数创建抛物线
		
		# 移动目标
		target.global_position = horizontal_position + Vector2(0, -vertical_offset)

# 更新击飞
func _update_knockup(delta: float) -> void:
	# 计算本帧移动距离
	var frame_distance = speed * delta
	
	# 更新已移动距离
	moved_distance += frame_distance
	
	# 计算击飞进度
	var progress = moved_distance / distance
	
	# 检查是否完成击飞
	if progress >= 1.0:
		# 移动到最终位置
		target.global_position = initial_position + direction * distance
		
		# 停止移动
		is_moving = false
		
		# 移除效果
		remove()
	else:
		# 计算水平位置
		var horizontal_position = initial_position + direction * moved_distance
		
		# 计算垂直位置（抛物线）
		var height = 100.0  # 击飞高度
		var vertical_offset = height * sin(progress * PI)  # 使用正弦函数创建抛物线
		
		# 移动目标
		target.global_position = horizontal_position + Vector2(0, -vertical_offset)

# 传送到目标位置
func _teleport_to_target() -> void:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return
	
	# 检查目标是否是Node2D
	if not target is Node2D:
		return
	
	# 如果有目标位置，直接传送
	if target_position != Vector2.ZERO:
		target.global_position = target_position
	else:
		# 否则，根据方向和距离计算目标位置
		target.global_position = initial_position + direction * distance
	
	# 更新已移动距离
	moved_distance = distance
	
	# 发送传送事件
	if EventBus:
		EventBus.emit_signal("teleport_completed", {
			"source": source,
			"target": target,
			"from": initial_position,
			"to": target.global_position
		})
	
	# 移除效果
	remove()

# 获取移动图标路径
func _get_movement_icon_path(movement_type: int) -> String:
	match movement_type:
		MovementType.PUSH:
			return "res://assets/icons/movement/push.png"
		MovementType.PULL:
			return "res://assets/icons/movement/pull.png"
		MovementType.TELEPORT:
			return "res://assets/icons/movement/teleport.png"
		MovementType.DASH:
			return "res://assets/icons/movement/dash.png"
		MovementType.JUMP:
			return "res://assets/icons/movement/jump.png"
		MovementType.KNOCKUP:
			return "res://assets/icons/movement/knockup.png"
	
	return ""

# 获取移动名称
func _get_movement_name(movement_type: int) -> String:
	match movement_type:
		MovementType.PUSH:
			return "推开"
		MovementType.PULL:
			return "拉近"
		MovementType.TELEPORT:
			return "传送"
		MovementType.DASH:
			return "冲刺"
		MovementType.JUMP:
			return "跳跃"
		MovementType.KNOCKUP:
			return "击飞"
	
	return "未知移动"

# 获取移动描述
func _get_movement_description(movement_type: int, distance: float) -> String:
	match movement_type:
		MovementType.PUSH:
			return "将目标推开 " + str(distance) + " 距离"
		MovementType.PULL:
			return "将目标拉近 " + str(distance) + " 距离"
		MovementType.TELEPORT:
			return "将目标传送 " + str(distance) + " 距离"
		MovementType.DASH:
			return "使目标冲刺 " + str(distance) + " 距离"
		MovementType.JUMP:
			return "使目标跳跃 " + str(distance) + " 距离"
		MovementType.KNOCKUP:
			return "将目标击飞 " + str(distance) + " 距离"
	
	return "移动目标 " + str(distance) + " 距离"

# 获取效果数据
func get_data() -> Dictionary:
	var data = super.get_data()
	data["movement_type"] = movement_type
	data["distance"] = distance
	data["speed"] = speed
	data["direction"] = {"x": direction.x, "y": direction.y}
	data["target_position"] = {"x": target_position.x, "y": target_position.y}
	data["is_moving"] = is_moving
	data["moved_distance"] = moved_distance
	data["initial_position"] = {"x": initial_position.x, "y": initial_position.y}
	return data

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> MovementEffect:
	var effect = MovementEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("duration", 0.0),
		data.get("movement_type", MovementType.PUSH),
		data.get("distance", 0.0),
		source,
		target,
		data.get("params", {})
	)
	
	effect.speed = data.get("speed", 200.0)
	
	var dir_data = data.get("direction", {})
	if dir_data.has("x") and dir_data.has("y"):
		effect.direction = Vector2(dir_data.x, dir_data.y)
	
	var pos_data = data.get("target_position", {})
	if pos_data.has("x") and pos_data.has("y"):
		effect.target_position = Vector2(pos_data.x, pos_data.y)
	
	effect.is_moving = data.get("is_moving", false)
	effect.moved_distance = data.get("moved_distance", 0.0)
	
	var init_pos_data = data.get("initial_position", {})
	if init_pos_data.has("x") and init_pos_data.has("y"):
		effect.initial_position = Vector2(init_pos_data.x, init_pos_data.y)
	
	return effect
