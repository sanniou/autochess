extends Node
class_name VisualEffectAnimator
## 视觉特效动画控制器
## 专注于创建和管理视觉特效，如粒子、精灵、着色器等特效，不处理游戏逻辑
## 提供统一的特效创建和管理接口，使用对象池优化性能

# 信号
signal animation_started(animation_name: String)
signal animation_completed(animation_name: String)
signal animation_cancelled(animation_name: String)

# 特效类型
enum EffectType {
	PARTICLE,  # 粒子特效
	SPRITE,    # 精灵特效
	SHADER,    # 着色器特效
	COMBINED   # 组合特效
}

# 动画状态
enum AnimationState {
	IDLE,     # 空闲状态
	PLAYING,  # 播放中
	PAUSED,   # 暂停
	COMPLETED # 已完成
}

# 特效容器
var effect_container = null

# 特效注册表
var effect_registry = null

# 当前活动的特效
var active_effects = {}

# 特效队列
var effect_queue = []

# 是否正在播放
var is_playing = false

# 对象池名称
const PARTICLE_POOL_NAME = "effect_particles"
const SPRITE_POOL_NAME = "effect_sprites"
const CONTAINER_POOL_NAME = "effect_containers"

# 最大特效数量
const MAX_PARTICLE_EFFECTS = 100
const MAX_SPRITE_EFFECTS = 100
const MAX_CONTAINER_EFFECTS = 50

# 初始化
func _init(container = null) -> void:
	# 如果没有提供容器，使用场景根节点
	if container == null:
		container = get_tree().get_root() if is_inside_tree() else null

	effect_container = container

	# 创建特效注册表
	effect_registry = EffectRegistry.new()

	# 获取LOD系统
	_get_lod_system()

# LOD系统引用
var lod_system = null

# 准备完成
func _ready() -> void:
	# 初始化对象池
	_initialize_ObjectPools()

	# 获取LOD系统
	_get_lod_system()

## 获取LOD系统
func _get_lod_system() -> void:
	# 尝试从动画管理器获取LOD系统
	var animation_manager = get_node_or_null("/root/AnimationManager")
	if animation_manager and animation_manager.has_node("AnimationLODSystem"):
		lod_system = animation_manager.get_node("AnimationLODSystem")
		return

	# 如果没有找到，在下一帧再次尝试
	call_deferred("_get_lod_system")

# 初始化对象池
func _initialize_ObjectPools() -> void:

	# 创建粒子特效池
	var particle_scene = load("res://scenes/effects/particle_effect.tscn")
	if particle_scene:
		ObjectPool.create_pool(PARTICLE_POOL_NAME, particle_scene, 20, 10, MAX_PARTICLE_EFFECTS)

	# 创建精灵特效池
	var sprite_scene = load("res://scenes/effects/sprite_effect.tscn")
	if sprite_scene:
		ObjectPool.create_pool(SPRITE_POOL_NAME, sprite_scene, 20, 10, MAX_SPRITE_EFFECTS)

	# 创建容器特效池
	var container_scene = load("res://scenes/effects/effect_container.tscn")
	if container_scene:
		ObjectPool.create_pool(CONTAINER_POOL_NAME, container_scene, 10, 5, MAX_CONTAINER_EFFECTS)

# 播放粒子特效
func play_particle_effect(position: Vector2, effect_name: String, duration: float, params: Dictionary = {}) -> String:
	# 创建特效ID
	var effect_id = _create_effect_id(EffectType.PARTICLE, effect_name)

	# 检查是否已经有相同的特效在播放
	if active_effects.has(effect_id):
		return effect_id

	# 合并默认参数
	var default_params = {
		"amount": 20,
		"lifetime": 1.0,
		"speed": 50.0,
		"color": Color(1, 1, 1, 1),
		"scale": Vector2(1, 1),
		"texture": null,
		"emission_shape": CPUParticles2D.EMISSION_SHAPE_POINT,
		"emission_radius": 10.0,
		"direction": Vector2(0, -1),
		"spread": 45.0,
		"gravity": Vector2(0, 98),
		"auto_remove": true
	}

	for key in default_params:
		if not params.has(key):
			params[key] = default_params[key]

	# 从对象池获取粒子特效
	var particles = null
	particles = ObjectPool.get_object(PARTICLE_POOL_NAME)

	# 如果对象池无法提供实例，则创建新实例
	if not particles:
		particles = CPUParticles2D.new()

	# 设置粒子属性
	particles.name = "Particles_" + effect_id
	particles.position = position
	particles.amount = params.amount
	particles.lifetime = params.lifetime
	particles.speed_scale = params.speed / 50.0
	particles.modulate = params.color
	particles.scale = params.scale
	particles.emission_shape = params.emission_shape
	particles.emission_sphere_radius = params.emission_radius
	particles.direction = params.direction
	particles.spread = params.spread
	particles.gravity = params.gravity
	particles.one_shot = true

	# 设置纹理
	if params.texture:
		if typeof(params.texture) == TYPE_STRING:
			# 使用资源管理器加载纹理，避免重复加载
			var texture = ResourceManager.get_texture(params.texture)
			if texture:
				particles.texture = texture
		else:
			particles.texture = params.texture

	# 添加到容器
	effect_container.add_child(particles)

	# 保存原始粒子数量（用于LOD系统）
	particles.set_meta("original_amount", params.amount)

	# 创建特效数据
	var effect_data = {
		"id": effect_id,
		"type": EffectType.PARTICLE,
		"node": particles,
		"duration": duration,
		"start_time": Time.get_ticks_msec(),
		"state": AnimationState.PLAYING,
		"auto_remove": params.auto_remove,
		"from_pool": particles != null and ObjectPool != null
	}

	# 添加到LOD系统
	if lod_system:
		lod_system.add_object(particles, "effect")

	# 添加到活动特效
	active_effects[effect_id] = effect_data

	# 发射粒子
	particles.emitting = true

	# 发送特效开始信号
	animation_started.emit(effect_id)

	# 如果设置了自动移除，创建定时器
	if params.auto_remove:
		var timer = get_tree().create_timer(duration)
		timer.timeout.connect(func(): _on_effect_completed(effect_id))

	return effect_id

# 播放精灵特效
func play_sprite_effect(position: Vector2, texture_path: String, frame_count: int, frame_duration: float, params: Dictionary = {}) -> String:
	# 创建特效ID
	var effect_id = _create_effect_id(EffectType.SPRITE, texture_path.get_file().get_basename())

	# 检查是否已经有相同的特效在播放
	if active_effects.has(effect_id):
		return effect_id

	# 合并默认参数
	var default_params = {
		"scale": Vector2(1, 1),
		"rotation": 0.0,
		"modulate": Color(1, 1, 1, 1),
		"loop": false,
		"auto_remove": true,
		"z_index": 0,
		"hframes": frame_count,
		"vframes": 1
	}

	for key in default_params:
		if not params.has(key):
			params[key] = default_params[key]

	# 加载纹理
	var texture = load(texture_path)
	if not texture:
		return ""

	# 创建精灵节点
	var sprite = AnimatedSprite2D.new()
	sprite.name = "Sprite_" + effect_id
	sprite.position = position
	sprite.scale = params.scale
	sprite.rotation = params.rotation
	sprite.modulate = params.modulate
	sprite.z_index = params.z_index

	# 创建精灵帧
	var frames = SpriteFrames.new()
	frames.add_animation("default")

	# 如果是精灵表，则添加所有帧
	if params.hframes > 1 or params.vframes > 1:
		var sprite_sheet = AtlasTexture.new()
		sprite_sheet.atlas = texture

		var frame_width = texture.get_width() / params.hframes
		var frame_height = texture.get_height() / params.vframes

		for v in range(params.vframes):
			for h in range(params.hframes):
				var region = Rect2(h * frame_width, v * frame_height, frame_width, frame_height)
				sprite_sheet.region = region
				frames.add_frame("default", sprite_sheet)
	else:
		# 单帧精灵
		frames.add_frame("default", texture)

	# 设置帧率
	frames.set_animation_speed("default", 1.0 / frame_duration)
	frames.set_animation_loop("default", params.loop)

	# 设置精灵帧
	sprite.sprite_frames = frames

	# 添加到容器
	effect_container.add_child(sprite)

	# 创建特效数据
	var effect_data = {
		"id": effect_id,
		"type": EffectType.SPRITE,
		"node": sprite,
		"duration": frame_duration * frame_count,
		"start_time": Time.get_ticks_msec(),
		"state": AnimationState.PLAYING,
		"auto_remove": params.auto_remove
	}

	# 添加到LOD系统
	if lod_system:
		lod_system.add_object(sprite, "effect")

	# 添加到活动特效
	active_effects[effect_id] = effect_data

	# 播放动画
	sprite.play("default")

	# 连接动画完成信号
	sprite.animation_finished.connect(func(): _on_effect_completed(effect_id))

	# 发送特效开始信号
	animation_started.emit(effect_id)

	return effect_id

# 播放着色器特效
func play_shader_effect(target, shader_path: String, duration: float, params: Dictionary = {}) -> String:
	# 检查目标是否有效
	if not is_instance_valid(target) or not target is CanvasItem:
		return ""

	# 创建特效ID
	var effect_id = _create_effect_id(EffectType.SHADER, shader_path.get_file().get_basename())

	# 检查是否已经有相同的特效在播放
	if active_effects.has(effect_id):
		return effect_id

	# 合并默认参数
	var default_params = {
		"shader_params": {},
		"auto_remove": true,
		"transition_in": 0.3,
		"transition_out": 0.3
	}

	for key in default_params:
		if not params.has(key):
			params[key] = default_params[key]

	# 加载着色器
	var shader = load(shader_path)
	if not shader:
		return ""

	# 保存原始材质
	var original_material = target.material

	# 创建着色器材质
	var material = ShaderMaterial.new()
	material.shader = shader

	# 设置着色器参数
	for param_name in params.shader_params:
		material.set_shader_parameter(param_name, params.shader_params[param_name])

	# 应用材质
	target.material = material

	# 创建特效数据
	var effect_data = {
		"id": effect_id,
		"type": EffectType.SHADER,
		"target": target,
		"material": material,
		"original_material": original_material,
		"duration": duration,
		"start_time": Time.get_ticks_msec(),
		"state": AnimationState.PLAYING,
		"auto_remove": params.auto_remove,
		"transition_in": params.transition_in,
		"transition_out": params.transition_out
	}

	# 添加到活动特效
	active_effects[effect_id] = effect_data

	# 创建渐变效果
	if params.transition_in > 0:
		var tween = create_tween()
		tween.tween_method(func(value): material.set_shader_parameter("intensity", value), 0.0, 1.0, params.transition_in)

	# 发送特效开始信号
	animation_started.emit(effect_id)

	# 如果设置了自动移除，创建定时器
	if params.auto_remove:
		var timer = get_tree().create_timer(duration - params.transition_out)
		timer.timeout.connect(func():
			# 创建渐出效果
			if params.transition_out > 0:
				var out_tween = create_tween()
				out_tween.tween_method(func(value): material.set_shader_parameter("intensity", value), 1.0, 0.0, params.transition_out)
				out_tween.tween_callback(func(): _on_effect_completed(effect_id))
			else:
				_on_effect_completed(effect_id)
		)

	return effect_id

# 播放组合特效
func play_combined_effect(position: Vector2, effect_name: String, params: Dictionary = {}) -> String:
	# 检查容器是否有效
	if not effect_container:
		_log_error("无效的特效容器")
		return ""

	# 检查特效注册表是否存在该特效
	if effect_registry and effect_registry.effect_configs.has(effect_name):
		# 使用特效注册表播放特效
		return effect_registry.play_effect(self, position, effect_name, params)

	# 如果特效注册表中没有该特效，则使用默认方式播放
	# 创建特效ID
	var effect_id = _create_effect_id(EffectType.COMBINED, effect_name)

	# 检查是否已经有相同的特效在播放
	if active_effects.has(effect_id):
		return effect_id

	# 合并默认参数
	var default_params = {
		"duration": 1.0,
		"scale": Vector2(1, 1),
		"rotation": 0.0,
		"auto_remove": true,
		"z_index": 0,
		"effects": []
	}

	for key in default_params:
		if not params.has(key):
			params[key] = default_params[key]

	# 从对象池获取容器
	var container = null
	if ObjectPool and ObjectPool.has_pool(CONTAINER_POOL_NAME):
		container = ObjectPool.get_object(CONTAINER_POOL_NAME)

	# 如果对象池无法提供实例，则创建新实例
	if not container:
		container = Node2D.new()

	# 设置容器属性
	container.name = "CombinedEffect_" + effect_id
	container.position = position
	container.scale = params.scale
	container.rotation = params.rotation
	container.z_index = params.z_index

	# 添加到特效容器
	effect_container.add_child(container)

	# 创建特效数据
	var effect_data = {
		"id": effect_id,
		"type": EffectType.COMBINED,
		"node": container,
		"duration": params.duration,
		"start_time": Time.get_ticks_msec(),
		"state": AnimationState.PLAYING,
		"auto_remove": params.auto_remove,
		"child_effects": [],
		"from_pool": container != null and ObjectPool != null and ObjectPool.has_pool(CONTAINER_POOL_NAME)
	}

	# 添加到活动特效
	active_effects[effect_id] = effect_data

	# 创建子特效
	for effect_config in params.effects:
		var child_effect_id = ""

		# 根据特效类型创建子特效
		if effect_config.has("type"):
			match effect_config.type:
				"particle":
					child_effect_id = play_particle_effect(
						effect_config.get("position", Vector2.ZERO),
						effect_config.get("name", "particle"),
						effect_config.get("duration", 1.0),
						effect_config.get("params", {})
					)
				"sprite":
					child_effect_id = play_sprite_effect(
						effect_config.get("position", Vector2.ZERO),
						effect_config.get("texture_path", ""),
						effect_config.get("frame_count", 1),
						effect_config.get("frame_duration", 0.1),
						effect_config.get("params", {})
					)
				"shader":
					# 着色器特效需要目标对象
					if effect_config.has("target"):
						child_effect_id = play_shader_effect(
							effect_config.target,
							effect_config.get("shader_path", ""),
							effect_config.get("duration", 1.0),
							effect_config.get("params", {})
						)

		# 如果创建成功，添加到子特效列表
		if child_effect_id != "":
			effect_data.child_effects.append(child_effect_id)

	# 添加到LOD系统
	if lod_system and is_instance_valid(container):
		lod_system.add_object(container, "effect")

	# 发送特效开始信号
	animation_started.emit(effect_id)

	# 如果设置了自动移除，创建定时器
	if params.auto_remove:
		var timer = get_tree().create_timer(params.duration)
		timer.timeout.connect(func(): _on_effect_completed(effect_id))

	return effect_id

# 取消特效
func cancel_effect(effect_id: String) -> bool:
	# 检查特效ID是否有效
	if effect_id.is_empty() or not active_effects.has(effect_id):
		return false

	# 获取特效数据
	var effect_data = active_effects[effect_id]

	# 如果是组合特效，递归取消所有子特效
	if effect_data.type == EffectType.COMBINED and effect_data.has("child_effects"):
		for child_id in effect_data.child_effects:
			cancel_effect(child_id)

	# 清理特效资源
	_cleanup_effect(effect_id)

	# 发送特效取消信号
	animation_cancelled.emit(effect_id)

	# 从活动特效中移除
	active_effects.erase(effect_id)

	return true

# 暂停特效
func pause_effect(effect_id: String) -> bool:
	# 检查特效ID是否有效
	if effect_id.is_empty() or not active_effects.has(effect_id):
		return false

	# 获取特效数据
	var effect_data = active_effects[effect_id]

	# 如果特效已经暂停或完成，则返回
	if effect_data.state == AnimationState.PAUSED or effect_data.state == AnimationState.COMPLETED:
		return false

	# 根据特效类型暂停
	match effect_data.type:
		EffectType.PARTICLE:
			if effect_data.has("node") and is_instance_valid(effect_data.node):
				effect_data.node.emitting = false
				effect_data.paused_time = Time.get_ticks_msec() - effect_data.start_time
		EffectType.SPRITE:
			if effect_data.has("node") and is_instance_valid(effect_data.node):
				effect_data.node.pause()
		EffectType.COMBINED:
			if effect_data.has("child_effects"):
				for child_id in effect_data.child_effects:
					pause_effect(child_id)

	# 更新特效状态
	effect_data.state = AnimationState.PAUSED

	return true

# 恢复特效
func resume_effect(effect_id: String) -> bool:
	# 检查特效ID是否有效
	if effect_id.is_empty() or not active_effects.has(effect_id):
		return false

	# 获取特效数据
	var effect_data = active_effects[effect_id]

	# 如果特效没有暂停，则返回
	if effect_data.state != AnimationState.PAUSED:
		return false

	# 根据特效类型恢复
	match effect_data.type:
		EffectType.PARTICLE:
			if effect_data.has("node") and is_instance_valid(effect_data.node):
				effect_data.node.emitting = true
				effect_data.start_time = Time.get_ticks_msec() - effect_data.paused_time
		EffectType.SPRITE:
			if effect_data.has("node") and is_instance_valid(effect_data.node):
				effect_data.node.play()
		EffectType.COMBINED:
			if effect_data.has("child_effects"):
				for child_id in effect_data.child_effects:
					resume_effect(child_id)

	# 更新特效状态
	effect_data.state = AnimationState.PLAYING

	return true

# 获取特效状态
func get_effect_state(effect_id: String) -> int:
	# 检查特效ID是否有效
	if effect_id.is_empty() or not active_effects.has(effect_id):
		return AnimationState.IDLE

	# 返回特效状态
	return active_effects[effect_id].state

# 是否有活动的特效
func has_active_effects() -> bool:
	# 检查是否有活动的特效
	for effect_id in active_effects:
		var effect_data = active_effects[effect_id]
		if effect_data.state == AnimationState.PLAYING or effect_data.state == AnimationState.PAUSED:
			return true

	return false

# 清除所有特效
func clear_effects() -> void:
	# 复制活动特效列表，因为我们将在遍历过程中修改它
	var effects_to_clear = active_effects.keys()

	# 取消所有特效
	for effect_id in effects_to_clear:
		cancel_effect(effect_id)

	# 清空特效队列
	effect_queue.clear()

	# 清空活动特效列表
	active_effects.clear()

# 创建特效ID
func _create_effect_id(type: int, name: String) -> String:
	# 生成唯一ID
	var timestamp = Time.get_ticks_msec()
	var random_part = randi() % 10000

	# 根据特效类型生成前缀
	var prefix = ""
	match type:
		EffectType.PARTICLE: prefix = "particle"
		EffectType.SPRITE: prefix = "sprite"
		EffectType.SHADER: prefix = "shader"
		EffectType.COMBINED: prefix = "combined"

	# 组合ID
	return prefix + "_" + name + "_" + str(timestamp) + "_" + str(random_part)

# 添加特效到队列
func _add_to_queue(effect_data: Dictionary) -> String:
	# 获取特效ID
	var effect_id = effect_data.id

	# 添加到队列
	effect_queue.append(effect_data)

	# 处理队列
	_process_queue()

	return effect_id

# 处理特效队列
func _process_queue() -> void:
	# 如果队列为空，则返回
	if effect_queue.is_empty():
		return

	# 获取下一个特效
	var effect_data = effect_queue.pop_front()

	# 添加到活动特效
	active_effects[effect_data.id] = effect_data

# 特效完成处理
func _on_effect_completed(effect_id: String) -> void:
	# 检查特效ID是否有效
	if effect_id.is_empty() or not active_effects.has(effect_id):
		return

	# 获取特效数据
	var effect_data = active_effects[effect_id]

	# 清理特效资源
	_cleanup_effect(effect_id)

	# 更新特效状态
	effect_data.state = AnimationState.COMPLETED

	# 发送特效完成信号
	animation_completed.emit(effect_id)

	# 从活动特效中移除
	active_effects.erase(effect_id)

	# 从LOD系统移除
	if lod_system and effect_data.has("node") and is_instance_valid(effect_data.node):
		lod_system.remove_object(effect_data.node)

# 清理特效资源
func _cleanup_effect(effect_id: String) -> void:
	# 检查特效ID是否有效
	if effect_id.is_empty() or not active_effects.has(effect_id):
		return

	# 获取特效数据
	var effect_data = active_effects[effect_id]

	# 根据特效类型清理资源
	match effect_data.type:
		EffectType.PARTICLE:
			if effect_data.has("node") and is_instance_valid(effect_data.node):
				# 如果节点在场景树中，移除它
				if effect_data.node.is_inside_tree():
					effect_data.node.get_parent().remove_child(effect_data.node)

				# 重置粒子属性
				effect_data.node.emitting = false
				effect_data.node.modulate = Color.WHITE
				effect_data.node.scale = Vector2.ONE

				# 如果来自对象池，则返回到池
				if effect_data.has("from_pool") and effect_data.from_pool and ObjectPool:
					ObjectPool.release_object(PARTICLE_POOL_NAME, effect_data.node)
				else:
					# 否则销毁节点
					effect_data.node.queue_free()

		EffectType.SPRITE:
			if effect_data.has("node") and is_instance_valid(effect_data.node):
				# 如果节点在场景树中，移除它
				if effect_data.node.is_inside_tree():
					effect_data.node.get_parent().remove_child(effect_data.node)

				# 重置精灵属性
				effect_data.node.modulate = Color.WHITE
				effect_data.node.scale = Vector2.ONE
				effect_data.node.rotation = 0

				# 如果来自对象池，则返回到池
				if effect_data.has("from_pool") and effect_data.from_pool and ObjectPool:
					ObjectPool.release_object(SPRITE_POOL_NAME, effect_data.node)
				else:
					# 否则销毁节点
					effect_data.node.queue_free()

		EffectType.COMBINED:
			# 如果有子特效，递归清理
			if effect_data.has("child_effects"):
				for child_id in effect_data.child_effects:
					_cleanup_effect(child_id)

			# 清理容器
			if effect_data.has("node") and is_instance_valid(effect_data.node):
				# 如果节点在场景树中，移除它
				if effect_data.node.is_inside_tree():
					effect_data.node.get_parent().remove_child(effect_data.node)

				# 如果来自对象池，则返回到池
				if effect_data.has("from_pool") and effect_data.from_pool and ObjectPool:
					ObjectPool.release_object(CONTAINER_POOL_NAME, effect_data.node)
				else:
					# 否则销毁节点
					effect_data.node.queue_free()

		EffectType.SHADER:
			if effect_data.has("target") and is_instance_valid(effect_data.target):
				# 恢复原始材质
				if effect_data.has("original_material"):
					effect_data.target.material = effect_data.original_material

# 记录错误信息
func _log_error(error_message: String) -> void:
	print("[VisualEffectAnimator] ERROR: " + error_message)

# 记录警告信息
func _log_warning(warning_message: String) -> void:
	print("[VisualEffectAnimator] WARNING: " + warning_message)

# 记录信息
func _log_info(info_message: String) -> void:
	print("[VisualEffectAnimator] INFO: " + info_message)

# 播放动画
# 兼容AnimationManager的接口
func play_animation(position: Vector2, effect_name: String, params: Dictionary = {}) -> bool:
	# 直接调用play_combined_effect
	var effect_id = play_combined_effect(position, effect_name, params)
	return effect_id != ""
