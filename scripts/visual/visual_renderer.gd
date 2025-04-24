extends Node
class_name VisualRenderer
## 视觉渲染器
## 负责创建和管理视觉效果的实际渲染

# 信号
signal effect_completed(effect_id)
signal effect_cancelled(effect_id)

# 效果节点字典 {效果ID: 效果节点}
var _effect_nodes: Dictionary = {}

# 效果池
var _effect_pool: Dictionary = {}

# 对象池大小
var _pool_size: int = 10

# 初始化
func _init() -> void:
	# 初始化效果池
	_init_effect_pool()

	# 连接对象池信号
	if ObjectPool:
		ObjectPool.pool_created.connect(_on_object_pool_created)
		ObjectPool.pool_cleared.connect(_on_object_pool_cleared)

# 初始化效果池
func _init_effect_pool() -> void:
	# 初始化粒子效果池
	_effect_pool["particle"] = []
	for i in range(_pool_size):
		var particle = GPUParticles2D.new()
		particle.one_shot = true
		particle.emitting = false
		particle.name = "PooledParticle_" + str(i)
		add_child(particle)
		particle.hide()
		_effect_pool["particle"].append(particle)

	# 初始化精灵效果池
	_effect_pool["sprite"] = []
	for i in range(_pool_size):
		var sprite = Sprite2D.new()
		sprite.name = "PooledSprite_" + str(i)
		add_child(sprite)
		sprite.hide()
		_effect_pool["sprite"].append(sprite)

	# 初始化动画效果池
	_effect_pool["animation"] = []
	for i in range(_pool_size):
		var anim_player = AnimationPlayer.new()
		var root = Node2D.new()
		root.name = "PooledAnimation_" + str(i)
		root.add_child(anim_player)
		anim_player.name = "AnimationPlayer"
		add_child(root)
		root.hide()
		_effect_pool["animation"].append(root)

	# 初始化着色器效果池
	_effect_pool["shader"] = []
	for i in range(_pool_size):
		var shader_node = ColorRect.new()
		shader_node.name = "PooledShader_" + str(i)
		add_child(shader_node)
		shader_node.hide()
		_effect_pool["shader"].append(shader_node)

	# 初始化文本效果池
	_effect_pool["text"] = []
	for i in range(_pool_size):
		var label = Label.new()
		label.name = "PooledText_" + str(i)
		add_child(label)
		label.hide()
		_effect_pool["text"].append(label)

# 创建效果
func create_effect(effect_id: String, effect_type: String, position: Vector2, params: Dictionary = {}) -> void:
	# 根据效果类型创建不同的效果
	match effect_type:
		"particle":
			_create_particle_effect(effect_id, position, params)

		"sprite":
			_create_sprite_effect(effect_id, position, params)

		"animation":
			_create_animation_effect(effect_id, position, params)

		"shader":
			_create_shader_effect(effect_id, position, params)

		"combined":
			_create_combined_effect(effect_id, position, params)

		"damage_number":
			_create_damage_number(effect_id, position, params)

		"heal_number":
			_create_heal_number(effect_id, position, params)

		"status_icon":
			_create_status_icon(effect_id, position, params)

		_:
			print("VisualRenderer: 未知的效果类型: " + effect_type)

# 取消效果
func cancel_effect(effect_id: String) -> bool:
	# 检查效果是否存在
	if not _effect_nodes.has(effect_id):
		return false

	# 获取效果节点
	var effect_node = _effect_nodes[effect_id]

	# 检查效果节点是否有效
	if not is_instance_valid(effect_node):
		_effect_nodes.erase(effect_id)
		return false

	# 停止效果
	_stop_effect(effect_node)

	# 回收效果节点
	_recycle_effect_node(effect_id, effect_node)

	# 移除效果节点引用
	_effect_nodes.erase(effect_id)

	# 发送效果取消信号
	effect_cancelled.emit(effect_id)

	return true

# 停止效果
func _stop_effect(effect_node: Node) -> void:
	# 检查效果节点类型
	if effect_node is GPUParticles2D:
		# 停止粒子发射
		effect_node.emitting = false

	elif effect_node is AnimationPlayer:
		# 停止动画
		effect_node.stop()

	elif effect_node.has_node("AnimationPlayer"):
		# 停止动画
		var anim_player = effect_node.get_node("AnimationPlayer")
		if anim_player:
			anim_player.stop()

	# 隐藏效果节点
	effect_node.hide()

# 回收效果节点
func _recycle_effect_node(effect_id: String, effect_node: Node) -> void:
	# 获取效果类型
	var effect_type = ""

	if effect_node is GPUParticles2D:
		effect_type = "particle"
	elif effect_node is Sprite2D:
		effect_type = "sprite"
	elif effect_node.has_node("AnimationPlayer"):
		effect_type = "animation"
	elif effect_node is ColorRect:
		effect_type = "shader"
	elif effect_node is Label:
		effect_type = "text"

	# 尝试使用全局对象池
	var pool_name = "visual_effect_" + effect_type
	if not effect_type.is_empty() and ObjectPool and ObjectPool.has_method("release_object") and ObjectPool._pools.has(pool_name):
		# 重置效果节点
		_reset_effect_node(effect_node, effect_type)

		# 如果节点在场景树中，移除它
		if effect_node.is_inside_tree():
			effect_node.get_parent().remove_child(effect_node)

		# 释放到全局对象池
		ObjectPool.release_object(pool_name, effect_node)
		return

	# 如果全局对象池不可用，使用内部对象池
	if not effect_type.is_empty() and _effect_pool.has(effect_type):
		# 重置效果节点
		_reset_effect_node(effect_node, effect_type)

		# 添加到对象池
		_effect_pool[effect_type].append(effect_node)
	else:
		# 否则，直接释放
		effect_node.queue_free()

# 重置效果节点
func _reset_effect_node(effect_node: Node, effect_type: String) -> void:
	# 根据效果类型重置节点
	match effect_type:
		"particle":
			var particle = effect_node as GPUParticles2D
			particle.emitting = false
			particle.amount = 8
			particle.lifetime = 1.0
			particle.explosiveness = 0.0
			particle.randomness = 0.0
			particle.fixed_fps = 0
			particle.process_material = null
			particle.texture = null
			particle.modulate = Color.WHITE
			particle.scale = Vector2.ONE
			particle.z_index = 0

		"sprite":
			var sprite = effect_node as Sprite2D
			sprite.texture = null
			sprite.modulate = Color.WHITE
			sprite.scale = Vector2.ONE
			sprite.rotation = 0.0
			sprite.z_index = 0

		"animation":
			var root = effect_node
			var anim_player = root.get_node("AnimationPlayer") as AnimationPlayer
			anim_player.stop()
			anim_player.clear_queue()
			root.modulate = Color.WHITE
			root.scale = Vector2.ONE
			root.rotation = 0.0
			root.z_index = 0

		"shader":
			var shader_node = effect_node as ColorRect
			shader_node.material = null
			shader_node.color = Color.WHITE
			shader_node.size = Vector2(100, 100)
			shader_node.scale = Vector2.ONE
			shader_node.z_index = 0

		"text":
			var label = effect_node as Label
			label.text = ""
			label.modulate = Color.WHITE
			label.scale = Vector2.ONE
			label.z_index = 0

	# 隐藏节点
	effect_node.hide()

	# 重置位置
	effect_node.position = Vector2.ZERO

# 对象池创建事件处理
func _on_object_pool_created(pool_name: String, initial_size: int) -> void:
	# 检查是否是视觉效果池
	if pool_name.begins_with("visual_effect_"):
		GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("VisualRenderer: 检测到视觉效果池创建: " + pool_name, 0))

# 对象池清理事件处理
func _on_object_pool_cleared(pool_name: String) -> void:
	# 检查是否是视觉效果池
	if pool_name.begins_with("visual_effect_"):
		GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("VisualRenderer: 检测到视觉效果池清理: " + pool_name, 0))

# 根据ID移除效果
func remove_effect_by_id(effect_id: String) -> bool:
	# 检查效果ID是否有效
	if effect_id.is_empty():
		return false

	# 检查效果是否存在
	if not _effect_nodes.has(effect_id):
		return false

	# 获取效果节点
	var effect_node = _effect_nodes[effect_id]

	# 检查效果节点是否有效
	if not is_instance_valid(effect_node):
		_effect_nodes.erase(effect_id)
		return false

	# 停止效果
	_stop_effect(effect_node)

	# 回收效果节点
	_recycle_effect_node(effect_id, effect_node)

	# 移除效果节点引用
	_effect_nodes.erase(effect_id)

	# 发送效果取消信号
	effect_cancelled.emit(effect_id)

	return true

# 移除效果节点
func remove_effect_node(effect_node: Node) -> bool:
	# 检查节点是否有效
	if not effect_node or not is_instance_valid(effect_node):
		return false

	# 查找节点对应的效果ID
	var effect_id = ""
	for id in _effect_nodes.keys():
		if _effect_nodes[id] == effect_node:
			effect_id = id
			break

	# 如果找到了效果ID，使用remove_effect_by_id移除
	if not effect_id.is_empty():
		return remove_effect_by_id(effect_id)

	# 如果没有找到效果ID，直接停止和回收节点
	_stop_effect(effect_node)

	# 尝试确定效果类型
	var effect_type = ""
	if effect_node is GPUParticles2D:
		effect_type = "particle"
	elif effect_node is Sprite2D:
		effect_type = "sprite"
	elif effect_node.has_node("AnimationPlayer"):
		effect_type = "animation"
	elif effect_node is ColorRect:
		effect_type = "shader"
	elif effect_node is Label:
		effect_type = "text"

	# 回收节点
	if not effect_type.is_empty():
		# 尝试使用全局对象池
		var pool_name = "visual_effect_" + effect_type
		if ObjectPool and ObjectPool.has_method("release_object") and ObjectPool._pools.has(pool_name):
			# 重置效果节点
			_reset_effect_node(effect_node, effect_type)

			# 如果节点在场景树中，移除它
			if effect_node.is_inside_tree():
				effect_node.get_parent().remove_child(effect_node)

			# 释放到全局对象池
			ObjectPool.release_object(pool_name, effect_node)
			return true

		# 如果全局对象池不可用，使用内部对象池
		if _effect_pool.has(effect_type):
			# 重置效果节点
			_reset_effect_node(effect_node, effect_type)

			# 添加到对象池
			_effect_pool[effect_type].append(effect_node)
			return true

	# 如果所有方法都失败，直接释放
	effect_node.queue_free()
	return true

# 恢复效果
func resume_effect(effect_id: String) -> bool:
	# 检查效果ID是否有效
	if effect_id.is_empty():
		return false

	# 检查效果是否存在
	if not _effect_nodes.has(effect_id):
		return false

	# 获取效果节点
	var effect_node = _effect_nodes[effect_id]

	# 检查效果节点是否有效
	if not is_instance_valid(effect_node):
		_effect_nodes.erase(effect_id)
		return false

	# 根据节点类型恢复效果
	if effect_node is GPUParticles2D:
		# 恢复粒子发射
		effect_node.emitting = true
		return true

	elif effect_node is AnimationPlayer:
		# 恢复动画
		if effect_node.is_paused():
			effect_node.play()
			return true

	elif effect_node.has_node("AnimationPlayer"):
		# 恢复动画
		var anim_player = effect_node.get_node("AnimationPlayer")
		if anim_player and anim_player.is_paused():
			anim_player.play()
			return true

	# 显示效果节点
	effect_node.show()
	return true

# 从对象池获取效果节点
func _get_from_pool(effect_type: String) -> Node:
	# 池名称
	var pool_name = "visual_effect_" + effect_type

	# 尝试使用全局对象池
	if ObjectPool and ObjectPool.has_method("get_object") and ObjectPool._pools.has(pool_name):
		var obj = ObjectPool.get_object(pool_name)
		if obj:
			return obj

	# 如果全局对象池不可用，使用内部对象池
	if _effect_pool.has(effect_type) and not _effect_pool[effect_type].is_empty():
		return _effect_pool[effect_type].pop_back()

	# 如果内部对象池也为空，创建新节点
	match effect_type:
		"particle":
			var particle = GPUParticles2D.new()
			particle.one_shot = true
			particle.emitting = false
			particle.name = "DynamicParticle_" + str(Time.get_ticks_msec())
			add_child(particle)
			return particle

		"sprite":
			var sprite = Sprite2D.new()
			sprite.name = "DynamicSprite_" + str(Time.get_ticks_msec())
			add_child(sprite)
			return sprite

		"animation":
			var anim_player = AnimationPlayer.new()
			var root = Node2D.new()
			root.name = "DynamicAnimation_" + str(Time.get_ticks_msec())
			root.add_child(anim_player)
			anim_player.name = "AnimationPlayer"
			add_child(root)
			return root

		"shader":
			var shader_node = ColorRect.new()
			shader_node.name = "DynamicShader_" + str(Time.get_ticks_msec())
			add_child(shader_node)
			return shader_node

		"text":
			var label = Label.new()
			label.name = "DynamicText_" + str(Time.get_ticks_msec())
			add_child(label)
			return label

	# 如果所有方法都失败，返回null
	return null

# 创建粒子效果
func _create_particle_effect(effect_id: String, position: Vector2, params: Dictionary) -> void:
	# 从对象池获取粒子节点
	var particle = _get_from_pool("particle") as GPUParticles2D

	# 设置粒子位置
	particle.position = position

	# 设置粒子类型
	var particle_type = params.get("particle_type", "default")

	# 设置粒子材质
	var process_material = _get_particle_material(particle_type)
	if process_material:
		particle.process_material = process_material

	# 设置粒子纹理
	var texture = _get_particle_texture(particle_type)
	if texture:
		particle.texture = texture

	# 设置粒子参数
	particle.amount = params.get("amount", 8)
	particle.lifetime = params.get("duration", 1.0)
	particle.explosiveness = params.get("explosiveness", 0.0)
	particle.randomness = params.get("randomness", 0.0)
	particle.fixed_fps = params.get("fixed_fps", 0)

	# 设置颜色
	if params.has("color"):
		particle.modulate = params.color

	# 设置缩放
	if params.has("scale"):
		particle.scale = params.scale

	# 设置Z索引
	if params.has("z_index"):
		particle.z_index = params.z_index

	# 设置自动移除
	var auto_remove = params.get("auto_remove", true)

	# 显示粒子
	particle.show()

	# 开始发射粒子
	particle.emitting = true

	# 存储效果节点
	_effect_nodes[effect_id] = particle

	# 如果自动移除，设置定时器
	if auto_remove:
		var timer = Timer.new()
		particle.add_child(timer)
		timer.wait_time = particle.lifetime * 1.5  # 给一些额外时间让粒子完全消失
		timer.one_shot = true
		timer.timeout.connect(_on_particle_timeout.bind(effect_id, particle, timer))
		timer.start()

# 粒子超时处理
func _on_particle_timeout(effect_id: String, particle: GPUParticles2D, timer: Timer) -> void:
	# 移除定时器
	timer.queue_free()

	# 检查效果是否仍然存在
	if not _effect_nodes.has(effect_id):
		return

	# 停止粒子发射
	particle.emitting = false

	# 回收粒子节点
	_recycle_effect_node(effect_id, particle)

	# 移除效果节点引用
	_effect_nodes.erase(effect_id)

	# 发送效果完成信号
	effect_completed.emit(effect_id)

# 获取粒子材质
func _get_particle_material(particle_type: String) -> ParticleProcessMaterial:
	# 创建基本粒子材质
	var material = ParticleProcessMaterial.new()

	# 根据粒子类型设置不同的材质参数
	match particle_type:
		"fire":
			material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			material.emission_sphere_radius = 5.0
			material.direction = Vector3(0, -1, 0)
			material.spread = 45.0
			material.gravity = Vector3(0, 0, 0)
			material.initial_velocity_min = 20.0
			material.initial_velocity_max = 40.0
			material.angular_velocity_min = -90.0
			material.angular_velocity_max = 90.0
			material.scale_min = 0.8
			material.scale_max = 1.2
			material.color = Color(1.0, 0.5, 0.0, 1.0)
			material.color_ramp = _create_fire_color_ramp()

		"smoke":
			material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			material.emission_sphere_radius = 5.0
			material.direction = Vector3(0, -1, 0)
			material.spread = 45.0
			material.gravity = Vector3(0, -10, 0)
			material.initial_velocity_min = 10.0
			material.initial_velocity_max = 20.0
			material.angular_velocity_min = -10.0
			material.angular_velocity_max = 10.0
			material.scale_min = 0.5
			material.scale_max = 1.5
			material.color = Color(0.5, 0.5, 0.5, 0.7)

		"sparkle":
			material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
			material.direction = Vector3(0, 0, 0)
			material.spread = 180.0
			material.gravity = Vector3(0, 0, 0)
			material.initial_velocity_min = 30.0
			material.initial_velocity_max = 60.0
			material.damping_min = 10.0
			material.damping_max = 20.0
			material.scale_min = 0.3
			material.scale_max = 0.6
			material.color = Color(1.0, 1.0, 0.0, 1.0)

		"heal":
			material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			material.emission_sphere_radius = 10.0
			material.direction = Vector3(0, -1, 0)
			material.spread = 45.0
			material.gravity = Vector3(0, -20, 0)
			material.initial_velocity_min = 10.0
			material.initial_velocity_max = 30.0
			material.angular_velocity_min = -10.0
			material.angular_velocity_max = 10.0
			material.scale_min = 0.5
			material.scale_max = 1.0
			material.color = Color(0.0, 1.0, 0.0, 0.8)

		"blood":
			material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			material.emission_sphere_radius = 5.0
			material.direction = Vector3(0, 1, 0)
			material.spread = 60.0
			material.gravity = Vector3(0, 98, 0)
			material.initial_velocity_min = 30.0
			material.initial_velocity_max = 60.0
			material.scale_min = 0.5
			material.scale_max = 1.0
			material.color = Color(0.8, 0.0, 0.0, 0.9)

		"explosion":
			material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			material.emission_sphere_radius = 1.0
			material.direction = Vector3(0, 0, 0)
			material.spread = 180.0
			material.gravity = Vector3(0, 0, 0)
			material.initial_velocity_min = 50.0
			material.initial_velocity_max = 100.0
			material.damping_min = 20.0
			material.damping_max = 50.0
			material.scale_min = 1.0
			material.scale_max = 2.0
			material.color = Color(1.0, 0.5, 0.0, 1.0)
			material.color_ramp = _create_explosion_color_ramp()

		_:  # default
			material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
			material.direction = Vector3(0, -1, 0)
			material.spread = 45.0
			material.gravity = Vector3(0, 98, 0)
			material.initial_velocity_min = 20.0
			material.initial_velocity_max = 40.0
			material.scale_min = 0.8
			material.scale_max = 1.2
			material.color = Color(1.0, 1.0, 1.0, 1.0)

	return material

# 创建火焰颜色渐变
func _create_fire_color_ramp() -> Gradient:
	var gradient = Gradient.new()
	gradient.colors = [
		Color(1.0, 1.0, 0.0, 1.0),  # 黄色
		Color(1.0, 0.5, 0.0, 0.8),  # 橙色
		Color(1.0, 0.0, 0.0, 0.6),  # 红色
		Color(0.3, 0.0, 0.0, 0.0)   # 透明深红
	]
	gradient.offsets = [0.0, 0.3, 0.6, 1.0]
	return gradient

# 创建爆炸颜色渐变
func _create_explosion_color_ramp() -> Gradient:
	var gradient = Gradient.new()
	gradient.colors = [
		Color(1.0, 1.0, 0.0, 1.0),  # 黄色
		Color(1.0, 0.5, 0.0, 0.8),  # 橙色
		Color(1.0, 0.0, 0.0, 0.6),  # 红色
		Color(0.3, 0.0, 0.0, 0.0)   # 透明深红
	]
	gradient.offsets = [0.0, 0.2, 0.5, 1.0]
	return gradient

# 获取粒子纹理
func _get_particle_texture(particle_type: String) -> Texture2D:
	# 根据粒子类型返回不同的纹理
	match particle_type:
		"fire":
			return load("res://assets/textures/particles/fire.png") if ResourceLoader.exists("res://assets/textures/particles/fire.png") else null
		"smoke":
			return load("res://assets/textures/particles/smoke.png") if ResourceLoader.exists("res://assets/textures/particles/smoke.png") else null
		"sparkle":
			return load("res://assets/textures/particles/sparkle.png") if ResourceLoader.exists("res://assets/textures/particles/sparkle.png") else null
		"heal":
			return load("res://assets/textures/particles/heal.png") if ResourceLoader.exists("res://assets/textures/particles/heal.png") else null
		"blood":
			return load("res://assets/textures/particles/blood.png") if ResourceLoader.exists("res://assets/textures/particles/blood.png") else null
		"explosion":
			return load("res://assets/textures/particles/explosion.png") if ResourceLoader.exists("res://assets/textures/particles/explosion.png") else null

	# 默认返回null
	return null

# 创建精灵效果
func _create_sprite_effect(effect_id: String, position: Vector2, params: Dictionary) -> void:
	# 从对象池获取精灵节点
	var sprite = _get_from_pool("sprite") as Sprite2D

	# 设置精灵位置
	sprite.position = position

	# 设置纹理
	var texture_path = params.get("texture_path", "")
	if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)

	# 设置颜色
	if params.has("color"):
		sprite.modulate = params.color

	# 设置缩放
	if params.has("scale"):
		sprite.scale = params.scale

	# 设置旋转
	if params.has("rotation"):
		sprite.rotation = params.rotation

	# 设置Z索引
	if params.has("z_index"):
		sprite.z_index = params.z_index

	# 设置持续时间
	var duration = params.get("duration", 1.0)

	# 设置自动移除
	var auto_remove = params.get("auto_remove", true)

	# 设置淡入淡出
	var fade_in = params.get("fade_in", 0.0)
	var fade_out = params.get("fade_out", 0.0)

	# 显示精灵
	sprite.show()

	# 存储效果节点
	_effect_nodes[effect_id] = sprite

	# 如果有淡入效果
	if fade_in > 0:
		sprite.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 1.0, fade_in)

	# 如果自动移除，设置定时器
	if auto_remove:
		var timer = Timer.new()
		sprite.add_child(timer)
		timer.wait_time = duration
		timer.one_shot = true

		# 如果有淡出效果
		if fade_out > 0:
			timer.timeout.connect(_on_sprite_fade_out.bind(effect_id, sprite, fade_out))
		else:
			timer.timeout.connect(_on_sprite_timeout.bind(effect_id, sprite, timer))

		timer.start()

# 精灵淡出处理
func _on_sprite_fade_out(effect_id: String, sprite: Sprite2D, fade_out: float) -> void:
	# 创建淡出动画
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, fade_out)
	tween.tween_callback(_on_sprite_timeout.bind(effect_id, sprite, null))

# 精灵超时处理
func _on_sprite_timeout(effect_id: String, sprite: Sprite2D, timer: Timer) -> void:
	# 移除定时器
	if timer:
		timer.queue_free()

	# 检查效果是否仍然存在
	if not _effect_nodes.has(effect_id):
		return

	# 回收精灵节点
	_recycle_effect_node(effect_id, sprite)

	# 移除效果节点引用
	_effect_nodes.erase(effect_id)

	# 发送效果完成信号
	effect_completed.emit(effect_id)

# 创建动画效果
func _create_animation_effect(effect_id: String, position: Vector2, params: Dictionary) -> void:
	# 从对象池获取动画节点
	var root = _get_from_pool("animation")
	var anim_player = root.get_node("AnimationPlayer") as AnimationPlayer

	# 设置位置
	root.position = position

	# 设置动画名称
	var animation_name = params.get("animation_name", "")

	# 设置动画库
	var animation_library = params.get("animation_library", "")
	if not animation_library.is_empty() and ResourceLoader.exists(animation_library):
		anim_player.add_animation_library("", load(animation_library))

	# 设置颜色
	if params.has("color"):
		root.modulate = params.color

	# 设置缩放
	if params.has("scale"):
		root.scale = params.scale

	# 设置旋转
	if params.has("rotation"):
		root.rotation = params.rotation

	# 设置Z索引
	if params.has("z_index"):
		root.z_index = params.z_index

	# 设置速度
	var speed_scale = params.get("speed_scale", 1.0)
	anim_player.speed_scale = speed_scale

	# 设置自动移除
	var auto_remove = params.get("auto_remove", true)

	# 显示动画
	root.show()

	# 存储效果节点
	_effect_nodes[effect_id] = root

	# 如果有动画名称，播放动画
	if not animation_name.is_empty():
		# 连接动画完成信号
		if auto_remove and not anim_player.animation_finished.is_connected(_on_animation_finished):
			anim_player.animation_finished.connect(_on_animation_finished.bind(effect_id, root))

		# 播放动画
		anim_player.play(animation_name)
	else:
		# 如果没有动画名称，直接完成
		if auto_remove:
			_on_animation_finished("", effect_id, root)

# 动画完成处理
func _on_animation_finished(anim_name: StringName, effect_id: String, root: Node) -> void:
	# 检查效果是否仍然存在
	if not _effect_nodes.has(effect_id):
		return

	# 回收动画节点
	_recycle_effect_node(effect_id, root)

	# 移除效果节点引用
	_effect_nodes.erase(effect_id)

	# 发送效果完成信号
	effect_completed.emit(effect_id)

# 创建着色器效果
func _create_shader_effect(effect_id: String, position: Vector2, params: Dictionary) -> void:
	# 从对象池获取着色器节点
	var shader_node = _get_from_pool("shader") as ColorRect

	# 设置位置
	shader_node.position = position

	# 设置大小
	var size = params.get("size", Vector2(100, 100))
	shader_node.size = size

	# 设置着色器路径
	var shader_path = params.get("shader_path", "")
	if not shader_path.is_empty() and ResourceLoader.exists(shader_path):
		var shader_material = ShaderMaterial.new()
		shader_material.shader = load(shader_path)
		shader_node.material = shader_material

	# 设置着色器参数
	var shader_params = params.get("shader_params", {})
	for param_name in shader_params:
		if shader_node.material:
			shader_node.material.set_shader_parameter(param_name, shader_params[param_name])

	# 设置颜色
	if params.has("color"):
		shader_node.color = params.color

	# 设置缩放
	if params.has("scale"):
		shader_node.scale = params.scale

	# 设置Z索引
	if params.has("z_index"):
		shader_node.z_index = params.z_index

	# 设置持续时间
	var duration = params.get("duration", 1.0)

	# 设置自动移除
	var auto_remove = params.get("auto_remove", true)

	# 显示着色器节点
	shader_node.show()

	# 存储效果节点
	_effect_nodes[effect_id] = shader_node

	# 如果自动移除，设置定时器
	if auto_remove:
		var timer = Timer.new()
		shader_node.add_child(timer)
		timer.wait_time = duration
		timer.one_shot = true
		timer.timeout.connect(_on_shader_timeout.bind(effect_id, shader_node, timer))
		timer.start()

# 着色器超时处理
func _on_shader_timeout(effect_id: String, shader_node: ColorRect, timer: Timer) -> void:
	# 移除定时器
	timer.queue_free()

	# 检查效果是否仍然存在
	if not _effect_nodes.has(effect_id):
		return

	# 回收着色器节点
	_recycle_effect_node(effect_id, shader_node)

	# 移除效果节点引用
	_effect_nodes.erase(effect_id)

	# 发送效果完成信号
	effect_completed.emit(effect_id)

# 创建组合效果
func _create_combined_effect(effect_id: String, position: Vector2, params: Dictionary) -> void:
	# 获取组合效果名称
	var effect_name = params.get("effect_name", "")
	if effect_name.is_empty():
		print("VisualRenderer: 组合效果名称为空")
		return

	# 获取组合效果定义
	var effect_def = null
	if GameManager and GameManager.visual_manager and GameManager.visual_manager.visual_registry:
		effect_def = GameManager.visual_manager.visual_registry.get_effect_definition(effect_name)

	if not effect_def:
		print("VisualRenderer: 未找到组合效果定义: " + effect_name)
		return

	# 获取子效果列表
	var sub_effects = effect_def.get("sub_effects", [])
	if sub_effects.is_empty():
		print("VisualRenderer: 组合效果没有子效果: " + effect_name)
		return

	# 创建组合效果根节点
	var root = Node2D.new()
	root.name = "CombinedEffect_" + effect_id
	root.position = position
	add_child(root)

	# 设置颜色
	if params.has("color"):
		root.modulate = params.color

	# 设置缩放
	if params.has("scale"):
		root.scale = params.scale

	# 设置旋转
	if params.has("rotation"):
		root.rotation = params.rotation

	# 设置Z索引
	if params.has("z_index"):
		root.z_index = params.z_index

	# 设置持续时间
	var duration = params.get("duration", effect_def.get("duration", 1.0))

	# 设置自动移除
	var auto_remove = params.get("auto_remove", true)

	# 存储效果节点
	_effect_nodes[effect_id] = root

	# 创建子效果
	var max_sub_duration = 0.0
	for sub_effect in sub_effects:
		var sub_type = sub_effect.get("type", "")
		var sub_position = sub_effect.get("position", Vector2.ZERO)
		var sub_params = sub_effect.get("params", {}).duplicate()

		# 合并参数
		for key in params:
			if key != "effect_name" and key != "position" and not sub_params.has(key):
				sub_params[key] = params[key]

		# 设置子效果不自动移除
		sub_params["auto_remove"] = false

		# 创建子效果ID
		var sub_id = effect_id + "_sub_" + str(sub_effects.find(sub_effect))

		# 创建子效果
		match sub_type:
			"particle":
				_create_particle_effect_for_combined(sub_id, sub_position, sub_params, root)
			"sprite":
				_create_sprite_effect_for_combined(sub_id, sub_position, sub_params, root)
			"animation":
				_create_animation_effect_for_combined(sub_id, sub_position, sub_params, root)
			"shader":
				_create_shader_effect_for_combined(sub_id, sub_position, sub_params, root)

		# 更新最大子效果持续时间
		var sub_duration = sub_params.get("duration", 1.0)
		max_sub_duration = max(max_sub_duration, sub_duration)

	# 如果自动移除，设置定时器
	if auto_remove:
		var timer = Timer.new()
		root.add_child(timer)
		timer.wait_time = max(duration, max_sub_duration)
		timer.one_shot = true
		timer.timeout.connect(_on_combined_timeout.bind(effect_id, root, timer))
		timer.start()

# 为组合效果创建粒子效果
func _create_particle_effect_for_combined(effect_id: String, position: Vector2, params: Dictionary, parent: Node) -> void:
	# 创建粒子节点
	var particle = GPUParticles2D.new()
	particle.name = "Particle_" + effect_id
	parent.add_child(particle)
	particle.position = position

	# 设置粒子类型
	var particle_type = params.get("particle_type", "default")

	# 设置粒子材质
	var process_material = _get_particle_material(particle_type)
	if process_material:
		particle.process_material = process_material

	# 设置粒子纹理
	var texture = _get_particle_texture(particle_type)
	if texture:
		particle.texture = texture

	# 设置粒子参数
	particle.amount = params.get("amount", 8)
	particle.lifetime = params.get("duration", 1.0)
	particle.explosiveness = params.get("explosiveness", 0.0)
	particle.randomness = params.get("randomness", 0.0)
	particle.fixed_fps = params.get("fixed_fps", 0)
	particle.one_shot = true

	# 设置颜色
	if params.has("color"):
		particle.modulate = params.color

	# 设置缩放
	if params.has("scale"):
		particle.scale = params.scale

	# 设置Z索引
	if params.has("z_index"):
		particle.z_index = params.z_index

	# 开始发射粒子
	particle.emitting = true


# 为组合效果创建精灵效果
func _create_sprite_effect_for_combined(effect_id: String, position: Vector2, params: Dictionary, parent: Node) -> void:
	# 创建精灵节点
	var sprite = Sprite2D.new()
	sprite.name = "Sprite_" + effect_id
	parent.add_child(sprite)
	sprite.position = position

	# 设置纹理
	var texture_path = params.get("texture_path", "")
	if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)

	# 设置颜色
	if params.has("color"):
		sprite.modulate = params.color

	# 设置缩放
	if params.has("scale"):
		sprite.scale = params.scale

	# 设置旋转
	if params.has("rotation"):
		sprite.rotation = params.rotation

	# 设置Z索引
	if params.has("z_index"):
		sprite.z_index = params.z_index

	# 设置淡入淡出
	var fade_in = params.get("fade_in", 0.0)
	var fade_out = params.get("fade_out", 0.0)
	var duration = params.get("duration", 1.0)

	# 如果有淡入效果
	if fade_in > 0:
		sprite.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 1.0, fade_in)

	# 如果有淡出效果
	if fade_out > 0 and duration > fade_out:
		var timer = Timer.new()
		sprite.add_child(timer)
		timer.wait_time = duration - fade_out
		timer.one_shot = true
		timer.timeout.connect(func():
			var tween = create_tween()
			tween.tween_property(sprite, "modulate:a", 0.0, fade_out)
		)
		timer.start()

# 为组合效果创建动画效果
func _create_animation_effect_for_combined(effect_id: String, position: Vector2, params: Dictionary, parent: Node) -> void:
	# 创建动画节点
	var anim_player = AnimationPlayer.new()
	var root = Node2D.new()
	root.name = "Animation_" + effect_id
	root.add_child(anim_player)
	anim_player.name = "AnimationPlayer"
	parent.add_child(root)
	root.position = position

	# 设置动画名称
	var animation_name = params.get("animation_name", "")

	# 设置动画库
	var animation_library = params.get("animation_library", "")
	if not animation_library.is_empty() and ResourceLoader.exists(animation_library):
		anim_player.add_animation_library("", load(animation_library))

	# 设置颜色
	if params.has("color"):
		root.modulate = params.color

	# 设置缩放
	if params.has("scale"):
		root.scale = params.scale

	# 设置旋转
	if params.has("rotation"):
		root.rotation = params.rotation

	# 设置Z索引
	if params.has("z_index"):
		root.z_index = params.z_index

	# 设置速度
	var speed_scale = params.get("speed_scale", 1.0)
	anim_player.speed_scale = speed_scale

	# 如果有动画名称，播放动画
	if not animation_name.is_empty():
		anim_player.play(animation_name)

# 为组合效果创建着色器效果
func _create_shader_effect_for_combined(effect_id: String, position: Vector2, params: Dictionary, parent: Node) -> void:
	# 创建着色器节点
	var shader_node = ColorRect.new()
	shader_node.name = "Shader_" + effect_id
	parent.add_child(shader_node)
	shader_node.position = position

	# 设置大小
	var size = params.get("size", Vector2(100, 100))
	shader_node.size = size

	# 设置着色器路径
	var shader_path = params.get("shader_path", "")
	if not shader_path.is_empty() and ResourceLoader.exists(shader_path):
		var shader_material = ShaderMaterial.new()
		shader_material.shader = load(shader_path)
		shader_node.material = shader_material

	# 设置着色器参数
	var shader_params = params.get("shader_params", {})
	for param_name in shader_params:
		if shader_node.material:
			shader_node.material.set_shader_parameter(param_name, shader_params[param_name])

	# 设置颜色
	if params.has("color"):
		shader_node.color = params.color

	# 设置缩放
	if params.has("scale"):
		shader_node.scale = params.scale

	# 设置Z索引
	if params.has("z_index"):
		shader_node.z_index = params.z_index

# 组合效果超时处理
func _on_combined_timeout(effect_id: String, root: Node, timer: Timer) -> void:
	# 移除定时器
	timer.queue_free()

	# 检查效果是否仍然存在
	if not _effect_nodes.has(effect_id):
		return

	# 移除效果节点
	root.queue_free()

	# 移除效果节点引用
	_effect_nodes.erase(effect_id)

	# 发送效果完成信号
	effect_completed.emit(effect_id)

# 创建伤害数字效果
func _create_damage_number(effect_id: String, position: Vector2, params: Dictionary) -> void:
	# 从对象池获取文本节点
	var label = _get_from_pool("text") as Label

	# 设置位置
	label.position = position

	# 设置伤害值
	var value = params.get("value", 0.0)
	var is_critical = params.get("is_critical", false)

	# 设置文本
	label.text = str(int(value))

	# 设置字体大小
	var font_size = params.get("font_size", 16)
	if is_critical:
		font_size *= 1.5

	# 设置字体
	var font = label.get_theme_font("font")
	if font:
		label.add_theme_font_size_override("font_size", font_size)

	# 设置颜色
	var color = params.get("color", Color(1.0, 0.0, 0.0, 1.0))  # 默认红色
	label.modulate = color

	# 设置描边
	var outline_size = params.get("outline_size", 1.0)
	var outline_color = params.get("outline_color", Color(0.0, 0.0, 0.0, 1.0))  # 默认黑色

	# 设置Z索引
	var z_index = params.get("z_index", 100)  # 伤害数字通常应该在最上层
	label.z_index = z_index

	# 设置持续时间
	var duration = params.get("duration", 1.0)

	# 设置移动和淡出
	var move_distance = params.get("move_distance", Vector2(0, -50))
	var fade_out_start = params.get("fade_out_start", 0.7)  # 开始淡出的时间点（相对于持续时间的比例）

	# 显示标签
	label.show()

	# 存储效果节点
	_effect_nodes[effect_id] = label

	# 创建动画
	var tween = create_tween()
	tween.set_parallel(true)

	# 移动动画
	tween.tween_property(label, "position", label.position + move_distance, duration)

	# 淡出动画
	tween.tween_property(label, "modulate:a", 0.0, duration * (1.0 - fade_out_start)).set_delay(duration * fade_out_start)

	# 如果是暴击，添加缩放动画
	if is_critical:
		tween.tween_property(label, "scale", Vector2(1.2, 1.2), duration * 0.2)
		tween.tween_property(label, "scale", Vector2(1.0, 1.0), duration * 0.3).set_delay(duration * 0.2)

	# 动画完成后清理
	tween.tween_callback(_on_damage_number_completed.bind(effect_id, label)).set_delay(duration)

# 伤害数字完成处理
func _on_damage_number_completed(effect_id: String, label: Label) -> void:
	# 检查效果是否仍然存在
	if not _effect_nodes.has(effect_id):
		return

	# 回收标签节点
	_recycle_effect_node(effect_id, label)

	# 移除效果节点引用
	_effect_nodes.erase(effect_id)

	# 发送效果完成信号
	effect_completed.emit(effect_id)

# 创建治疗数字效果
func _create_heal_number(effect_id: String, position: Vector2, params: Dictionary) -> void:
	# 设置治疗颜色
	params["color"] = params.get("color", Color(0.0, 1.0, 0.0, 1.0))  # 默认绿色

	# 使用伤害数字效果的实现
	_create_damage_number(effect_id, position, params)

# 创建状态图标效果
func _create_status_icon(effect_id: String, position: Vector2, params: Dictionary) -> void:
	# 从对象池获取精灵节点
	var sprite = _get_from_pool("sprite") as Sprite2D

	# 设置位置
	sprite.position = position

	# 获取状态类型
	var status_type = params.get("status_type", "")

	# 设置纹理
	var texture_path = _get_status_icon_path(status_type)
	if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)

	# 设置颜色
	if params.has("color"):
		sprite.modulate = params.color

	# 设置缩放
	var scale = params.get("scale", Vector2(1.0, 1.0))
	sprite.scale = scale

	# 设置Z索引
	var z_index = params.get("z_index", 50)  # 状态图标通常应该在较上层
	sprite.z_index = z_index

	# 设置持续时间
	var duration = params.get("duration", 1.0)

	# 设置自动移除
	var auto_remove = params.get("auto_remove", true)

	# 设置淡入淡出
	var fade_in = params.get("fade_in", 0.2)
	var fade_out = params.get("fade_out", 0.2)

	# 显示精灵
	sprite.show()

	# 存储效果节点
	_effect_nodes[effect_id] = sprite

	# 如果有淡入效果
	if fade_in > 0:
		sprite.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 1.0, fade_in)

	# 如果自动移除，设置定时器
	if auto_remove:
		var timer = Timer.new()
		sprite.add_child(timer)
		timer.wait_time = duration - fade_out
		timer.one_shot = true

		# 如果有淡出效果
		if fade_out > 0:
			timer.timeout.connect(_on_status_icon_fade_out.bind(effect_id, sprite, fade_out))
		else:
			timer.timeout.connect(_on_status_icon_timeout.bind(effect_id, sprite, timer))

		timer.start()

# 状态图标淡出处理
func _on_status_icon_fade_out(effect_id: String, sprite: Sprite2D, fade_out: float) -> void:
	# 创建淡出动画
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, fade_out)
	tween.tween_callback(_on_status_icon_timeout.bind(effect_id, sprite, null))

# 状态图标超时处理
func _on_status_icon_timeout(effect_id: String, sprite: Sprite2D, timer: Timer) -> void:
	# 移除定时器
	if timer:
		timer.queue_free()

	# 检查效果是否仍然存在
	if not _effect_nodes.has(effect_id):
		return

	# 回收精灵节点
	_recycle_effect_node(effect_id, sprite)

	# 移除效果节点引用
	_effect_nodes.erase(effect_id)

	# 发送效果完成信号
	effect_completed.emit(effect_id)

# 获取状态图标路径
func _get_status_icon_path(status_type: String) -> String:
	# 根据状态类型返回不同的图标路径
	match status_type:
		"stun":
			return "res://assets/icons/status/stun.png"
		"silence":
			return "res://assets/icons/status/silence.png"
		"disarm":
			return "res://assets/icons/status/disarm.png"
		"root":
			return "res://assets/icons/status/root.png"
		"taunt":
			return "res://assets/icons/status/taunt.png"
		"frozen":
			return "res://assets/icons/status/frozen.png"
		"burning":
			return "res://assets/icons/status/burning.png"
		"poisoned":
			return "res://assets/icons/status/poisoned.png"
		"bleeding":
			return "res://assets/icons/status/bleeding.png"
		"buff":
			return "res://assets/icons/status/buff.png"
		"debuff":
			return "res://assets/icons/status/debuff.png"

	# 默认返回空字符串
	return ""
