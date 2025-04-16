extends WeatherEffect
class_name FogEffect
## 雾天特效
## 实现雾天的视觉和音效

# 雾气纹理
var fog_texture = preload("res://assets/images/vfx/fog.png")

# 雾气层
var fog_layers = []

# 初始化
func _ready():
	super._ready()

# 创建粒子系统
func _create_particles() -> void:
	# 创建雾气粒子
	particles = CPUParticles2D.new()
	particles.name = "FogParticles"
	particles.amount = 50
	particles.lifetime = 10.0
	particles.texture = fog_texture
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(1000, 500)
	particles.direction = Vector2(1, 0)
	particles.spread = 10
	particles.gravity = Vector2(0, 0)
	particles.initial_velocity_min = 10
	particles.initial_velocity_max = 20
	particles.scale_amount = 200.0
	particles.scale_amount_random = 100.0
	particles.color = Color(0.9, 0.9, 0.9, 0.2)
	add_child(particles)
	
	# 创建多层雾气
	_create_fog_layers()

# 创建雾气层
func _create_fog_layers() -> void:
	# 创建3层雾气
	for i in range(3):
		var fog_layer = Sprite2D.new()
		fog_layer.texture = fog_texture
		fog_layer.modulate = Color(1, 1, 1, 0.1)
		fog_layer.scale = Vector2(10, 5)
		fog_layer.position = Vector2(randf_range(-500, 500), randf_range(-300, 300))
		add_child(fog_layer)
		fog_layers.append(fog_layer)
		
		# 创建雾气移动动画
		var tween = create_tween().set_loops()
		tween.tween_property(fog_layer, "position:x", fog_layer.position.x + 1000, 60.0)
		tween.tween_property(fog_layer, "position:x", fog_layer.position.x - 1000, 0.0)

# 获取音效路径
func _get_sound_path() -> String:
	return "res://assets/audio/sfx/weather/wind.ogg"

# 设置强度
func _set_intensity(value: float) -> void:
	if particles:
		# 调整雾气数量
		particles.amount = int(50 * value)
		
		# 调整雾气透明度
		particles.color.a = 0.2 * value
	
	# 调整雾气层透明度
	for layer in fog_layers:
		layer.modulate.a = 0.1 * value

# 设置风向
func _set_wind_direction(direction: Vector2) -> void:
	if particles:
		# 调整雾气方向
		particles.direction = direction.normalized()
	
	# 调整雾气层移动方向
	for i in range(fog_layers.size()):
		var layer = fog_layers[i]
		var tween = create_tween().set_loops()
		tween.tween_property(layer, "position", layer.position + direction * 1000, 60.0 / (1 + i * 0.5))
		tween.tween_property(layer, "position", layer.position - direction * 1000, 0.0)

# 设置风力
func _set_wind_strength(strength: float) -> void:
	if particles:
		# 调整雾气速度
		particles.initial_velocity_min = 10 * (1 + strength)
		particles.initial_velocity_max = 20 * (1 + strength)
