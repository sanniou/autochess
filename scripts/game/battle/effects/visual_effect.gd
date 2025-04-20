extends BattleEffect
class_name VisualEffect
## 视觉效果
## 用于显示视觉效果

# 视觉效果类型枚举
enum VisualType {
	PARTICLE,   # 粒子效果
	ANIMATION,  # 动画效果
	SPRITE,     # 精灵效果
	TRAIL,      # 轨迹效果
	BEAM,       # 光束效果
	AREA,       # 区域效果
	IMPACT,     # 冲击效果
	AURA        # 光环效果
}

# 视觉效果属性
var visual_type: int = VisualType.PARTICLE
var scene_path: String = ""
var offset: Vector2 = Vector2.ZERO
var scale_value: Vector2 = Vector2.ONE
var color: Color = Color.WHITE
var modulate_value: Color = Color.WHITE
var z_index: int = 0
var auto_free: bool = true
var visual_node: Node2D = null

# 初始化
func _init(effect_id: String = "", effect_name: String = "", effect_description: String = "", 
		effect_duration: float = 1.0, visual_type_value: int = VisualType.PARTICLE, 
		scene_path_value: String = "", effect_source = null, effect_target = null, 
		effect_params: Dictionary = {}):
	super._init(effect_id, effect_name, effect_description, effect_duration, 
			EffectType.VISUAL, effect_source, effect_target, effect_params)
	
	visual_type = visual_type_value
	scene_path = scene_path_value
	
	# 设置属性
	if effect_params.has("offset"):
		offset = effect_params.offset
	
	if effect_params.has("scale"):
		scale_value = effect_params.scale
	
	if effect_params.has("color"):
		color = effect_params.color
	
	if effect_params.has("modulate"):
		modulate_value = effect_params.modulate
	
	if effect_params.has("z_index"):
		z_index = effect_params.z_index
	
	if effect_params.has("auto_free"):
		auto_free = effect_params.auto_free
	
	# 如果没有指定场景路径，使用默认路径
	if scene_path.is_empty():
		scene_path = _get_default_scene_path(visual_type)
	
	# 设置图标路径
	icon_path = _get_visual_icon_path(visual_type)
	
	# 设置名称和描述
	if name.is_empty():
		name = _get_visual_name(visual_type)
	
	if description.is_empty():
		description = _get_visual_description(visual_type)

# 应用效果
func apply() -> bool:
	if not super.apply():
		return false
	
	# 创建视觉效果
	_create_visual_node()
	
	return true

# 移除效果
func remove() -> bool:
	if not super.remove():
		return false
	
	# 移除视觉效果
	_remove_visual_node()
	
	return true

# 更新效果
func update(delta: float) -> bool:
	if not super.update(delta):
		return false
	
	# 更新视觉效果
	_update_visual_node(delta)
	
	return true

# 创建视觉节点
func _create_visual_node() -> void:
	# 检查场景路径
	if scene_path.is_empty():
		return
	
	# 加载场景资源
	var scene_resource = load(scene_path)
	if not scene_resource:
		return
	
	# 实例化场景
	visual_node = scene_resource.instantiate()
	
	# 设置属性
	visual_node.position = offset
	visual_node.scale = scale_value
	visual_node.modulate = modulate_value
	visual_node.z_index = z_index
	
	# 设置颜色（如果节点支持）
	if visual_node.has_method("set_color"):
		visual_node.set_color(color)
	elif visual_node is GPUParticles2D and visual_node.process_material:
		visual_node.process_material.color = color
	
	# 添加到目标
	if target and is_instance_valid(target):
		target.add_child(visual_node)
	elif source and is_instance_valid(source):
		source.add_child(visual_node)
	else:
		var scene_root = Engine.get_main_loop().current_scene
		scene_root.add_child(visual_node)
	
	# 如果是粒子效果，启动发射
	if visual_node is GPUParticles2D:
		visual_node.emitting = true
	
	# 如果是动画效果，播放动画
	if visual_node.has_node("AnimationPlayer"):
		var anim_player = visual_node.get_node("AnimationPlayer")
		anim_player.play("default")
	
	# 如果是一次性效果，连接完成信号
	if auto_free and visual_node is GPUParticles2D:
		# 使用定时器等待粒子完成
		var timer = Timer.new()
		visual_node.add_child(timer)
		timer.wait_time = visual_node.lifetime
		timer.one_shot = true
		timer.timeout.connect(_on_particles_finished.bind(visual_node))
		timer.start()

# 移除视觉节点
func _remove_visual_node() -> void:
	if visual_node and is_instance_valid(visual_node):
		# 如果是粒子效果，停止发射
		if visual_node is GPUParticles2D:
			visual_node.emitting = false
			
			# 如果设置了自动释放，等待粒子完成后释放
			if auto_free:
				var timer = Timer.new()
				visual_node.add_child(timer)
				timer.wait_time = visual_node.lifetime
				timer.one_shot = true
				timer.timeout.connect(_on_particles_finished.bind(visual_node))
				timer.start()
			else:
				visual_node.queue_free()
		else:
			visual_node.queue_free()
		
		visual_node = null

# 更新视觉节点
func _update_visual_node(delta: float) -> void:
	if not visual_node or not is_instance_valid(visual_node):
		return
	
	# 更新位置（如果目标移动）
	if target and is_instance_valid(target):
		visual_node.global_position = target.global_position + offset
	elif source and is_instance_valid(source):
		visual_node.global_position = source.global_position + offset

# 粒子完成回调
func _on_particles_finished(particle_node: GPUParticles2D) -> void:
	if particle_node and is_instance_valid(particle_node):
		particle_node.queue_free()
		
		if visual_node == particle_node:
			visual_node = null

# 获取默认场景路径
func _get_default_scene_path(visual_type: int) -> String:
	match visual_type:
		VisualType.PARTICLE:
			return "res://scenes/effects/particle_effect.tscn"
		VisualType.ANIMATION:
			return "res://scenes/effects/animation_effect.tscn"
		VisualType.SPRITE:
			return "res://scenes/effects/sprite_effect.tscn"
		VisualType.TRAIL:
			return "res://scenes/effects/trail_effect.tscn"
		VisualType.BEAM:
			return "res://scenes/effects/beam_effect.tscn"
		VisualType.AREA:
			return "res://scenes/effects/area_effect.tscn"
		VisualType.IMPACT:
			return "res://scenes/effects/impact_effect.tscn"
		VisualType.AURA:
			return "res://scenes/effects/aura_effect.tscn"
	
	return ""

# 获取视觉类型图标路径
func _get_visual_icon_path(visual_type: int) -> String:
	match visual_type:
		VisualType.PARTICLE:
			return "res://assets/icons/effects/particle.png"
		VisualType.ANIMATION:
			return "res://assets/icons/effects/animation.png"
		VisualType.SPRITE:
			return "res://assets/icons/effects/sprite.png"
		VisualType.TRAIL:
			return "res://assets/icons/effects/trail.png"
		VisualType.BEAM:
			return "res://assets/icons/effects/beam.png"
		VisualType.AREA:
			return "res://assets/icons/effects/area.png"
		VisualType.IMPACT:
			return "res://assets/icons/effects/impact.png"
		VisualType.AURA:
			return "res://assets/icons/effects/aura.png"
	
	return ""

# 获取视觉类型名称
func _get_visual_name(visual_type: int) -> String:
	match visual_type:
		VisualType.PARTICLE:
			return "粒子效果"
		VisualType.ANIMATION:
			return "动画效果"
		VisualType.SPRITE:
			return "精灵效果"
		VisualType.TRAIL:
			return "轨迹效果"
		VisualType.BEAM:
			return "光束效果"
		VisualType.AREA:
			return "区域效果"
		VisualType.IMPACT:
			return "冲击效果"
		VisualType.AURA:
			return "光环效果"
	
	return "未知视觉效果"

# 获取视觉类型描述
func _get_visual_description(visual_type: int) -> String:
	match visual_type:
		VisualType.PARTICLE:
			return "显示粒子效果"
		VisualType.ANIMATION:
			return "播放动画效果"
		VisualType.SPRITE:
			return "显示精灵效果"
		VisualType.TRAIL:
			return "显示轨迹效果"
		VisualType.BEAM:
			return "显示光束效果"
		VisualType.AREA:
			return "显示区域效果"
		VisualType.IMPACT:
			return "显示冲击效果"
		VisualType.AURA:
			return "显示光环效果"
	
	return "显示未知视觉效果"

# 获取效果数据
func get_data() -> Dictionary:
	var data = super.get_data()
	data["visual_type"] = visual_type
	data["scene_path"] = scene_path
	data["offset"] = {"x": offset.x, "y": offset.y}
	data["scale"] = {"x": scale_value.x, "y": scale_value.y}
	data["color"] = {"r": color.r, "g": color.g, "b": color.b, "a": color.a}
	data["modulate"] = {"r": modulate_value.r, "g": modulate_value.g, "b": modulate_value.b, "a": modulate_value.a}
	data["z_index"] = z_index
	data["auto_free"] = auto_free
	return data

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> VisualEffect:
	var effect = VisualEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("duration", 1.0),
		data.get("visual_type", VisualType.PARTICLE),
		data.get("scene_path", ""),
		source,
		target,
		{}
	)
	
	# 设置偏移
	var offset_data = data.get("offset", {})
	if offset_data.has("x") and offset_data.has("y"):
		effect.offset = Vector2(offset_data.x, offset_data.y)
	
	# 设置缩放
	var scale_data = data.get("scale", {})
	if scale_data.has("x") and scale_data.has("y"):
		effect.scale_value = Vector2(scale_data.x, scale_data.y)
	
	# 设置颜色
	var color_data = data.get("color", {})
	if color_data.has("r") and color_data.has("g") and color_data.has("b") and color_data.has("a"):
		effect.color = Color(color_data.r, color_data.g, color_data.b, color_data.a)
	
	# 设置调制
	var modulate_data = data.get("modulate", {})
	if modulate_data.has("r") and modulate_data.has("g") and modulate_data.has("b") and modulate_data.has("a"):
		effect.modulate_value = Color(modulate_data.r, modulate_data.g, modulate_data.b, modulate_data.a)
	
	# 设置Z索引
	effect.z_index = data.get("z_index", 0)
	
	# 设置自动释放
	effect.auto_free = data.get("auto_free", true)
	
	return effect
