extends AbilityEffect
class_name VisualEffect
## 视觉效果
## 显示视觉效果

# 视觉效果类型
var visual_type: String = "particle"  # 视觉效果类型(particle/sprite/animation)
var visual_path: String = ""          # 视觉效果资源路径

# 应用效果
func apply() -> void:
	if not target or not is_instance_valid(target):
		return
	
	# 根据视觉效果类型应用效果
	match visual_type:
		"particle":
			_apply_particle_effect()
		"sprite":
			_apply_sprite_effect()
		"animation":
			_apply_animation_effect()
		_:
			_apply_default_effect()

# 应用粒子效果
func _apply_particle_effect() -> void:
	if not target or not is_instance_valid(target):
		return
	
	# 创建粒子效果
	var particles = GPUParticles2D.new()
	
	# 设置粒子属性
	particles.amount = 30
	particles.lifetime = 1.0
	particles.explosiveness = 0.8
	particles.randomness = 0.5
	
	# 加载粒子材质
	if visual_path and ResourceLoader.exists(visual_path):
		var material = load(visual_path)
		if material:
			particles.process_material = material
	else:
		# 创建默认粒子材质
		var material = ParticleProcessMaterial.new()
		material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		material.emission_sphere_radius = 10.0
		material.direction = Vector3(0, -1, 0)
		material.spread = 45.0
		material.gravity = Vector3(0, 98, 0)
		material.initial_velocity_min = 50.0
		material.initial_velocity_max = 100.0
		material.color = Color(0.8, 0.2, 0.8, 0.8)
		particles.process_material = material
	
	# 添加到目标
	target.add_child(particles)
	
	# 设置一次性发射
	particles.emitting = true
	particles.one_shot = true
	
	# 创建定时器，在粒子完成后移除
	var timer = Timer.new()
	timer.wait_time = particles.lifetime * 1.5
	timer.one_shot = true
	timer.autostart = true
	timer.timeout.connect(func(): 
		particles.queue_free()
		timer.queue_free()
	)
	target.add_child(timer)

# 应用精灵效果
func _apply_sprite_effect() -> void:
	if not target or not is_instance_valid(target):
		return
	
	# 创建精灵
	var sprite = Sprite2D.new()
	
	# 加载纹理
	if visual_path and ResourceLoader.exists(visual_path):
		var texture = load(visual_path)
		if texture:
			sprite.texture = texture
	else:
		# 创建默认纹理
		var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.8, 0.2, 0.8, 0.8))
		var texture = ImageTexture.create_from_image(image)
		sprite.texture = texture
	
	# 设置属性
	sprite.scale = Vector2(1.5, 1.5)
	
	# 添加到目标
	target.add_child(sprite)
	
	# 创建消失动画
	var tween = target.create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0), duration if duration > 0 else 1.0)
	tween.tween_callback(sprite.queue_free)

# 应用动画效果
func _apply_animation_effect() -> void:
	if not target or not is_instance_valid(target):
		return
	
	# 创建动画精灵
	var anim_sprite = AnimatedSprite2D.new()
	
	# 加载动画
	if visual_path and ResourceLoader.exists(visual_path):
		var sprite_frames = load(visual_path)
		if sprite_frames:
			anim_sprite.sprite_frames = sprite_frames
	else:
		# 创建默认动画
		var frames = SpriteFrames.new()
		frames.add_animation("default")
		
		# 创建默认帧
		for i in range(4):
			var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
			image.fill(Color(0.8, 0.2, 0.8, 0.8 - i * 0.2))
			var texture = ImageTexture.create_from_image(image)
			frames.add_frame("default", texture)
		
		frames.set_animation_speed("default", 10)
		frames.set_animation_loop("default", false)
		
		anim_sprite.sprite_frames = frames
	
	# 设置属性
	anim_sprite.scale = Vector2(1.5, 1.5)
	
	# 添加到目标
	target.add_child(anim_sprite)
	
	# 播放动画
	anim_sprite.play("default")
	
	# 创建定时器，在动画完成后移除
	var timer = Timer.new()
	timer.wait_time = duration if duration > 0 else 1.0
	timer.one_shot = true
	timer.autostart = true
	timer.timeout.connect(func(): 
		anim_sprite.queue_free()
		timer.queue_free()
	)
	target.add_child(timer)

# 应用默认效果
func _apply_default_effect() -> void:
	if not target or not is_instance_valid(target):
		return
	
	# 创建默认特效
	var effect = ColorRect.new()
	effect.color = Color(0.8, 0.2, 0.8, 0.5)  # 紫色
	effect.size = Vector2(40, 40)
	effect.position = Vector2(-20, -20)
	
	# 添加到目标
	target.add_child(effect)
	
	# 创建消失动画
	var tween = target.create_tween()
	tween.tween_property(effect, "modulate", Color(1, 1, 1, 0), duration if duration > 0 else 1.0)
	tween.tween_callback(effect.queue_free)
