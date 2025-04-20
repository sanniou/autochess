extends BattleEffect
class_name MovementEffect
## 移动效果
## 用于控制单位移动

# 移动类型枚举
enum MovementType {
	KNOCKBACK,   # 击退
	PULL,        # 拉近
	TELEPORT,    # 传送
	DASH,        # 冲刺
	JUMP,        # 跳跃
	SWAP         # 交换位置
}

# 移动效果属性
var movement_type: int = MovementType.KNOCKBACK
var distance: float = 1.0  # 移动距离
var direction: Vector2 = Vector2.ZERO  # 移动方向
var target_position: Vector2 = Vector2.ZERO  # 目标位置
var speed: float = 300.0  # 移动速度
var is_moving: bool = false  # 是否正在移动

# 初始化
func _init(effect_id: String = "", effect_name: String = "", effect_description: String = "", 
		movement_type_value: int = MovementType.KNOCKBACK, distance_value: float = 1.0,
		effect_source = null, effect_target = null, effect_params: Dictionary = {}):
	super._init(effect_id, effect_name, effect_description, 0.0, 
			EffectType.MOVEMENT, effect_source, effect_target, effect_params)
	
	movement_type = movement_type_value
	distance = distance_value
	
	# 设置方向
	if effect_params.has("direction"):
		direction = effect_params.direction
	elif effect_source and effect_target and is_instance_valid(effect_source) and is_instance_valid(effect_target):
		# 计算从源到目标的方向
		var source_pos = effect_source.global_position
		var target_pos = effect_target.global_position
		direction = (target_pos - source_pos).normalized()
	
	# 设置目标位置
	if effect_params.has("target_position"):
		target_position = effect_params.target_position
	
	# 设置速度
	if effect_params.has("speed"):
		speed = effect_params.speed
	
	# 设置图标路径
	icon_path = _get_movement_icon_path(movement_type)
	
	# 设置名称和描述
	if name.is_empty():
		name = _get_movement_name(movement_type)
	
	if description.is_empty():
		description = _get_movement_description(movement_type)

# 应用效果
func apply() -> bool:
	if not super.apply():
		return false
	
	if not target or not is_instance_valid(target):
		return false
	
	# 根据移动类型应用效果
	match movement_type:
		MovementType.KNOCKBACK:
			return _apply_knockback()
		
		MovementType.PULL:
			return _apply_pull()
		
		MovementType.TELEPORT:
			return _apply_teleport()
		
		MovementType.DASH:
			return _apply_dash()
		
		MovementType.JUMP:
			return _apply_jump()
		
		MovementType.SWAP:
			return _apply_swap()
	
	return false

# 更新效果
func update(delta: float) -> bool:
	if not super.update(delta):
		return false
	
	# 如果正在移动，更新移动
	if is_moving:
		return _update_movement(delta)
	
	return true

# 应用击退效果
func _apply_knockback() -> bool:
	if not target or not is_instance_valid(target):
		return false
	
	# 计算目标位置
	var current_pos = target.global_position
	var knockback_dir = direction
	
	# 如果没有指定方向，使用从源到目标的方向
	if knockback_dir == Vector2.ZERO and source and is_instance_valid(source):
		knockback_dir = (target.global_position - source.global_position).normalized()
	
	# 如果仍然没有方向，使用随机方向
	if knockback_dir == Vector2.ZERO:
		knockback_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	# 计算目标位置
	target_position = current_pos + knockback_dir * distance * 100.0  # 转换为像素
	
	# 开始移动
	is_moving = true
	
	# 创建视觉效果
	_create_visual_effect()
	
	return true

# 应用拉近效果
func _apply_pull() -> bool:
	if not target or not is_instance_valid(target) or not source or not is_instance_valid(source):
		return false
	
	# 计算目标位置
	var current_pos = target.global_position
	var pull_dir = (source.global_position - current_pos).normalized()
	
	# 计算目标位置
	target_position = current_pos + pull_dir * distance * 100.0  # 转换为像素
	
	# 开始移动
	is_moving = true
	
	# 创建视觉效果
	_create_visual_effect()
	
	return true

# 应用传送效果
func _apply_teleport() -> bool:
	if not target or not is_instance_valid(target):
		return false
	
	# 如果指定了目标位置，直接传送
	if target_position != Vector2.ZERO:
		# 创建消失特效
		_create_disappear_effect()
		
		# 传送到目标位置
		target.global_position = target_position
		
		# 创建出现特效
		_create_appear_effect()
		
		return true
	
	# 如果没有指定目标位置，但指定了方向和距离
	if direction != Vector2.ZERO:
		var current_pos = target.global_position
		target_position = current_pos + direction * distance * 100.0  # 转换为像素
		
		# 创建消失特效
		_create_disappear_effect()
		
		# 传送到目标位置
		target.global_position = target_position
		
		# 创建出现特效
		_create_appear_effect()
		
		return true
	
	return false

# 应用冲刺效果
func _apply_dash() -> bool:
	if not target or not is_instance_valid(target):
		return false
	
	# 计算目标位置
	var current_pos = target.global_position
	var dash_dir = direction
	
	# 如果没有指定方向，使用目标的朝向
	if dash_dir == Vector2.ZERO and target.has_method("get_facing_direction"):
		dash_dir = target.get_facing_direction()
	
	# 如果仍然没有方向，使用随机方向
	if dash_dir == Vector2.ZERO:
		dash_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	# 计算目标位置
	target_position = current_pos + dash_dir * distance * 100.0  # 转换为像素
	
	# 开始移动
	is_moving = true
	speed = 600.0  # 冲刺速度更快
	
	# 创建视觉效果
	_create_visual_effect()
	
	return true

# 应用跳跃效果
func _apply_jump() -> bool:
	if not target or not is_instance_valid(target):
		return false
	
	# 计算目标位置
	var current_pos = target.global_position
	var jump_dir = direction
	
	# 如果没有指定方向，使用随机方向
	if jump_dir == Vector2.ZERO:
		jump_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	# 计算目标位置
	target_position = current_pos + jump_dir * distance * 100.0  # 转换为像素
	
	# 开始移动
	is_moving = true
	
	# 创建视觉效果
	_create_jump_effect()
	
	return true

# 应用交换位置效果
func _apply_swap() -> bool:
	if not target or not is_instance_valid(target) or not source or not is_instance_valid(source):
		return false
	
	# 保存当前位置
	var target_pos = target.global_position
	var source_pos = source.global_position
	
	# 创建消失特效
	_create_disappear_effect()
	
	# 交换位置
	target.global_position = source_pos
	source.global_position = target_pos
	
	# 创建出现特效
	_create_appear_effect()
	
	return true

# 更新移动
func _update_movement(delta: float) -> bool:
	if not target or not is_instance_valid(target):
		return false
	
	# 计算当前位置到目标位置的向量
	var current_pos = target.global_position
	var move_vec = target_position - current_pos
	
	# 如果已经接近目标位置，完成移动
	if move_vec.length() < 5.0:
		target.global_position = target_position
		is_moving = false
		return true
	
	# 计算移动方向和距离
	var move_dir = move_vec.normalized()
	var move_dist = min(move_vec.length(), speed * delta)
	
	# 移动目标
	target.global_position += move_dir * move_dist
	
	return true

# 创建视觉效果
func _create_visual_effect() -> void:
	if not target or not is_instance_valid(target):
		return
	
	# 创建移动效果视觉表现
	var effect_scene = load("res://scenes/effects/movement_effect_visual.tscn")
	if effect_scene:
		visual_effect = effect_scene.instantiate()
		target.add_child(visual_effect)
		
		# 设置视觉效果参数
		if visual_effect.has_method("initialize"):
			visual_effect.initialize(self)

# 创建消失特效
func _create_disappear_effect() -> void:
	if not target or not is_instance_valid(target):
		return
	
	# 创建消失特效
	var effect_manager = GameManager.effect_manager
	if effect_manager:
		effect_manager.create_visual_effect(
			effect_manager.VisualEffectType.TELEPORT_DISAPPEAR,
			target,
			{}
		)

# 创建出现特效
func _create_appear_effect() -> void:
	if not target or not is_instance_valid(target):
		return
	
	# 创建出现特效
	var effect_manager = GameManager.effect_manager
	if effect_manager:
		effect_manager.create_visual_effect(
			effect_manager.VisualEffectType.TELEPORT_APPEAR,
			target,
			{}
		)

# 创建跳跃特效
func _create_jump_effect() -> void:
	if not target or not is_instance_valid(target):
		return
	
	# 创建跳跃特效
	var effect_manager = GameManager.effect_manager
	if effect_manager:
		effect_manager.create_visual_effect(
			effect_manager.VisualEffectType.JUMP,
			target,
			{}
		)

# 获取移动类型图标路径
func _get_movement_icon_path(movement_type: int) -> String:
	match movement_type:
		MovementType.KNOCKBACK:
			return "res://assets/icons/effects/knockback.png"
		MovementType.PULL:
			return "res://assets/icons/effects/pull.png"
		MovementType.TELEPORT:
			return "res://assets/icons/effects/teleport.png"
		MovementType.DASH:
			return "res://assets/icons/effects/dash.png"
		MovementType.JUMP:
			return "res://assets/icons/effects/jump.png"
		MovementType.SWAP:
			return "res://assets/icons/effects/swap.png"
	
	return ""

# 获取移动类型名称
func _get_movement_name(movement_type: int) -> String:
	match movement_type:
		MovementType.KNOCKBACK:
			return "击退"
		MovementType.PULL:
			return "拉近"
		MovementType.TELEPORT:
			return "传送"
		MovementType.DASH:
			return "冲刺"
		MovementType.JUMP:
			return "跳跃"
		MovementType.SWAP:
			return "交换位置"
	
	return "未知移动效果"

# 获取移动类型描述
func _get_movement_description(movement_type: int) -> String:
	match movement_type:
		MovementType.KNOCKBACK:
			return "将目标击退一段距离"
		MovementType.PULL:
			return "将目标拉向施法者"
		MovementType.TELEPORT:
			return "将目标传送到指定位置"
		MovementType.DASH:
			return "使目标快速冲向指定方向"
		MovementType.JUMP:
			return "使目标跳跃到指定位置"
		MovementType.SWAP:
			return "交换施法者和目标的位置"
	
	return "未知移动效果"

# 获取效果数据
func get_data() -> Dictionary:
	var data = super.get_data()
	data["movement_type"] = movement_type
	data["distance"] = distance
	data["direction"] = {"x": direction.x, "y": direction.y}
	data["target_position"] = {"x": target_position.x, "y": target_position.y}
	data["speed"] = speed
	return data

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> MovementEffect:
	var effect = MovementEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("movement_type", MovementType.KNOCKBACK),
		data.get("distance", 1.0),
		source,
		target,
		{}
	)
	
	# 设置方向
	var dir_data = data.get("direction", {})
	if dir_data.has("x") and dir_data.has("y"):
		effect.direction = Vector2(dir_data.x, dir_data.y)
	
	# 设置目标位置
	var pos_data = data.get("target_position", {})
	if pos_data.has("x") and pos_data.has("y"):
		effect.target_position = Vector2(pos_data.x, pos_data.y)
	
	# 设置速度
	effect.speed = data.get("speed", 300.0)
	
	return effect
