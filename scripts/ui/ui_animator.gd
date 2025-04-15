extends Node
class_name UIAnimator
## UI动画管理器
## 负责管理UI元素的动画效果

# 信号
signal animation_started(animation_name: String, target: Control)
signal animation_finished(animation_name: String, target: Control)

# 常量
const ANIMATION_DURATION = 0.3  # 默认动画时间

# 活动动画
var active_animations: Dictionary = {}

# 初始化
func _ready() -> void:
	pass

# 淡入动画
func fade_in(target: Control, duration: float = ANIMATION_DURATION) -> void:
	if not is_instance_valid(target):
		return
	
	# 设置初始状态
	target.modulate.a = 0.0
	target.visible = true
	
	# 创建动画
	var tween = create_tween()
	tween.tween_property(target, "modulate:a", 1.0, duration)
	
	# 记录动画
	var animation_name = "fade_in"
	active_animations[target] = {
		"name": animation_name,
		"tween": tween
	}
	
	# 发送信号
	animation_started.emit(animation_name, target)
	
	# 连接完成信号
	tween.finished.connect(func(): _on_animation_finished(animation_name, target))

# 淡出动画
func fade_out(target: Control, duration: float = ANIMATION_DURATION) -> void:
	if not is_instance_valid(target):
		return
	
	# 创建动画
	var tween = create_tween()
	tween.tween_property(target, "modulate:a", 0.0, duration)
	
	# 记录动画
	var animation_name = "fade_out"
	active_animations[target] = {
		"name": animation_name,
		"tween": tween
	}
	
	# 发送信号
	animation_started.emit(animation_name, target)
	
	# 连接完成信号
	tween.finished.connect(func(): 
		_on_animation_finished(animation_name, target)
		target.visible = false
	)

# 滑入动画
func slide_in(target: Control, from_direction: String = "right", duration: float = ANIMATION_DURATION) -> void:
	if not is_instance_valid(target):
		return
	
	# 获取目标位置
	var final_position = target.position
	var start_position = final_position
	
	# 根据方向设置起始位置
	match from_direction:
		"left":
			start_position.x = -target.size.x
		"right":
			start_position.x = get_viewport().size.x
		"top":
			start_position.y = -target.size.y
		"bottom":
			start_position.y = get_viewport().size.y
	
	# 设置初始状态
	target.position = start_position
	target.visible = true
	
	# 创建动画
	var tween = create_tween()
	tween.tween_property(target, "position", final_position, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# 记录动画
	var animation_name = "slide_in_" + from_direction
	active_animations[target] = {
		"name": animation_name,
		"tween": tween
	}
	
	# 发送信号
	animation_started.emit(animation_name, target)
	
	# 连接完成信号
	tween.finished.connect(func(): _on_animation_finished(animation_name, target))

# 滑出动画
func slide_out(target: Control, to_direction: String = "right", duration: float = ANIMATION_DURATION) -> void:
	if not is_instance_valid(target):
		return
	
	# 获取起始位置
	var start_position = target.position
	var final_position = start_position
	
	# 根据方向设置目标位置
	match to_direction:
		"left":
			final_position.x = -target.size.x
		"right":
			final_position.x = get_viewport().size.x
		"top":
			final_position.y = -target.size.y
		"bottom":
			final_position.y = get_viewport().size.y
	
	# 创建动画
	var tween = create_tween()
	tween.tween_property(target, "position", final_position, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	
	# 记录动画
	var animation_name = "slide_out_" + to_direction
	active_animations[target] = {
		"name": animation_name,
		"tween": tween
	}
	
	# 发送信号
	animation_started.emit(animation_name, target)
	
	# 连接完成信号
	tween.finished.connect(func(): 
		_on_animation_finished(animation_name, target)
		target.visible = false
	)

# 缩放动画
func scale_animation(target: Control, start_scale: Vector2, end_scale: Vector2, duration: float = ANIMATION_DURATION) -> void:
	if not is_instance_valid(target):
		return
	
	# 设置初始状态
	target.scale = start_scale
	target.visible = true
	
	# 创建动画
	var tween = create_tween()
	tween.tween_property(target, "scale", end_scale, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	
	# 记录动画
	var animation_name = "scale"
	active_animations[target] = {
		"name": animation_name,
		"tween": tween
	}
	
	# 发送信号
	animation_started.emit(animation_name, target)
	
	# 连接完成信号
	tween.finished.connect(func(): _on_animation_finished(animation_name, target))

# 弹出动画
func pop_in(target: Control, duration: float = ANIMATION_DURATION) -> void:
	scale_animation(target, Vector2(0.5, 0.5), Vector2(1.0, 1.0), duration)

# 弹出消失动画
func pop_out(target: Control, duration: float = ANIMATION_DURATION) -> void:
	if not is_instance_valid(target):
		return
	
	# 创建动画
	var tween = create_tween()
	tween.tween_property(target, "scale", Vector2(0.5, 0.5), duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	
	# 记录动画
	var animation_name = "pop_out"
	active_animations[target] = {
		"name": animation_name,
		"tween": tween
	}
	
	# 发送信号
	animation_started.emit(animation_name, target)
	
	# 连接完成信号
	tween.finished.connect(func(): 
		_on_animation_finished(animation_name, target)
		target.visible = false
	)

# 闪烁动画
func blink(target: Control, times: int = 3, duration: float = ANIMATION_DURATION) -> void:
	if not is_instance_valid(target):
		return
	
	# 创建动画
	var tween = create_tween()
	for i in range(times):
		tween.tween_property(target, "modulate:a", 0.0, duration / (times * 2))
		tween.tween_property(target, "modulate:a", 1.0, duration / (times * 2))
	
	# 记录动画
	var animation_name = "blink"
	active_animations[target] = {
		"name": animation_name,
		"tween": tween
	}
	
	# 发送信号
	animation_started.emit(animation_name, target)
	
	# 连接完成信号
	tween.finished.connect(func(): _on_animation_finished(animation_name, target))

# 抖动动画
func shake(target: Control, intensity: float = 10.0, times: int = 5, duration: float = ANIMATION_DURATION) -> void:
	if not is_instance_valid(target):
		return
	
	# 获取原始位置
	var original_position = target.position
	
	# 创建动画
	var tween = create_tween()
	for i in range(times):
		var offset_x = randf_range(-intensity, intensity)
		var offset_y = randf_range(-intensity, intensity)
		tween.tween_property(target, "position", original_position + Vector2(offset_x, offset_y), duration / (times * 2))
		tween.tween_property(target, "position", original_position, duration / (times * 2))
	
	# 记录动画
	var animation_name = "shake"
	active_animations[target] = {
		"name": animation_name,
		"tween": tween,
		"original_position": original_position
	}
	
	# 发送信号
	animation_started.emit(animation_name, target)
	
	# 连接完成信号
	tween.finished.connect(func(): 
		_on_animation_finished(animation_name, target)
		target.position = original_position
	)

# 动画完成处理
func _on_animation_finished(animation_name: String, target: Control) -> void:
	# 移除动画记录
	if active_animations.has(target):
		active_animations.erase(target)
	
	# 发送信号
	animation_finished.emit(animation_name, target)

# 停止动画
func stop_animation(target: Control) -> void:
	if not active_animations.has(target):
		return
	
	var animation = active_animations[target]
	if animation.has("tween") and animation.tween is Tween:
		animation.tween.kill()
	
	# 恢复原始状态
	if animation.has("original_position"):
		target.position = animation.original_position
	
	# 移除动画记录
	active_animations.erase(target)

# 是否有活动动画
func has_active_animation(target: Control) -> bool:
	return active_animations.has(target)

# 获取活动动画名称
func get_active_animation_name(target: Control) -> String:
	if not active_animations.has(target):
		return ""
	
	return active_animations[target].name
